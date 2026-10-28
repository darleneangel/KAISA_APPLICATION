import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../router/app_router.dart';

/// Signs out an authenticated user after five minutes with no local activity.
/// The clock is not reset when moving between KAISA routes.
class KaisaInactivityGuard extends StatefulWidget {
  const KaisaInactivityGuard({required this.child, super.key});

  final Widget child;

  @override
  State<KaisaInactivityGuard> createState() => _KaisaInactivityGuardState();
}

class _KaisaInactivityGuardState extends State<KaisaInactivityGuard>
    with WidgetsBindingObserver {
  static const _idleLimit = Duration(minutes: 5);
  static const _checkEvery = Duration(seconds: 1);

  Timer? _checkTimer;
  StreamSubscription<AuthState>? _authSubscription;
  DateTime? _lastActivity;
  bool _signingOut = false;

  bool get _hasSession => Supabase.instance.client.auth.currentSession != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastActivity = DateTime.now();

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      state,
    ) {
      if (state.event == AuthChangeEvent.signedIn ||
          state.event == AuthChangeEvent.signedOut) {
        // A new login gets its own full five-minute period.
        // An auth token refresh is NOT user activity.
        _lastActivity = DateTime.now();
      }
    });

    _checkTimer = Timer.periodic(_checkEvery, (_) => _checkIdleTime());
  }

  void _recordActivity() {
    if (!_signingOut && _hasSession) {
      // Check the deadline *before* refreshing it: the first click after
      // a sleeping/inactive device must not revive an expired session.
      if (_isExpired) {
        unawaited(_signOutDueToInactivity());
      } else {
        _lastActivity = DateTime.now();
      }
    }
  }

  bool get _isExpired =>
      _lastActivity != null &&
      DateTime.now().difference(_lastActivity!) >= _idleLimit;

  void _checkIdleTime() {
    if (!_signingOut && _hasSession && _isExpired) {
      unawaited(_signOutDueToInactivity());
    }
  }

  Future<void> _signOutDueToInactivity() async {
    if (_signingOut || !_hasSession) return;
    _signingOut = true;
    try {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      appRouter.go('/welcome');
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('You were signed out after 5 minutes of inactivity.'),
        ),
      );
    } catch (error) {
      debugPrint('KAISA automatic sign out failed: $error');
      // Keep checking rather than falsely claiming the server session ended.
    } finally {
      _signingOut = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkIdleTime();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _checkTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _recordActivity(),
      onPointerMove: (_) => _recordActivity(),
      onPointerHover: (_) => _recordActivity(),
      onPointerSignal: (_) => _recordActivity(),
      child: Focus(
        canRequestFocus: false,
        onKeyEvent: (_, KeyEvent event) {
          if (event is KeyDownEvent || event is KeyRepeatEvent) {
            _recordActivity();
          }
          return KeyEventResult.ignored;
        },
        child: widget.child,
      ),
    );
  }
}
