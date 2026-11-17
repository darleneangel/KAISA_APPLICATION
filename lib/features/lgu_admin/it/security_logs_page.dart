import 'package:flutter/material.dart';

const _forest = Color(0xFF00492C);
const _green = Color(0xFF2A7F57);
const _paper = Color(0xFFF4F4F0);
const _ink = Color(0xFF0E3A27);
const _muted = Color(0xFF6E7773);
const _stroke = Color(0xFFECECE6);
const _soft = Color(0xFFE3F1E9);

class SecurityLogsPage extends StatefulWidget {
  const SecurityLogsPage({super.key});

  @override
  State<SecurityLogsPage> createState() => _SecurityLogsPageState();
}

class _SecurityLogsPageState extends State<SecurityLogsPage> {
  String _search = '';
  String _filter = 'All';

  // Fictional development data, not Supabase logs.
  static const _logs = <_SecurityEvent>[
    _SecurityEvent(
      'DEMO-LOG-001',
      'Successful login',
      'Demo Resident A',
      'Authentication',
      'Info',
      'Success',
      'Nov 16, 2026 · 09:42',
    ),
    _SecurityEvent(
      'DEMO-LOG-002',
      'Failed login attempt',
      'Demo Resident B',
      'Authentication',
      'Warning',
      'Denied',
      'Nov 16, 2026 · 09:18',
    ),
    _SecurityEvent(
      'DEMO-LOG-003',
      'Role change request',
      'Demo IT Administrator',
      'Authorization',
      'Info',
      'Pending',
      'Nov 16, 2026 · 08:54',
    ),
    _SecurityEvent(
      'DEMO-LOG-004',
      'Failed login attempt',
      'Demo Resident C',
      'Authentication',
      'Warning',
      'Denied',
      'Nov 15, 2026 · 17:21',
    ),
    _SecurityEvent(
      'DEMO-LOG-005',
      'Security review flagged',
      'Demo IT Administrator',
      'Security',
      'High',
      'For review',
      'Nov 15, 2026 · 14:05',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final query = _search.trim().toLowerCase();

    final results = _logs.where((log) {
      final matchesSearch =
          log.event.toLowerCase().contains(query) ||
          log.actor.toLowerCase().contains(query) ||
          log.id.toLowerCase().contains(query) ||
          log.category.toLowerCase().contains(query);

      final matchesSeverity = _filter == 'All' || log.severity == _filter;

      return matchesSearch && matchesSeverity;
    }).toList();

    final failedLogins = _logs
        .where((log) => log.event == 'Failed login attempt')
        .length;

    final highSeverity = _logs.where((log) => log.severity == 'High').length;

    return ColoredBox(
      color: _paper,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1260),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Security Logs',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: _ink,
                      fontSize: 29,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Review authentication activity, security '
                    'events, and permission-related activity.',
                    style: TextStyle(color: _muted, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  _previewNotice(),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 680 ? 3 : 1;
                      const gap = 12.0;
                      final width =
                          (constraints.maxWidth - gap * (columns - 1)) /
                          columns;

                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          _statCard(
                            'Demo security events',
                            '${_logs.length}',
                            Icons.receipt_long_outlined,
                            width,
                          ),
                          _statCard(
                            'Failed login attempts',
                            '$failedLogins',
                            Icons.lock_outline,
                            width,
                          ),
                          _statCard(
                            'High severity events',
                            '$highSeverity',
                            Icons.warning_amber_rounded,
                            width,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 25),
                  _logsPanel(results),
                  const SizedBox(height: 18),
                  const Text(
                    'Prototype only. Production security logs '
                    'must come from authorized server-side '
                    'logging services with appropriate access '
                    'controls and retention policies.',
                    style: TextStyle(color: _muted, fontSize: 11, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CF),
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF92650D)),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Development preview: these are fictional '
              'security events. No live authentication '
              'records are being accessed.',
              style: TextStyle(color: Color(0xFF73550E), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _soft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _forest, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: _forest,
            ),
          ),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(color: _muted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _logsPanel(List<_SecurityEvent> results) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Security Event Directory',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Search and filter fictional security records.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 19),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 315,
                child: TextField(
                  onChanged: (value) => setState(() => _search = value),
                  decoration: const InputDecoration(
                    hintText: 'Search event, actor, or ID',
                    prefixIcon: Icon(Icons.search_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: _stroke),
                    ),
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<String>(
                  initialValue: _filter,
                  decoration: const InputDecoration(
                    labelText: 'Severity',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: _stroke),
                    ),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(value: 'Info', child: Text('Info')),
                    DropdownMenuItem(value: 'Warning', child: Text('Warning')),
                    DropdownMenuItem(value: 'High', child: Text('High')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _filter = value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (results.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(
                child: Text(
                  'No matching demo security events.',
                  style: TextStyle(color: _muted),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(_soft),
                columns: const [
                  DataColumn(label: Text('EVENT ID')),
                  DataColumn(label: Text('EVENT')),
                  DataColumn(label: Text('ACTOR')),
                  DataColumn(label: Text('CATEGORY')),
                  DataColumn(label: Text('SEVERITY')),
                  DataColumn(label: Text('RESULT')),
                  DataColumn(label: Text('TIMESTAMP')),
                ],
                rows: [
                  for (final log in results)
                    DataRow(
                      cells: [
                        DataCell(Text(log.id)),
                        DataCell(SizedBox(width: 170, child: Text(log.event))),
                        DataCell(Text(log.actor)),
                        DataCell(Text(log.category)),
                        DataCell(_severityTag(log.severity)),
                        DataCell(Text(log.result)),
                        DataCell(Text(log.timestamp)),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _severityTag(String severity) {
    final Color color;
    final Color background;

    switch (severity) {
      case 'High':
        color = const Color(0xFF9B2C2C);
        background = const Color(0xFFFFE9E9);
        break;
      case 'Warning':
        color = const Color(0xFF92650D);
        background = const Color(0xFFFFF5DA);
        break;
      default:
        color = _forest;
        background = _soft;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        severity,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  BoxDecoration _surface() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _stroke),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A00492C),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ],
    );
  }
}

class _SecurityEvent {
  final String id;
  final String event;
  final String actor;
  final String category;
  final String severity;
  final String result;
  final String timestamp;

  const _SecurityEvent(
    this.id,
    this.event,
    this.actor,
    this.category,
    this.severity,
    this.result,
    this.timestamp,
  );
}
