import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/kaisa_auth_slideshow_background.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;

  static const _forest = Color(0xFF00492C);
  static const _ink = Color(0xFF18392C);
  static const _muted = Color(0xFF667970);

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _sendRecoveryCode() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);

    try {
      final email = _email.text.trim();
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      context.go('/reset-password?email=${Uri.encodeComponent(email)}');
    } on AuthException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to send your recovery code. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // UI only: the controllers, validation, recovery request, and routes above
  // remain copied from forgot_password_page(4).dart without logic changes.
  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFE2EAE5);

    return Scaffold(
      backgroundColor: const Color(0xFF002818),
      body: Stack(
        children: [
          const Positioned.fill(child: KaisaAuthSlideshowBackground()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final mobile = constraints.maxWidth < 520;
                final outer = mobile ? 18.0 : 28.0;
                final inner = mobile ? 22.0 : 30.0;

                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.symmetric(
                    horizontal: outer,
                    vertical: mobile ? 16 : 24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight > (mobile ? 32 : 48)
                          ? constraints.maxHeight - (mobile ? 32 : 48)
                          : 0.0,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 404),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: _busy
                                      ? null
                                      : () => context.go('/login'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 0,
                                      vertical: 8,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.arrow_back_rounded,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Back to login',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                ClipOval(
                                  child: SizedBox(
                                    width: 34,
                                    height: 34,
                                    child: Image.asset(
                                      'assets/images/kaisa_logo.png',
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                                Icons.diversity_3_rounded,
                                                size: 25,
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
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.1,
                                    fontSize: 17,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 26,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Padding(
                                  padding: EdgeInsets.all(inner),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          height: 48,
                                          width: 48,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFE8F2EC),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.lock_reset_rounded,
                                            color: _forest,
                                            size: 27,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      const Text(
                                        'Forgot your password?',
                                        style: TextStyle(
                                          color: _ink,
                                          fontSize: 24,
                                          height: 1.15,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.7,
                                        ),
                                      ),
                                      const SizedBox(height: 9),
                                      const Text(
                                        "Enter your registered email and we'll "
                                        'send you a code to reset your password.',
                                        style: TextStyle(
                                          color: _muted,
                                          fontSize: 13,
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      const Text(
                                        'Email address',
                                        style: TextStyle(
                                          color: _ink,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _email,
                                        enabled: !_busy,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.done,
                                        autofillHints: const [
                                          AutofillHints.email,
                                        ],
                                        onFieldSubmitted: (_) =>
                                            _sendRecoveryCode(),
                                        decoration: InputDecoration(
                                          hintText: 'you@example.com',
                                          hintStyle: const TextStyle(
                                            color: Color(0xFF96A49C),
                                            fontSize: 13,
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.alternate_email_rounded,
                                            color: _forest,
                                            size: 20,
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 13,
                                                vertical: 14,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            borderSide: const BorderSide(
                                              color: borderColor,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            borderSide: const BorderSide(
                                              color: _forest,
                                              width: 1.8,
                                            ),
                                          ),
                                        ),
                                        validator: (value) {
                                          final email = (value ?? '').trim();
                                          if (!RegExp(
                                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                          ).hasMatch(email)) {
                                            return 'Please enter a valid email address';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        height: 48,
                                        child: FilledButton(
                                          onPressed: _busy
                                              ? null
                                              : _sendRecoveryCode,
                                          style: FilledButton.styleFrom(
                                            backgroundColor: _forest,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: _busy
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : const Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      'Send recovery code',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                    SizedBox(width: 9),
                                                    Icon(
                                                      Icons
                                                          .arrow_forward_rounded,
                                                      size: 19,
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Center(
                                        child: TextButton(
                                          onPressed: _busy
                                              ? null
                                              : () => context.go('/login'),
                                          child: const Text(
                                            'Remember your password? Log in',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: _forest,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
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
                                      'Your password can only be changed after '
                                      'verifying your recovery code.',
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
