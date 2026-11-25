import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/security/kaisa_password_policy.dart';
import 'package:google_fonts/google_fonts.dart';

/// OTP password recovery; the Supabase Reset Password template uses {{ .Token }}.
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, required this.email});
  final String email;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
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

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _codeFocus = FocusNode();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _otpVerified = false;
  bool _busy = false;
  bool _resending = false;
  bool _hidden = true;
  bool _confirmHidden = true;
  String? _error;

  // The first recovery email is requested on Forgot Password. Begin the
  // visible cooldown as soon as the resident reaches this page.
  static const Duration _resendCooldown = Duration(seconds: 60);
  static final RegExp _exactSixDigits = RegExp(r'^[0-9]{6}$');
  Timer? _resendTimer;
  DateTime? _nextResendAt;
  int _resendSeconds = 60;

  static const _forest = Color(0xFF00492C);
  static const _ink = Color(0xFF18392C);
  static const _muted = Color(0xFF667970);

  bool _tagalog = false;
  String _t(String en, String tl) => _tagalog ? tl : en;

  // Documented civic milestones. Keep each image and caption together.
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

  @override
  void initState() {
    super.initState();
    _email.text = widget.email;
    _startResendCooldown();
  }

  /// Updates the visible countdown from a deadline, rather than decrementing
  /// a counter, so backgrounded browser tabs do not extend the wait.
  void _startResendCooldown() {
    _resendTimer?.cancel();
    _nextResendAt = DateTime.now().add(_resendCooldown);
    _resendSeconds = _resendCooldown.inSeconds;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final millis =
          _nextResendAt?.difference(DateTime.now()).inMilliseconds ?? 0;
      final seconds = millis <= 0 ? 0 : (millis + 999) ~/ 1000;
      if (seconds != _resendSeconds) {
        setState(() => _resendSeconds = seconds);
      }
      if (seconds == 0) {
        timer.cancel();
        _resendTimer = null;
      }
    });
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _resendTimer?.cancel();
    _email.dispose();
    _codeFocus.dispose();
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
    if (_busy ||
        _resending ||
        _otpVerified ||
        (_nextResendAt?.isAfter(DateTime.now()) ?? false)) {
      return;
    }
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
      // Uses Supabase Auth's password-recovery endpoint. Its per-user
      // cooldown must also be set to at least 60 seconds in the dashboard.
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      setState(() {
        _code.clear(); // An earlier code may no longer be the current code.
        _startResendCooldown();
      });
      _notice(
        'If this account exists, a new recovery code has been requested.',
      );
    } on AuthException catch (e) {
      debugPrint(
        'KAISA password recovery resend failed: ${e.message} (${e.statusCode})',
      );
      if (e.statusCode == '429' && mounted) {
        // Respect an additional server-side rate limit as well.
        setState(_startResendCooldown);
      }
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
    if (_busy || _otpVerified) return;
    // Reject any altered/pasted value that is not exactly six ASCII digits
    // before contacting Supabase. Supabase verifies the actual code as well.
    if (!_exactSixDigits.hasMatch(_code.text)) {
      _form.currentState?.validate();
      setState(() => _error = 'Enter exactly 6 numbers for the recovery code.');
      return;
    }
    if (!(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = Supabase.instance.client.auth;
      final result = await auth.verifyOTP(
        email: _email.text.trim(),
        token: _code.text, // Must be exactly 6 digits.
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
      if (mounted) {
        setState(
          () => _error = e.message.toLowerCase().contains('expired')
              ? 'This code has expired. Request a fresh recovery code.'
              : 'The recovery code could not be verified. Check the email and code.',
        );
      }
    } catch (e) {
      debugPrint('KAISA recovery verification error: ${e.runtimeType}');
      if (mounted) {
        setState(
          () => _error = 'Unable to verify the code right now. Try again.',
        );
      }
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
      if (mounted) {
        setState(() => _error = 'Unable to update password: ${e.message}');
      }
    } catch (e) {
      debugPrint('KAISA password update error: ${e.runtimeType}');
      if (mounted) {
        setState(
          () => _error = 'Unable to change password right now. Try again.',
        );
      }
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
    hintStyle: GoogleFonts.inter(fontSize: 13, color: _muted),
    errorMaxLines: 3,
    prefixIcon: Icon(icon, color: _forest, size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: _CivicColors.input,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: Color(0xFFDCE7DF)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: _forest, width: 2),
    ),
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(
      text,
      style: const TextStyle(
        color: _ink,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  /// A single editable field renders six visual slots. Keeping one controller
  /// preserves paste, autofill, keyboard editing, and the existing Form validator.
  Widget _buildOtpInput() {
    final digitStyle = GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: _ink,
      fontFeatures: const [FontFeature.tabularFigures()],
      height: 1.2,
    );
    final scaledHeight = MediaQuery.textScalerOf(context).scale(20) * 1.2;
    final boxHeight = scaledHeight + 28 > 50 ? scaledHeight + 28 : 50.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          alignment: Alignment.topCenter,
          children: [
            // Decorative slots never intercept pointer events or accessibility.
            ExcludeSemantics(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_code, _codeFocus]),
                  builder: (context, _) {
                    final value = _code.value;
                    final digits = value.text;
                    final cursor = value.selection.isValid
                        ? value.selection.extentOffset.clamp(0, 5).toInt()
                        : digits.length.clamp(0, 5).toInt();
                    return Row(
                      children: List.generate(6, (index) {
                        final active =
                            !_busy && _codeFocus.hasFocus && cursor == index;
                        final filled = index < digits.length;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: index == 5 ? 0 : 5),
                            child: AnimatedContainer(
                              duration: _reduceMotion
                                  ? Duration.zero
                                  : const Duration(milliseconds: 150),
                              height: boxHeight,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _busy
                                    ? const Color(0xFFF0F3F1)
                                    : _CivicColors.input,
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: active
                                      ? _forest
                                      : filled
                                      ? const Color(0xFF9DB7A8)
                                      : _CivicColors.border,
                                  width: active ? 1.8 : 1,
                                ),
                              ),
                              child: Text(
                                filled ? digits[index] : '',
                                style: digitStyle,
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ),
            // The real field stays in the Form, with visible validation messages.
            // Its transparent glyphs are represented by the slots above.
            Semantics(
              label: _t(
                'Six-digit recovery code',
                'Anim na digit na recovery code',
              ),
              child: TextFormField(
                controller: _code,
                focusNode: _codeFocus,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                autocorrect: false,
                enableSuggestions: false,
                maxLength: 6,
                showCursor: false,
                style: digitStyle.copyWith(color: Colors.transparent),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    return newValue.text.length <= 6 ? newValue : oldValue;
                  }),
                ],
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  counterText: '',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: (boxHeight - scaledHeight) / 2,
                  ),
                  errorMaxLines: 2,
                  errorStyle: GoogleFonts.inter(fontSize: 11),
                ),
                validator: (s) => !_exactSixDigits.hasMatch(s ?? '')
                    ? 'Enter exactly 6 numeric digits'
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          _t('Six digits only', 'Anim na numero lamang'),
          style: GoogleFonts.inter(fontSize: 11, color: _muted),
        ),
      ],
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final light = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: _CivicColors.green),
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
                  final mobile = constraints.maxWidth < 700;
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: mobile ? 12 : 40,
                          vertical: mobile ? 8 : 16,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildHeader(
                              isMobile: mobile,
                              smallPhone: constraints.maxWidth < 390,
                            ),
                            if (mobile) _dots(),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: mobile ? 6 : 18,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: mobile ? 340 : 380,
                                  ),
                                  child: _buildResetCard(isMobile: mobile),
                                ),
                              ),
                            ),
                            _buildFooter(isMobile: mobile),
                          ],
                        ),
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

  Widget _buildHeader({required bool isMobile, required bool smallPhone}) =>
      Row(
        children: [
          IconButton(
            tooltip: _otpVerified
                ? _t('Back to login', 'Bumalik sa login')
                : _t(
                    'Back to forgot password',
                    'Bumalik sa pagbawi ng password',
                  ),
            onPressed: _busy
                ? null
                : () => _leave(_otpVerified ? '/login' : '/forgot-password'),
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

  Widget _buildResetCard({required bool isMobile}) => Container(
    width: double.infinity,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(isMobile ? 14 : 17),
      border: Border.all(color: _CivicColors.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1800301B),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          height: 4,
          width: double.infinity,
          child: ColoredBox(color: _CivicColors.gold),
        ),
        Padding(
          padding: EdgeInsets.all(isMobile ? 14 : 20),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _t('ACCOUNT RECOVERY', 'PAGBAWI NG ACCOUNT'),
                  style: GoogleFonts.inter(
                    color: _forest,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _otpVerified
                      ? _t('Create a new password', 'Gumawa ng bagong password')
                      : _t(
                          'Verify your identity',
                          'I-verify ang iyong pagkakakilanlan',
                        ),
                  style: GoogleFonts.outfit(
                    color: _CivicColors.forest,
                    fontSize: isMobile ? 22 : 26,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    letterSpacing: -.7,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _otpVerified
                      ? _t(
                          'Your recovery code is verified. Choose a strong new password.',
                          'Na-verify ang code. Pumili ng matibay na password.',
                        )
                      : _t(
                          'Enter the six-digit code sent to your registered email.',
                          'Ilagay ang anim na digit na code na ipinadala sa iyong email.',
                        ),
                  style: GoogleFonts.inter(
                    color: _muted,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                if (!_otpVerified) ...[
                  _label(_t('Account email', 'Email ng account')),
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
                  const SizedBox(height: 12),
                  _label(
                    _t(
                      'Six-digit recovery code',
                      'Anim na digit na recovery code',
                    ),
                  ),
                  _buildOtpInput(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: (_resending || _busy || _resendSeconds > 0)
                          ? null
                          : _resend,
                      child: Text(
                        _resending
                            ? _t('Sending...', 'Ipinapadala...')
                            : _resendSeconds > 0
                            ? _t(
                                'Resend code in ${_resendSeconds}s',
                                'Ipadala muli sa ${_resendSeconds}s',
                              )
                            : _t('Resend code', 'Ipadala muli ang code'),
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
                  const SizedBox(height: 12),
                  _label(_t('New password', 'Bagong password')),
                  TextFormField(
                    controller: _password,
                    enabled: !_busy,
                    obscureText: _hidden,
                    onChanged: (_) => setState(() {}),
                    decoration: _fieldDecoration(
                      'Create a strong password',
                      Icons.lock_outline_rounded,
                      suffix: IconButton(
                        tooltip: _hidden ? 'Show password' : 'Hide password',
                        onPressed: () => setState(() => _hidden = !_hidden),
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
                  KaisaPasswordStrengthIndicator(password: _password.text),
                  const SizedBox(height: 10),
                  _label(
                    _t(
                      'Confirm new password',
                      'Kumpirmahin ang bagong password',
                    ),
                  ),
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
                        onPressed: () =>
                            setState(() => _confirmHidden = !_confirmHidden),
                        icon: Icon(
                          _confirmHidden
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (s) =>
                        s != _password.text ? 'Passwords do not match' : null,
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 10),
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
                const SizedBox(height: 14),
                SizedBox(
                  height: 44,
                  child: FilledButton.icon(
                    onPressed:
                        _busy ||
                            (_otpVerified &&
                                !KaisaPasswordPolicy.isStrong(_password.text))
                        ? null
                        : (_otpVerified ? _update : _verifyCode),
                    style: FilledButton.styleFrom(
                      backgroundColor: _CivicColors.forest,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.lock_reset_rounded),
                    label: Text(
                      _busy
                          ? (_otpVerified
                                ? _t('Updating...', 'Ina-update...')
                                : _t('Verifying...', 'Bine-verify...'))
                          : (_otpVerified
                                ? _t('Update password', 'I-update ang password')
                                : _t(
                                    'Verify recovery code',
                                    'I-verify ang code',
                                  )),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: TextButton(
                    onPressed: _busy ? null : () => _leave('/login'),
                    child: const Text(
                      'Back to login',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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
                  style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

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
