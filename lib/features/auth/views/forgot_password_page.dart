import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/auth_ui.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_form.currentState!.validate()) return;
    showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Recovery preview'),
        content: const Text(
          'Password reset delivery is not connected in this prototype. No email has been sent.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AuthResponsivePage(
    showBack: true,
    backRoute: '/login',
    hero: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthTag(label: 'Account recovery', icon: Icons.lock_reset_rounded),
        SizedBox(height: 24),
        Text(
          'A fresh start\nis just ahead.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.w800,
            height: 1.08,
          ),
        ),
        SizedBox(height: 16),
        Text(
          'We’re making it easier to return to the community connections that matter.',
          style: TextStyle(color: Color(0xFFE1F2E8), fontSize: 15, height: 1.6),
        ),
        SizedBox(height: 26),
        AuthScenicArtwork(),
        SizedBox(height: 14),
        AuthInfoCard(
          title: 'Your privacy matters',
          subtitle:
              'Password recovery will be securely handled by the connected authentication provider.',
          icon: Icons.shield_outlined,
        ),
      ],
    ),
    panel: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.mail_lock_outlined,
            size: 48,
            color: AppColors.forest,
          ),
          const SizedBox(height: 22),
          const Text(
            'Forgot your password?',
            style: TextStyle(
              color: Color(0xFF163E2C),
              fontSize: 29,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Enter your account email address. Once email delivery is configured, this page will send a reset link.',
            style: TextStyle(color: Color(0xFF68786E), height: 1.6),
          ),
          const SizedBox(height: 26),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
            validator: (s) =>
                s == null ||
                    !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s.trim())
                ? 'Enter a valid email address'
                : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _continue,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Continue'),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Back to login'),
            ),
          ),
        ],
      ),
    ),
  );
}
