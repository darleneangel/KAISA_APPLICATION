import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../notifications/kaisa_notification_repository.dart';
import 'kaisa_resident_design.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key, this.unreadCount});
  final int? unreadCount;
  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final repo = KaisaNotificationRepository();
  Timer? _timer;
  int? _count;
  bool _fetching = false;
  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_fetching || widget.unreadCount != null) return;
    _fetching = true;
    try {
      final count = await repo.unreadCount();
      if (mounted) setState(() => _count = count);
    } catch (_) {
      if (mounted) setState(() => _count = null);
    } finally {
      _fetching = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.unreadCount ?? _count;
    return IconButton(
      tooltip: count == null
          ? 'Notifications'
          : 'Notifications ($count unread)',
      onPressed: () async {
        await context.push('/resident/notifications');
        if (mounted) await _refresh();
      },
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_none_rounded),
          if (count != null && count > 0)
            Positioned(
              right: -7,
              top: -6,
              child: Container(
                constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: KaisaTypography.data(
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
