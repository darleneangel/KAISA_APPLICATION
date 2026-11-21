import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// KAISA password recovery — compact, responsive Civic Dignity UI.
/// Existing Supabase reset flow and routes are intentionally unchanged.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;

  // Google Stitch's Civic Dignity palette.
  static const _forest = Color(0xFF00492C);
  static const _forestDeep = Color(0xFF00301B);
  static const _ink = Color(0xFF1F2937);
  static const _muted = Color(0xFF637068);
  static const _canvas = Color(0xFFF9F9FF);
  static const _soft = Color(0xFFF0F3FF);
  static const _line = Color(0xFFE3E8E8);
  static const _gold = Color(0xFFFDBC19);

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  // Preserved: validates the email, sends the Supabase recovery request,
  // and navigates to the existing reset-password page.
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isNarrow = screenWidth < 500;
    final horizontalInset = isNarrow ? 18.0 : 28.0;
    final verticalInset = isNarrow ? 18.0 : 28.0;

    return Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalInset,
                vertical: verticalInset,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight > verticalInset * 2
                      ? constraints.maxHeight - verticalInset * 2
                      : 0.0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 412),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _topNavigation(),
                        const SizedBox(height: 24),
                        _recoveryCard(isNarrow),
                        const SizedBox(height: 18),
                        const Text(
                          'KAISA  •  CAVITE CITY',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6,
                            color: Color(0xFF8A9790),
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

  Widget _topNavigation() {
    return Row(
      children: [
        TextButton.icon(
          onPressed: _busy ? null : () => context.go('/login'),
          style: TextButton.styleFrom(
            foregroundColor: _forest,
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text(
            'Back to Login',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
        const Spacer(),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFE2EAE5),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFD5E1D9)),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/kaisa_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.diversity_3_rounded,
                size: 17,
                color: _forest,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'KAISA',
          style: TextStyle(
            color: _forestDeep,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _recoveryCard(bool isNarrow) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: _forestDeep.withValues(alpha: .06),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: ColoredBox(color: _forest),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isNarrow ? 23 : 30,
              isNarrow ? 26 : 32,
              isNarrow ? 20 : 28,
              isNarrow ? 24 : 30,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _soft,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_outlined, color: _forest, size: 14),
                          SizedBox(width: 7),
                          Text(
                            'ACCOUNT RECOVERY',
                            style: TextStyle(
                              color: _forest,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                              letterSpacing: .7,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 19),
                  const Text(
                    'Forgot your\npassword?',
                    style: TextStyle(
                      color: _forestDeep,
                      fontSize: 27,
                      height: 1.13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 11),
                  const Text(
                    "Enter your registered email address and we'll send you a code to reset your password.",
                    style: TextStyle(color: _muted, fontSize: 13, height: 1.55),
                  ),
                  const SizedBox(height: 27),
                  const Text(
                    'Registered email address',
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
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    onFieldSubmitted: (_) => _sendRecoveryCode(),
                    style: const TextStyle(color: _ink, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'you@example.com',
                      hintStyle: const TextStyle(color: Color(0xFF9CA6A1)),
                      prefixIcon: const Icon(
                        Icons.alternate_email_rounded,
                        color: _forest,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 13,
                      ),
                      border: _fieldBorder(_line),
                      enabledBorder: _fieldBorder(_line),
                      focusedBorder: _fieldBorder(_forest, width: 1.8),
                      errorBorder: _fieldBorder(const Color(0xFFB3261E)),
                      focusedErrorBorder: _fieldBorder(
                        const Color(0xFFB3261E),
                        width: 1.8,
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
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _busy ? null : _sendRecoveryCode,
                      style: FilledButton.styleFrom(
                        backgroundColor: _forest,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _forest.withValues(alpha: .65),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
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
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Send recovery code',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 9),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: _gold,
                                  size: 19,
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 17),
                  Center(
                    child: TextButton(
                      onPressed: _busy ? null : () => context.go('/login'),
                      style: TextButton.styleFrom(foregroundColor: _forest),
                      child: const Text(
                        'Remember your password? Log in',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 19),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: _soft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          color: _forest,
                          size: 18,
                        ),
                        SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'Your password can only be changed after verifying your recovery code.',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 11,
                              height: 1.5,
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
        ],
      ),
    );
  }

  OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
