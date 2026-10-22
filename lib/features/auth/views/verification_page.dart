import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _timer;

  int _secondsRemaining = 60;
  bool _isVerifying = false;

  // Prototype only — will be populated from Supabase Auth session
  final String userEmail = 'resident@example.com';

  bool get _canResend => _secondsRemaining == 0;

  String get _formattedTime {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get _otp {
    return _controllers.map((controller) => controller.text).join();
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();

    for (final controller in _controllers) {
      controller.dispose();
    }

    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }

    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();

    setState(() {
      _secondsRemaining = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (_secondsRemaining <= 1) {
        timer.cancel();

        setState(() {
          _secondsRemaining = 0;
        });

        return;
      }

      setState(() {
        _secondsRemaining--;
      });
    });
  }

  void _handleOtpChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < _focusNodes.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }
  }

  void _handleBackspace(KeyEvent event, int index) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verifyCode() async {
    FocusScope.of(context).unfocus();

    if (_otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: const Text(
            'Please enter the complete 6-digit verification code.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );

      return;
    }

    setState(() {
      _isVerifying = true;
    });

    // Prototype delay simulating Supabase OTP verification
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    setState(() {
      _isVerifying = false;
    });

    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF06392F),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_rounded,
                    color: AppColors.green,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Email Verified!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your email address has been successfully verified. You can now continue setting up your KAISA profile.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFFDDF3DA),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      context.go('/profile-setup');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC5ED89),
                      foregroundColor: const Color(0xFF06392F),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                    label: const Text(
                      'Continue Setup',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _resendCode() {
    if (!_canResend) return;

    for (final controller in _controllers) {
      controller.clear();
    }

    _focusNodes.first.requestFocus();

    _startTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF06392F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          'A new verification code was sent to $userEmail.',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _changeEmail() {
    context.go('/signup');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF084B3B),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF06392F),
                    Color(0xFF084B3B),
                    Color(0xFF0B7153),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -110,
            right: -120,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFC5ED89).withValues(alpha: .13),
                  width: 42,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -110,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFC5ED89).withValues(alpha: .09),
                  width: 45,
                ),
              ),
            ),
          ),
          // Background Glow Orbs
          Positioned(
            top: -90,
            right: -70,
            child: _GlowingOrb(
              color: const Color(0xFFC5ED89).withValues(alpha: 0.18),
              radius: 170,
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _GlowingOrb(
              color: AppColors.green.withValues(alpha: 0.14),
              radius: 150,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _changeEmail,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: Colors.black.withValues(alpha: 0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Dual Logos Header Section (LGU + KAISA PNGs)
                            _BrandedLogoHeader(),

                            const SizedBox(height: 24),

                            // Main Verification Glass Card
                            _GlassContainer(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Verification Badge Icon
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFC5ED89,
                                      ).withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.mark_email_unread_rounded,
                                      color: const Color(0xFFC5ED89),
                                      size: 38,
                                    ),
                                  ),

                                  const SizedBox(height: 18),

                                  const Text(
                                    'Verify Email Address',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  const Text(
                                    'Enter the 6-digit verification code sent to',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: const Color(0xFFDDF3DA),
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  // Email Badge with Change Action
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF105C49),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.border.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          userEmail,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFFC5ED89),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: _changeEmail,
                                          child: const Text(
                                            'Edit',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFFC5ED89),
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // 6-Digit OTP TextFields Row
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: List.generate(6, (index) {
                                      return SizedBox(
                                        width: 50,
                                        height: 58,
                                        child: KeyboardListener(
                                          focusNode: FocusNode(
                                            skipTraversal: true,
                                          ),
                                          onKeyEvent: (event) =>
                                              _handleBackspace(event, index),
                                          child: TextField(
                                            controller: _controllers[index],
                                            focusNode: _focusNodes[index],
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            maxLength: 1,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                            ],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                            ),
                                            decoration: InputDecoration(
                                              counterText: '',
                                              contentPadding: EdgeInsets.zero,
                                              filled: true,
                                              fillColor: const Color(
                                                0xFF105C49,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                borderSide: BorderSide(
                                                  color: AppColors.border
                                                      .withValues(alpha: 0.8),
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                borderSide: BorderSide(
                                                  color: AppColors.border
                                                      .withValues(alpha: 0.8),
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                borderSide: const BorderSide(
                                                  color: const Color(
                                                    0xFFC5ED89,
                                                  ),
                                                  width: 2.0,
                                                ),
                                              ),
                                            ),
                                            onChanged: (value) =>
                                                _handleOtpChanged(value, index),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),

                                  const SizedBox(height: 24),

                                  // Glowing Verify Action Button
                                  _GlowingButton(
                                    label: 'Verify Email',
                                    icon: Icons.verified_user_rounded,
                                    isLoading: _isVerifying,
                                    onPressed: _verifyCode,
                                  ),

                                  const SizedBox(height: 20),

                                  // Resend Code Section
                                  Column(
                                    children: [
                                      const Text(
                                        'Didn\'t receive the code?',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: const Color(0xFFDDF3DA),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (_canResend)
                                        TextButton.icon(
                                          onPressed: _resendCode,
                                          icon: const Icon(
                                            Icons.refresh_rounded,
                                            size: 16,
                                            color: const Color(0xFFC5ED89),
                                          ),
                                          label: const Text(
                                            'Resend Code',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFFC5ED89),
                                            ),
                                          ),
                                        )
                                      else
                                        RichText(
                                          text: TextSpan(
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: const Color(0xFFB5D9CA),
                                            ),
                                            children: [
                                              const TextSpan(
                                                text: 'You can resend in ',
                                              ),
                                              TextSpan(
                                                text: _formattedTime,
                                                style: const TextStyle(
                                                  color: const Color(
                                                    0xFFC5ED89,
                                                  ),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Security Info Banner
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFC5ED89,
                                ).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(
                                    0xFFC5ED89,
                                  ).withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFC5ED89,
                                      ).withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.shield_rounded,
                                      color: Color(0xFFC5ED89),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Email verification confirms your account ownership under RA 10173 data guidelines. Never share your OTP.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFDDF3DA),
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Onboarding Step Indicator
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: AppColors.border.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'STEP 2 OF 3',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                      color: const Color(0xFFB5D9CA),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: AppColors.border.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Step Progress Dots
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                _ProgressDot(completed: true),
                                SizedBox(width: 6),
                                _ProgressDot(active: true),
                                SizedBox(width: 6),
                                _ProgressDot(),
                              ],
                            ),

                            const SizedBox(height: 10),

                            const Center(
                              child: Text(
                                'Account  •  Verification  •  Profile',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFB5D9CA),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// BRANDING LOGO HEADER (LGU Seal + KAISA Logo PNGs)
// -----------------------------------------------------------------------------
class _BrandedLogoHeader extends StatelessWidget {
  const _BrandedLogoHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .18),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/LGU.png',
                height: 64,
                width: 64,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const _LogoFallback(
                  icon: Icons.account_balance_rounded,
                  color: Color(0xFF084B3B),
                ),
              ),
              const SizedBox(width: 20),
              Container(height: 45, width: 1.5, color: const Color(0xFFE2E9E4)),
              const SizedBox(width: 20),
              Image.asset(
                'assets/images/kaisa_logo.png',
                height: 64,
                width: 64,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const _LogoFallback(
                  icon: Icons.diversity_3_rounded,
                  color: Color(0xFF084B3B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'KAISA CAVITE CITY',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _LogoFallback extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _LogoFallback({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

// -----------------------------------------------------------------------------
// GLASS CONTAINER & GLOWING BUTTON COMPONENTS
// -----------------------------------------------------------------------------
class _GlassContainer extends StatelessWidget {
  final Widget child;

  const _GlassContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF06392F).withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: .20),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlowingButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onPressed;

  const _GlowingButton({
    required this.label,
    required this.icon,
    this.isLoading = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC5ED89).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC5ED89),
          foregroundColor: const Color(0xFF06392F),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: const Color(0xFF06392F),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(icon, size: 20),
                ],
              ),
      ),
    );
  }
}

class _ProgressDot extends StatelessWidget {
  final bool active;
  final bool completed;

  const _ProgressDot({this.active = false, this.completed = false});

  @override
  Widget build(BuildContext context) {
    if (completed) {
      return Container(
        width: 24,
        height: 6,
        decoration: BoxDecoration(
          color: AppColors.green,
          borderRadius: BorderRadius.circular(20),
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 24 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFC5ED89) : AppColors.border,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _GlowingOrb extends StatelessWidget {
  final Color color;
  final double radius;

  const _GlowingOrb({required this.color, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
