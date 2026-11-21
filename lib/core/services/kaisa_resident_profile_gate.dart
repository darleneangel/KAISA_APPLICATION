import 'package:supabase_flutter/supabase_flutter.dart';

/// Chooses the resident landing page from the persisted Supabase profile.
///
/// This is a navigation check, NOT a substitute for Supabase RLS.
/// Administrator accounts must be routed separately using trusted app metadata.
class KaisaResidentProfileGate {
  const KaisaResidentProfileGate._();

  static Future<String> destinationFor(User user) async {
    if (user.appMetadata['is_super_admin'] == true) {
      throw StateError('Administrator accounts require administrator routing.');
    }

    final activeUser = Supabase.instance.client.auth.currentUser;
    if (activeUser == null || activeUser.id != user.id) {
      throw const AuthException(
        'Your session has expired. Please sign in again.',
      );
    }

    // Read the dedicated profile record rather than trusting cached UI state,
    // local storage, or editable user_metadata as the source of truth.
    // A missing row or false flag means the resident must complete setup.
    // Unexpected database/RLS errors propagate: never guess that the user is
    // complete, which would let them bypass the mandatory setup step.
    final profile = await Supabase.instance.client
        .from('resident_profiles')
        .select('profile_completed')
        .eq('user_id', user.id)
        .maybeSingle();

    return profile?['profile_completed'] == true
        ? '/resident/home'
        : '/profile-setup';
  }
}
