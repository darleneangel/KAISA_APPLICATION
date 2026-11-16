
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


const _forest = Color(0xFF14532D);
const _green = Color(0xFF237A50);
const _paper = Color(0xFFF8FAF8);
const _ink = Color(0xFF173D2B);
const _muted = Color(0xFF687B70);
const _stroke = Color(0xFFE2EBE4);
const _soft = Color(0xFFEAF5EE);

class PendingApplicationsPage extends StatefulWidget {
  const PendingApplicationsPage({super.key});

  @override
  State<PendingApplicationsPage> createState() =>
      _PendingApplicationsPageState();
}

class _PendingApplicationsPageState
    extends State<PendingApplicationsPage> {
  String _search = '';
  String _status = 'All';
  String _priority = 'All';

  // Fictional records. No Supabase identity data is accessed.
  static const _applications = <_Application>[
    _Application(
      'VER-DEMO-001',
      'Demo Resident A',
      'Pending',
      'High',
      'Nov 16, 2026',
      'Tier 1',
    ),
    _Application(
      'VER-DEMO-002',
      'Demo Resident B',
      'Under Review',
      'Normal',
      'Nov 16, 2026',
      'Tier 1',
    ),
    _Application(
      'VER-DEMO-003',
      'Demo Resident C',
      'Pending',
      'Normal',
      'Nov 15, 2026',
      'Tier 1',
    ),
    _Application(
      'VER-DEMO-004',
      'Demo Resident D',
      'Approved',
      'Normal',
      'Nov 15, 2026',
      'Tier 2',
    ),
    _Application(
      'VER-DEMO-005',
      'Demo Resident E',
      'Resubmission Requested',
      'High',
      'Nov 14, 2026',
      'Tier 1',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final query = _search.trim().toLowerCase();

    final filtered = _applications.where((app) {
      final matchesSearch =
          app.name.toLowerCase().contains(query) ||
          app.id.toLowerCase().contains(query);

      final matchesStatus =
          _status == 'All' || app.status == _status;

      final matchesPriority =
          _priority == 'All' || app.priority == _priority;

      return matchesSearch &&
          matchesStatus &&
          matchesPriority;
    }).toList();

    final awaitingReview = _applications
        .where((app) =>
            app.status == 'Pending' ||
            app.status == 'Under Review')
        .length;

    final highPriority = _applications
        .where((app) =>
            app.priority == 'High' &&
            (app.status == 'Pending' ||
                app.status == 'Under Review'))
        .length;

    return ColoredBox(
      color: _paper,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: 1260),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'KAISA / LGU ADMINISTRATION / VERIFICATION',
                    style: TextStyle(
                      color: _green,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 9),
                  const Text(
                    'Pending Applications',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 29,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Manage the Tier 2 verification '
                    'application review queue.',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _notice(),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns =
                          constraints.maxWidth >= 750 ? 3 : 1;
                      const gap = 12.0;
                      final width =
                          (constraints.maxWidth -
                              gap * (columns - 1)) /
                          columns;

                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          _metric(
                            'All Demo Applications',
                            '${_applications.length}',
                            Icons.description_outlined,
                            width,
                          ),
                          _metric(
                            'Awaiting Review',
                            '$awaitingReview',
                            Icons.pending_actions_outlined,
                            width,
                          ),
                          _metric(
                            'High Priority in Queue',
                            '$highPriority',
                            Icons.priority_high_rounded,
                            width,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 25),
                  _directory(filtered),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notice() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8DE),
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Color(0xFF92650D),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'DEVELOPMENT PREVIEW — All applications, '
                'priorities, and statuses are fictional. '
                'No actual resident documents or '
                'verification decisions are involved.',
                style: TextStyle(
                  color: Color(0xFF73550E),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _metric(
    String label,
    String value,
    IconData icon,
    double width,
  ) =>
      Container(
        width: width,
        padding: const EdgeInsets.all(19),
        decoration: _surface(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _green, size: 26),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                color: _forest,
                fontSize: 29,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );

  Widget _directory(List<_Application> filtered) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verification Application Directory',
            style: TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Search and filter sample applications.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 285,
                child: TextField(
                  onChanged: (value) =>
                      setState(() => _search = value),
                  decoration: const InputDecoration(
                    hintText: 'Search name or application ID',
                    prefixIcon: Icon(Icons.search_rounded),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(
                width: 205,
                child: DropdownButtonFormField<String>(
                  initialValue: _status,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'All',
                      child: Text('All'),
                    ),
                    DropdownMenuItem(
                      value: 'Pending',
                      child: Text('Pending'),
                    ),
                    DropdownMenuItem(
                      value: 'Under Review',
                      child: Text('Under Review'),
                    ),
                    DropdownMenuItem(
                      value: 'Approved',
                      child: Text('Approved'),
                    ),
                    DropdownMenuItem(
                      value: 'Resubmission Requested',
                      child: Text('Resubmission Requested'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _status = value);
                    }
                  },
                ),
              ),
              SizedBox(
                width: 170,
                child: DropdownButtonFormField<String>(
                  initialValue: _priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'All',
                      child: Text('All'),
                    ),
                    DropdownMenuItem(
                      value: 'High',
                      child: Text('High'),
                    ),
                    DropdownMenuItem(
                      value: 'Normal',
                      child: Text('Normal'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _priority = value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Showing ${filtered.length} of '
            '${_applications.length} demo applications',
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(
                child: Text(
                  'No applications match your filters.',
                  style: TextStyle(color: _muted),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(_soft),
                columns: const [
                  DataColumn(label: Text('APPLICATION ID')),
                  DataColumn(label: Text('APPLICANT')),
                  DataColumn(label: Text('SUBMITTED')),
                  DataColumn(label: Text('TIER')),
                  DataColumn(label: Text('PRIORITY')),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('ACTION')),
                ],
                rows: [
                  for (final app in filtered)
                    DataRow(
                      cells: [
                        DataCell(Text(app.id)),
                        DataCell(Text(app.name)),
                        DataCell(Text(app.date)),
                        DataCell(Text(app.tier)),
                        DataCell(_chip(app.priority)),
                        DataCell(_chip(app.status)),
                        DataCell(
                          TextButton.icon(
                            
onPressed: () {
  context.go(
    '/lgu-admin/verification/review/${app.id}',
  );
},

                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 17,
                            ),
                            label: const Text('View'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    final isWarning =
        label == 'Pending' || label == 'High';

    final color = isWarning
        ? const Color(0xFF92650D)
        : _forest;

    final background = isWarning
        ? const Color(0xFFFFF4D9)
        : _soft;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  void _showApplication(_Application app) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Application Preview'),
        content: SizedBox(
          width: 410,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Fictional applicant information',
                style: TextStyle(
                  color: _green,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              _detail('Application ID', app.id),
              _detail('Applicant', app.name),
              _detail('Submitted', app.date),
              _detail('Current Tier', app.tier),
              _detail('Priority', app.priority),
              _detail('Status', app.status),
              const SizedBox(height: 12),
              const Text(
                'Identity document inspection and '
                'review actions will be added in '
                'the Identity Review module.',
                style: TextStyle(
                  color: _muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 112,
              child: Text(
                label,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );

  BoxDecoration _surface() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _stroke),
      );
}

class _Application {
  final String id;
  final String name;
  final String status;
  final String priority;
  final String date;
  final String tier;

  const _Application(
    this.id,
    this.name,
    this.status,
    this.priority,
    this.date,
    this.tier,
  );
}
