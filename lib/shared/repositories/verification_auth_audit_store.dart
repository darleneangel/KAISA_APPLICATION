import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Local demonstration recorder for verification administrators' auth events.
/// NOT persistent, immutable, complete, or a substitute for server audit logs.
class VerificationAuthAuditStore extends ChangeNotifier {
  VerificationAuthAuditStore._();
  static final VerificationAuthAuditStore instance =
      VerificationAuthAuditStore._();

  final List<VerificationAuthAuditEvent> _events = [];
  List<VerificationAuthAuditEvent> get events =>
      List.unmodifiable(_events.reversed);
  StreamSubscription<AuthState>? _subscription;
  String? _currentUserId;
  String? _currentEmail;
  bool _currentWasVerificationAdmin = false;

  /// Call once after Supabase.initialize, before runApp, so navigation and
  /// page changes do not stop login/logout observation.
  void start() {
    if (_subscription != null) return;
    final auth = Supabase.instance.client.auth;
    _remember(auth.currentUser);
    _subscription = auth.onAuthStateChange.listen((state) {
      final event = state.event;
      if (event == AuthChangeEvent.signedIn) {
        final user = state.session?.user ?? auth.currentUser;
        _remember(user);
        if (_currentWasVerificationAdmin && _currentUserId != null) {
          _append(
            'Login',
            _currentUserId!,
            _currentEmail ?? 'Email unavailable',
          );
        }
      } else if (event == AuthChangeEvent.signedOut) {
        // The current Supabase user may already be null after signOut.
        // Keep the last authenticated identity captured by this observer.
        if (_currentWasVerificationAdmin && _currentUserId != null) {
          _append(
            'Logout',
            _currentUserId!,
            _currentEmail ?? 'Email unavailable',
          );
        }
        _remember(null);
      } else if (event == AuthChangeEvent.initialSession ||
          event == AuthChangeEvent.userUpdated) {
        // Restoring an existing session is not a new sign-in.
        _remember(state.session?.user ?? auth.currentUser);
      }
      // TOKEN_REFRESHED is not a new login.
    });
  }

  void _remember(User? user) {
    _currentUserId = user?.id;
    _currentEmail = user?.email;
    _currentWasVerificationAdmin =
        user?.appMetadata['kaisa_lgu_role'] == 'lgu_verification_admin';
  }

  void _append(String action, String userId, String email) {
    _events.add(
      VerificationAuthAuditEvent(
        action: action,
        userId: userId,
        email: email,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  /// For explicit application shutdown / test cleanup. Do not call when the
  /// admin merely navigates away from the Audit Logs page.
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}

class VerificationAuthAuditEvent {
  const VerificationAuthAuditEvent({
    required this.action,
    required this.userId,
    required this.email,
    required this.timestamp,
  });
  final String action;
  final String userId;
  final String email;
  final DateTime timestamp;
}
