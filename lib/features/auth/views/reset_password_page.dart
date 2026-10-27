import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/security/kaisa_password_policy.dart';

/// OTP password recovery; the Supabase Reset Password template uses {{ .Token }}.
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, required this.email});
  final String email;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _otpVerified = false;
  bool _busy = false;
  bool _resending = false;
  bool _hidden = true;
  bool _confirmHidden = true;
  String? _error;

  static const _forest = Color(0xFF175C42);
  static const _ink = Color(0xFF18392C);
  static const _muted = Color(0xFF667970);

  @override
  void initState() {
    super.initState();
    _email.text = widget.email;
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _resend() async {
    if (_busy || _resending) return;
    final email = _email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _notice('Enter a valid account email first.');
      return;
    }
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      _notice(
        'If this account exists, a new recovery code has been requested.',
      );
    } on AuthException catch (e) {
      debugPrint(
        'KAISA password recovery resend failed: ${e.message} (${e.statusCode})',
      );
      _notice(
        e.statusCode == '429'
            ? 'Too many requests. Please try again later.'
            : 'Could not request another recovery code. Please try again.',
      );
    } catch (e) {
      debugPrint(
        'KAISA password recovery resend network error: ${e.runtimeType}',
      );
      _notice('Network issue. Please try again.');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_busy || _otpVerified || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = Supabase.instance.client.auth;
      final result = await auth.verifyOTP(
        email: _email.text.trim(),
        token: _code.text.trim(),
        type: OtpType.recovery,
      );
      if (result.session == null || auth.currentUser == null) {
        throw const AuthException(
          'Recovery verification did not create a session.',
        );
      }
      if (mounted) setState(() => _otpVerified = true);
    } on AuthException catch (e) {
      debugPrint(
        'KAISA recovery verification failed: ${e.message} (${e.statusCode})',
      );
      if (mounted)
        setState(
          () => _error = e.message.toLowerCase().contains('expired')
              ? 'This code has expired. Request a fresh recovery code.'
              : 'The recovery code could not be verified. Check the email and code.',
        );
    } catch (e) {
      debugPrint('KAISA recovery verification error: ${e.runtimeType}');
      if (mounted)
        setState(
          () => _error = 'Unable to verify the code right now. Try again.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _update() async {
    if (_busy || !_otpVerified || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = Supabase.instance.client.auth;
    var passwordUpdated = false;
    try {
      // An authenticated session was established by the verified recovery OTP.
      if (auth.currentSession == null || auth.currentUser == null) {
        throw const AuthException(
          'Recovery session expired. Request a new code.',
        );
      }
      await auth.updateUser(UserAttributes(password: _password.text));
      passwordUpdated = true;
    } on AuthException catch (e) {
      debugPrint(
        'KAISA password update failed: ${e.message} (${e.statusCode})',
      );
      if (mounted)
        setState(() => _error = 'Unable to update password: ${e.message}');
    } catch (e) {
      debugPrint('KAISA password update error: ${e.runtimeType}');
      if (mounted)
        setState(
          () => _error = 'Unable to change password right now. Try again.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!passwordUpdated) return;
    try {
      await auth.signOut();
    } catch (e) {
      debugPrint('KAISA password updated; logout error: ${e.runtimeType}');
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded, color: _forest, size: 48),
        title: const Text('Password updated!'),
        content: const Text(
          'Your new password is saved. Please sign in again.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Go to login'),
          ),
        ],
      ),
    );
    if (mounted) context.go('/login');
  }

  Future<void> _leave(String route) async {
    if (_busy) return;
    // Verifying a recovery OTP creates a Supabase session. Never retain it
    // when the resident cancels recovery from this screen.
    if (_otpVerified) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (e) {
        debugPrint('KAISA recovery cancel logout: ${e.runtimeType}');
      }
    }
    if (mounted) context.go(route);
  }

  InputDecoration _fieldDecoration(
    String hint,
    IconData icon, {
    Widget? suffix,
  }) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, color: _forest),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFDCE7DF)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _forest, width: 2),
    ),
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Text(
      text,
      style: const TextStyle(
        color: _ink,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFAFCFA),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 36),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 54),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _leave(
                                  _otpVerified ? '/login' : '/forgot-password',
                                ),
                          style: TextButton.styleFrom(
                            foregroundColor: _ink,
                            padding: EdgeInsets.zero,
                          ),
                          icon: const Icon(Icons.arrow_back_rounded, size: 19),
                          label: const Text('Back'),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF5ED),
                            borderRadius: BorderRadius.circular(23),
                          ),
                          child: const Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                size: 39,
                                color: _forest,
                              ),
                              Positioned(
                                right: 12,
                                top: 12,
                                child: CircleAvatar(
                                  radius: 7,
                                  backgroundColor: Color(0xFFFFD65A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 23),
                      Text(
                        _otpVerified
                            ? 'Create a new password'
                            : 'Verify your identity',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _ink,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _otpVerified
                            ? 'Your recovery code is verified. Choose a strong new password for your KAISA account.'
                            : 'Enter the six-digit code sent to your registered email to continue.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _muted,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 30),
                      if (!_otpVerified) ...[
                        _label('Account email'),
                        TextFormField(
                          controller: _email,
                          enabled: !_busy,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: _fieldDecoration(
                            'you@example.com',
                            Icons.alternate_email_rounded,
                          ),
                          validator: (s) =>
                              !RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              ).hasMatch((s ?? '').trim())
                              ? 'Enter a valid email address'
                              : null,
                        ),
                        const SizedBox(height: 17),
                        _label('Six-digit recovery code'),
                        TextFormField(
                          controller: _code,
                          enabled: !_busy,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          decoration: _fieldDecoration(
                            'Enter the code from Gmail',
                            Icons.password_rounded,
                          ),
                          validator: (s) =>
                              !RegExp(r'^\d{6}$').hasMatch((s ?? '').trim())
                              ? 'Enter the complete six-digit code'
                              : null,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: (_resending || _busy) ? null : _resend,
                            child: Text(
                              _resending ? 'Sending...' : 'Resend code',
                            ),
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF5ED),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified_rounded, color: _forest),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Email successfully verified',
                                  style: TextStyle(
                                    color: _ink,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        _label('New password'),
                        TextFormField(
                          controller: _password,
                          enabled: !_busy,
                          obscureText: _hidden,
                          onChanged: (_) => setState(() {}),
                          decoration: _fieldDecoration(
                            'Create a strong password',
                            Icons.lock_outline_rounded,
                            suffix: IconButton(
                              tooltip: _hidden
                                  ? 'Show password'
                                  : 'Hide password',
                              onPressed: () =>
                                  setState(() => _hidden = !_hidden),
                              icon: Icon(
                                _hidden
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (s) => KaisaPasswordPolicy.error(s ?? ''),
                        ),
                        const SizedBox(height: 12),
                        KaisaPasswordStrengthIndicator(
                          password: _password.text,
                        ),
                        const SizedBox(height: 18),
                        _label('Confirm new password'),
                        TextFormField(
                          controller: _confirm,
                          enabled: !_busy,
                          obscureText: _confirmHidden,
                          decoration: _fieldDecoration(
                            'Re-enter your new password',
                            Icons.verified_user_outlined,
                            suffix: IconButton(
                              tooltip: _confirmHidden
                                  ? 'Show confirmation'
                                  : 'Hide confirmation',
                              onPressed: () => setState(
                                () => _confirmHidden = !_confirmHidden,
                              ),
                              icon: Icon(
                                _confirmHidden
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (s) => s != _password.text
                              ? 'Passwords do not match'
                              : null,
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1EC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFB34735),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: Color(0xFF913B2D),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 54,
                        child: FilledButton.icon(
                          onPressed:
                              _busy ||
                                  (_otpVerified &&
                                      !KaisaPasswordPolicy.isStrong(
                                        _password.text,
                                      ))
                              ? null
                              : (_otpVerified ? _update : _verifyCode),
                          style: FilledButton.styleFrom(
                            backgroundColor: _forest,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          icon: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.lock_reset_rounded),
                          label: Text(
                            _busy
                                ? (_otpVerified
                                      ? 'Updating...'
                                      : 'Verifying...')
                                : (_otpVerified
                                      ? 'Update password'
                                      : 'Verify recovery code'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 13),
                      Center(
                        child: TextButton(
                          onPressed: _busy ? null : () => _leave('/login'),
                          child: const Text(
                            'Back to login',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Row(
                        children: [
                          Expanded(child: Divider(color: Color(0xFFE6ECE8))),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'ACCOUNT SECURITY',
                              style: TextStyle(
                                color: Color(0xFF91A29A),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Color(0xFFE6ECE8))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _otpVerified
                            ? 'Choose a password you have not used before. Never share it.'
                            : 'Only a valid emailed recovery code can authorize a password reset. Never share your code.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _muted,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
