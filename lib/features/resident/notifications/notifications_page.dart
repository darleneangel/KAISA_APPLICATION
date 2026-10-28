import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/kaisa_resident_design.dart';
import 'kaisa_notifications_repository.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final repo = KaisaNotificationsRepository.instance;
  RealtimeChannel? channel;
  List<KaisaNotification> items = [];
  bool loading = true, unreadOnly = false, busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    _load();
    if (repo.userId != null) channel = repo.subscribe(_load);
  }

  Future<void> _load() async {
    try {
      final fetched = await repo.list();
      if (mounted)
        setState(() {
          items = fetched;
          loading = false;
          error = null;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          error = 'Notifications could not load. Please retry. ($e)';
          loading = false;
        });
    }
  }

  Future<void> _open(KaisaNotification item) async {
    try {
      if (!item.isRead) await repo.markRead(item.id);
      await _load();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not mark this notification as read.'),
          ),
        );
    }
    if (!mounted) return;
    final path = item.targetPath;
    // Only resident-internal routes stored by trusted triggers may be opened.
    if (path.startsWith('/resident/')) context.go(path);
  }

  Future<void> _markAll() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await repo.markAllRead();
      await _load();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to mark notifications as read.'),
          ),
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  IconData _icon(String kind) => switch (kind) {
    'message' => Icons.chat_bubble_outline_rounded,
    'like' => Icons.favorite_outline_rounded,
    'comment' => Icons.mode_comment_outlined,
    'event' => Icons.event_available_outlined,
    'organization' => Icons.groups_2_outlined,
    'verification' => Icons.verified_outlined,
    'certificate' => Icons.workspace_premium_outlined,
    'post' => Icons.campaign_outlined,
    _ => Icons.notifications_none_rounded,
  };
  @override
  void dispose() {
    if (channel != null) Supabase.instance.client.removeChannel(channel!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = items
        .where((item) => !unreadOnly || !item.isRead)
        .toList();
    final count = items.where((item) => !item.isRead).length;
    return Scaffold(
      backgroundColor: KaisaResidentDesign.paper,
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: KaisaResidentDesign.desktopWidth,
            ),
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  KaisaResidentDesign.pagePadding(
                    MediaQuery.sizeOf(context).width,
                  ),
                  22,
                  KaisaResidentDesign.pagePadding(
                    MediaQuery.sizeOf(context).width,
                  ),
                  36,
                ),
                children: [
                  const Text(
                    'YOUR COMMUNITY UPDATES',
                    style: TextStyle(
                      color: KaisaResidentDesign.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      color: KaisaResidentDesign.ink,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Messages, engagement, participation, and account updates—all in one place.',
                    style: TextStyle(color: KaisaResidentDesign.muted),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: KaisaResidentDesign.forest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_active_outlined,
                          color: KaisaResidentDesign.yellow,
                          size: 36,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$count unread ${count == 1 ? 'notification' : 'notifications'}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Text(
                                'Updates appear here automatically while KAISA is open.',
                                style: TextStyle(
                                  color: Color(0xFFDDEFE2),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: !unreadOnly,
                        onSelected: (_) => setState(() => unreadOnly = false),
                      ),
                      ChoiceChip(
                        label: const Text('Unread'),
                        selected: unreadOnly,
                        onSelected: (_) => setState(() => unreadOnly = true),
                      ),
                      if (count > 0)
                        TextButton.icon(
                          onPressed: busy ? null : _markAll,
                          icon: const Icon(Icons.done_all_rounded),
                          label: const Text('Mark all as read'),
                        ),
                      IconButton(
                        tooltip: 'Refresh notifications',
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (loading)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (error != null)
                    KaisaResidentCard(
                      child: Column(
                        children: [
                          Text(error!),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _load,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  else if (filtered.isEmpty)
                    const KaisaResidentCard(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Column(
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 42,
                              color: KaisaResidentDesign.muted,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'You’re all caught up!',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'New community activity will appear here.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...filtered.map(
                      (n) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            onTap: () => _open(n),
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: n.isRead
                                      ? KaisaResidentDesign.border
                                      : KaisaResidentDesign.green.withValues(
                                          alpha: .35,
                                        ),
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFFE5F2E9),
                                    child: Icon(
                                      _icon(n.kind),
                                      color: KaisaResidentDesign.forest,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                n.title,
                                                style: TextStyle(
                                                  fontWeight: n.isRead
                                                      ? FontWeight.w600
                                                      : FontWeight.w800,
                                                  color:
                                                      KaisaResidentDesign.ink,
                                                ),
                                              ),
                                            ),
                                            if (!n.isRead)
                                              const CircleAvatar(
                                                radius: 4,
                                                backgroundColor:
                                                    KaisaResidentDesign.green,
                                              ),
                                          ],
                                        ),
                                        if (n.body.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            n.body,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: KaisaResidentDesign.muted,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Text(
                                          _time(n.createdAt),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: KaisaResidentDesign.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: KaisaResidentDesign.muted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _time(DateTime date) {
    final delta = DateTime.now().difference(date);
    if (delta.inMinutes < 1) return 'Just now';
    if (delta.inHours < 1) return '${delta.inMinutes}m ago';
    if (delta.inDays < 1) return '${delta.inHours}h ago';
    if (delta.inDays < 7) return '${delta.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
