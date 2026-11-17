import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/organization_model.dart';
import '../../../shared/repositories/organization_repository.dart';
import '../../../shared/repositories/community_event_repository.dart';
import 'operations_insights_section.dart';

// KAISA Operations visual system — shared with Registry and Admin Assignments.
// Data remains sourced from the current repositories, not from Supabase queries.
const _forest = Color(0xFF00492C);
const _green = Color(0xFF287D55);
const _paper = Color(0xFFF6F8F5);
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
    final active = all.where((o) => o.status == 'Active').length;
    final inactive = total - active;
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

    final preview = all
        .where((org) {
          final q = _registrySearch.trim().toLowerCase();
          return q.isEmpty ||
              org.name.toLowerCase().contains(q) ||
              org.category.toLowerCase().contains(q) ||
              org.registryReference.toLowerCase().contains(q);
        })
        .take(6)
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 650;
        return ColoredBox(
          color: _paper,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 28,
              24,
              compact ? 16 : 28,
              48,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1260),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _pageHeader(compact),
                      const SizedBox(height: 16),
                      _quickAccess(),
                      const SizedBox(height: 16),
                      _attentionPanel(unassigned, inactive),
                      const SizedBox(height: 24),
                      _sectionHeading(
                        'Operations at a glance',
                        'Registry and event counts use local repositories; performance insights use clearly labeled fictional demo data.',
                      ),
                      const SizedBox(height: 13),
                      _kpiGrid([
                        _Kpi(
                          'Registered organizations',
                          '$total',
                          Icons.apartment_rounded,
                          'All registry records',
                        ),
                        _Kpi(
                          'Active organizations',
                          '$active',
                          Icons.verified_outlined,
                          'Inactive: $inactive',
                        ),
                        _Kpi(
                          'Assigned administrators',
                          '$assigned',
                          Icons.admin_panel_settings_outlined,
                          'Unassigned: $unassigned',
                        ),
                        _Kpi(
                          'Upcoming events',
                          '${eventRepository.upcomingEvents}',
                          Icons.event_available_outlined,
                          'Repository event schedule',
                        ),
                        const _Kpi(
                          'Total organization members',
                          '—',
                          Icons.groups_2_outlined,
                          'Awaiting member data',
                        ),
                        const _Kpi(
                          'Event participation',
                          '—',
                          Icons.how_to_reg_outlined,
                          'Awaiting attendance data',
                        ),
                      ]),
                      const SizedBox(height: 25),
                      _sectionHeading(
                        'Organization performance & insights',
                        'Interactive prototype rankings and charts using sample data. Not official LGU statistics.',
                      ),
                      const SizedBox(height: 13),
                      const OperationsInsightsSection(),
                      const SizedBox(height: 25),
                      _sectionHeading(
                        'Registry distribution',
                        'Organization status and categories from the prototype registry.',
                      ),
                      const SizedBox(height: 13),
                      LayoutBuilder(
                        builder: (context, box) {
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
                                  'Organization status',
                                  'Active and inactive registry records',
                                  _statusChart(total, active, inactive),
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
                        },
                      ),
                      const SizedBox(height: 25),
                      _sectionHeading(
                        'Operations workspaces',
                        'Quick access to the six currently configured Operations routes.',
                      ),
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
      },
    );
  }

  Widget _pageHeader(bool compact) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(compact ? 23 : 30),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        colors: [Color(0xFF0B3024), Color(0xFF15543A), Color(0xFF288258)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 18,
      runSpacing: 18,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 610),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'KAISA  /  LGU OPERATIONS',
                style: TextStyle(
                  color: _gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 13),
              Text(
                'Operations Command Center',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 27 : 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Oversee registered organizations, authorized representatives, community events, and operational activity in one workspace.',
                style: TextStyle(
                  color: Color(0xFFE2F0E6),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _go('/lgu-admin/organizations'),
          icon: const Icon(Icons.apartment_rounded, size: 18),
          label: const Text('Open registry'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white54),
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
          ),
        ),
      ],
    ),
  );

  // Compact quick actions mirror the desktop Operations navigation.
  // They use existing GoRouter destinations, so no new routes are required.
  Widget _quickAccess() {
    final actions = <(String, IconData, String)>[
      ('Registry', Icons.apartment_rounded, '/lgu-admin/organizations'),
      ('Assignments', Icons.manage_accounts_outlined, '/lgu-admin/assignments'),
      ('Events', Icons.event_note_outlined, '/lgu-admin/events'),
      ('Reports', Icons.bar_chart_outlined, '/lgu-admin/reports'),
    ];
    return LayoutBuilder(
      builder: (context, bounds) {
        final columns = bounds.maxWidth >= 760
            ? 4
            : bounds.maxWidth >= 430
            ? 2
            : 1;
        const space = 10.0;
        final tileWidth = (bounds.maxWidth - (columns - 1) * space) / columns;
        return Wrap(
          spacing: space,
          runSpacing: space,
          children: [
            for (final item in actions)
              SizedBox(
                width: tileWidth,
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _go(item.$3),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 15,
                      ),
                      decoration: _surface(radius: 16),
                      child: Row(
                        children: [
                          Icon(item.$2, color: _forest, size: 21),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.$1,
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: _muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _attentionPanel(int unassigned, int inactive) => Container(
    padding: const EdgeInsets.all(19),
    decoration: _surface(radius: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5D8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.fact_check_outlined,
            color: Color(0xFF92650D),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Items to review',
                style: TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$unassigned organization(s) without assigned representatives  •  $inactive inactive organization(s)',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'These are registry indicators, not verified incidents or pending approval counts.',
                style: TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Review organization registry',
          onPressed: () => _go('/lgu-admin/organizations'),
          icon: const Icon(Icons.arrow_forward_rounded, color: _forest),
        ),
      ],
    ),
  );

  Widget _sectionHeading(String title, String caption) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: _ink,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 4),
      Text(caption, style: const TextStyle(color: _muted, fontSize: 12)),
    ],
  );

  Widget _kpiGrid(List<_Kpi> cards) => LayoutBuilder(
    builder: (context, constraints) {
      final cols = constraints.maxWidth >= 1050
          ? 3
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
            color: _soft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(item.icon, color: _forest, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.value,
                style: const TextStyle(
                  color: _forest,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                item.label,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.detail,
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
        ),
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
        Text(
          title,
          style: const TextStyle(
            color: _forest,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
        const SizedBox(height: 23),
        content,
      ],
    ),
  );

  Widget _statusChart(int total, int active, int inactive) {
    if (total == 0) return _emptyChart('No organization records available.');
    final ratio = active / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${(ratio * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                color: _forest,
                fontSize: 31,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 9),
            const Text(
              'currently active',
              style: TextStyle(color: _muted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 15),
        ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Row(
            children: [
              if (active > 0)
                Expanded(
                  flex: active,
                  child: Container(height: 16, color: _green),
                ),
              if (inactive > 0)
                Expanded(
                  flex: inactive,
                  child: Container(height: 16, color: _gold),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _legend('Active', active, _green),
        const SizedBox(height: 10),
        _legend('Inactive / other', inactive, _gold),
        const SizedBox(height: 9),
        const Text(
          'Based on organization registry status.',
          style: TextStyle(color: _muted, fontSize: 11),
        ),
      ],
    );
  }

  Widget _legend(String name, int count, Color color) => Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Text(name, style: const TextStyle(color: _ink, fontSize: 12)),
      ),
      Text(
        '$count',
        style: const TextStyle(
          color: _ink,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );

  Widget _categoryChart(List<MapEntry<String, int>> categories, int total) {
    if (categories.isEmpty) {
      return _emptyChart(
        'Category analytics appear when organizations are added.',
      );
    }
    final maxCount = categories.first.value;
    return Column(
      children: [
        for (final item in categories.take(6)) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  item.key,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _ink, fontSize: 12),
                ),
              ),
              Text(
                '${item.value}  ·  ${(item.value * 100 / total).toStringAsFixed(0)}%',
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
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
          Text(
            '+ ${categories.length - 6} more categories',
            style: const TextStyle(color: _muted, fontSize: 11),
          ),
      ],
    );
  }

  Widget _emptyChart(String message) => SizedBox(
    height: 145,
    child: Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: _muted, fontSize: 12),
      ),
    ),
  );

  Widget _workspaceLinks() {
    final links = <(String, IconData, String)>[
      (
        'Organization Registry',
        Icons.apartment_rounded,
        '/lgu-admin/organizations',
      ),
      (
        'Admin Assignments',
        Icons.manage_accounts_outlined,
        '/lgu-admin/assignments',
      ),
      ('Event Monitoring', Icons.event_note_outlined, '/lgu-admin/events'),
      ('Reports', Icons.bar_chart_outlined, '/lgu-admin/reports'),
      ('Audit Logs', Icons.history_rounded, '/lgu-admin/audit-logs'),
      ('Settings', Icons.settings_outlined, '/lgu-admin/settings'),
    ];
    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth >= 1050
            ? 3
            : box.maxWidth >= 570
            ? 2
            : 1;
        const gap = 11.0;
        final width = (box.maxWidth - (cols - 1) * gap) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in links)
              SizedBox(
                width: width,
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(13),
                    onTap: () => _go(item.$3),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      decoration: _surface(radius: 13),
                      child: Row(
                        children: [
                          Icon(item.$2, color: _green, size: 22),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              item.$1,
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 19,
                            color: _muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Organization Registry',
                      style: TextStyle(
                        color: _forest,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$total registered organization records',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: TextField(
              onChanged: (value) => setState(() => _registrySearch = value),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search_rounded, color: _green),
                hintText: 'Search organization name, category or reference',
                hintStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          if (organizations.isEmpty)
            const Padding(
              padding: EdgeInsets.all(26),
              child: Center(
                child: Text(
                  'No matching organizations found.',
                  style: TextStyle(color: _muted),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, tableBounds) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableBounds.maxWidth < 865
                      ? 865
                      : tableBounds.maxWidth,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(_soft),
                    columnSpacing: 32,
                    columns: const [
                      DataColumn(label: Text('ORGANIZATION')),
                      DataColumn(label: Text('CATEGORY')),
                      DataColumn(label: Text('STATUS')),
                      DataColumn(label: Text('ASSIGNED ADMIN')),
                    ],
                    rows: [
                      for (final org in organizations)
                        DataRow(
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 220,
                                child: Text(
                                  org.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _forest,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              onTap: () => _go('/lgu-admin/organizations'),
                            ),
                            DataCell(Text(org.category)),
                            DataCell(_statusLabel(org.status)),
                            DataCell(
                              SizedBox(
                                width: 180,
                                child: Text(
                                  org.adminEmail.isEmpty
                                      ? 'Not assigned'
                                      : org.adminEmail,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusLabel(String status) {
    final active = status == 'Active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: active ? _soft : const Color(0xFFFFF5DA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: active ? _forest : const Color(0xFF92650D),
        ),
      ),
    );
  }

  Widget _notice() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(Icons.info_outline_rounded, color: _muted, size: 17),
      const SizedBox(width: 8),
      const Expanded(
        child: Text(
          'Operations overview: organization counts, categories, and upcoming '
          'event counts use local repositories. Member totals and attendance '
          'remain unavailable in local metrics. The performance panel independently '
          'queries Supabase and reports errors when its authorized view is unavailable.',
          style: TextStyle(color: _muted, fontSize: 11, height: 1.5),
        ),
      ),
    ],
  );

  BoxDecoration _surface({double radius = 18}) => BoxDecoration(
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
