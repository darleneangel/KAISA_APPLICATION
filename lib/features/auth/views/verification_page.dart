import 'dart:async';

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
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());

  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

  Timer? _timer;

  int _secondsRemaining = 60;
  bool _isVerifying = false;

  // Prototype only.
  // Later this email will come from the account created in Supabase.
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

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
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
      },
    );
  }

  void _handleOtpChanged(
    String value,
    int index,
  ) {
    if (value.isNotEmpty) {
      if (index < _focusNodes.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }
  }

  void _handleBackspace(
    KeyEvent event,
    int index,
  ) {
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
        const SnackBar(
          content: Text(
            'Please enter the complete 6-digit verification code.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isVerifying = true;
    });

    // ==========================================================
    // PROTOTYPE ONLY
    //
    // Later:
    // Supabase will verify the actual OTP sent to the user's email.
    // ==========================================================

    await Future.delayed(
      const Duration(milliseconds: 900),
    );

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
        return AlertDialog(
          icon: Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: AppColors.greenLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              color: AppColors.greenDark,
              size: 36,
            ),
          ),
          title: const Text(
            'Email Verified!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Your email address has been successfully verified. '
            'You can now continue setting up your KAISA profile.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);

                context.go('/profile-setup');
              },
              icon: const Icon(
                Icons.arrow_forward_rounded,
              ),
              label: const Text(
                'Continue',
              ),
            ),
          ],
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

    // Prototype only.
    // Later Supabase will resend the actual email OTP.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'A new verification code was sent to $userEmail.',
        ),
      ),
    );
  }

  void _changeEmail() {
    // During the prototype, return to signup so
    // the resident can change their email address.
    context.go('/signup');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                20,
                14,
                20,
                30,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 44,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 500,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        // ======================================
                        // TOP BAR
                        // ======================================

                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                context.go('/signup');
                              },
                              borderRadius:
                                  BorderRadius.circular(13),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(13),
                                  border: Border.all(
                                    color: AppColors.border,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_rounded,
                                  size: 20,
                                ),
                              ),
                            ),

                            const Spacer(),

                            Container(
                              width: 43,
                              height: 43,
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(13),
                                border: Border.all(
                                  color: AppColors.border,
                                ),
                              ),
                              child: Image.asset(
                                'assets/images/kaisa_logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),

                            const SizedBox(width: 9),

                            const Text(
                              'KAISA',
                              style: TextStyle(
                                color: AppColors.blueDark,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 48),

                        // ======================================
                        // ICON
                        // ======================================

                        Center(
                          child: Container(
                            width: 94,
                            height: 94,
                            decoration: BoxDecoration(
                              color: AppColors.blueLight,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.blue
                                    .withValues(alpha: .15),
                                width: 5,
                              ),
                            ),
                            child: const Icon(
                              Icons.mark_email_unread_outlined,
                              color: AppColors.blue,
                              size: 43,
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ======================================
                        // TITLE
                        // ======================================

                        const Center(
                          child: Text(
                            'Verify your email',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        const Center(
                          child: Text(
                            'We sent a 6-digit verification code to',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),

                        const SizedBox(height: 5),

                        Center(
                          child: Text(
                            userEmail,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.blueDark,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Center(
                          child: TextButton(
                            onPressed: _changeEmail,
                            child: const Text(
                              'Change email',
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ======================================
                        // OTP BOX
                        // ======================================

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(
                            18,
                            24,
                            18,
                            22,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(22),
                            border: Border.all(
                              color: AppColors.border,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0D000000),
                                blurRadius: 20,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Enter verification code',
                                style: TextStyle(
                                  color:
                                      AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),

                              const SizedBox(height: 20),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween,
                                children:
                                    List.generate(6, (index) {
                                  return Expanded(
                                    child: Padding(
                                      padding:
                                          EdgeInsets.only(
                                        right:
                                            index == 5 ? 0 : 7,
                                      ),
                                      child: KeyboardListener(
                                        focusNode: FocusNode(
                                          skipTraversal: true,
                                        ),
                                        onKeyEvent: (event) {
                                          _handleBackspace(
                                            event,
                                            index,
                                          );
                                        },
                                        child: TextField(
                                          controller:
                                              _controllers[index],
                                          focusNode:
                                              _focusNodes[index],
                                          keyboardType:
                                              TextInputType.number,
                                          textAlign:
                                              TextAlign.center,
                                          maxLength: 1,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          style: const TextStyle(
                                            color: AppColors
                                                .textPrimary,
                                            fontSize: 21,
                                            fontWeight:
                                                FontWeight.w800,
                                          ),
                                          decoration:
                                              InputDecoration(
                                            counterText: '',
                                            contentPadding:
                                                const EdgeInsets
                                                    .symmetric(
                                              vertical: 17,
                                            ),
                                            filled: true,
                                            fillColor:
                                                AppColors
                                                    .surfaceSoft,
                                            border:
                                                OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                13,
                                              ),
                                              borderSide:
                                                  const BorderSide(
                                                color: AppColors
                                                    .border,
                                              ),
                                            ),
                                            enabledBorder:
                                                OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                13,
                                              ),
                                              borderSide:
                                                  const BorderSide(
                                                color: AppColors
                                                    .border,
                                              ),
                                            ),
                                            focusedBorder:
                                                OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                13,
                                              ),
                                              borderSide:
                                                  const BorderSide(
                                                color:
                                                    AppColors.blue,
                                                width: 1.8,
                                              ),
                                            ),
                                          ),
                                          onChanged: (value) {
                                            _handleOtpChanged(
                                              value,
                                              index,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),

                              const SizedBox(height: 22),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isVerifying
                                      ? null
                                      : _verifyCode,
                                  child: _isVerifying
                                      ? const SizedBox(
                                          width: 21,
                                          height: 21,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment
                                                  .center,
                                          children: [
                                            Icon(
                                              Icons
                                                  .verified_outlined,
                                              size: 19,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Verify Email',
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // ======================================
                        // RESEND
                        // ======================================

                        Center(
                          child: Column(
                            children: [
                              const Text(
                                'Didn\'t receive the code?',
                                style: TextStyle(
                                  color:
                                      AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),

                              const SizedBox(height: 4),

                              if (_canResend)
                                TextButton.icon(
                                  onPressed: _resendCode,
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Resend Code',
                                  ),
                                )
                              else
                                Text.rich(
                                  TextSpan(
                                    style: const TextStyle(
                                      color:
                                          AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text:
                                            'You can resend the code in ',
                                      ),
                                      TextSpan(
                                        text: _formattedTime,
                                        style: const TextStyle(
                                          color:
                                              AppColors.blue,
                                          fontWeight:
                                              FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ======================================
                        // SECURITY INFO
                        // ======================================

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.blueLight,
                            borderRadius:
                                BorderRadius.circular(16),
                          ),
                          child: const Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                color: AppColors.blueDark,
                                size: 21,
                              ),
                              SizedBox(width: 11),
                              Expanded(
                                child: Text(
                                  'Email verification helps us confirm '
                                  'that your KAISA account belongs to you. '
                                  'Never share your verification code with anyone.',
                                  style: TextStyle(
                                    color:
                                        AppColors.blueDark,
                                    fontSize: 11,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ======================================
                        // ONBOARDING PROGRESS
                        // ======================================

                        const Row(
                          children: [
                            Expanded(
                              child: Divider(),
                            ),
                            Padding(
                              padding:
                                  EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                'STEP 2 OF 3',
                                style: TextStyle(
                                  color:
                                      AppColors.textMuted,
                                  fontSize: 9,
                                  fontWeight:
                                      FontWeight.w800,
                                  letterSpacing: .7,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 11),

                        const Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            _ProgressDot(
                              completed: true,
                            ),
                            SizedBox(width: 7),
                            _ProgressDot(
                              active: true,
                            ),
                            SizedBox(width: 7),
                            _ProgressDot(),
                          ],
                        ),

                        const SizedBox(height: 16),

                        const Center(
                          child: Text(
                            'Account  •  Verification  •  Profile',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
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
    );
  }
}

// ============================================================================
// PROGRESS DOT
// ============================================================================

class _ProgressDot extends StatelessWidget {
  final bool active;
  final bool completed;

  const _ProgressDot({
    this.active = false,
    this.completed = false,
  });

  @override
  Widget build(BuildContext context) {
    if (completed) {
      return Container(
        width: 24,
        height: 7,
        decoration: BoxDecoration(
          color: AppColors.green,
          borderRadius: BorderRadius.circular(20),
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 200,
      ),
      width: active ? 24 : 7,
      height: 7,
      decoration: BoxDecoration(
        color: active
            ? AppColors.blue
            : AppColors.border,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}