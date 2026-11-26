import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Match the resident Community Feed's Civic Dignity design.
const _forest = Color(0xFF00301B);
const _green = Color(0xFF2C6A4A);
const _yellow = Color(0xFFFDBC19);
const _ink = Color(0xFF151C27);
const _muted = Color(0xFF66736B);
const _canvas = Color(0xFFF9FAF9);
const _soft = Color(0xFFF0F5F1);
const _line = Color(0xFFE5ECE7);
const _announcementTint = Color(0xFFFFF2D5);
const _announcementInk = Color(0xFF856000);

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _read(Object? value) => value?.toString().trim() ?? '';
DateTime? _date(Object? value) => DateTime.tryParse(_read(value))?.toLocal();
String _relativeTime(Object? value) {
  final date = _date(value);
  if (date == null) return 'Date unavailable';
  final elapsed = DateTime.now().difference(date);
  if (elapsed.isNegative) return '${_months[date.month - 1]} ${date.day}, ${date.year}';
  if (elapsed.inMinutes < 1) return 'Just now';
  if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m ago';
  if (elapsed.inHours < 24) return '${elapsed.inHours}h ago';
  if (elapsed.inDays < 7) return '${elapsed.inDays}d ago';
  return '${_months[date.month - 1]} ${date.day}, ${date.year}';
}

String _audienceLabel(Object? value) {
  switch (_read(value).toLowerCase()) {
    case 'public': return 'Public';
    case 'members': return 'Members only';
    default: return 'Audience unavailable';
  }
}

IconData _audienceIcon(Object? value) {
  switch (_read(value).toLowerCase()) {
    case 'public': return Icons.public_rounded;
    case 'members': return Icons.groups_outlined;
    default: return Icons.help_outline_rounded;
  }
}

BoxDecoration _surface({bool shadow = false}) => BoxDecoration(
  color: Colors.white,
  border: Border.all(color: _line),
  borderRadius: BorderRadius.circular(15),
  boxShadow: shadow ? const [
    BoxShadow(color: Color(0x06000000), blurRadius: 16, offset: Offset(0, 4)),
  ] : null,
);

InputDecoration _field(String hint, {IconData? icon}) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: _muted, fontSize: 13),
  prefixIcon: icon == null ? null : Icon(icon, color: _green, size: 20),
  filled: true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _line)),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _line)),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _green, width: 1.5)),
);

class _OrgAvatar extends StatelessWidget {
  const _OrgAvatar({required this.name, this.radius = 23});
  final String name;
  final double radius;
  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: radius,
    backgroundColor: const Color(0xFFE3F1E7),
    child: name == 'Your organization' || name.trim().isEmpty
        ? Icon(Icons.groups_2_outlined, color: _forest, size: radius + 2)
        : Text(name.trim().characters.first.toUpperCase(), style: const TextStyle(color: _forest, fontWeight: FontWeight.w900, fontSize: 19)),
  );
}

/// Organization-only announcement history and composer. The existing RPCs
/// remain responsible for server-side authorization and audience enforcement.
/// No resident feed writes, new storage buckets, or schema changes are used.
class KaisaOrgAnnouncementsPage extends StatefulWidget {
  const KaisaOrgAnnouncementsPage({super.key});
  @override
  State<KaisaOrgAnnouncementsPage> createState() => _KaisaOrgAnnouncementsPageState();
}

class _KaisaOrgAnnouncementsPageState extends State<KaisaOrgAnnouncementsPage> {
  final _db = Supabase.instance.client;
  final _search = TextEditingController();
  List<Map<String, dynamic>> _announcements = [];
  String? _organizationId;
  String _orgName = 'Your organization';
  String _audience = 'all';
  bool _newestFirst = true;
  bool _showFilters = true;
  bool _loading = false;
  bool _composerOpen = false;
  String? _error;
  bool _mock = kDebugMode && const bool.fromEnvironment('USE_MOCK_DATA');
  List<Map<String, dynamic>> _mockRows = [];
  int _scope = 0;

  void _seedMock() {
    final now = DateTime.now();
    _mockRows = [
      for (final (title, body, audience, days) in [
        ('Volunteer orientation reminder', 'Please bring your reusable water bottle and arrive 15 minutes early.', 'public', 0),
        ('Monthly members meeting', 'Members are invited to review our upcoming activities and committee assignments.', 'members', 1),
        ('Community clean-up update', 'Thank you to our volunteers. Upcoming activities will be listed in Events Management.', 'public', 3),
      ])
        {'title': title, 'body': body, 'visibility': audience,
         'created_at': now.subtract(Duration(days: days)).toIso8601String()},
    ];
    _announcements = List.of(_mockRows);
    _orgName = 'KAISA Demo Organization';
  }

  void _switchMode(bool value) {
    if (!kDebugMode || _composerOpen || value == _mock) return;
    setState(() {
      _mock = value;
      ++_scope;
      ++_request;
      _error = null;
      _loading = false;
      _search.clear();
      _audience = 'all';
      _announcements = [];
      _orgName = 'Your organization';
      if (_mock) _seedMock();
    });
    final id = _organizationId;
    if (!_mock && id != null) {
      _reload();
      _loadOrganizationName(id, _scope);
    }
  }

  int _request = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final raw = GoRouterState.of(context).uri.queryParameters['organizationId'];
    final id = _read(raw).isEmpty ? null : raw;
    if (id == _organizationId) return;
    _organizationId = id;
    final scope = ++_scope;
    ++_request;
    _announcements = [];
    _orgName = 'Your organization';
    _error = null;
    _audience = 'all';
    _search.clear();
    _loading = id != null;
    if (_mock) {
      _loading = false;
      _seedMock();
      return;
    }
    if (id != null) {
      Future.microtask(() async {
        if (!mounted || scope != _scope) return;
        await Future.wait<void>([_reload(), _loadOrganizationName(id, scope)]);
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // This is the same organization lookup already used by Dashboard & Analytics.
  // Optional name lookup never expands the announcement query's access scope.
  Future<void> _loadOrganizationName(String id, int scope) async {
    try {
      final result = await _db.rpc('kaisa_admin_my_organizations');
      if (!mounted || scope != _scope || id != _organizationId) return;
      for (final row in result as List) {
        final org = Map<String, dynamic>.from(row as Map);
        if (_read(org['id']) != id) continue;
        final name = _read(org['name']);
        if (name.isNotEmpty) setState(() => _orgName = name);
        break;
      }
    } catch (_) {
      // Safe organization avatar/name fallback; announcement history still works.
    }
  }

  Future<void> _reload() async {
    if (_mock) {
      if (mounted) setState(() => _announcements = List.of(_mockRows));
      return;
    }
    final id = _organizationId;
    if (!mounted || id == null) return;
    final request = ++_request;
    final scope = _scope;
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _db.rpc('kaisa_org_announcements_list', params: {
        'p_organization_id': id, 'p_limit': 30,
      });
      final rows = (result as List).map((item) => Map<String, dynamic>.from(item as Map)).toList();
      if (!mounted || scope != _scope || request != _request) return;
      setState(() => _announcements = rows);
    } catch (e) {
      if (!mounted || scope != _scope || request != _request) return;
      debugPrint('KAISA announcement history: $e');
      setState(() => _error = 'Unable to load announcements. Please try again.');
    } finally {
      if (mounted && scope == _scope && request == _request) setState(() => _loading = false);
    }
  }

  void _snack(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _publish(String id, int scope, _AnnouncementDraft draft) async {
    if (!mounted || scope != _scope || id != _organizationId) {
      throw StateError('The active organization changed. Close this composer and start a new announcement.');
    }
    if (_mock) {
      _mockRows.insert(0, {
        'title': draft.title, 'body': draft.body, 'visibility': draft.visibility,
        'created_at': DateTime.now().toIso8601String(),
      });
      return;
    }
    await _db.rpc('kaisa_org_announcement_publish', params: {
      'p_organization_id': id,
      'p_title': draft.title,
      'p_body': draft.body,
      'p_visibility': draft.visibility,
      'p_notify_in_app': draft.inApp,
      'p_notify_email': draft.email,
    });
  }

  Future<void> _compose() async {
    final id = _organizationId;
    if (id == null || _composerOpen) return;
    final scope = _scope;
    setState(() => _composerOpen = true);
    final wide = MediaQuery.sizeOf(context).width >= 700;
    Widget content() => _AnnouncementComposer(
      organizationName: _orgName,
      mock: _mock,
      onPublish: (draft) => _publish(id, scope, draft),
    );
    try {
      final result = wide
          ? await showDialog<_AnnouncementDraft>(
              context: context,
              barrierDismissible: false,
              builder: (_) => Dialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: content()),
              ),
            )
          : await showModalBottomSheet<_AnnouncementDraft>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              isDismissible: false,
              enableDrag: false,
              backgroundColor: Colors.white,
              builder: (_) => content(),
            );
      if (!mounted || result == null || scope != _scope) return;
      _snack(_mock ? 'Sample announcement published locally. No notifications sent.' : result.email
          ? 'Announcement published. Email requests queued (not yet sent).'
          : 'Announcement published successfully.');
      setState(() { _search.clear(); _audience = 'all'; _newestFirst = true; });
      await _reload();
    } finally {
      if (mounted) setState(() => _composerOpen = false);
    }
  }

  List<Map<String, dynamic>> get _shown {
    final terms = _search.text.toLowerCase().trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
    final result = _announcements.where((item) {
      final audience = _read(item['visibility']).toLowerCase();
      final corpus = '${item['title'] ?? ''} ${item['body'] ?? ''} ${_audienceLabel(audience)} $_orgName'.toLowerCase();
      return (_audience == 'all' || audience == _audience) && terms.every(corpus.contains);
    }).toList();
    result.sort((a, b) {
      final first = _date(a['created_at']);
      final second = _date(b['created_at']);
      if (first == null) return second == null ? 0 : 1;
      if (second == null) return -1;
      return _newestFirst ? second.compareTo(first) : first.compareTo(second);
    });
    return result;
  }

  Widget _filter(String value, String label, IconData icon) {
    final selected = _audience == value;
    final count = value == 'all' ? _announcements.length : _announcements.where((p) => _read(p['visibility']).toLowerCase() == value).length;
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      backgroundColor: Colors.white,
      selectedColor: _forest,
      side: BorderSide(color: selected ? _forest : _line),
      shape: const StadiumBorder(),
      avatar: Icon(icon, size: 16, color: selected ? _yellow : _green),
      label: Text('$label${_loading || _error != null ? '' : '  $count'}', style: TextStyle(color: selected ? Colors.white : _ink, fontSize: 12, fontWeight: FontWeight.w700)),
      onSelected: (_) => setState(() => _audience = value),
    );
  }

  Widget _composer() => Container(
    decoration: _surface(shadow: true),
    padding: const EdgeInsets.fromLTRB(17, 17, 17, 10),
    child: Column(children: [
      Row(children: [
        _OrgAvatar(name: _orgName),
        const SizedBox(width: 12),
        Expanded(child: Material(
          color: _soft,
          borderRadius: BorderRadius.circular(11),
          child: InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: _composerOpen ? null : _compose,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              child: Text('Share an update from your organization…', style: TextStyle(color: _muted, fontSize: 13)),
            ),
          ),
        )),
      ]),
      const SizedBox(height: 13),
      const Divider(height: 1, color: _line),
      const SizedBox(height: 7),
      TextButton.icon(
        onPressed: _composerOpen ? null : _compose,
        icon: const Icon(Icons.campaign_outlined, size: 21),
        label: const Text('Create announcement'),
        style: TextButton.styleFrom(foregroundColor: _forest, textStyle: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    ]),
  );

  Widget _notice(String title, String message, IconData icon, String action, VoidCallback onTap) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 22),
    decoration: _surface(),
    child: Column(children: [
      Container(width: 58, height: 58, decoration: BoxDecoration(color: _soft, borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: _green, size: 28)),
      const SizedBox(height: 13),
      Text(title, textAlign: TextAlign.center, style: const TextStyle(color: _ink, fontWeight: FontWeight.w800, fontSize: 16)),
      const SizedBox(height: 6),
      Text(message, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 13, height: 1.5)),
      const SizedBox(height: 15),
      FilledButton(onPressed: onTap, style: FilledButton.styleFrom(backgroundColor: _forest, foregroundColor: Colors.white), child: Text(action)),
    ]),
  );

  Widget _main() {
    final shown = _shown;
    final filtered = _audience != 'all' || _search.text.trim().isNotEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Row(children: [
        Icon(Icons.circle, color: _green, size: 7), SizedBox(width: 7),
        Expanded(child: Text('KAISA / ORGANIZATION COMMUNICATIONS', style: TextStyle(color: _green, fontWeight: FontWeight.w800, letterSpacing: 1.15, fontSize: 10))),
      ]),
      const SizedBox(height: 7),
      const Text('Feed & Announcements', style: TextStyle(color: _forest, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8, height: 1.15)),
      const SizedBox(height: 7),
      const Text('Manage official organization announcements. Events are published from Events Management.', style: TextStyle(color: _muted, fontSize: 13, height: 1.45)),
      const SizedBox(height: 16),
      if (kDebugMode) ...[
        Container(decoration: _surface(), child: SwitchListTile(
          title: Text(_mock ? 'Mock data mode' : 'Existing service mode'),
          subtitle: Text(_mock ? 'Local sample announcements only' : 'Authorized organization announcements'),
          value: _mock,
          onChanged: _composerOpen ? null : _switchMode,
        )),
        if (_mock) Wrap(spacing: 8, children: [
          TextButton(onPressed: _composerOpen ? null : () => setState(_seedMock), child: const Text('Reset samples')),
          TextButton(onPressed: _composerOpen ? null : () => setState(() { _mockRows.clear(); _announcements = []; }), child: const Text('Test empty state')),
        ]),
        const SizedBox(height: 12),
      ],
      Row(children: [
        Expanded(child: TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: _field('Search announcements and updates…', icon: Icons.search_rounded).copyWith(
            suffixIcon: _search.text.isEmpty ? null : IconButton(tooltip: 'Clear search', onPressed: () => setState(() => _search.clear()), icon: const Icon(Icons.close_rounded, color: _muted, size: 18)),
          ),
        )),
        const SizedBox(width: 7),
        Material(color: _soft, borderRadius: BorderRadius.circular(12), child: IconButton(tooltip: _showFilters ? 'Hide filters' : 'Show filters', onPressed: () => setState(() => _showFilters = !_showFilters), icon: Icon(_showFilters ? Icons.tune_rounded : Icons.filter_list_rounded, color: _forest))),
        IconButton(tooltip: 'Refresh announcements', onPressed: _loading ? null : _reload, icon: const Icon(Icons.refresh_rounded, color: _forest)),
      ]),
      if (_showFilters) ...[
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 5, children: [
          _filter('all', 'All updates', Icons.forum_outlined),
          _filter('public', 'Public', Icons.public_rounded),
          _filter('members', 'Members only', Icons.groups_outlined),
        ]),
      ] else if (_audience != 'all') ...[
        const SizedBox(height: 8),
        Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => setState(() => _audience = 'all'), icon: const Icon(Icons.close_rounded, size: 16), label: Text('Clear ${_audienceLabel(_audience)} filter'))),
      ],
      const SizedBox(height: 17),
      _composer(),
      const SizedBox(height: 25),
      Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 10, runSpacing: 8, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('ORGANIZATION UPDATES', style: TextStyle(color: _green, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          const Text('Published announcements', style: TextStyle(color: _ink, fontSize: 19, fontWeight: FontWeight.w800)),
          if (!_loading && _error == null) Text('${shown.length} of ${_announcements.length} loaded', style: const TextStyle(color: _muted, fontSize: 11.5)),
        ]),
        PopupMenuButton<bool>(
          tooltip: 'Sort announcements',
          initialValue: _newestFirst,
          onSelected: (value) => setState(() => _newestFirst = value),
          itemBuilder: (_) => const [PopupMenuItem(value: true, child: Text('Most recent')), PopupMenuItem(value: false, child: Text('Oldest first'))],
          child: Container(decoration: _surface(), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.sort_rounded, color: _green, size: 17), const SizedBox(width: 6),
            Text(_newestFirst ? 'Most recent' : 'Oldest first', style: const TextStyle(color: _forest, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(width: 4), const Icon(Icons.expand_more_rounded, color: _muted, size: 16),
          ])),
        ),
      ]),
      const SizedBox(height: 13),
      if (_loading)
        const Padding(padding: EdgeInsets.symmetric(vertical: 45), child: Center(child: CircularProgressIndicator(color: _green)))
      else if (_error != null)
        _notice('Unable to load updates', _error!, Icons.wifi_off_rounded, 'Try again', _reload)
      else if (shown.isEmpty)
        _notice(filtered ? 'No matching announcements' : 'No announcements yet', filtered ? 'Try another keyword or clear your filters.' : 'Share your first official update with the community.', Icons.forum_outlined, filtered ? 'Show all updates' : 'Create announcement', filtered ? () => setState(() { _search.clear(); _audience = 'all'; }) : _compose)
      else
        for (final item in shown) ...[
          _AnnouncementCard(item: item, organizationName: _orgName),
          const SizedBox(height: 15),
        ],
      if (!_loading && _error == null && _announcements.length >= 30)
        const Padding(padding: EdgeInsets.symmetric(vertical: 7), child: Text('Showing up to 30 announcements returned by the server. Search and filters apply to these loaded records.', style: TextStyle(color: _muted, fontSize: 11.5, height: 1.4))),
    ]);
  }

  Widget _sidePanel() {
    final public = _announcements.where((p) => _read(p['visibility']).toLowerCase() == 'public').length;
    final members = _announcements.where((p) => _read(p['visibility']).toLowerCase() == 'members').length;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(decoration: _surface(), padding: const EdgeInsets.all(17), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Your organization', style: TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        Row(children: [_OrgAvatar(name: _orgName, radius: 21), const SizedBox(width: 10), Expanded(child: Text(_orgName, style: const TextStyle(color: _forest, fontSize: 14, fontWeight: FontWeight.w800)))]),
        const SizedBox(height: 15),
        const Divider(height: 1, color: _line),
        const SizedBox(height: 12),
        const Text('Loaded announcements', style: TextStyle(color: _muted, fontSize: 12)),
        const SizedBox(height: 5),
        Text(_loading || _error != null ? '—' : '${_announcements.length}', style: const TextStyle(color: _forest, fontSize: 27, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        _countLine(Icons.public_rounded, 'Public', public),
        const SizedBox(height: 10),
        _countLine(Icons.groups_outlined, 'Members only', members),
      ])),
      const SizedBox(height: 15),
      Container(decoration: BoxDecoration(color: _forest, borderRadius: BorderRadius.circular(15)), padding: const EdgeInsets.all(18), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.campaign_outlined, color: _yellow, size: 28),
        SizedBox(height: 11),
        Text('Make every update count.', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        SizedBox(height: 8),
        Text('Use Public for community-wide announcements and Members only for internal organization updates.', style: TextStyle(color: Color(0xFFDCECDF), fontSize: 12.5, height: 1.5)),
      ])),
    ]);
  }

  Widget _countLine(IconData icon, String text, int count) => Row(children: [
    Icon(icon, color: _green, size: 17), const SizedBox(width: 8),
    Expanded(child: Text(text, style: const TextStyle(color: _muted, fontSize: 12))),
    Text(_loading || _error != null ? '—' : '$count', style: const TextStyle(color: _forest, fontWeight: FontWeight.w800)),
  ]);

  @override
  Widget build(BuildContext context) {
    if (_organizationId == null) {
      return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Choose an organization from the account switcher first.', textAlign: TextAlign.center)));
    }
    // The existing organization-admin shell owns the app bar and navigation.
    return Material(
      color: _canvas,
      child: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1000;
        final padding = constraints.maxWidth < 550 ? 14.0 : 25.0;
        return RefreshIndicator(
          color: _green,
          onRefresh: _reload,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(padding, 25, padding, 45),
            child: Center(child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: wide ? 1120 : 740),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 7, child: _main()),
                if (wide) ...[const SizedBox(width: 25), Expanded(flex: 3, child: _sidePanel())],
              ]),
            )),
          ),
        );
      }),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.item, required this.organizationName});
  final Map<String, dynamic> item;
  final String organizationName;

  Future<void> _copy(BuildContext context) async {
    final text = [_read(item['title']), _read(item['body'])].where((s) => s.isNotEmpty).join('\n\n');
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement text copied.')));
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to copy announcement text.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _read(item['title']);
    final body = _read(item['body']);
    final visibility = item['visibility'];
    final date = _date(item['created_at']);
    final fullDate = date == null ? 'Date unavailable' : '${MaterialLocalizations.of(context).formatFullDate(date)} · ${TimeOfDay.fromDateTime(date).format(context)}';
    return Container(
      decoration: _surface(shadow: true),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(padding: const EdgeInsets.fromLTRB(17, 17, 9, 0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _OrgAvatar(name: organizationName),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(organizationName, style: const TextStyle(color: _forest, fontWeight: FontWeight.w800, fontSize: 14.5)),
            const SizedBox(height: 4),
            Wrap(spacing: 6, runSpacing: 3, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Tooltip(message: fullDate, child: Text(_relativeTime(item['created_at']), style: const TextStyle(color: _muted, fontSize: 11.5))),
              const Icon(Icons.circle, color: _muted, size: 3),
              Icon(_audienceIcon(visibility), color: _muted, size: 14),
              Text(_audienceLabel(visibility), style: const TextStyle(color: _muted, fontSize: 11.5)),
            ]),
          ])),
          PopupMenuButton<String>(
            tooltip: 'Announcement options',
            icon: const Icon(Icons.more_horiz_rounded, color: _muted),
            onSelected: (_) => _copy(context),
            itemBuilder: (_) => const [PopupMenuItem(value: 'copy', child: Row(children: [Icon(Icons.copy_rounded, size: 18), SizedBox(width: 10), Text('Copy announcement')]))],
          ),
        ])),
        Padding(padding: const EdgeInsets.fromLTRB(17, 14, 17, 0), child: Align(alignment: Alignment.centerLeft, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(color: _announcementTint, borderRadius: BorderRadius.circular(5)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.campaign_outlined, color: _announcementInk, size: 13), SizedBox(width: 5),
            Text('ANNOUNCEMENT', style: TextStyle(color: _announcementInk, fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: .5)),
          ]),
        ))),
        if (title.isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(17, 12, 17, 0), child: Text(title, style: const TextStyle(color: _ink, fontSize: 19, fontWeight: FontWeight.w800, height: 1.3))),
        if (body.isNotEmpty) Padding(padding: EdgeInsets.fromLTRB(17, title.isEmpty ? 13 : 7, 17, 0), child: SelectableText(body, style: const TextStyle(color: _ink, fontSize: 14.5, height: 1.55))),
        const SizedBox(height: 17),
        const Divider(height: 1, color: _line),
        Padding(padding: const EdgeInsets.fromLTRB(17, 3, 10, 3), child: Row(children: [
          const Icon(Icons.check_circle_outline_rounded, color: _green, size: 17),
          const SizedBox(width: 6),
          const Expanded(child: Text('Published', style: TextStyle(color: _muted, fontSize: 12))),
          TextButton.icon(onPressed: () => _copy(context), icon: const Icon(Icons.copy_rounded, size: 16), label: const Text('Copy text'), style: TextButton.styleFrom(foregroundColor: _forest, textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
        ])),
      ]),
    );
  }
}

class _AnnouncementDraft {
  const _AnnouncementDraft({required this.title, required this.body, required this.visibility, required this.inApp, required this.email});
  final String title, body, visibility;
  final bool inApp, email;
}

class _AnnouncementComposer extends StatefulWidget {
  const _AnnouncementComposer({required this.organizationName, required this.onPublish, required this.mock});
  final bool mock;
  final String organizationName;
  final Future<void> Function(_AnnouncementDraft) onPublish;
  @override
  State<_AnnouncementComposer> createState() => _AnnouncementComposerState();
}

class _AnnouncementComposerState extends State<_AnnouncementComposer> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  String _visibility = 'public';
  bool _inApp = true;
  bool _email = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  bool get _valid => _title.text.trim().isNotEmpty && _body.text.trim().isNotEmpty && _title.text.characters.length <= 120 && _body.text.characters.length <= 4000;

  Future<void> _submit() async {
    if (_busy || !_valid) return;
    final draft = _AnnouncementDraft(title: _title.text.trim(), body: _body.text.trim(), visibility: _visibility, inApp: _inApp, email: _email);
    setState(() { _busy = true; _error = null; });
    try {
      await widget.onPublish(draft);
      if (!mounted) return;
      Navigator.of(context).pop(draft);
    } catch (e) {
      if (!mounted) return;
      debugPrint('KAISA announcement publish: $e');
      setState(() {
        _error = e is StateError ? e.message.toString() : 'Unable to publish the announcement. Refresh the feed to check whether it was saved before trying again.';
        _busy = false;
      });
    }
  }

  Widget _label(String text) => Padding(padding: const EdgeInsets.only(bottom: 7), child: Text(text, style: const TextStyle(color: _forest, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w800)));

  Widget _notification({required String title, required String subtitle, required bool value, required ValueChanged<bool?> onChanged, required IconData icon}) => CheckboxListTile(
    contentPadding: EdgeInsets.zero,
    secondary: Icon(icon, color: _green, size: 21),
    activeColor: _forest,
    controlAffinity: ListTileControlAffinity.trailing,
    title: Text(title, style: const TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w700)),
    subtitle: Text(subtitle, style: const TextStyle(color: _muted, fontSize: 11.5, height: 1.35)),
    value: value,
    onChanged: _busy ? null : onChanged,
  );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Container(width: 42, height: 42, decoration: BoxDecoration(color: _soft, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.campaign_outlined, color: _forest, size: 24)),
                const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('NEW ORGANIZATION UPDATE', style: TextStyle(color: _green, fontSize: 10, letterSpacing: 1.1, fontWeight: FontWeight.w800)),
                  SizedBox(height: 3),
                  Text('Create announcement', style: TextStyle(color: _forest, fontWeight: FontWeight.w900, fontSize: 22, height: 1.2)),
                ])),
                IconButton(tooltip: 'Close composer', onPressed: _busy ? null : () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded, color: _ink)),
              ]),
              const SizedBox(height: 12),
              const Text('Share important news and updates with your community.', style: TextStyle(color: _muted, fontSize: 13, height: 1.45)),
              const SizedBox(height: 20),
              _label('POSTING AS'),
              Container(decoration: BoxDecoration(color: _soft, borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.all(12), child: Row(children: [
                _OrgAvatar(name: widget.organizationName, radius: 20), const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.organizationName, style: const TextStyle(color: _forest, fontWeight: FontWeight.w800, fontSize: 14)),
                  const Text('Organization announcement', style: TextStyle(color: _muted, fontSize: 11.5)),
                ])),
              ])),
              const SizedBox(height: 17),
              _label('WHO CAN SEE THIS?'),
              DropdownButtonFormField<String>(
                initialValue: _visibility,
                isExpanded: true,
                decoration: _field('Audience', icon: _audienceIcon(_visibility)).copyWith(fillColor: _soft),
                items: const [DropdownMenuItem(value: 'public', child: Text('Public · All signed-in users')), DropdownMenuItem(value: 'members', child: Text('Members only'))],
                onChanged: _busy ? null : (value) => setState(() => _visibility = value ?? 'public'),
              ),
              const SizedBox(height: 7),
              Text(_visibility == 'members' ? 'Visible only to approved organization members.' : 'Visible to signed-in KAISA users.', style: const TextStyle(color: _muted, fontSize: 12)),
              const SizedBox(height: 18),
              _label('ANNOUNCEMENT TITLE'),
              TextField(controller: _title, enabled: !_busy, maxLength: 120, textCapitalization: TextCapitalization.sentences, onChanged: (_) => setState(() {}), decoration: _field('Give your announcement a title')),
              const SizedBox(height: 8),
              _label('YOUR MESSAGE'),
              TextField(controller: _body, enabled: !_busy, minLines: 4, maxLines: 8, maxLength: 4000, textCapitalization: TextCapitalization.sentences, onChanged: (_) => setState(() {}), decoration: _field('What would you like to share?')),
              const Divider(height: 24, color: _line),
              _label('NOTIFICATION SETTINGS'),
              if (widget.mock) const Text('Simulation only: no email or in-app notifications will be sent.'),
              _notification(title: 'In-app notifications', subtitle: 'Notify approved organization members in KAISA.', value: _inApp, onChanged: (v) => setState(() => _inApp = v ?? false), icon: Icons.notifications_none_rounded),
              _notification(title: 'Email notifications', subtitle: 'Queue emails to members. Server email delivery must be configured.', value: _email, onChanged: (v) => setState(() => _email = v ?? false), icon: Icons.mail_outline_rounded),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12, height: 1.4)),
              ],
              const SizedBox(height: 19),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: _busy ? null : () => Navigator.of(context).pop(), style: OutlinedButton.styleFrom(foregroundColor: _forest, side: const BorderSide(color: _line), padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('Cancel'))),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: FilledButton.icon(
                  onPressed: _busy || !_valid ? null : _submit,
                  style: FilledButton.styleFrom(backgroundColor: _forest, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6)),
                  icon: _busy ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded, size: 17),
                  label: Text(_busy ? 'Publishing…' : 'Publish announcement', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5)),
                )),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
