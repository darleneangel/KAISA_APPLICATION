import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/kaisa_resident_design.dart';
import '../widgets/kaisa_notification_card.dart';
import '../widgets/kaisa_responsive_shell.dart';
import 'kaisa_notification_repository.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _repo = KaisaNotificationRepository();
  final _items = <KaisaNotification>[];
  String? _expanded, _kind, _error;
  bool _loading = true, _busy = false, _more = true, _unreadOnly = false;
  int _generation = 0;
  int? _unread;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool append = false}) async {
    final token = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _repo.fetch(
        offset: append ? _items.length : 0,
        unreadOnly: _unreadOnly,
        kind: _kind,
      );
      final count = await _repo.unreadCount();
      if (!mounted || token != _generation) return;
      setState(() {
        if (!append) _items.clear();
        _items.addAll(rows);
        _more = rows.length == 50;
        _unread = count;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || token != _generation) return;
      setState(() {
        _error = 'Could not load notifications. Please retry.';
        _loading = false;
      });
    }
  }

  void _message(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
  Future<void> _change(
    Future<void> Function() action, {
    bool reload = true,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted && reload) await _load();
    } catch (_) {
      if (mounted)
        _message('Unable to update notifications. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(KaisaNotification n) async {
    final uri = Uri.tryParse(n.targetPath);
    const allowed = {
      '/resident/feed',
      '/resident/events',
      '/resident/my-events',
      '/resident/organizations',
      '/resident/my-organizations',
      '/resident/verification-status',
      '/resident/profile',
      '/resident/home',
    };
    final message =
        uri != null &&
        RegExp(r'^/resident/messages/[0-9a-fA-F-]{36}$').hasMatch(uri.path);
    if (uri == null ||
        uri.hasScheme ||
        uri.hasAuthority ||
        (!allowed.contains(uri.path) && !message)) {
      _message('The related page is unavailable.');
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (!n.isRead) await _repo.markRead(n.id);
      if (mounted) {
        await context.push(n.targetPath);
        if (mounted) await _load();
      }
    } catch (_) {
      if (mounted) _message('Unable to open the related page.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(KaisaNotification n) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Remove notification?',
          style: KaisaTypography.heading(const TextStyle(fontSize: 22)),
        ),
        content: const Text(
          'This removes only the notification, not the event or registration.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) await _change(() => _repo.delete(n.id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = KaisaTypography.theme(context);
    final inside = KaisaShellScope.isInside(context);
    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: inside ? null : AppBar(title: const Text('Notifications')),
        body: SafeArea(
          top: !inside,
          child: RefreshIndicator(
            onRefresh: () => _load(),
            child: LayoutBuilder(
              builder: (context, c) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    c.maxWidth < 600 ? 16 : 32,
                    24,
                    c.maxWidth < 600 ? 16 : 32,
                    32,
                  ),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 960),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Notifications',
                              style: KaisaTypography.heading(
                                TextStyle(
                                  fontSize: c.maxWidth < 600 ? 30 : 38,
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _unread == null
                                  ? 'Stay informed about your community.'
                                  : '$_unread unread · Stay informed about your community.',
                              style: KaisaTypography.body(
                                TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                ChoiceChip(
                                  label: const Text('All'),
                                  selected: !_unreadOnly,
                                  onSelected: _busy
                                      ? null
                                      : (_) {
                                          setState(() {
                                            _unreadOnly = false;
                                            _expanded = null;
                                          });
                                          _load();
                                        },
                                ),
                                ChoiceChip(
                                  label: const Text('Unread'),
                                  selected: _unreadOnly,
                                  onSelected: _busy
                                      ? null
                                      : (_) {
                                          setState(() {
                                            _unreadOnly = true;
                                            _expanded = null;
                                          });
                                          _load();
                                        },
                                ),
                                TextButton.icon(
                                  onPressed:
                                      _busy || _unread == null || _unread == 0
                                      ? null
                                      : () => _change(_repo.markAllRead),
                                  icon: const Icon(Icons.done_all),
                                  label: const Text('Mark all as read'),
                                ),
                                IconButton(
                                  tooltip: 'Refresh',
                                  onPressed: _busy || _loading
                                      ? null
                                      : () => _load(),
                                  icon: const Icon(Icons.refresh),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _kind ?? 'all',
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'all',
                                  child: Text('All categories'),
                                ),
                                DropdownMenuItem(
                                  value: 'event',
                                  child: Text('Events'),
                                ),
                                DropdownMenuItem(
                                  value: 'organization',
                                  child: Text('Organizations'),
                                ),
                                DropdownMenuItem(
                                  value: 'verification',
                                  child: Text('Verification'),
                                ),
                                DropdownMenuItem(
                                  value: 'like',
                                  child: Text('Likes'),
                                ),
                                DropdownMenuItem(
                                  value: 'comment',
                                  child: Text('Comments'),
                                ),
                                DropdownMenuItem(
                                  value: 'message',
                                  child: Text('Messages'),
                                ),
                                DropdownMenuItem(
                                  value: 'certificate',
                                  child: Text('Certificates'),
                                ),
                              ],
                              onChanged: _busy
                                  ? null
                                  : (v) {
                                      setState(() {
                                        _kind = v == 'all' ? null : v;
                                        _expanded = null;
                                      });
                                      _load();
                                    },
                            ),
                            const SizedBox(height: 20),
                            if (_loading) const LinearProgressIndicator(),
                            if (_error != null) ...[
                              Text(_error!),
                              TextButton(
                                onPressed: () => _load(),
                                child: const Text('Retry'),
                              ),
                            ],
                            if (!_loading && _error == null && _items.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.notifications_none,
                                      size: 44,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No notifications here',
                                      style: KaisaTypography.heading(
                                        const TextStyle(fontSize: 20),
                                      ),
                                    ),
                                    const Text('New updates will appear here.'),
                                  ],
                                ),
                              ),
                            if (_error == null)
                              for (final n in _items)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: KaisaNotificationCard(
                                    key: ValueKey(n.id),
                                    notification: n,
                                    expanded: _expanded == n.id,
                                    busy: _busy || _loading,
                                    onExpand: () => setState(
                                      () => _expanded = _expanded == n.id
                                          ? null
                                          : n.id,
                                    ),
                                    onRead: () =>
                                        _change(() => _repo.markRead(n.id)),
                                    onOpen: () => _open(n),
                                    onDelete: () => _delete(n),
                                  ),
                                ),
                            if (_more &&
                                !_loading &&
                                _error == null &&
                                _items.isNotEmpty)
                              OutlinedButton(
                                onPressed: _busy
                                    ? null
                                    : () => _load(append: true),
                                child: const Text('Load more'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
