import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/kaisa_auth_service.dart';
import '../../../shared/repositories/resident_account_repository.dart';
import '../widgets/kaisa_auth_slideshow_background.dart';
import '../widgets/kaisa_terms_privacy_dialog.dart';
import '../../../core/security/kaisa_password_policy.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _hide = true, _hideConfirm = true, _agreed = false;
  bool _emailEdited = false;
  bool get _strongPassword => KaisaPasswordPolicy.isStrong(_password.text);

  // This is a local FORMAT / obvious-test-address check, not a mailbox lookup.
  // Supabase's emailed signup OTP is what proves access to a real inbox.
  static String? _validateEmail(String? raw) {
    final email = (raw ?? '').trim();
    if (email.isEmpty) return 'Please enter your email address.';
    if (email.length > 254 || email.contains('..')) {
      return 'Enter a valid email address.';
    }

    final parts = email.split('@');
    if (parts.length != 2 || parts[0].isEmpty || parts[0].length > 64) {
      return 'Enter an email like name@gmail.com.';
    }

    final local = parts[0];
    final domain = parts[1].toLowerCase();
    if (local.startsWith('.') ||
        local.endsWith('.') ||
        !RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+$").hasMatch(local)) {
      return 'Enter a valid email address.';
    }

    // Requires domain labels separated by dots; rejects spaces, doubled dots,
    // misplaced hyphens, and one-character top-level domains.
    const domainPattern =
        r'^[a-z0-9]+(?:[a-z0-9-]*[a-z0-9])?(?:\.[a-z0-9]+(?:[a-z0-9-]*[a-z0-9])?)+$';
    if (domain.length > 253 || !RegExp(domainPattern).hasMatch(domain)) {
      return 'Check the email domain (for example, gmail.com).';
    }
    final tld = domain.split('.').last;
    if (tld.length < 2 || RegExp(r'^\d+$').hasMatch(tld)) {
      return 'Check the email domain (for example, gmail.com).';
    }

    // These are reserved for examples/testing; they cannot receive a real
    // KAISA verification email. A random address at gmail.com cannot be
    // identified as fake from its spelling alone.
    const reservedDomains = {'example.com', 'example.net', 'example.org'};
    const reservedSuffixes = ['.test', '.invalid', '.example', '.localhost'];
    if (reservedDomains.contains(domain) ||
        domain == 'localhost' ||
        reservedSuffixes.any(domain.endsWith)) {
      return 'Use a real inbox, not an example or test email.';
    }

    const frequentTypos = {
      'gmail.con',
      'gmail.cmo',
      'gmail.comm',
      'gmial.com',
      'gamil.com',
      'yahoo.con',
      'outlook.con',
      'hotmail.con',
    };
    if (frequentTypos.contains(domain)) {
      return 'Please double-check the email domain for typos.';
    }

    return null;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool _emailBusy = false;
  Future<void> _submit() async {
    if (_emailBusy || !_form.currentState!.validate()) return;
    if (!_strongPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose a strong password before registering.'),
        ),
      );
      return;
    }
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and privacy notice.'),
        ),
      );
      return;
    }
    setState(() => _emailBusy = true);
    try {
      final result = await KaisaAuthService.instance.signUp(
        _email.text.trim(),
        _password.text,
      );
      if (!mounted) return;
      final user = result.user;
      if (user == null) {
        throw const AuthException(
          'Could not create account. Please try again.',
        );
      }

      // Supabase may intentionally return an obfuscated user when an email
      // is already registered. In that case it did NOT register the password
      // entered here. Don't advance to a signup OTP that was never sent.
      // Keep the message generic to avoid exposing whether an email exists.
      if (result.session == null && user.identities?.isEmpty == true) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              duration: Duration(seconds: 8),
              content: Text(
                'If you already have a KAISA account, sign in with your '
                'original method or use Forgot Password. Otherwise, '
                'check your email for a registration code.',
              ),
            ),
          );
        return;
      }

      ResidentAccountRepository.instance.setPrototypeAccount(
        _email.text.trim(),
      );
      if (result.session != null) {
        ResidentAccountRepository.instance.markEmailVerified();
        context.go('/profile-setup');
      } else {
        context.go('/verification');
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to register. Check your connection and try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _emailBusy = false);
    }
  }

  bool _socialBusy = false;

  Future<void> _socialSignUp(OAuthProvider provider) async {
    if (_socialBusy) return;
    setState(() => _socialBusy = true);
    try {
      // Requires Google/Facebook provider configuration and redirect URLs in Supabase.
      await KaisaAuthService.instance.socialSignIn(provider);
      if (!mounted) return;
      // OAuth login completes on redirect. Do not fake verification or account creation.
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Social sign-in unavailable. Configure this provider in Supabase. $error',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _socialBusy = false);
    }
  }

  // Acceptance is explicit: showing the document never auto-checks the box.
  Future<bool> _openTermsPrivacy() async {
    if (_emailBusy || _socialBusy) return false;
    final accepted = await KaisaTermsPrivacyDialog.show(
      context,
      initiallyAccepted: _agreed,
    );
    if (!mounted) return false;
    if (accepted != null) {
      setState(() => _agreed = accepted);
    }
    return accepted == true;
  }

  // Social signup also requires agreement, without modifying OAuth behavior.
  Future<void> _socialSignUpWithConsent(OAuthProvider provider) async {
    if (!_agreed) {
      final accepted = await _openTermsPrivacy();
      if (!accepted) return;
    }
    if (!mounted) return;
    await _socialSignUp(provider);
  }

  // Existing registration and OAuth methods above are preserved. Only the
  // email field's client-side validation and visual feedback are enhanced.
  static const Color _forest = Color(0xFF00492C);
  static const Color _ink = Color(0xFF18392C);
  static const Color _muted = Color(0xFF667970);
  static const Color _border = Color(0xFFDCE7DF);

  InputDecoration _fieldStyle(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9DA9A2)),
      prefixIcon: Icon(icon, color: _forest, size: 19),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _forest, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFB34735)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFB34735), width: 1.8),
      ),
    );
  }

  Widget _fieldLabel(String value) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      value,
      style: const TextStyle(
        color: _ink,
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isBusy = _emailBusy || _socialBusy;
    return Scaffold(
      backgroundColor: const Color(0xFF002818),
      body: Stack(
        children: [
          const Positioned.fill(child: KaisaAuthSlideshowBackground()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final mobile = constraints.maxWidth < 520;
                final outerX = mobile ? 17.0 : 28.0;
                final outerY = mobile ? 14.0 : 22.0;
                final inside = mobile ? 22.0 : 29.0;
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.symmetric(
                    horizontal: outerX,
                    vertical: outerY,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight > outerY * 2
                          ? constraints.maxHeight - outerY * 2
                          : 0.0,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 410),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: isBusy
                                      ? null
                                      : () => context.go('/login'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    disabledForegroundColor: Colors.white54,
                                    padding: EdgeInsets.zero,
                                  ),
                                  icon: const Icon(
                                    Icons.arrow_back_rounded,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Back to login',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                ClipOval(
                                  child: SizedBox(
                                    height: 35,
                                    width: 35,
                                    child: Image.asset(
                                      'assets/images/kaisa_logo.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, error, stackTrace) =>
                                          const Icon(
                                            Icons.diversity_3_rounded,
                                            size: 26,
                                            color: Colors.white,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'KAISA',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(17),
                                border: Border.all(
                                  color: const Color(0xFFE3ECE6),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 32,
                                    offset: const Offset(0, 16),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(inside),
                                child: Form(
                                  key: _form,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFE8F2EC),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.person_add_alt_1_rounded,
                                              color: _forest,
                                              size: 23,
                                            ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF2F6F2),
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                            child: const Text(
                                              'RESIDENT REGISTRATION',
                                              style: TextStyle(
                                                fontSize: 9,
                                                letterSpacing: 0.8,
                                                color: _forest,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 15),
                                      const Text(
                                        'Create your account.',
                                        style: TextStyle(
                                          color: _ink,
                                          fontSize: 25,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.7,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Connect with your community. Set up '
                                        'your KAISA account to get started.',
                                        style: TextStyle(
                                          color: _muted,
                                          fontSize: 12.5,
                                          height: 1.45,
                                        ),
                                      ),
                                      const SizedBox(height: 19),
                                      _fieldLabel('Email address'),
                                      TextFormField(
                                        controller: _email,
                                        enabled: !isBusy,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        autofillHints: const [
                                          AutofillHints.email,
                                        ],
                                        autovalidateMode:
                                            AutovalidateMode.onUserInteraction,
                                        onChanged: (_) => setState(() {
                                          _emailEdited = true;
                                        }),
                                        decoration:
                                            _fieldStyle(
                                              'name@gmail.com',
                                              Icons.alternate_email_rounded,
                                              suffix:
                                                  _emailEdited &&
                                                      _email.text
                                                          .trim()
                                                          .isNotEmpty &&
                                                      _validateEmail(
                                                            _email.text,
                                                          ) !=
                                                          null
                                                  ? const Icon(
                                                      Icons
                                                          .error_outline_rounded,
                                                      color: Color(0xFFB34735),
                                                      size: 20,
                                                    )
                                                  : null,
                                            ).copyWith(
                                              errorMaxLines: 2,
                                              errorStyle: const TextStyle(
                                                color: Color(0xFFB34735),
                                                fontSize: 11.5,
                                                height: 1.2,
                                              ),
                                            ),
                                        validator: _validateEmail,
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Enter an email you can open. KAISA will send a verification code to it.',
                                        style: TextStyle(
                                          color: _muted,
                                          fontSize: 10.5,
                                          height: 1.35,
                                        ),
                                      ),
                                      const SizedBox(height: 13),
                                      _fieldLabel('Password'),
                                      TextFormField(
                                        controller: _password,
                                        enabled: !isBusy,
                                        onChanged: (_) {
                                          setState(() {});
                                          if (_confirm.text.isNotEmpty) {
                                            _form.currentState?.validate();
                                          }
                                        },
                                        obscureText: _hide,
                                        textInputAction: TextInputAction.next,
                                        autofillHints: const [
                                          AutofillHints.newPassword,
                                        ],
                                        decoration: _fieldStyle(
                                          'Create a strong password',
                                          Icons.lock_outline_rounded,
                                          suffix: IconButton(
                                            tooltip: _hide
                                                ? 'Show password'
                                                : 'Hide password',
                                            onPressed: () =>
                                                setState(() => _hide = !_hide),
                                            icon: Icon(
                                              _hide
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                        .visibility_off_outlined,
                                              size: 19,
                                              color: _muted,
                                            ),
                                          ),
                                        ),
                                        validator: (s) =>
                                            KaisaPasswordPolicy.error(s ?? ''),
                                      ),
                                      const SizedBox(height: 9),
                                      KaisaPasswordStrengthIndicator(
                                        password: _password.text,
                                      ),
                                      const SizedBox(height: 13),
                                      _fieldLabel('Confirm password'),
                                      TextFormField(
                                        controller: _confirm,
                                        enabled: !isBusy,
                                        obscureText: _hideConfirm,
                                        textInputAction: TextInputAction.done,
                                        autofillHints: const [
                                          AutofillHints.newPassword,
                                        ],
                                        onFieldSubmitted: (_) {
                                          if (!isBusy) _submit();
                                        },
                                        decoration: _fieldStyle(
                                          'Re-enter your password',
                                          Icons.verified_user_outlined,
                                          suffix: IconButton(
                                            tooltip: _hideConfirm
                                                ? 'Show confirmation'
                                                : 'Hide confirmation',
                                            onPressed: () => setState(
                                              () =>
                                                  _hideConfirm = !_hideConfirm,
                                            ),
                                            icon: Icon(
                                              _hideConfirm
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                        .visibility_off_outlined,
                                              color: _muted,
                                              size: 19,
                                            ),
                                          ),
                                        ),
                                        validator: (s) => s != _password.text
                                            ? 'Passwords do not match'
                                            : null,
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Checkbox(
                                            value: _agreed,
                                            activeColor: _forest,
                                            visualDensity:
                                                VisualDensity.compact,
                                            onChanged: isBusy
                                                ? null
                                                : (value) {
                                                    if (value == false) {
                                                      setState(
                                                        () => _agreed = false,
                                                      );
                                                    } else {
                                                      _openTermsPrivacy();
                                                    }
                                                  },
                                          ),
                                          Expanded(
                                            child: Wrap(
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              spacing: 3,
                                              children: [
                                                const Text(
                                                  'I agree to KAISA’s',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    height: 1.4,
                                                    color: _ink,
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: isBusy
                                                      ? null
                                                      : () =>
                                                            _openTermsPrivacy(),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  child: const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          vertical: 3,
                                                        ),
                                                    child: Text(
                                                      'Terms and Privacy Notice',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        height: 1.4,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        decoration:
                                                            TextDecoration
                                                                .underline,
                                                        decorationThickness:
                                                            1.2,
                                                        color: _forest,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 11),
                                      SizedBox(
                                        height: 47,
                                        child: FilledButton(
                                          onPressed:
                                              (_emailBusy ||
                                                  _socialBusy ||
                                                  _validateEmail(_email.text) !=
                                                      null ||
                                                  !_strongPassword ||
                                                  !_agreed)
                                              ? null
                                              : _submit,
                                          style: FilledButton.styleFrom(
                                            backgroundColor: _forest,
                                            foregroundColor: Colors.white,
                                            disabledBackgroundColor:
                                                const Color(0xFFC3D4C7),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(11),
                                            ),
                                          ),
                                          child: _emailBusy
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                )
                                              : const Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      'Create account',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 13.5,
                                                      ),
                                                    ),
                                                    SizedBox(width: 8),
                                                    Icon(
                                                      Icons
                                                          .arrow_forward_rounded,
                                                      size: 17,
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      const Row(
                                        children: [
                                          Expanded(
                                            child: Divider(color: _border),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 11,
                                            ),
                                            child: Text(
                                              'OR SIGN UP WITH',
                                              style: TextStyle(
                                                color: _muted,
                                                fontSize: 10,
                                                letterSpacing: 0.8,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Divider(color: _border),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _CivicSocialButton(
                                              label: 'Google',
                                              mark: 'G',
                                              color: const Color(0xFF4285F4),
                                              onPressed: isBusy
                                                  ? null
                                                  : () =>
                                                        _socialSignUpWithConsent(
                                                          OAuthProvider.google,
                                                        ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: _CivicSocialButton(
                                              label: 'Facebook',
                                              mark: 'f',
                                              color: const Color(0xFF1877F2),
                                              onPressed: isBusy
                                                  ? null
                                                  : () =>
                                                        _socialSignUpWithConsent(
                                                          OAuthProvider
                                                              .facebook,
                                                        ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 13),
                                      Center(
                                        child: TextButton(
                                          onPressed: isBusy
                                              ? null
                                              : () => context.go('/login'),
                                          child: const Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: 'Already registered? ',
                                                  style: TextStyle(
                                                    color: _muted,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: 'Log in',
                                                  style: TextStyle(
                                                    color: _forest,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'After registration, check your email '
                                        'for the confirmation code. Google and '
                                        'Facebook sign-in continue securely '
                                        'through their providers.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _muted,
                                          fontSize: 10.5,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              'KAISA  •  Connect. Participate. Impact.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10.5,
                                letterSpacing: 0.3,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CivicSocialButton extends StatelessWidget {
  const _CivicSocialButton({
    required this.label,
    required this.mark,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final String mark;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF18392C),
      side: const BorderSide(color: Color(0xFFDCE7DF)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          mark,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}
