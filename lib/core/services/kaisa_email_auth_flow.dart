
import 'package:supabase_flutter/supabase_flutter.dart';

/// Email/password authentication for KAISA.
/// Does not replace the existing Google/Facebook login.
class KaisaEmailAuthFlow {
  KaisaEmailAuthFlow._();

  static final KaisaEmailAuthFlow instance =
      KaisaEmailAuthFlow._();

  SupabaseClient get _client => Supabase.instance.client;

  // REGISTER WITH EMAIL AND PASSWORD
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final normalizedEmail = email.trim();

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
        .hasMatch(normalizedEmail)) {
      throw const AuthException('Enter a valid email address.');
    }

    if (password.length < 8) {
      throw const AuthException(
        'Password must contain at least 8 characters.',
      );
    }

    if (password != confirmPassword) {
      throw const AuthException('Passwords do not match.');
    }

    final response = await _client.auth.signUp(
      email: normalizedEmail,
      password: password,
    );

    if (response.user == null) {
      throw const AuthException(
        'Registration could not be completed.',
      );
    }

    return response;
  }

  // VERIFY SIGNUP EMAIL OTP
  Future<AuthResponse> confirmSignup({
    required String email,
    required String code,
  }) async {
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      throw const AuthException(
        'Enter the six-digit verification code.',
      );
    }

    return _client.auth.verifyOTP(
      email: email.trim(),
      token: code,
      type: OtpType.signup,
    );
  }

  // RESEND SIGNUP OTP
  Future<void> resendSignupCode(String email) async {
    await _client.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
    );
  }

  // LOGIN WITH EXISTING ACCOUNT
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    if (response.session == null || response.user == null) {
      throw const AuthException('Unable to sign in.');
    }

    return response;
  }

  // LOGOUT
  Future<void> logout() async {
    await _client.auth.signOut();
  }
}
