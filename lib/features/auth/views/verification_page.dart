import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/repositories/resident_account_repository.dart';
import '../../../core/services/social_otp_service.dart';
import '../../../core/services/kaisa_resident_profile_gate.dart';
import '../widgets/kaisa_auth_slideshow_background.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key, this.social = false});
  final bool social;
  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  bool _socialSent = false;
  int _attemptsUsed = 0;
  int _resendsUsed = 0;
  bool _sending = false;
  bool _canceling = false;
  bool _resendingSignup = false;
  bool _hasSocialCode = false;
  String? _socialError;
  // Supports both explicit router configuration and /verification?mode=social.
  // This prevents a social OTP screen from accidentally running signup OTP logic.
  bool get _social =>
      widget.social ||
      GoRouterState.of(context).uri.queryParameters['mode'] == 'social';
  final _fields = List.generate(6, (_) => TextEditingController());
  final _focus = List.generate(6, (_) => FocusNode());
  Timer? _timer;
  int _seconds = 0;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_social) {
        _sendSocialCode();
      } else {
        _startTimer();
      }
    });
  }

  @override
  void dispose() {
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
      // The server owns validity and attempt limits; this is only a display.
      _seconds = state.secondsLeft < 0 ? 0 : state.secondsLeft;
      _hasSocialCode = _seconds > 0;
      if (_hasSocialCode) _socialSent = true;
      _socialError = null;
    });
    if (_seconds == 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _seconds <= 1) {
        timer.cancel();
        if (mounted) setState(() => _seconds = 0);
        return;
      }
      setState(() => _seconds--);
    });
  }

  Future<void> _refreshSocialState() async {
    try {
      final state = await SocialOtpService.instance.status();
      _applyOtpState(state);
    } catch (error) {
      debugPrint('KAISA OTP status could not be refreshed: $error');
      if (mounted) {
        setState(
          () => _socialError =
              'Cannot check the code status. Try again or return to login.',
        );
      }
    }
  }

  Future<void> _sendSocialCode() async {
    if (_socialSent || _sending || _canceling) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(
        () => _socialError =
            'Your social sign-in session is missing. Return to login and sign in again.',
      );
      return;
    }
    setState(() {
      _sending = true;
      _socialError = null;
    });
    try {
      final state = await SocialOtpService.instance.send();
      if (!mounted) return;
      _socialSent = true;
      _applyOtpState(state);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state.sent
                ? 'Your KAISA verification code has been requested.'
                : 'A code request already exists. Check your email or resend when available.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _socialSent = false;
      setState(() => _socialError = 'Could not request a code: $error');
      // A failed network request may have succeeded on the server.
      await _refreshSocialState();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _cancelVerification() async {
    if (_busy || _canceling) return;
    if (!_social) {
      context.go('/signup');
      return;
    }
    setState(() => _canceling = true);
    try {
      // Social verification is an additional KAISA gate; canceling it must
      // invalidate the signed-in OAuth session, not just change the route.
      await Supabase.instance.client.auth.signOut();
      if (mounted) context.go('/login');
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _socialError = 'Could not securely cancel sign-in: $error',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign-out failed. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _canceling = false);
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
                'Welcome to KAISA. Checking your resident profile...',
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

    // Social sign-in is only complete after the existing social OTP service
    // has successfully verified the code. Now check the actual profile row.
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw const AuthException(
          'Your session has expired. Please sign in again.',
        );
      }
      final destination = await KaisaResidentProfileGate.destinationFor(user);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      context.go(destination);
    } catch (error) {
      debugPrint('KAISA post-OTP profile lookup failed: $error');
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      // An already verified OTP must not be requested a second time merely
      // because the profile lookup failed. Offer a fresh lookup or secure exit.
      await _showProfileLookupRetry();
    }
  }

  Future<void> _showProfileLookupRetry() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Unable to load your profile'),
          content: const Text(
            'Your code was verified, but KAISA could not check whether your '
            'resident profile is complete. Check your connection and retry.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                // OAuth verification creates an authenticated session.
                // Cancel it securely instead of leaving an open session.
                await _cancelVerification();
              },
              child: const Text('Cancel sign-in'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _resolveVerifiedSocialDestination();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resolveVerifiedSocialDestination() async {
    if (!mounted) return;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw const AuthException(
          'Your session has expired. Please sign in again.',
        );
      }
      final destination = await KaisaResidentProfileGate.destinationFor(user);
      if (mounted) context.go(destination);
    } catch (error) {
      debugPrint('KAISA profile lookup retry failed: $error');
      if (mounted) await _showProfileLookupRetry();
    }
  }

  Future<void> _verify() async {
    if (_fields.any((c) => c.text.isEmpty)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter all six digits.')));
      return;
    }
    if (_social) {
      if (!_hasSocialCode || _seconds <= 0) {
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
      if (_busy) return;
      setState(() => _busy = true);
      try {
        await SocialOtpService.instance.verify(
          _fields.map((c) => c.text).join(),
        );
        if (!mounted) return;
        await _showSuccessAndOpenHome();
      } catch (error) {
        await _refreshSocialState();
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$error')));
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
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not verify this code.')),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    if (_busy || _sending || _canceling) return;
    if (_social) {
      if (_resendsUsed >= 5) return;
      if (!_socialSent) {
        await _sendSocialCode();
        return;
      }
      if (_seconds > 0) return;
      setState(() {
        _sending = true;
        _socialError = null;
      });
      try {
        final state = await SocialOtpService.instance.resend();
        if (!mounted) return;
        _applyOtpState(state);
        for (final field in _fields) {
          field.clear();
        }
        _focus.first.requestFocus();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              state.sent
                  ? 'A new verification code has been requested.'
                  : 'A code request already exists. Check your email.',
            ),
          ),
        );
      } catch (error) {
        if (!mounted) return;
        setState(() => _socialError = 'Could not resend code: $error');
        await _refreshSocialState();
      } finally {
        if (mounted) setState(() => _sending = false);
      }
      return;
    }
    if (_seconds > 0 || _resendingSignup) return;
    final email = ResidentAccountRepository.instance.email;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please return to Sign Up.')),
      );
      return;
    }
    setState(() => _resendingSignup = true);
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
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to resend. Check your connection and retry.'),
          ),
        );
      }
      debugPrint('KAISA signup OTP resend error: $error');
    } finally {
      if (mounted) setState(() => _resendingSignup = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI only: the OTP workflow, timers, server-state handling, resend limits,
    // signup verification and social verification methods above are unchanged.
    final email = _social
        ? (Supabase.instance.client.auth.currentUser?.email ?? '')
        : (ResidentAccountRepository.instance.email ?? '');

    const forest = Color(0xFF175C42);
    const ink = Color(0xFF18392C);
    const muted = Color(0xFF667970);
    const border = Color(0xFFDCE7DF);

    final expired = _social && _socialSent && _seconds <= 0;
    final attemptsExhausted = _social && _attemptsUsed >= 5;
    final resendUnavailable = _social && _resendsUsed >= 5;
    final canVerify =
        !_busy &&
        !_sending &&
        !_canceling &&
        (!_social || (_hasSocialCode && !expired && !attemptsExhausted));

    final statusText = _social && _sending
        ? 'Requesting verification code...'
        : _social && !_socialSent
        ? 'No code requested yet.'
        : expired
        ? 'Code expired or unavailable. Request a new one.'
        : _social
        ? 'Code time remaining: ${_seconds ~/ 60}:${(_seconds % 60).toString().padLeft(2, '0')}'
        : _seconds > 0
        ? 'Resend available in $_seconds seconds'
        : 'You can request a new code.';

    return Scaffold(
      backgroundColor: const Color(0xFF002818),
      body: Stack(
        children: [
          const Positioned.fill(child: KaisaAuthSlideshowBackground()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final mobile = constraints.maxWidth < 520;
                final padX = mobile ? 16.0 : 26.0;
                final padY = mobile ? 14.0 : 22.0;
                final cardPadding = mobile ? 20.0 : 28.0;

                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.symmetric(
                    horizontal: padX,
                    vertical: padY,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight > padY * 2
                          ? constraints.maxHeight - padY * 2
                          : 0.0,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 414),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: (_busy || _canceling)
                                      ? null
                                      : _cancelVerification,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    disabledForegroundColor: Colors.white54,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 0,
                                      vertical: 8,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.arrow_back_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    _social
                                        ? 'Back to login'
                                        : 'Back to sign up',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                ClipOval(
                                  child: SizedBox(
                                    width: 35,
                                    height: 35,
                                    child: Image.asset(
                                      'assets/images/kaisa_logo.png',
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                                Icons.diversity_3_rounded,
                                                color: Colors.white,
                                                size: 26,
                                              ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'KAISA',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.16),
                                    blurRadius: 32,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  cardPadding,
                                  mobile ? 23 : 28,
                                  cardPadding,
                                  mobile ? 22 : 26,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Center(
                                      child: Container(
                                        height: 56,
                                        width: 56,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFEAF5ED),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.mark_email_read_outlined,
                                          color: forest,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'One last step.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 25,
                                        height: 1.12,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.6,
                                        color: ink,
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    const Text(
                                      'Verify your email to continue',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.5,
                                        color: muted,
                                      ),
                                    ),
                                    if (email.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Center(
                                        child: Container(
                                          constraints: const BoxConstraints(
                                            maxWidth: 330,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 11,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F6F2),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.alternate_email_rounded,
                                                size: 15,
                                                color: forest,
                                              ),
                                              const SizedBox(width: 7),
                                              Flexible(
                                                child: Text(
                                                  email,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: ink,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 25),
                                    const Text(
                                      'Verification code',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: ink,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        for (
                                          var index = 0;
                                          index < 6;
                                          index++
                                        ) ...[
                                          if (index > 0)
                                            const SizedBox(width: 7),
                                          Expanded(
                                            child: TextField(
                                              controller: _fields[index],
                                              focusNode: _focus[index],
                                              enabled: !_busy && !_sending,
                                              textAlign: TextAlign.center,
                                              keyboardType:
                                                  TextInputType.number,
                                              textInputAction: index == 5
                                                  ? TextInputAction.done
                                                  : TextInputAction.next,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                                LengthLimitingTextInputFormatter(
                                                  1,
                                                ),
                                              ],
                                              style: const TextStyle(
                                                fontSize: 21,
                                                fontWeight: FontWeight.w800,
                                                color: ink,
                                              ),
                                              decoration: InputDecoration(
                                                isDense: true,
                                                counterText: '',
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 14,
                                                      horizontal: 0,
                                                    ),
                                                filled: true,
                                                fillColor: Colors.white,
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: border,
                                                          ),
                                                    ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: forest,
                                                            width: 1.8,
                                                          ),
                                                    ),
                                              ),
                                              onChanged: (value) {
                                                if (value.isNotEmpty &&
                                                    index < 5) {
                                                  _focus[index + 1]
                                                      .requestFocus();
                                                } else if (value.isEmpty &&
                                                    index > 0) {
                                                  _focus[index - 1]
                                                      .requestFocus();
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (_socialError != null) ...[
                                      const SizedBox(height: 14),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF0E9),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          _socialError!,
                                          style: const TextStyle(
                                            color: Color(0xFF994A30),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 15),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          expired
                                              ? Icons.info_outline_rounded
                                              : Icons.schedule_rounded,
                                          size: 17,
                                          color: expired
                                              ? const Color(0xFFBB674C)
                                              : muted,
                                        ),
                                        const SizedBox(width: 7),
                                        Expanded(
                                          child: Text(
                                            statusText,
                                            style: TextStyle(
                                              color: expired
                                                  ? const Color(0xFFBB674C)
                                                  : muted,
                                              fontSize: 12,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (attemptsExhausted) ...[
                                      const SizedBox(height: 10),
                                      const Text(
                                        'This code can no longer be used. '
                                        'Request a new code.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFBB674C),
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 21),
                                    SizedBox(
                                      height: 48,
                                      child: FilledButton(
                                        onPressed: canVerify ? _verify : null,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: forest,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        child: _busy
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
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
                                                    'Verify & continue',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Icon(
                                                    Icons.arrow_forward_rounded,
                                                    size: 18,
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 11),
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 2,
                                      children: [
                                        const Text(
                                          'Didn’t get the code?',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: muted,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed:
                                              (_busy ||
                                                  _canceling ||
                                                  _resendingSignup ||
                                                  _seconds > 0 ||
                                                  _sending ||
                                                  resendUnavailable)
                                              ? null
                                              : _resend,
                                          child: Text(
                                            resendUnavailable
                                                ? 'Resend limit reached'
                                                : (_social && !_socialSent
                                                      ? 'Retry sending code'
                                                      : _seconds > 0
                                                      ? 'Resend in ${_seconds}s'
                                                      : 'Resend code'),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.shield_outlined,
                                    color: Colors.white70,
                                    size: 17,
                                  ),
                                  SizedBox(width: 9),
                                  Expanded(
                                    child: Text(
                                      'Your account is protected with '
                                      'one-time email verification.',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ],
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
