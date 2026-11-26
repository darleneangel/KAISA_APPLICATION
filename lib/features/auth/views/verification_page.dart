import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/repositories/resident_account_repository.dart';
import '../../../core/services/social_otp_service.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key, this.social = false});
  final bool social;
  @override
  State<VerificationPage> createState() => _VerificationPageState();
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

class _VerificationPageState extends State<VerificationPage> {
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

  bool _socialSent = false;
  bool _leaving = false;
  String? _deliveryError;
  bool _initialRequestFailed = false;
  String get _email =>
      (_social
              ? Supabase.instance.client.auth.currentUser?.email
              : ResidentAccountRepository.instance.email)
          ?.trim() ??
      '';
  bool get _hasContext =>
      _email.isNotEmpty &&
      (!_social ||
          (Supabase.instance.client.auth.currentSession != null &&
              _isCurrentSocial));

  void _notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _back() async {
    if (_leaving) return;
    final destination = _social ? '/login' : '/signup';
    setState(() => _leaving = true);
    try {
      if (_social || Supabase.instance.client.auth.currentSession != null) {
        await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
      }
      if (mounted) context.go(destination);
    } catch (error) {
      _notice('Could not return safely. Please try again.');
    } finally {
      if (mounted) setState(() => _leaving = false);
    }
  }

  int _attemptsUsed = 0;
  int _resendsUsed = 0;
  bool _sending = false;
  bool _detectedSocial = false;
  StreamSubscription<AuthState>? _authSubscription;
  String? _initializedContext;
  bool get _social => widget.social || _detectedSocial || _isCurrentSocial;
  bool get _isCurrentSocial {
    final user = Supabase.instance.client.auth.currentUser;
    return user != null && SocialOtpService.instance.isSocial(user);
  }

  bool get _codeComplete =>
      _fields.every((c) => RegExp(r'^\d$').hasMatch(c.text));

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      final start = value.length == 6 ? 0 : index;
      final count = value.length < 6 - start ? value.length : 6 - start;
      for (var n = 0; n < count; n++) {
        _fields[start + n].text = value[n];
      }
      final next = start + count;
      _focus[next < 6 ? next : 5].requestFocus();
    } else if (value.isNotEmpty && index < 5) {
      _focus[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focus[index - 1].requestFocus();
    }
    setState(() {});
  }

  final _fields = List.generate(6, (_) => TextEditingController());
  final _focus = List.generate(6, (_) => FocusNode());
  Timer? _timer;
  int _seconds = 0;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (_) {
        if (!mounted || _leaving || _busy) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _syncVerificationContext();
        });
      },
      onError: (Object error) {
        if (mounted && !_leaving) {
          setState(
            () => _deliveryError =
                'Could not restore sign-in. Please return to login and try again.',
          );
        }
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncVerificationContext();
    });
  }

  void _syncVerificationContext() {
    if (!mounted || _leaving || _busy || _sending) return;
    if (_isCurrentSocial) _detectedSocial = true;
    if (!_hasContext) {
      _initializedContext = null;
      _socialSent = false;
      _timer?.cancel();
      setState(() {
        _seconds = 0;
        _deliveryError =
            'No active verification request. Return to sign in or sign up and try again.';
      });
      return;
    }
    final key = _social
        ? 'social:${Supabase.instance.client.auth.currentUser!.id}'
        : 'email:$_email';
    if (_initializedContext == key) return;
    _initializedContext = key;
    _socialSent = false;
    setState(() {
      _deliveryError = null;
      _initialRequestFailed = false;
      _attemptsUsed = 0;
      _resendsUsed = 0;
    });
    if (_social) {
      _sendSocialCode();
    } else {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _slideTimer?.cancel();
    _timer?.cancel();
    for (final c in _fields) {
      c.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_seconds <= 1) {
        t.cancel();
        setState(() => _seconds = 0);
      } else {
        setState(() => _seconds--);
      }
    });
  }

  void _applyOtpState(KaisaOtpState state) {
    if (!mounted) return;
    _timer?.cancel();
    setState(() {
      _attemptsUsed = state.attempts;
      _resendsUsed = state.resends;
      _seconds = state.secondsLeft;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _seconds <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _seconds--);
    });
  }

  Future<void> _refreshSocialState() async {
    try {
      _applyOtpState(await SocialOtpService.instance.status());
    } catch (error) {
      debugPrint('KAISA OTP status: $error');
    }
  }

  Future<void> _sendSocialCode() async {
    if (_socialSent || _sending || _leaving) return;
    if (!_hasContext) {
      setState(
        () => _deliveryError =
            'Your sign-in session is missing. Return to login and try again.',
      );
      return;
    }
    _socialSent = true;
    setState(() {
      _sending = true;
      _deliveryError = null;
    });
    try {
      final state = await SocialOtpService.instance.send();
      _applyOtpState(state);
      if (!mounted) return;
      setState(() => _initialRequestFailed = false);
      if (state.verified) {
        await _showSuccessAndOpenHome();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state.sent
                ? 'Your six-digit KAISA code has been sent.'
                : 'An OTP has already been requested. Check your inbox.',
          ),
        ),
      );
    } catch (error) {
      _socialSent = false;
      if (mounted) {
        setState(() {
          _initialRequestFailed = true;
          _deliveryError =
              'Unable to request your verification code. Try again or return to login.';
          _seconds = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not request OTP: $error')),
        );
      }
      await _refreshSocialState();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _showSuccessAndOpenHome() async {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.forest,
                size: 62,
              ),
              SizedBox(height: 16),
              Text(
                'Verification successful!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 10),
              Text(
                'Welcome to KAISA. Continuing to your account...',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    if (!mounted || _leaving) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      context.go('/login');
      return;
    }
    final profile = await Supabase.instance.client
        .from('resident_profiles')
        .select('profile_completed')
        .eq('user_id', user.id)
        .maybeSingle();
    if (!mounted || _leaving) return;
    context.go(
      profile?['profile_completed'] == true
          ? '/resident/home'
          : '/profile-setup',
    );
  }

  Future<void> _verify() async {
    if (_busy || _sending || _leaving) return;
    if (!_hasContext) {
      _notice('No active verification request. Please go back and try again.');
      return;
    }
    if (_fields.any((c) => c.text.isEmpty)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter all six digits.')));
      return;
    }
    if (_social) {
      if (_seconds <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This code expired. Request a new code.'),
          ),
        );
        return;
      }
      if (_attemptsUsed >= 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Five attempts used. Resend a new code.'),
          ),
        );
        return;
      }
      setState(() => _busy = true);
      try {
        await SocialOtpService.instance.verify(
          _fields.map((c) => c.text).join(),
        );
        if (!mounted) return;
        await _showSuccessAndOpenHome();
      } catch (error) {
        await _refreshSocialState();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$error')));
        }
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }
    final email = ResidentAccountRepository.instance.email;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please return to Sign Up.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await Supabase.instance.client.auth.verifyOTP(
        email: email,
        token: _fields.map((c) => c.text).join(),
        type: OtpType.signup,
      );
      if (!mounted) return;
      if (result.session == null) {
        throw const AuthException('Verification did not establish a session.');
      }
      ResidentAccountRepository.instance.markEmailVerified();
      context.go('/profile-setup');
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not verify this code.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    if (_busy || _sending || _leaving) return;
    if (!_hasContext) {
      _notice('No email or active session. Please go back and sign in again.');
      return;
    }
    if (_seconds > 0) return;
    if (_social) {
      if (_resendsUsed >= 5 || _sending) return;
      setState(() => _sending = true);
      try {
        final service = SocialOtpService.instance;
        final current = await service.status();
        final state = current.verified
            ? current
            : current.expiresAt == null
            ? await service.send()
            : await service.resend();
        _applyOtpState(state);
        if (!mounted) return;
        setState(() {
          _deliveryError = null;
          _initialRequestFailed = false;
        });
        if (state.verified) {
          await _showSuccessAndOpenHome();
          return;
        }
        for (final field in _fields) {
          field.clear();
        }
        if (mounted) {
          _focus.first.requestFocus();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A fresh verification code has been sent.'),
            ),
          );
        }
      } catch (error) {
        if (mounted) {
          setState(
            () =>
                _deliveryError = 'Could not resend the code. Please try again.',
          );
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Could not resend: $error')));
        }
        await _refreshSocialState();
      } finally {
        if (mounted) setState(() => _sending = false);
      }
      return;
    }
    final email = ResidentAccountRepository.instance.email;
    if (email == null || email.isEmpty) {
      _notice('Email missing. Return to sign up.');
      return;
    }
    setState(() {
      _sending = true;
      _deliveryError = null;
    });
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      if (!mounted) return;
      for (final c in _fields) {
        c.clear();
      }
      _focus.first.requestFocus();
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email requested.')),
      );
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
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
                                  child: _buildVerificationCard(
                                    isMobile: mobile,
                                  ),
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
            tooltip: _t('Back', 'Bumalik'),
            onPressed: (_busy || _leaving) ? null : _back,
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

  Widget _buildVerificationCard({required bool isMobile}) {
    final expired = _social && _seconds <= 0;
    final exhausted = _social && _attemptsUsed >= 5;
    final resendLimit = _social && _resendsUsed >= 5;
    final blocked = _busy || _sending || _leaving;
    final canVerify =
        _hasContext && !blocked && !expired && !exhausted && _codeComplete;
    final canResend = _hasContext && !blocked && _seconds <= 0 && !resendLimit;
    final countdown =
        '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}';
    return Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _t('ACCOUNT VERIFICATION', 'PAG-VERIFY NG ACCOUNT'),
                  style: GoogleFonts.inter(
                    color: _CivicColors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _t('Verify your email', 'I-verify ang iyong email'),
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
                  _t(
                    'Enter your six-digit verification code to continue.',
                    'Ilagay ang anim na digit na verification code upang magpatuloy.',
                  ),
                  style: GoogleFonts.inter(
                    color: _CivicColors.muted,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                if (_email.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.alternate_email_rounded,
                        color: _CivicColors.green,
                        size: 18,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          _email,
                          style: GoogleFonts.inter(
                            color: _CivicColors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_deliveryError != null || !_hasContext) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4ED),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _deliveryError ??
                          _t(
                            'No active verification request. Go back and sign in again.',
                            'Walang aktibong verification request. Bumalik at mag-login muli.',
                          ),
                      style: GoogleFonts.inter(
                        color: const Color(0xFF9B422A),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  _t('Verification code', 'Verification code'),
                  style: GoogleFonts.inter(
                    color: _CivicColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                LayoutBuilder(
                  builder: (context, box) => Row(
                    children: [
                      for (var i = 0; i < 6; i++) ...[
                        if (i > 0) const SizedBox(width: 5),
                        Expanded(
                          child: TextField(
                            controller: _fields[i],
                            focusNode: _focus[i],
                            enabled: !blocked,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            textInputAction: i == 5
                                ? TextInputAction.done
                                : TextInputAction.next,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: _CivicColors.ink,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: _CivicColors.input,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: _CivicColors.border,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: _CivicColors.green,
                                  width: 1.8,
                                ),
                              ),
                            ),
                            onChanged: (value) => _onDigitChanged(i, value),
                            onSubmitted: (_) {
                              if (i == 5 &&
                                  _hasContext &&
                                  !blocked &&
                                  !expired &&
                                  !exhausted &&
                                  _codeComplete)
                                _verify();
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _sending
                      ? _t('Requesting code…', 'Humihiling ng code…')
                      : !_hasContext
                      ? _t('Sign in again to continue.', 'Mag-login muli.')
                      : exhausted
                      ? _t(
                          'Attempt limit reached. Request a new code.',
                          'Naabot ang limitasyon. Humiling ng bagong code.',
                        )
                      : expired
                      ? _t(
                          'No active code. Request a new code.',
                          'Walang aktibong code. Humiling ng bago.',
                        )
                      : _seconds > 0
                      ? (_social
                            ? _t(
                                'Code expires in $countdown',
                                'Mag-e-expire sa $countdown',
                              )
                            : _t(
                                'Resend available in $countdown',
                                'Maaaring mag-resend sa $countdown',
                              ))
                      : _t(
                          'You may request another code.',
                          'Maaari nang humiling ng bagong code.',
                        ),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: expired
                        ? const Color(0xFF9B422A)
                        : _CivicColors.muted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: canVerify ? _verify : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _CivicColors.forest,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                _t(
                                  'Verify & continue',
                                  'I-verify at magpatuloy',
                                ),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const CircleAvatar(
                              radius: 12,
                              backgroundColor: _CivicColors.gold,
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: _CivicColors.forest,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 5),
                TextButton(
                  onPressed: canResend ? _resend : null,
                  child: Text(
                    resendLimit
                        ? _t('Resend limit reached', 'Naabot ang resend limit')
                        : _seconds > 0
                        ? _t(
                            'Resend in ${_seconds}s',
                            'Mag-resend sa ${_seconds}s',
                          )
                        : _initialRequestFailed
                        ? _t('Retry sending code', 'Subukang ipadala muli')
                        : _t(
                            'Didn’t get the code? Resend',
                            'Walang code? Ipadala muli',
                          ),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: (_busy || _leaving) ? null : _back,
                  child: Text(
                    _t(
                      'Return to sign in or sign up',
                      'Bumalik sa login o sign up',
                    ),
                    style: GoogleFonts.inter(
                      color: _CivicColors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Divider(color: _CivicColors.border),
                const SizedBox(height: 5),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: _CivicColors.green,
                      size: 17,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        _t(
                          'Your account is protected with one-time email verification.',
                          'Protektado ang iyong account sa pamamagitan ng one-time email verification.',
                        ),
                        style: GoogleFonts.inter(
                          color: _CivicColors.muted,
                          fontSize: 11,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
