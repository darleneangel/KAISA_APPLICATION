import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/repositories/resident_account_repository.dart';
import '../widgets/auth_ui.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});
  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final _fields = List.generate(6, (_) => TextEditingController());
  final _focus = List.generate(6, (_) => FocusNode());
  Timer? _timer;
  int _seconds = 60;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _startTimer();
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

  Future<void> _verify() async {
    if (_fields.any((c) => c.text.isEmpty)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter all six digits.')));
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
    final email = ResidentAccountRepository.instance.email ?? '';
    return AuthResponsivePage(
      showBack: true,
      backRoute: '/signup',
      hero: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthTag(label: 'One more step', icon: Icons.verified_user_outlined),
          SizedBox(height: 26),
          Text(
            'Almost there.\nMake it official.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w800,
              height: 1.09,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'A secure community begins with trusted residents. Verify your email before building your KAISA profile.',
            style: TextStyle(
              color: Color(0xFFE1F2E8),
              fontSize: 15,
              height: 1.6,
            ),
          ),
          SizedBox(height: 28),
          AuthScenicArtwork(),
          SizedBox(height: 14),
          AuthInfoCard(
            title: 'Build trust together',
            subtitle:
                'Verification helps KAISA maintain a safer, more responsible community experience.',
            icon: Icons.shield_rounded,
          ),
        ],
      ),
      panel: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.mark_email_unread_outlined,
            color: AppColors.forest,
            size: 48,
          ),
          const SizedBox(height: 22),
          const Text(
            'Verify your email',
            style: TextStyle(
              color: Color(0xFF163E2C),
              fontWeight: FontWeight.w800,
              fontSize: 29,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the six-digit verification code for ${email.isEmpty ? 'your email' : email}.',
            style: const TextStyle(color: Color(0xFF667970), height: 1.5),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, box) {
              final gap = box.maxWidth < 380 ? 6.0 : 10.0;
              final width = ((box.maxWidth - gap * 5) / 6).clamp(30.0, 58.0);
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) {
                  return SizedBox(
                    width: width,
                    child: TextField(
                      controller: _fields[i],
                      focusNode: _focus[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1),
                      ],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forest,
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && i < 5)
                          _focus[i + 1].requestFocus();
                      },
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                        counterText: '',
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy ? null : _verify,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.verified_outlined),
              label: Text(_busy ? 'Checking...' : 'Verify and continue'),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: TextButton(
              onPressed: _seconds > 0 ? null : _resend,
              child: Text(
                _seconds > 0
                    ? 'Resend available in ${_seconds}s'
                    : 'Resend code',
              ),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () => context.go('/signup'),
              child: const Text('Change email address'),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Use the code sent by Supabase. For six-digit codes, set the Supabase Confirm Signup email template to include {{ .Token }}.',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF68786E),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
