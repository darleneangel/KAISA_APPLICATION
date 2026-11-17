import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// KAISA / IT SUPERADMIN / SYSTEM HEALTH
// All service readings are static examples. No Supabase health API is queried.
const _deep = Color(0xFF0B3024);
const _forest = Color(0xFF124732);
const _green = Color(0xFF26805A);
const _paper = Color(0xFFF5F8F5);
const _ink = Color(0xFF173A2B);
const _muted = Color(0xFF6E8174);
const _line = Color(0xFFE3EBE4);
const _mint = Color(0xFFEAF5EE);
const _yellow = Color(0xFFFFCF4B);

enum _HealthStatus { operational, degraded, outage, unknown }

extension _StatusInfo on _HealthStatus {
  String get label => switch (this) {
    _HealthStatus.operational => 'Operational',
    _HealthStatus.degraded => 'Degraded',
    _HealthStatus.outage => 'Outage',
    _HealthStatus.unknown => 'Unknown',
  };
  String get definition => switch (this) {
    _HealthStatus.operational =>
      'The monitored service meets its defined health checks. This does not guarantee all functions are error-free.',
    _HealthStatus.degraded =>
      'The service may be available but is experiencing elevated errors, latency, or reduced capacity.',
    _HealthStatus.outage =>
      'A required service is unavailable or failing its defined availability checks.',
    _HealthStatus.unknown =>
      'No reliable or recent measurement is available. Unknown must never be interpreted as healthy.',
  };
  Color get color => switch (this) {
    _HealthStatus.operational => _green,
    _HealthStatus.degraded => const Color(0xFF987014),
    _HealthStatus.outage => const Color(0xFFC34A49),
    _HealthStatus.unknown => _muted,
  };
  Color get background => switch (this) {
    _HealthStatus.operational => _mint,
    _HealthStatus.degraded => const Color(0xFFFFF4D8),
    _HealthStatus.outage => const Color(0xFFFFEAEA),
    _HealthStatus.unknown => const Color(0xFFF0F3F0),
  };
}

class _Service {
  final String name;
  final String category;
  final String description;
  final String check;
  final IconData icon;
  final _HealthStatus status;
  const _Service(
    this.name,
    this.category,
    this.status,
    this.description,
    this.check,
    this.icon,
  );
}

class _Incident {
  final String id;
  final String service;
  final String title;
  final String impact;
  final DateTime createdAt;
  String state;
  String note;
  _Incident(
    this.id,
    this.service,
    this.title,
    this.impact,
    this.createdAt, {
    this.state = 'Open',
    this.note = '',
  });
}

class SystemHealthPage extends StatefulWidget {
  const SystemHealthPage({super.key});
  @override
  State<SystemHealthPage> createState() => _SystemHealthPageState();
}

class _SystemHealthPageState extends State<SystemHealthPage> {
  final _searchController = TextEditingController();
  String _query = '';
  String _filter = 'All';
  String _category = 'All';
  final List<_Incident> _incidents = [];
  final Set<int> _checklist = {};

  // Original sample statuses retained, with a more explicit monitoring definition.
  static const _services = <_Service>[
    _Service(
      'Supabase Database',
      'Database',
      _HealthStatus.operational,
      'Fictional database service reading.',
      'Monitor Postgres connections, CPU, memory, disk and slow queries.',
      Icons.storage_rounded,
    ),
    _Service(
      'Authentication Service',
      'Authentication',
      _HealthStatus.operational,
      'Fictional authentication service reading.',
      'Monitor sign-in errors, Auth API errors and service response time.',
      Icons.lock_outline_rounded,
    ),
    _Service(
      'Application API',
      'API',
      _HealthStatus.degraded,
      'Fictional example of slow API responses.',
      'Monitor API error rate, latency and critical endpoint availability.',
      Icons.api_rounded,
    ),
    _Service(
      'Notification Service',
      'Notifications',
      _HealthStatus.operational,
      'Fictional notification service reading.',
      'Monitor delivery failures and queue health for KAISA notifications.',
      Icons.notifications_active_outlined,
    ),
    _Service(
      'File Storage',
      'Storage',
      _HealthStatus.unknown,
      'No sample measurement provided.',
      'Monitor authorized file upload/download failures and storage usage.',
      Icons.folder_outlined,
    ),
  ];

  static const _tasks = <String>[
    'Define acceptable API latency and error-rate thresholds',
    'Configure trusted backend monitoring for Supabase and KAISA services',
    'Set up alerts for outages, repeated failures, and exhausted resources',
    'Assign an LGU IT incident-response contact and escalation route',
    'Document incident recovery and review alert thresholds regularly',
  ];

  List<_Service> get _visible => _services.where((s) {
    final q = _query.trim().toLowerCase();
    return (q.isEmpty ||
            '${s.name} ${s.category} ${s.description}'.toLowerCase().contains(
              q,
            )) &&
        (_filter == 'All' || s.status.label == _filter) &&
        (_category == 'All' || s.category == _category);
  }).toList();

  String _stamp(DateTime t) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '${months[t.month - 1]} ${t.day}, ${t.year} · $hour:${t.minute.toString().padLeft(2, '0')} ${t.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _csv(String text) {
    final safe = RegExp(r'^\s*[=+@\-]').hasMatch(text) ? "'$text" : text;
    return '"${safe.replaceAll('"', '""')}"';
  }

  Future<void> _copyCsv() async {
    final rows = [
      'Service,Category,Sample status,Description,Recommended check',
      for (final s in _visible)
        [
          s.name,
          s.category,
          s.status.label,
          s.description,
          s.check,
        ].map(_csv).join(','),
    ];
    await Clipboard.setData(ClipboardData(text: rows.join('\r\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filtered fictional service records copied as CSV.'),
      ),
    );
  }

  Future<void> _copyLink(String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Official Supabase link copied. Open it in your browser.',
        ),
      ),
    );
  }

  Future<void> _recordIncident({_Service? service}) async {
    final title = TextEditingController(
      text: service == null ? '' : 'Investigate ${service.name}',
    );
    final impact = TextEditingController();
    var selected = service?.name ?? _services.first.name;
    try {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, changeDialog) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Log a demo incident'),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Creates a local example incident. No actual alert or Supabase ticket is submitted.',
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      key: ValueKey(selected),
                      initialValue: selected,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Affected service',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final s in _services)
                          DropdownMenuItem(value: s.name, child: Text(s.name)),
                      ],
                      onChanged: (v) {
                        if (v != null) changeDialog(() => selected = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: title,
                      maxLength: 90,
                      decoration: const InputDecoration(
                        labelText: 'Incident title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: impact,
                      maxLines: 3,
                      maxLength: 300,
                      decoration: const InputDecoration(
                        labelText: 'Observed impact or evidence',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (title.text.trim().length < 5 ||
                      impact.text.trim().length < 5) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Provide a title and observed impact (at least 5 characters each).',
                        ),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('Log demo incident'),
              ),
            ],
          ),
        ),
      );
      if (!mounted || accepted != true) return;
      setState(
        () => _incidents.insert(
          0,
          _Incident(
            'INC-DEMO-${(_incidents.length + 1).toString().padLeft(3, '0')}',
            selected,
            title.text.trim(),
            impact.text.trim(),
            DateTime.now(),
          ),
        ),
      );
    } finally {
      title.dispose();
      impact.dispose();
    }
  }

  Future<void> _updateIncident(_Incident incident) async {
    final note = TextEditingController(text: incident.note);
    var next = incident.state;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, change) => AlertDialog(
            title: const Text('Update demo incident'),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${incident.id} · ${incident.title}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: ValueKey(next),
                    initialValue: next,
                    decoration: const InputDecoration(
                      labelText: 'Case state',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Open', child: Text('Open')),
                      DropdownMenuItem(
                        value: 'Investigating',
                        child: Text('Investigating'),
                      ),
                      DropdownMenuItem(
                        value: 'Resolved',
                        child: Text('Resolved'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) change(() => next = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: note,
                    maxLines: 3,
                    maxLength: 300,
                    decoration: const InputDecoration(
                      labelText: 'Investigation note (required)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (note.text.trim().length < 5) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Enter a meaningful investigation note.'),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('Save demo update'),
              ),
            ],
          ),
        ),
      );
      if (!mounted || confirmed != true) return;
      setState(() {
        incident.state = next;
        incident.note = note.text.trim();
      });
    } finally {
      note.dispose();
    }
  }

  void _details(_Service s) => showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(s.name),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _status(s.status),
            const SizedBox(height: 12),
            Text(s.status.definition, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            const Text(
              'What the IT team should monitor',
              style: TextStyle(fontWeight: FontWeight.bold, color: _forest),
            ),
            const SizedBox(height: 5),
            Text(s.check, style: const TextStyle(color: _muted)),
            const SizedBox(height: 16),
            const Text(
              'Data source',
              style: TextStyle(fontWeight: FontWeight.bold, color: _forest),
            ),
            const SizedBox(height: 5),
            const Text(
              'Static example only. This status is not queried from Supabase and does not indicate actual uptime.',
              style: TextStyle(color: _muted),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(ctx);
            _recordIncident(service: s);
          },
          icon: const Icon(Icons.add_alert_outlined),
          label: const Text('Log demo incident'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 690;
    final ok = _services
        .where((s) => s.status == _HealthStatus.operational)
        .length;
    final degraded = _services
        .where((s) => s.status == _HealthStatus.degraded)
        .length;
    final unknown = _services
        .where((s) => s.status == _HealthStatus.unknown)
        .length;
    return ColoredBox(
      color: _paper,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          compact ? 14 : 26,
          22,
          compact ? 14 : 26,
          44,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _hero(compact),
                  const SizedBox(height: 16),
                  _notice(),
                  const SizedBox(height: 22),
                  LayoutBuilder(
                    builder: (ctx, c) {
                      final cols = c.maxWidth >= 980
                          ? 4
                          : (c.maxWidth >= 520 ? 2 : 1);
                      const gap = 12.0;
                      final w = (c.maxWidth - (cols - 1) * gap) / cols;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          _stat(
                            'Services in preview',
                            '${_services.length}',
                            Icons.dns_outlined,
                            w,
                          ),
                          _stat(
                            'Sample operational',
                            '$ok',
                            Icons.check_circle_outline,
                            w,
                          ),
                          _stat(
                            'Sample degraded',
                            '$degraded',
                            Icons.warning_amber_outlined,
                            w,
                          ),
                          _stat(
                            'No measurement',
                            '$unknown',
                            Icons.help_outline_rounded,
                            w,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 19),
                  LayoutBuilder(
                    builder: (ctx, c) {
                      final wide = c.maxWidth >= 850;
                      return Wrap(
                        spacing: 15,
                        runSpacing: 15,
                        children: [
                          SizedBox(
                            width: wide ? (c.maxWidth - 15) * .54 : c.maxWidth,
                            child: _distribution(),
                          ),
                          SizedBox(
                            width: wide ? (c.maxWidth - 15) * .46 : c.maxWidth,
                            child: _quickGuide(),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _directory(),
                  const SizedBox(height: 20),
                  _incidentsPanel(),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (ctx, c) {
                      final wide = c.maxWidth >= 850;
                      return Wrap(
                        spacing: 15,
                        runSpacing: 15,
                        children: [
                          SizedBox(
                            width: wide ? (c.maxWidth - 15) / 2 : c.maxWidth,
                            child: _integration(),
                          ),
                          SizedBox(
                            width: wide ? (c.maxWidth - 15) / 2 : c.maxWidth,
                            child: _readiness(),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Preview only • No actual service telemetry, uptime calculations, alerts, or Supabase changes are performed on this screen.',
                    style: TextStyle(fontSize: 11, color: _muted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(bool compact) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(compact ? 22 : 30),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        colors: [_deep, _forest, Color(0xFF267650)],
      ),
    ),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 15,
      runSpacing: 15,
      children: [
        SizedBox(
          width: compact ? 270 : 530,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'KAISA  /  IT OPERATIONS',
                style: TextStyle(
                  fontSize: 11,
                  color: _yellow,
                  letterSpacing: 1.7,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 11),
              Text(
                'System Health Center',
                style: TextStyle(
                  fontSize: compact ? 27 : 33,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Oversee service availability, investigate performance concerns, and prepare incident response for the LGU.',
                style: TextStyle(
                  color: Color(0xFFE0EEE4),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .12),
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.monitor_heart_outlined, color: _yellow),
              SizedBox(width: 9),
              Text(
                'IT SUPERADMIN',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _notice() => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF6DB),
      borderRadius: BorderRadius.circular(13),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, color: Color(0xFF936A17)),
        SizedBox(width: 11),
        Expanded(
          child: Text(
            'DEVELOPMENT PREVIEW — Sample statuses are fictional and must not be used to assess KAISA or Supabase uptime. Live monitoring requires an authorized backend integration.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF735715),
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _stat(String title, String value, IconData icon, double width) =>
      Container(
        width: width,
        padding: const EdgeInsets.all(18),
        decoration: _surface(),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: _mint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 11, color: _muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _distribution() => _panel(
    'Sample service distribution',
    Icons.donut_large_outlined,
    [
      const Text(
        'Illustrative breakdown of five fictional service readings.',
        style: TextStyle(fontSize: 12, color: _muted),
      ),
      const SizedBox(height: 20),
      for (final status in _HealthStatus.values) ...[
        Row(
          children: [
            Expanded(child: _status(status)),
            Text(
              '${_services.where((s) => s.status == status).length} / ${_services.length}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: _ink),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 10,
            value:
                _services.where((s) => s.status == status).length /
                _services.length,
            backgroundColor: _mint,
            valueColor: AlwaysStoppedAnimation(status.color),
          ),
        ),
        const SizedBox(height: 14),
      ],
      const Text(
        'A status is only trustworthy when supported by an actual recent health check.',
        style: TextStyle(
          color: _muted,
          fontSize: 11,
          fontStyle: FontStyle.italic,
        ),
      ),
    ],
  );

  Widget _quickGuide() => _panel(
    'Status meanings & response',
    Icons.menu_book_outlined,
    [
      const Text(
        'Hover or long-press a status badge to read its definition.',
        style: TextStyle(fontSize: 12, color: _muted),
      ),
      const SizedBox(height: 15),
      for (final s in _HealthStatus.values)
        Padding(
          padding: const EdgeInsets.only(bottom: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _status(s),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s.definition,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _muted,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _mint,
          borderRadius: BorderRadius.circular(11),
        ),
        child: const Text(
          'Availability, latency, errors, and resource utilization are different measures. One green indicator never proves the entire application is healthy.',
          style: TextStyle(fontSize: 11, color: _forest),
        ),
      ),
    ],
  );

  Widget
  _directory() => _panel('Service monitoring directory', Icons.dns_outlined, [
    const Text(
      'Filter the example services, inspect recommended checks, and log a local investigation.',
      style: TextStyle(fontSize: 12, color: _muted),
    ),
    const SizedBox(height: 17),
    LayoutBuilder(
      builder: (ctx, c) => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          SizedBox(
            width: c.maxWidth >= 470 ? 280 : c.maxWidth,
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search service or category',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          _dropdown('Status', _filter, [
            'All',
            ..._HealthStatus.values.map((e) => e.label),
          ], (v) => setState(() => _filter = v)),
          _dropdown('Category', _category, [
            'All',
            ..._services.map((e) => e.category),
          ], (v) => setState(() => _category = v)),
          OutlinedButton.icon(
            onPressed: _copyCsv,
            icon: const Icon(Icons.copy_all_outlined, size: 17),
            label: const Text('Copy filtered CSV'),
          ),
          TextButton.icon(
            onPressed: () => setState(() {
              _query = '';
              _filter = 'All';
              _category = 'All';
              _searchController.clear();
            }),
            icon: const Icon(Icons.refresh, size: 17),
            label: const Text('Clear filters'),
          ),
        ],
      ),
    ),
    const SizedBox(height: 14),
    Text(
      'Showing ${_visible.length} of ${_services.length} demonstration services',
      style: const TextStyle(color: _muted, fontSize: 11),
    ),
    const SizedBox(height: 12),
    if (_visible.isEmpty)
      const Padding(
        padding: EdgeInsets.all(22),
        child: Text('No services match these filters.'),
      )
    else
      LayoutBuilder(
        builder: (ctx, c) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: c.maxWidth < 890 ? 890 : c.maxWidth,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(_mint),
              horizontalMargin: 10,
              columnSpacing: 16,
              columns: const [
                DataColumn(label: Text('SERVICE')),
                DataColumn(label: Text('CATEGORY')),
                DataColumn(label: Text('SAMPLE STATUS')),
                DataColumn(label: Text('MONITORING')),
                DataColumn(label: Text('ACTIONS')),
              ],
              rows: [
                for (final s in _visible)
                  DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 180,
                          child: Row(
                            children: [
                              Icon(s.icon, color: _green, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  s.name,
                                  style: const TextStyle(
                                    color: _ink,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(Text(s.category)),
                      DataCell(_status(s.status)),
                      DataCell(
                        SizedBox(
                          width: 260,
                          child: Text(
                            s.check,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _muted, fontSize: 11),
                          ),
                        ),
                      ),
                      DataCell(
                        TextButton(
                          onPressed: () => _details(s),
                          child: const Text('Details'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
  ]);

  Widget _incidentsPanel() => _panel(
    'Incident workbench · demo',
    Icons.report_problem_outlined,
    [
      const Text(
        'Create and triage local incident examples. These are not actual infrastructure alerts or persistent IT tickets.',
        style: TextStyle(fontSize: 12, color: _muted),
      ),
      const SizedBox(height: 13),
      Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.icon(
          onPressed: () => _recordIncident(),
          icon: const Icon(Icons.add),
          label: const Text('Log demo incident'),
        ),
      ),
      const SizedBox(height: 12),
      if (_incidents.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(23),
          decoration: BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'No local incidents recorded. Use “Log demo incident” to practice an IT investigation.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
        )
      else
        for (final i in _incidents)
          Container(
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _line),
            ),
            child: Row(
              children: [
                const Icon(Icons.assignment_late_outlined, color: _green),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${i.title} · ${i.state}',
                        style: const TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${i.id} · ${i.service} · ${_stamp(i.createdAt)}',
                        style: const TextStyle(color: _muted, fontSize: 11),
                      ),
                      Text(
                        i.impact,
                        style: const TextStyle(color: _muted, fontSize: 11),
                      ),
                      if (i.note.isNotEmpty)
                        Text(
                          'Note: ${i.note}',
                          style: const TextStyle(color: _muted, fontSize: 11),
                        ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _updateIncident(i),
                  child: const Text('Triage'),
                ),
              ],
            ),
          ),
    ],
  );

  Widget _integration() => _panel(
    'Supabase monitoring resources',
    Icons.query_stats_outlined,
    [
      const Text(
        'Supabase already provides observability. Your LGU IT team should use the official dashboard for detailed metrics and logs, and the platform status page for provider incidents.',
        style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
      ),
      const SizedBox(height: 13),
      _resource(
        'Supabase dashboard',
        'Project-specific reports, database CPU, Auth, Storage, and API logs',
        'https://supabase.com/dashboard',
      ),
      _resource(
        'Supabase status',
        'Provider-wide incidents; not proof of your project’s availability',
        'https://status.supabase.com',
      ),
      _resource(
        'Official observability guide',
        'Reports, logs, monitoring approaches, and metrics',
        'https://supabase.com/docs/guides/observability',
      ),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5D8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Production integration: use a trusted backend or monitoring collector. Never put Supabase service-role keys or monitoring secrets into Flutter.',
          style: TextStyle(fontSize: 11, color: Color(0xFF795D18)),
        ),
      ),
    ],
  );

  Widget _resource(String title, String description, String url) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Row(
      children: [
        const Icon(Icons.open_in_new, color: _green, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                description,
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Copy official link',
          onPressed: () => _copyLink(url),
          icon: const Icon(Icons.content_copy, size: 18, color: _green),
        ),
      ],
    ),
  );

  Widget _readiness() => _panel(
    'Monitoring readiness checklist',
    Icons.fact_check_outlined,
    [
      const Text(
        'Planning checklist only. Marking items complete does not configure monitoring.',
        style: TextStyle(color: _muted, fontSize: 12),
      ),
      const SizedBox(height: 13),
      ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: LinearProgressIndicator(
          value: _checklist.length / _tasks.length,
          minHeight: 9,
          color: _green,
          backgroundColor: _mint,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        '${_checklist.length} of ${_tasks.length} planning items selected',
        style: const TextStyle(fontSize: 11, color: _muted),
      ),
      for (var index = 0; index < _tasks.length; index++)
        CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          activeColor: _green,
          controlAffinity: ListTileControlAffinity.leading,
          value: _checklist.contains(index),
          title: Text(
            _tasks[index],
            style: const TextStyle(fontSize: 12, color: _ink),
          ),
          onChanged: (value) => setState(() {
            if (value == true) {
              _checklist.add(index);
            } else {
              _checklist.remove(index);
            }
          }),
        ),
      TextButton.icon(
        onPressed: () => setState(_checklist.clear),
        icon: const Icon(Icons.restart_alt, size: 17),
        label: const Text('Reset checklist'),
      ),
    ],
  );

  Widget _dropdown(
    String label,
    String value,
    List<String> choices,
    ValueChanged<String> onChanged,
  ) => SizedBox(
    width: 174,
    child: DropdownButtonFormField<String>(
      key: ValueKey('$label-$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: [
        for (final item in choices)
          DropdownMenuItem(
            value: item,
            child: Text(
              item,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    ),
  );

  Widget _status(_HealthStatus s) => Tooltip(
    message: '${s.label}: ${s.definition}',
    waitDuration: const Duration(milliseconds: 250),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: s.background,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, size: 12, color: s.color),
          const SizedBox(width: 5),
          Text(
            s.label,
            style: TextStyle(
              color: s.color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _panel(String title, IconData icon, List<Widget> content) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(19),
    decoration: _surface(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: _mint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _green, size: 21),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...content,
      ],
    ),
  );

  BoxDecoration _surface() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: _line),
    boxShadow: const [
      BoxShadow(color: Color(0x0B164E32), blurRadius: 20, offset: Offset(0, 6)),
    ],
  );
}
