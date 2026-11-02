import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Organization announcement composer + announcement history.
/// Backend RPCs, not this widget, enforce organization-specific access.
class KaisaOrgAnnouncementsPage extends StatefulWidget {
  const KaisaOrgAnnouncementsPage({super.key});

  @override
  State<KaisaOrgAnnouncementsPage> createState() =>
      _KaisaOrgAnnouncementsPageState();
}

class _KaisaOrgAnnouncementsPageState extends State<KaisaOrgAnnouncementsPage> {
  static const forest = Color(0xFF14532D);
  final _title = TextEditingController();
  final _body = TextEditingController();
  String _visibility = 'public';
  bool _inApp = true;
  bool _email = false;
  bool _loading = false;
  bool _publishing = false;
  String? _error;
  String? _lastOrganizationId;
  List<Map<String, dynamic>> _announcements = [];

  String? get _organizationId =>
      GoRouterState.of(context).uri.queryParameters['organizationId'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = _organizationId;
    if (id != _lastOrganizationId) {
      _lastOrganizationId = id;
      if (id != null && id.isNotEmpty) {
        Future.microtask(_reload);
      } else {
        _announcements = [];
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final id = _lastOrganizationId;
    if (id == null || id.isEmpty || !mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await Supabase.instance.client.rpc(
        'kaisa_org_announcements_list',
        params: {'p_organization_id': id, 'p_limit': 30},
      );
      if (!mounted || _lastOrganizationId != id) return;
      setState(() {
        _announcements = (result as List<dynamic>)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Unable to load announcements: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _publish() async {
    final id = _organizationId;
    if (_publishing || id == null || id.isEmpty) return;
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter an announcement title and message.'),
        ),
      );
      return;
    }
    setState(() {
      _publishing = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.rpc(
        'kaisa_org_announcement_publish',
        params: {
          'p_organization_id': id,
          'p_title': _title.text.trim(),
          'p_body': _body.text.trim(),
          'p_visibility': _visibility,
          'p_notify_in_app': _inApp,
          'p_notify_email': _email,
        },
      );
      if (!mounted) return;
      _title.clear();
      _body.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _email
                ? 'Published. In-app notifications processed; email requests queued (not yet sent).'
                : 'Announcement published successfully.',
          ),
        ),
      );
      await _reload();
    } catch (e) {
      if (mounted) setState(() => _error = 'Unable to publish: $e');
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = _organizationId;
    if (id == null || id.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Choose an organization from the account switcher first.',
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'ORGANIZATION COMMUNICATION',
          style: TextStyle(
            color: Color(0xFF237A50),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Posts & Announcements',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: forest,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Share news with the KAISA community or approved organization members.',
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create announcement',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: forest,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _title,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _body,
                  maxLines: 5,
                  maxLength: 4000,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Who can see this?',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Public'),
                  subtitle: const Text('Visible to signed-in KAISA users'),
                  value: 'public',
                  groupValue: _visibility,
                  onChanged: (v) => setState(() => _visibility = v!),
                ),
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Members Only'),
                  subtitle: const Text(
                    'Only approved members of this organization',
                  ),
                  value: 'members',
                  groupValue: _visibility,
                  onChanged: (v) => setState(() => _visibility = v!),
                ),
                const Divider(),
                const Text(
                  'Send notifications through',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('KAISA in-app notifications'),
                  subtitle: const Text('Notify approved organization members'),
                  value: _inApp,
                  onChanged: (v) => setState(() => _inApp = v ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Email notifications'),
                  subtitle: const Text(
                    'Queue emails to members; server email delivery must be configured',
                  ),
                  value: _email,
                  onChanged: (v) => setState(() => _email = v ?? false),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _publishing ? null : _publish,
                  icon: const Icon(Icons.campaign_outlined),
                  label: Text(
                    _publishing ? 'Publishing...' : 'Publish announcement',
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Recent announcements',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: forest,
                ),
              ),
            ),
            IconButton(
              onPressed: _loading ? null : _reload,
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
        if (!_loading && _announcements.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('No announcements yet for this organization.'),
          ),
        for (final item in _announcements)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item['title'] ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Chip(
                        label: Text(
                          item['visibility'] == 'members'
                              ? 'Members Only'
                              : 'Public',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('${item['body'] ?? ''}'),
                  const SizedBox(height: 8),
                  Text(
                    '${item['created_at'] ?? ''}',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
