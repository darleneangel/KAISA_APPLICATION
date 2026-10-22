import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/compact_auth_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidden = true;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CompactAuthShell(
    backRoute: '/welcome',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome back!',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            color: Color(0xFF153D30),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sign in to your KAISA community account.',
          style: TextStyle(fontSize: 14, color: Color(0xFF697B72), height: 1.5),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email address',
            prefixIcon: Icon(Icons.mail_outline_rounded),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _password,
          obscureText: _hidden,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              onPressed: () => setState(() => _hidden = !_hidden),
              icon: Icon(
                _hidden
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.go('/forgot-password'),
            child: const Text('Forgot password?'),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.forest,
              foregroundColor: Colors.white,
            ),
            onPressed: () => context.go('/resident/home'),
            child: const Text(
              'Log In',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Flexible(
              child: Text(
                "Don't have an account?",
                style: TextStyle(color: Color(0xFF60766B)),
              ),
            ),
            TextButton(
              onPressed: () => context.go('/signup'),
              child: const Text(
                'Create Account',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Prototype: login currently opens the resident dashboard without checking credentials.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF73877B), fontSize: 11, height: 1.5),
        ),
      ],
    ),
  );
}
