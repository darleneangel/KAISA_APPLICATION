import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/kaisa_auth_service.dart';
import '../../../shared/repositories/resident_account_repository.dart';
import '../widgets/kaisa_terms_privacy_dialog.dart';
import '../../../core/security/kaisa_password_policy.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool _tagalog = false;
  String _t(String en, String tl) => _tagalog ? tl : en;
  static const _slides = <_AchievementSlide>[
    _AchievementSlide(
      'assets/images/cavite/unlad_pier.jpg',
      'https://thecaviterising.com/wp-content/uploads/2023/09/Photo-1-Article-180-091623.png',
      'Unlad Pier opens to the public',
      'Binuksan sa publiko ang Unlad Pier',
      'A waterfront facility supporting local transport and tourism.',
      'Pasilidad sa baybayin para sa transportasyon at turismo.',
      'INFRASTRUCTURE • SEP 2023',
      'The Cavite Rising',
    ),
    _AchievementSlide(
      'assets/images/cavite/corregidor_2025.jpg',
      'https://thecaviterising.com/wp-content/uploads/2025/06/Photo-8-Article-143-060625.jpg',
      'Corregidor tours launched',
      'Inilunsad ang Corregidor tours',
      'The City Tourism Office launched group tours from Unlad Pier.',
      'Inilunsad ng City Tourism Office ang group tours mula sa Unlad Pier.',
      'TOURISM • JUN 2025',
      'The Cavite Rising',
    ),
    _AchievementSlide(
      'assets/images/cavite/regada_foam_2025.jpg',
      'https://media.assettype.com/tribune%2F2025-07-20%2Fq9frrgh4%2FRevelers-enjoying-a-foam-party-Photo-by-Roel-Hoang-Manipon.jpg',
      'Regada community celebration',
      'Pagdiriwang ng Regada',
      'Residents celebrate together at the Regada foam party.',
      'Sama-samang nagdiriwang ang mga residente sa Regada.',
      'COMMUNITY • JUN 2025',
      'Roel Hoang Manipon / Daily Tribune',
    ),
    _AchievementSlide(
      'assets/images/cavite/regada_2025.jpg',
      'https://media.assettype.com/tribune%2F2025-07-20%2Fg6tgw5si%2FFirefighters-drenching-attendees-with-cool-water-Photo-by-Roel-Hoang-Manipon.jpg',
      'Regada Water Festival',
      'Pista ng Regada',
      'The city celebrated local culture through festivities and community activities.',
      'Ipinagdiwang ng lungsod ang kultura sa pamamagitan ng mga gawaing pangkomunidad.',
      'CULTURE • JUN 2025',
      'Roel Hoang Manipon / Daily Tribune',
    ),
  ];
  Timer? _slideTimer;
  int _activeSlide = 0;
  bool _paused = false;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _scheduleSlides();
  }

  void _scheduleSlides() {
    _slideTimer?.cancel();
    _slideTimer = null;
    if (_paused || _reduceMotion) return;
    _slideTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (mounted)
        setState(() => _activeSlide = (_activeSlide + 1) % _slides.length);
    });
  }

  void _selectSlide(int index) {
    setState(() => _activeSlide = (index + _slides.length) % _slides.length);
    _scheduleSlides();
  }

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
    _slideTimer?.cancel();
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
  static const Color _forest = Color(0xFF00301B);
  static const Color _gold = Color(0xFFFDBC19);
  static const Color _ink = Color(0xFF17211B);
  static const Color _muted = Color(0xFF65716B);
  static const Color _border = Color(0xFFE2E9E5);

  InputDecoration _fieldStyle(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        color: const Color(0xFF65716B),
      ),
      prefixIcon: Icon(icon, color: _forest, size: 19),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF4F6FB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _background() {
    final slide = _slides[_activeSlide % _slides.length];
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: _CivicColors.dark),
            AnimatedSwitcher(
              duration: _reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 450),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              layoutBuilder: (current, previous) => Stack(
                fit: StackFit.expand,
                children: [...previous, if (current != null) current],
              ),
              child: SizedBox.expand(
                key: ValueKey(slide.asset),
                child: Image.asset(
                  slide.asset,
                  filterQuality: FilterQuality.high,
                  fit: slide.contain ? BoxFit.contain : BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.network(
                    slide.url,
                    filterQuality: FilterQuality.high,
                    fit: slide.contain ? BoxFit.contain : BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const ColoredBox(color: _CivicColors.dark),
                  ),
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xA6002115),
                    Color(0x5500301B),
                    Color(0xC6002818),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dots() => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      for (var i = 0; i < _slides.length; i++)
        IconButton(
          tooltip: _slides[i].title,
          onPressed: () => _selectSlide(i),
          icon: Icon(
            Icons.circle,
            size: _activeSlide == i ? 13 : 8,
            color: _activeSlide == i ? _CivicColors.gold : Colors.white54,
          ),
        ),
      IconButton(
        tooltip: _paused ? 'Resume slideshow' : 'Pause slideshow',
        onPressed: _reduceMotion
            ? null
            : () {
                setState(() => _paused = !_paused);
                _scheduleSlides();
              },
        color: Colors.white,
        icon: Icon(_paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
      ),
    ],
  );

  Widget _buildHeader({required bool isMobile, required bool smallPhone}) =>
      Row(
        children: [
          IconButton(
            tooltip: _t('Back to login', 'Bumalik sa pag-login'),
            onPressed: (_emailBusy || _socialBusy)
                ? null
                : () => context.go('/login'),
            color: Colors.white,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Image.asset(
            'assets/images/kaisa_logo.png',
            width: isMobile ? 34 : 42,
            height: isMobile ? 34 : 42,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.groups_rounded,
              color: _CivicColors.gold,
              size: 36,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KAISA',
                  style: GoogleFonts.outfit(
                    fontSize: isMobile ? 21 : 25,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                if (!smallPhone)
                  Text(
                    'LUNGSOD NG CAVITE',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      letterSpacing: 1,
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ),
          if (!isMobile) _dots(),
          _buildLanguagePicker(isMobile),
        ],
      );

  Widget _buildLanguagePicker(bool isMobile) => PopupMenuButton<bool>(
    tooltip: 'Choose language / Piliin ang wika',
    initialValue: _tagalog,
    onSelected: (value) => setState(() => _tagalog = value),
    itemBuilder: (_) => const [
      PopupMenuItem(value: false, child: Text('English')),
      PopupMenuItem(value: true, child: Text('Tagalog')),
    ],
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black26,
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.translate_rounded,
            color: _CivicColors.gold,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            _tagalog
                ? (isMobile ? 'FIL' : 'Tagalog')
                : (isMobile ? 'EN' : 'English'),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final light = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: _forest),
    );
    return Theme(
      data: light.copyWith(
        textTheme: Theme.of(
          context,
        ).textTheme.apply(fontFamily: GoogleFonts.inter().fontFamily),
        platform: Theme.of(context).platform,
      ),
      child: Scaffold(
        backgroundColor: _CivicColors.dark,
        body: Stack(
          children: [
            _background(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final mobile = constraints.maxWidth < 850;
                  final compactHeader = constraints.maxWidth < 700;
                  final horizontal = compactHeader ? 12.0 : 40.0;
                  final vertical = compactHeader ? 8.0 : 16.0;
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontal,
                      vertical: vertical,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight - vertical * 2)
                            .clamp(0.0, double.infinity)
                            .toDouble(),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildHeader(
                            isMobile: compactHeader,
                            smallPhone: constraints.maxWidth < 390,
                          ),
                          if (compactHeader) _dots(),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: mobile ? 8 : 16,
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: mobile ? 380 : 820,
                                ),
                                child: _registrationCard(mobile),
                              ),
                            ),
                          ),
                          _buildFooter(isMobile: mobile),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _registrationCard(bool mobile) {
    final isBusy = _emailBusy || _socialBusy;
    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _fieldLabel(_t('Email address', 'Email address')),
        TextFormField(
          controller: _email,
          style: GoogleFonts.inter(fontSize: 14, color: _ink),
          enabled: !isBusy,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: (_) => setState(() {
            _emailEdited = true;
          }),
          decoration:
              _fieldStyle(
                'name@gmail.com',
                Icons.alternate_email_rounded,
                suffix:
                    _emailEdited &&
                        _email.text.trim().isNotEmpty &&
                        _validateEmail(_email.text) != null
                    ? const Icon(
                        Icons.error_outline_rounded,
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
        Text(
          _t(
            'Enter an email you can open. KAISA will send a verification code to it.',
            'Gumamit ng email na mabubuksan mo. Dito ipapadala ang verification code.',
          ),
          style: TextStyle(color: _muted, fontSize: 12, height: 1.35),
        ),
        SizedBox(height: mobile ? 8 : 12),
        _fieldLabel(_t('Password', 'Password')),
        TextFormField(
          controller: _password,
          style: GoogleFonts.inter(fontSize: 14, color: _ink),
          enabled: !isBusy,
          onChanged: (_) {
            setState(() {});
            if (_confirm.text.isNotEmpty) {
              _form.currentState?.validate();
            }
          },
          obscureText: _hide,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          decoration: _fieldStyle(
            _t('Create a strong password', 'Gumawa ng matibay na password'),
            Icons.lock_outline_rounded,
            suffix: IconButton(
              tooltip: _hide ? 'Show password' : 'Hide password',
              onPressed: () => setState(() => _hide = !_hide),
              icon: Icon(
                _hide
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 19,
                color: _muted,
              ),
            ),
          ),
          validator: (s) => KaisaPasswordPolicy.error(s ?? ''),
        ),
        const SizedBox(height: 9),
        KaisaPasswordStrengthIndicator(password: _password.text),
      ],
    );
    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: mobile ? 12 : 0),
        _fieldLabel(_t('Confirm password', 'Kumpirmahin ang password')),
        TextFormField(
          controller: _confirm,
          style: GoogleFonts.inter(fontSize: 14, color: _ink),
          enabled: !isBusy,
          obscureText: _hideConfirm,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          onFieldSubmitted: (_) {
            if (!isBusy) _submit();
          },
          decoration: _fieldStyle(
            _t('Re-enter your password', 'Ilagay muli ang password'),
            Icons.verified_user_outlined,
            suffix: IconButton(
              tooltip: _hideConfirm ? 'Show confirmation' : 'Hide confirmation',
              onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
              icon: Icon(
                _hideConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: _muted,
                size: 19,
              ),
            ),
          ),
          validator: (s) =>
              s != _password.text ? 'Passwords do not match' : null,
        ),

        SizedBox(height: mobile ? 8 : 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Checkbox(
              value: _agreed,
              activeColor: _forest,
              visualDensity: VisualDensity.compact,
              onChanged: isBusy
                  ? null
                  : (value) {
                      if (value == false) {
                        setState(() => _agreed = false);
                      } else {
                        _openTermsPrivacy();
                      }
                    },
            ),
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 3,
                children: [
                  Text(
                    _t('I agree to KAISA’s', 'Sumasang-ayon ako sa'),
                    style: TextStyle(fontSize: 12, height: 1.4, color: _ink),
                  ),
                  InkWell(
                    onTap: isBusy ? null : () => _openTermsPrivacy(),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 3),
                      child: Text(
                        _t(
                          'Terms and Privacy Notice',
                          'Mga Tuntunin at Privacy Notice',
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w800,
                          decoration: TextDecoration.underline,
                          decorationThickness: 1.2,
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
          width: double.infinity,
          child: FilledButton(
            onPressed:
                (_emailBusy ||
                    _socialBusy ||
                    _validateEmail(_email.text) != null ||
                    !_strongPassword ||
                    !_agreed)
                ? null
                : _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 48),
              backgroundColor: _forest,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFC3D4C7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            child: _emailBusy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _t('Create account', 'Gumawa ng account'),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 17),
                    ],
                  ),
          ),
        ),
        SizedBox(height: mobile ? 9 : 14),
        Row(
          children: [
            Expanded(child: Divider(color: _border)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 11),
              child: Text(
                _t('OR SIGN UP WITH', 'O GAMITIN ANG'),
                style: TextStyle(
                  color: _muted,
                  fontSize: 10,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(child: Divider(color: _border)),
          ],
        ),
        SizedBox(height: mobile ? 8 : 12),
        Row(
          children: [
            Expanded(
              child: _CivicSocialButton(
                label: 'Google',
                mark: 'G',
                color: const Color(0xFF4285F4),
                onPressed: isBusy
                    ? null
                    : () => _socialSignUpWithConsent(OAuthProvider.google),
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
                    : () => _socialSignUpWithConsent(OAuthProvider.facebook),
              ),
            ),
          ],
        ),
        SizedBox(height: mobile ? 8 : 12),
        Center(
          child: TextButton(
            onPressed: isBusy ? null : () => context.go('/login'),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: _t('Already registered? ', 'May account na? '),
                    style: TextStyle(
                      color: _muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: _t('Log in', 'Mag-login'),
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
      ],
    );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(mobile ? 16 : 22),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .15),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 5,
            width: double.infinity,
            child: ColoredBox(color: _gold),
          ),
          Padding(
            padding: EdgeInsets.all(mobile ? 16 : 28),
            child: AutofillGroup(
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _t(
                        'RESIDENT REGISTRATION',
                        'PAGPAPAREHISTRO NG RESIDENTE',
                      ),
                      style: GoogleFonts.inter(
                        color: _forest,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _t('Create your account.', 'Gumawa ng account.'),
                      style: GoogleFonts.outfit(
                        color: _forest,
                        fontSize: mobile ? 24 : 32,
                        height: 1.12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.7,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _t(
                        'Join your community on KAISA.',
                        'Makiisa sa komunidad sa KAISA.',
                      ),
                      style: TextStyle(
                        color: _muted,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    SizedBox(height: mobile ? 12 : 18),

                    if (mobile) ...[
                      left,
                      right,
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: left),
                          const SizedBox(width: 28),
                          Expanded(child: right),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter({required bool isMobile}) {
    final slide = _slides[_activeSlide % _slides.length];
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        const Icon(Icons.circle, color: _CivicColors.gold, size: 9),
        Text(
          _t(slide.title, slide.titleTl),
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        Text(
          slide.credit,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
        ),
      ],
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
      foregroundColor: const Color(0xFF17211B),
      side: const BorderSide(color: Color(0xFFE2E9E5)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.string(
          label == 'Google' ? _googleLogoSvg : _facebookLogoSvg,
          width: 21,
          height: 21,
          excludeFromSemantics: true,
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

class _CivicColors {
  const _CivicColors._();

  static const Color dark = Color(0xFF002818);
  static const Color forest = Color(0xFF00301B);
  static const Color green = Color(0xFF00492C);
  static const Color gold = Color(0xFFFDBC19);
  static const Color ink = Color(0xFF17211B);
  static const Color muted = Color(0xFF65716B);
  static const Color input = Color(0xFFF9F9FF);
  static const Color border = Color(0xFFE2E9E5);
}

class _AchievementSlide {
  const _AchievementSlide(
    this.asset,
    this.url,
    this.title,
    this.titleTl,
    this.description,
    this.descriptionTl,
    this.category,
    this.credit, {
    this.contain = false,
  });
  final String asset,
      url,
      title,
      titleTl,
      description,
      descriptionTl,
      category,
      credit;
  final bool contain;
}

const _googleLogoSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48"><path fill="#4285F4" d="M43.6 24.5c0-1.4-.1-2.8-.4-4.1H24v7.8h11a9.4 9.4 0 0 1-4.1 6.2v5.2h6.7c3.9-3.6 6-8.9 6-15.1z"/><path fill="#34A853" d="M24 44c5.5 0 10.1-1.8 13.5-4.9l-6.7-5.2c-1.8 1.2-4.1 2-6.8 2-5.3 0-9.8-3.6-11.4-8.4H5.7v5.4A20 20 0 0 0 24 44z"/><path fill="#FBBC05" d="M12.6 27.5a12 12 0 0 1 0-7.1V15H5.7a20 20 0 0 0 0 17.9l6.9-5.4z"/><path fill="#EA4335" d="M24 12c3 0 5.7 1 7.8 3l5.9-5.9A19.2 19.2 0 0 0 24 4 20 20 0 0 0 5.7 15l6.9 5.4C14.2 15.6 18.7 12 24 12z"/></svg>';
const _facebookLogoSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><circle cx="12" cy="12" r="12" fill="#0866FF"/><path fill="#fff" d="M16.67 15.47l.53-3.47h-3.33V9.75c0-.95.46-1.87 1.95-1.87h1.52V4.93s-1.38-.23-2.7-.23c-2.75 0-4.55 1.67-4.55 4.68V12H7.03v3.47h3.06V24h3.78v-8.53z"/></svg>';
