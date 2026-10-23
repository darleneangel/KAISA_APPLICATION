import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/kaisa_auth_service.dart';
import '../widgets/compact_auth_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidden = true;
  bool _isLoading = false;
  bool _socialLoading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final response = await KaisaAuthService.instance.signIn(
        _email.text.trim(),
        _password.text,
      );
      if (!mounted) return;

      if (response.user == null || response.session == null) {
        _showError('Could not establish a session. Please try again.');
        return;
      }

      // For now, only resident login is wired. Do not infer a role from email.
      // Implement trusted server-side role lookup before directing admin users.
      context.go('/resident/home');
    } on AuthException catch (error) {
      if (!mounted) return;
      _showError(_messageForAuthError(error));
    } catch (_) {
      if (!mounted) return;
      _showError(
        'Could not connect to KAISA. Check your connection and try again.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _social(OAuthProvider provider) async {
    if (_socialLoading) return;
    setState(() => _socialLoading = true);
    try {
      await KaisaAuthService.instance.socialSignIn(provider);
      // Supabase redirects back; router listens for the authenticated session.
    } on AuthException catch (error) {
      if (mounted) _showError(error.message);
    } catch (_) {
      if (mounted) _showError('Unable to open social login. Please try again.');
    } finally {
      if (mounted) setState(() => _socialLoading = false);
    }
  }

  String _messageForAuthError(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'Incorrect email or password.';
    }
    if (message.contains('email not confirmed')) {
      return 'Please confirm your email address before logging in.';
    }
    if (message.contains('rate limit') ||
        message.contains('too many requests')) {
      return 'Too many attempts. Please try again later.';
    }
    return error.message;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => CompactAuthShell(
    backRoute: '/welcome',
    child: Form(
      key: _formKey,
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
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF697B72),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _email,
            enabled: !_isLoading,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            validator: (value) {
              final email = (value ?? '').trim();
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _password,
            enabled: !_isLoading,
            obscureText: _hidden,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _signIn(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: _hidden ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _hidden = !_hidden),
                icon: Icon(
                  _hidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Enter your password' : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isLoading
                  ? null
                  : () => context.go('/forgot-password'),
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
              onPressed: _isLoading ? null : _signIn,
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Log In',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR CONTINUE WITH',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _socialLoading
                      ? null
                      : () => _social(OAuthProvider.google),
                  child: const Text('Google'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _socialLoading
                      ? null
                      : () => _social(OAuthProvider.facebook),
                  child: const Text('Facebook'),
                ),
              ),
            ],
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
                onPressed: _isLoading ? null : () => context.go('/signup'),
                child: const Text(
                  'Create Account',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
