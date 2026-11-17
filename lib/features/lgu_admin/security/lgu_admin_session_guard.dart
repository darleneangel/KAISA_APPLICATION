import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LguAdminSessionGuard extends StatefulWidget {
  final Widget child;

  const LguAdminSessionGuard({super.key, required this.child});

  @override
  State<LguAdminSessionGuard> createState() => _LguAdminSessionGuardState();
}

class _LguAdminSessionGuardState extends State<LguAdminSessionGuard>
    with WidgetsBindingObserver {
  static const Duration _idleLimit = Duration(minutes: 5);

  Timer? _idleTimer;
  late DateTime _lastActivity;

  bool _signingOut = false;

  @override
  void initState() {
    super.initState();

    _lastActivity = DateTime.now();

    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_onKeyEvent);

    _scheduleTimeout();
  }

  bool _onKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      _recordActivity();
    }

    // Do not consume keyboard events.
    return false;
  }

  void _recordActivity() {
    if (!mounted || _signingOut) return;

    // An interaction after the timeout does not
    // restore an already-expired session.
    if (_hasTimedOut) {
      _checkTimeout();
      return;
    }

    _lastActivity = DateTime.now();
    _scheduleTimeout();
  }

  bool get _hasTimedOut {
    return DateTime.now().difference(_lastActivity) >= _idleLimit;
  }

  void _scheduleTimeout() {
    _idleTimer?.cancel();

    final elapsed = DateTime.now().difference(_lastActivity);

    final remaining = _idleLimit - elapsed;

    if (remaining <= Duration.zero) {
      _checkTimeout();
      return;
    }

    _idleTimer = Timer(remaining, _checkTimeout);
  }

  void _checkTimeout() {
    if (!mounted || _signingOut) return;

    if (_hasTimedOut) {
      _logoutDueToInactivity();
    } else {
      _scheduleTimeout();
    }
  }

  Future<void> _logoutDueToInactivity() async {
    if (_signingOut) return;

    _signingOut = true;
    _idleTimer?.cancel();

    try {
      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;

      context.go('/login');
    } catch (error) {
      debugPrint('KAISA automatic logout failed: $error');

      // Stay blocked rather than silently treating
      // inactivity as a valid active session.
      if (!mounted) return;

      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkTimeout();
    }
  }

  @override
  void dispose() {
    _idleTimer?.cancel();

    HardwareKeyboard.instance.removeHandler(_onKeyEvent);

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_signingOut) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 18),
              Text('Securing your administrator session...'),
            ],
          ),
        ),
      );
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _recordActivity(),
      onPointerMove: (_) => _recordActivity(),
      onPointerHover: (_) => _recordActivity(),
      onPointerSignal: (_) => _recordActivity(),
      child: widget.child,
    );
  }
}
