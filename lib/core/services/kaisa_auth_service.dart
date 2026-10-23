import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Central Supabase authentication entry points for both mobile and web.
class KaisaAuthService {
  KaisaAuthService._();
  static final instance = KaisaAuthService._();
  SupabaseClient get client => Supabase.instance.client;
  User? get user => client.auth.currentUser;

  static const mobileRedirect = 'com.kaisa.app://login-callback/';

  Future<void> socialSignIn(OAuthProvider provider) async {
    final started = await client.auth.signInWithOAuth(
      provider,
      redirectTo: kIsWeb ? null : mobileRedirect,
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
    if (!started)
      throw const AuthException('Unable to launch the sign-in page.');
  }

  Future<AuthResponse> signIn(String email, String password) =>
      client.auth.signInWithPassword(email: email.trim(), password: password);

  Future<AuthResponse> signUp(String email, String password) =>
      client.auth.signUp(email: email.trim(), password: password);

  Future<void> signOut() => client.auth.signOut();
}
