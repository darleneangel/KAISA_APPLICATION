import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/organization_model.dart';
import '../../../shared/repositories/organization_repository.dart';
import '../../../shared/repositories/community_event_repository.dart';

// KAISA administration design tokens — aligned with the Organization Admin UI.
const _forest = Color(0xFF00492C);
const _green = Color(0xFF237A50);
const _paper = Color(0xFFF8FAF8);
const _ink = Color(0xFF173D2B);
const _muted = Color(0xFF687B70);
const _gold = Color(0xFFFBBA16);
const _stroke = Color(0xFFE2EBE4);
const _soft = Color(0xFFEAF5EE);

class LguAdminDashboardPage extends StatefulWidget {
  const LguAdminDashboardPage({super.key});

  @override
  State<LguAdminDashboardPage> createState() => _LguAdminDashboardPageState();
}

class _LguAdminDashboardPageState extends State<LguAdminDashboardPage> {
  final OrganizationRepository repository = OrganizationRepository.instance;
  final CommunityEventRepository eventRepository =
      CommunityEventRepository.instance;
  String _registrySearch = '';

  @override
  void initState() {
    super.initState();
    repository.addListener(_refresh);
    eventRepository.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    repository.removeListener(_refresh);
    eventRepository.removeListener(_refresh);
    super.dispose();
  }

  void _go(String route) => context.go(route);

  @override
  Widget build(BuildContext context) {
    final all = repository.organizations;
    final total = all.length;
    final assigned = all.where((o) => o.adminEmail.trim().isNotEmpty).length;
    final unassigned = total - assigned;

    final categories = <String, int>{};
    for (final org in all) {
      final name = org.category.trim().isEmpty ? 'Uncategorized' : org.category;
      categories[name] = (categories[name] ?? 0) + 1;
    }
    final categoryRows = categories.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });

    final preview = all.where((org) {
      final q = _registrySearch.trim().toLowerCase();
      return q.isEmpty ||
          org.name.toLowerCase().contains(q) ||
          org.category.toLowerCase().contains(q) ||
          org.registryReference.toLowerCase().contains(q);
    }).take(6).toList();

    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 650;
      return ColoredBox(
        color: _paper,
        child: ListView(
          padding: EdgeInsets.fromLTRB(compact ? 16 : 28, 24,
              compact ? 16 : 28, 48),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1260),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _pageHeader(compact),
                    const SizedBox(height: 24),
                    _sectionHeading('Operations overview',
                        'Registry, representative and event totals from the shared prototype repositories.'),
                    const SizedBox(height: 13),
                    _kpiGrid([
                      _Kpi('Registered organizations', '$total',
                          Icons.apartment_rounded, 'All organizations in the registry'),
                      _Kpi('With representatives', '$assigned',
                          Icons.person_pin_outlined, 'Organizations with an assigned contact'),
                      _Kpi('Without representatives', '$unassigned',
                          Icons.person_search_outlined, 'Organizations requiring assignment'),
                      _Kpi('Upcoming events', '${eventRepository.upcomingEvents}',
                          Icons.event_available_outlined, 'From the prototype event schedule'),
                    ]),
                    const SizedBox(height: 25),
                    LayoutBuilder(builder: (context, box) {
                      final two = box.maxWidth >= 800;
                      final width = two
                          ? (box.maxWidth - 14) / 2
                          : box.maxWidth;
                      return Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          SizedBox(
                            width: width,
                            child: _panel(
                              'Representative coverage',
                              'Organizations with and without assigned representatives',
                              _assignmentChart(total, assigned, unassigned),
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: _panel(
                              'Organizations by category',
                              'Distribution across registered sectors',
                              _categoryChart(categoryRows, total),
                            ),
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 25),
                    _sectionHeading('Operational workspaces',
                        'Manage records, assignments, and community activity.'),
                    const SizedBox(height: 13),
                    _workspaceLinks(),
                    const SizedBox(height: 25),
                    _registryPreview(preview, total),
                    const SizedBox(height: 15),
                    _notice(),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _pageHeader(bool compact) => Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('KAISA  /  LGU OPERATIONS',
                    style: TextStyle(color: _green, fontSize: 11,
                        fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                const SizedBox(height: 6),
                Text('Operations Dashboard',
                    style: TextStyle(color: _ink,
                        fontSize: compact ? 25 : 30,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text('Oversight of registered organizations, '
                    'administrators, and community programs.',
                    style: TextStyle(color: _muted, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Refresh overview'),
            style: OutlinedButton.styleFrom(
                foregroundColor: _forest,
                side: const BorderSide(color: _stroke)),
          ),
        ],
      );

  Widget _sectionHeading(String title, String caption) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(
              color: _ink, fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(caption, style: const TextStyle(color: _muted, fontSize: 12)),
        ],
      );

  Widget _kpiGrid(List<_Kpi> cards) => LayoutBuilder(
        builder: (context, constraints) {
          final cols = constraints.maxWidth >= 1050
              ? 4
              : constraints.maxWidth >= 590
                  ? 2
                  : 1;
          const gap = 12.0;
          final width = (constraints.maxWidth - gap * (cols - 1)) / cols;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [for (final item in cards) _kpiCard(item, width)],
          );
        },
      );

  Widget _kpiCard(_Kpi item, double width) => Container(
        width: width,
        padding: const EdgeInsets.all(17),
        decoration: _surface(),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: _soft, borderRadius: BorderRadius.circular(12)),
              child: Icon(item.icon, color: _forest, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.value, style: const TextStyle(color: _forest,
                    fontSize: 27, fontWeight: FontWeight.w900)),
                Text(item.label, style: const TextStyle(color: _ink,
                    fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(item.detail, style: const TextStyle(color: _muted,
                    fontSize: 11)),
              ],
            )),
          ],
        ),
      );

  Widget _panel(String title, String subtitle, Widget content) => Container(
        constraints: const BoxConstraints(minHeight: 280),
        padding: const EdgeInsets.all(19),
        decoration: _surface(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: _forest,
                fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: _muted,
                fontSize: 12)),
            const SizedBox(height: 23),
            content,
          ],
        ),
      );

  Widget _assignmentChart(int total, int assigned, int unassigned) {
    if (total == 0) {
      return _emptyChart('Add organizations to see representative coverage.');
    }
    final ratio = assigned / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Tooltip(
          message: '$assigned of $total organizations have a recorded representative email. This does not grant access permissions.',
          child: Row(children: [
            Text('${(ratio * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: _forest, fontSize: 31,
                  fontWeight: FontWeight.w900)),
            const SizedBox(width: 9),
            const Expanded(child: Text('with a recorded representative',
                style: TextStyle(color: _muted, fontSize: 12))),
          ]),
        ),
        const SizedBox(height: 15),
        ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Row(children: [
            if (assigned > 0)
              Expanded(flex: assigned, child: Container(height: 16, color: _green)),
            if (unassigned > 0)
              Expanded(flex: unassigned,
                  child: Container(height: 16, color: _gold)),
          ]),
        ),
        const SizedBox(height: 20),
        _legend('With representative', assigned, _green),
        const SizedBox(height: 10),
        _legend('Without representative', unassigned, _gold),
        const SizedBox(height: 9),
        const Text('Source: organization registry. Assignment is not a Supabase role grant.',
            style: TextStyle(color: _muted, fontSize: 11)),
      ],
    );
  }

  Widget _legend(String name, int count, Color color) => Row(children: [
        Container(width: 10, height: 10,
            decoration: BoxDecoration(color: color,
                borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 9),
        Expanded(child: Text(name, style: const TextStyle(
            color: _ink, fontSize: 12))),
        Text('$count', style: const TextStyle(color: _ink,
            fontSize: 12, fontWeight: FontWeight.w800)),
      ]);

  Widget _categoryChart(List<MapEntry<String, int>> categories, int total) {
    if (categories.isEmpty) {
      return _emptyChart('Category analytics appear when organizations are added.');
    }
    final maxCount = categories.first.value;
    return Column(children: [
      for (final item in categories.take(6)) ...[
        Row(children: [
          Expanded(child: Text(item.key, maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _ink, fontSize: 12))),
          Text('${item.value}  ·  ${(item.value * 100 / total).toStringAsFixed(0)}%',
              style: const TextStyle(color: _muted, fontSize: 11)),
        ]),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: item.value / maxCount,
            minHeight: 9,
            color: _green,
            backgroundColor: _soft,
          ),
        ),
        const SizedBox(height: 14),
      ],
      if (categories.length > 6)
        Text('+ ${categories.length - 6} more categories',
            style: const TextStyle(color: _muted, fontSize: 11)),
    ]);
  }

  Widget _emptyChart(String message) => SizedBox(
        height: 145,
        child: Center(child: Text(message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, fontSize: 12))),
      );

  Widget _workspaceLinks() {
    final links = <(String, IconData, String)>[
      ('Organization Registry', Icons.apartment_rounded,
          '/lgu-admin/organizations'),
      ('Admin Assignments', Icons.manage_accounts_outlined,
          '/lgu-admin/assignments'),
      ('Event Monitoring', Icons.event_note_outlined,
          '/lgu-admin/events'),
      ('Reports', Icons.bar_chart_outlined, '/lgu-admin/reports'),
      ('Audit Logs', Icons.history_rounded, '/lgu-admin/audit-logs'),
      ('Settings', Icons.settings_outlined, '/lgu-admin/settings'),
    ];
    return LayoutBuilder(builder: (context, box) {
      final cols = box.maxWidth >= 1050 ? 3 : box.maxWidth >= 570 ? 2 : 1;
      const gap = 11.0;
      final width = (box.maxWidth - (cols - 1) * gap) / cols;
      return Wrap(spacing: gap, runSpacing: gap, children: [
        for (final item in links)
          SizedBox(width: width, child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            child: InkWell(
              borderRadius: BorderRadius.circular(13),
              onTap: () => _go(item.$3),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16,
                    vertical: 15),
                decoration: _surface(radius: 13),
                child: Row(children: [
                  Icon(item.$2, color: _green, size: 22),
                  const SizedBox(width: 11),
                  Expanded(child: Text(item.$1, style: const TextStyle(
                      color: _ink, fontSize: 12,
                      fontWeight: FontWeight.w700))),
                  const Icon(Icons.chevron_right_rounded,
                      size: 19, color: _muted),
                ]),
              ),
            ),
          )),
      ]);
    });
  }

  Widget _registryPreview(List<RegistryOrganization> organizations, int total) {
    return Container(
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Organization Registry', style: TextStyle(
                      color: _forest, fontWeight: FontWeight.w800,
                      fontSize: 17)),
                  const SizedBox(height: 4),
                  Text('$total registered organization records',
                      style: const TextStyle(color: _muted, fontSize: 12)),
                ]),
                TextButton.icon(
                  onPressed: () => _go('/lgu-admin/organizations'),
                  label: const Text('View full registry'),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                  style: TextButton.styleFrom(foregroundColor: _forest),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _stroke),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18,
                vertical: 12),
            child: TextField(
              onChanged: (value) => setState(() => _registrySearch = value),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search_rounded, color: _green),
                hintText: 'Search organization name, category or reference',
                hintStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          if (organizations.isEmpty)
            const Padding(
              padding: EdgeInsets.all(26),
              child: Center(child: Text('No matching organizations found.',
                  style: TextStyle(color: _muted))),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(_soft),
                columnSpacing: 32,
                columns: const [
                  DataColumn(label: Text('ORGANIZATION')),
                  DataColumn(label: Text('CATEGORY')),
                  DataColumn(label: Text('ASSIGNED ADMIN')),
                ],
                rows: [
                  for (final org in organizations)
                    DataRow(cells: [
                      DataCell(SizedBox(width: 220,
                        child: Text(org.name, maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _forest,
                                fontWeight: FontWeight.w700))),
                        onTap: () => _go('/lgu-admin/organizations')),
                      DataCell(Text(org.category)),
                      DataCell(SizedBox(width: 180,
                        child: Text(org.adminEmail.isEmpty
                            ? 'Not assigned' : org.adminEmail,
                            maxLines: 1, overflow: TextOverflow.ellipsis))),
                    ]),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _notice() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: _muted, size: 17),
          const SizedBox(width: 8),
          const Expanded(child: Text(
            'Prototype analytics: registry counts, representative coverage, categories, and upcoming '
            'events come from local repositories. They are not live Supabase analytics; '
            'representative assignments do not grant account permissions. '
            'Refresh redraws the local data and does not query the server.',
            style: TextStyle(color: _muted, fontSize: 11, height: 1.5),
          )),
        ],
      );

  BoxDecoration _surface({double radius = 15}) => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _stroke),
      );
}

class _Kpi {
  final String label;
  final String value;
  final IconData icon;
  final String detail;

  const _Kpi(this.label, this.value, this.icon, this.detail);
}
