import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/kaisa_auth_service.dart';
import '../widgets/compact_auth_shell.dart';

/// KAISA login. Authenticates against Supabase through KaisaAuthService.
/// Navigation is based on server-controlled app_metadata, never the email.
/// Backend RLS / authorization must independently protect privileged data.
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

  bool get _working => _isLoading || _socialLoading;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Returns null for residents. Throws for incomplete / unrecognized admin
  /// metadata rather than allowing a privileged account to fall through to
  /// an ordinary resident experience.
  String? _destinationFor(User user) {
    final metadata = user.appMetadata;
    if (metadata['is_super_admin'] != true) {
      return null;
    }

    switch (metadata['kaisa_lgu_role']) {
      case 'lgu_it_admin':
        // The existing LGU shell selects the IT dashboard by authenticated role.
        return '/lgu-admin/dashboard';
      case 'lgu_verification_admin':
        return '/lgu-admin/verification/dashboard';
      case 'lgu_operations_admin':
        return '/lgu-admin/dashboard';
      default:
        throw const FormatException(
          'Your administrator role is not configured correctly. '
          'Please contact the KAISA IT administrator.',
        );
    }
  }

  Future<void> _signIn() async {
    if (_working) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

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

      // Read the latest user record from Supabase Auth after the new session
      // is established. The Admin API / service-role key is NOT used here.
      final fresh = await Supabase.instance.client.auth.getUser();
      if (!mounted) return;

      final user = fresh.user;
      if (user == null || user.id != response.user!.id) {
        _showError('Could not verify your account. Please sign in again.');
        await Supabase.instance.client.auth.signOut();
        return;
      }

      final destination = _destinationFor(user);
      if (!mounted) return;

      // Preserve existing resident path; privileged users are routed first.
      context.go(destination ?? '/resident/home');
    } on AuthException catch (error) {
      if (mounted) _showError(_messageForAuthError(error));
    } on FormatException catch (error) {
      // Refuse an account with incomplete administrator claims.
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {
        // The user-facing error still explains that access was not granted.
      }
      if (mounted) _showError(error.message);
    } catch (_) {
      if (mounted) {
        _showError(
          'Could not verify your KAISA login. Check your connection '
          'and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _social(OAuthProvider provider) async {
    if (_working) return;
    FocusScope.of(context).unfocus();
    setState(() => _socialLoading = true);
    try {
      await KaisaAuthService.instance.socialSignIn(provider);
      // Supabase completes OAuth via redirect. The application's existing
      // auth-state listener/router handles the callback and social OTP flow.
    } on AuthException catch (error) {
      if (mounted) _showError(_messageForAuthError(error));
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
    if (!mounted) return;
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
            enabled: !_working,
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
            enabled: !_working,
            obscureText: _hidden,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _signIn(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: _hidden ? 'Show password' : 'Hide password',
                onPressed: _working
                    ? null
                    : () => setState(() => _hidden = !_hidden),
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
              onPressed: _working ? null : () => context.go('/forgot-password'),
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
              onPressed: _working ? null : _signIn,
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
                  onPressed: _working
                      ? null
                      : () => _social(OAuthProvider.google),
                  child: const Text('Google'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _working
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
                onPressed: _working ? null : () => context.go('/signup'),
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
