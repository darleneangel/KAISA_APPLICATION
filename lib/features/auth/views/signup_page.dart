import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/repositories/resident_account_repository.dart';
import '../widgets/compact_auth_shell.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _hide = true, _hideConfirm = true, _agreed = false;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and privacy notice.'),
        ),
      );
      return;
    }
    ResidentAccountRepository.instance.setPrototypeAccount(_email.text.trim());
    context.go('/verification');
  }

  bool _socialBusy = false;

  Future<void> _socialSignUp(OAuthProvider provider) async {
    if (_socialBusy) return;
    setState(() => _socialBusy = true);
    try {
      // Requires Google/Facebook provider configuration and redirect URLs in Supabase.
      final launched = await Supabase.instance.client.auth.signInWithOAuth(
        provider,
      );
      if (!mounted) return;
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open the social sign-in page. Check OAuth settings.',
            ),
          ),
        );
      }
      // OAuth login completes on redirect. Do not fake verification or account creation.
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Social sign-in unavailable. Configure this provider in Supabase. $error',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _socialBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) => CompactAuthShell(
    backRoute: '/login',
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FormHeader(
            title: 'Create your account.',
            description:
                'Join the KAISA community with your email or a social account.',
          ),
          const SizedBox(height: 24),
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
          const SizedBox(height: 14),
          TextFormField(
            controller: _password,
            obscureText: _hide,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _hide = !_hide),
                icon: Icon(
                  _hide
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (s) {
              if (s == null || s.length < 8) return 'Use at least 8 characters';
              if (!RegExp(r'[A-Z]').hasMatch(s) ||
                  !RegExp(r'[a-z]').hasMatch(s) ||
                  !RegExp(r'[0-9]').hasMatch(s))
                return 'Include uppercase, lowercase and a number';
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _confirm,
            obscureText: _hideConfirm,
            decoration: InputDecoration(
              labelText: 'Confirm password',
              prefixIcon: const Icon(Icons.verified_user_outlined),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
                icon: Icon(
                  _hideConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (s) =>
                s != _password.text ? 'Passwords do not match' : null,
          ),
          const SizedBox(height: 18),
          CheckboxListTile(
            value: _agreed,
            onChanged: (v) => setState(() => _agreed = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'I agree to KAISA’s Terms and Privacy Notice.',
              style: TextStyle(fontSize: 13, color: Color(0xFF274737)),
            ),
            activeColor: AppColors.forest,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Create account'),
            ),
          ),
          const SizedBox(height: 22),
          const Row(
            children: [
              Expanded(child: Divider(color: Color(0xFFDCE8DF))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR SIGN UP WITH',
                  style: TextStyle(
                    color: Color(0xFF6B8074),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Color(0xFFDCE8DF))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SocialButton(
                  label: 'Google',
                  symbol: 'G',
                  onPressed: _socialBusy
                      ? null
                      : () => _socialSignUp(OAuthProvider.google),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SocialButton(
                  label: 'Facebook',
                  symbol: 'f',
                  onPressed: _socialBusy
                      ? null
                      : () => _socialSignUp(OAuthProvider.facebook),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Social signup requires Google/Facebook OAuth to be enabled in Supabase.',
            style: TextStyle(
              fontSize: 11,
              height: 1.45,
              color: Color(0xFF6D7A72),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Already have an account? Log in'),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Prototype: account creation and email verification will connect to Supabase in the production version.',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF6D7A72),
              height: 1.5,
            ),
          ),
        ],
      ),
    ),
  );
}

class _FormHeader extends StatelessWidget {
  final String title, description;
  const _FormHeader({required this.title, required this.description});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: Color(0xFF163E2C),
          fontSize: 29,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 9),
      Text(
        description,
        style: const TextStyle(
          color: Color(0xFF68786E),
          fontSize: 14,
          height: 1.5,
        ),
      ),
    ],
  );
}

class _SocialButton extends StatelessWidget {
  final String label;
  final String symbol;
  final VoidCallback? onPressed;
  const _SocialButton({
    required this.label,
    required this.symbol,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF193B2D),
      side: const BorderSide(color: Color(0xFFD8E5DE)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          symbol,
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w900,
            color: label == 'Google'
                ? const Color(0xFF4285F4)
                : const Color(0xFF1877F2),
          ),
        ),
        const SizedBox(width: 9),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}
