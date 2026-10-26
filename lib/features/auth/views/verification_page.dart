import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _VerificationPageState extends State<VerificationPage> {
  bool _socialSent = false;
  int _attemptsUsed = 0;
  int _resendsUsed = 0;
  bool _sending = false;
  bool get _social => widget.social;
  final _fields = List.generate(6, (_) => TextEditingController());
  final _focus = List.generate(6, (_) => FocusNode());
  Timer? _timer;
  int _seconds = 60;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    if (!_social) _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _social) _sendSocialCode();
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
    if (_socialSent || _sending) return;
    _socialSent = true;
    setState(() => _sending = true);
    try {
      final state = await SocialOtpService.instance.send();
      _applyOtpState(state);
      if (!mounted) return;
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
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not request OTP: $error')),
        );
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
                'Welcome to KAISA. Opening your homepage...',
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
    if (mounted) context.go('/resident/home');
  }

  Future<void> _verify() async {
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
    if (_seconds > 0) return;
    if (_social) {
      if (_resendsUsed >= 5 || _sending) return;
      setState(() => _sending = true);
      try {
        final state = await SocialOtpService.instance.resend();
        _applyOtpState(state);
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
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Could not resend: $error')));
        await _refreshSocialState();
      } finally {
        if (mounted) setState(() => _sending = false);
      }
      return;
    }
    final email = ResidentAccountRepository.instance.email;
    if (email == null || email.isEmpty) return;
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
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _social
        ? (Supabase.instance.client.auth.currentUser?.email ?? '')
        : (ResidentAccountRepository.instance.email ?? '');
    const forest = Color(0xFF175C42);
    const ink = Color(0xFF18392C);
    const muted = Color(0xFF667970);
    const yellow = Color(0xFFFFD65A);
    final expired = _social && _seconds <= 0;
    final attemptsExhausted = _social && _attemptsUsed >= 5;
    final resendUnavailable = _social && _resendsUsed >= 5;
    final canVerify = !_busy && !_sending && !expired && !attemptsExhausted;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFCFA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: ink,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 10,
                              ),
                            ),
                            onPressed: () async {
                              if (_social) {
                                await Supabase.instance.client.auth.signOut();
                                if (context.mounted) context.go('/login');
                              } else {
                                context.go('/signup');
                              }
                            },
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              size: 19,
                            ),
                            label: const Text('Back'),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Center(
                          child: Container(
                            height: 76,
                            width: 76,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF5ED),
                              borderRadius: BorderRadius.circular(23),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(
                                  Icons.mark_email_read_outlined,
                                  size: 37,
                                  color: forest,
                                ),
                                Positioned(
                                  right: 11,
                                  top: 12,
                                  child: Container(
                                    width: 13,
                                    height: 13,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: yellow,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 23),
                        const Text(
                          'One last step.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                            letterSpacing: -0.8,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: 9),
                        const Text(
                          'Verify your email to continue',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: muted,
                          ),
                        ),
                        const SizedBox(height: 15),
                        if (email.isNotEmpty)
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F1),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.alternate_email_rounded,
                                    size: 16,
                                    color: forest,
                                  ),
                                  const SizedBox(width: 7),
                                  Flexible(
                                    child: Text(
                                      email,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: ink,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 40),
                        const Text(
                          'Verification code',
                          style: TextStyle(
                            color: ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 13),
                        LayoutBuilder(
                          builder: (context, box) {
                            const gap = 8.0;
                            final cellWidth = ((box.maxWidth - gap * 5) / 6)
                                .clamp(34.0, 64.0);
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                6,
                                (index) => SizedBox(
                                  width: cellWidth,
                                  child: TextField(
                                    controller: _fields[index],
                                    focusNode: _focus[index],
                                    enabled: !_busy && !_sending,
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    textInputAction: index == 5
                                        ? TextInputAction.done
                                        : TextInputAction.next,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(1),
                                    ],
                                    style: const TextStyle(
                                      color: ink,
                                      fontSize: 23,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    decoration: InputDecoration(
                                      counterText: '',
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 18,
                                            horizontal: 0,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(13),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFDCE7DF),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(13),
                                        borderSide: const BorderSide(
                                          color: forest,
                                          width: 2,
                                        ),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      if (value.isNotEmpty && index < 5) {
                                        _focus[index + 1].requestFocus();
                                      } else if (value.isEmpty && index > 0) {
                                        _focus[index - 1].requestFocus();
                                      }
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 17),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              expired
                                  ? Icons.info_outline_rounded
                                  : Icons.schedule_rounded,
                              color: expired ? const Color(0xFFBB674C) : muted,
                              size: 17,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              expired
                                  ? 'Code expired. Request a new one.'
                                  : 'Code expires in 00:${_seconds.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: expired
                                    ? const Color(0xFFBB674C)
                                    : muted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        if (attemptsExhausted) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'This code can no longer be used. Request a new code.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFBB674C),
                            ),
                          ),
                        ],
                        const SizedBox(height: 27),
                        SizedBox(
                          height: 54,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: forest,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: canVerify ? _verify : null,
                            child: _busy
                                ? const SizedBox(
                                    width: 21,
                                    height: 21,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Verify & continue',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(width: 9),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Didn’t get the code?',
                              style: TextStyle(color: muted, fontSize: 13),
                            ),
                            const SizedBox(width: 4),
                            TextButton(
                              onPressed:
                                  (_seconds > 0 ||
                                      _sending ||
                                      resendUnavailable)
                                  ? null
                                  : _resend,
                              child: Text(
                                resendUnavailable
                                    ? 'Contact support'
                                    : (_seconds > 0
                                          ? 'Resend in ${_seconds}s'
                                          : 'Resend code'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(color: Color(0xFFE6ECE8)),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'SECURE VERIFICATION',
                                style: TextStyle(
                                  color: Color(0xFF91A29A),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.3,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(color: Color(0xFFE6ECE8)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 13),
                        const Text(
                          'Your account is protected with one-time email verification.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: muted,
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
}
