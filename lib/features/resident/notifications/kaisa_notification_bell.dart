import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'kaisa_notifications_repository.dart';

/// Place ONCE in the shared KaisaResidentTopBar; never duplicate it in page AppBars.
class KaisaNotificationBell extends StatefulWidget {
  const KaisaNotificationBell({super.key});
  @override
  State<KaisaNotificationBell> createState() => _KaisaNotificationBellState();
}

class _KaisaNotificationBellState extends State<KaisaNotificationBell> {
  final repo = KaisaNotificationsRepository.instance;
  RealtimeChannel? channel;
  int unread = 0;
  @override
  void initState() {
    super.initState();
    _load();
    if (repo.userId != null) channel = repo.subscribe(_load);
  }

  Future<void> _load() async {
    try {
      final value = await repo.unreadCount();
      if (mounted) setState(() => unread = value);
    } catch (_) {
      /* Bell must not crash navigation if Supabase is offline. */
    }
  }

  @override
  void dispose() {
    final c = channel;
    if (c != null) Supabase.instance.client.removeChannel(c);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: unread > 0 ? '$unread unread notifications' : 'Notifications',
    onPressed: () => context.go('/resident/notifications'),
    icon: Badge(
      isLabelVisible: unread > 0,
      label: Text(unread > 99 ? '99+' : '$unread'),
      child: const Icon(
        Icons.notifications_none_rounded,
        color: Color(0xFF173D2B),
        size: 22,
      ),
    ),
  );
}
