import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// KAISA · IT SUPERADMIN · SECURITY EVENT CENTER
// Everything on this screen is fictional and stored locally. No database calls.
const _deep = Color(0xFF0A2F24);
const _forest = Color(0xFF124632);
const _green = Color(0xFF26805A);
const _paper = Color(0xFFF5F8F5);
const _ink = Color(0xFF173A2B);
const _muted = Color(0xFF718276);
const _line = Color(0xFFE3ECE5);
const _mint = Color(0xFFE9F4ED);
const _yellow = Color(0xFFFFCC47);

enum _Severity { critical, high, medium, low, info }

enum _CaseState { newEvent, investigating, resolved, falsePositive }

enum _EventType { authentication, account, access, configuration, monitoring }

extension _SeverityInfo on _Severity {
  String get label => switch (this) {
    _Severity.critical => 'Critical',
    _Severity.high => 'High',
    _Severity.medium => 'Medium',
    _Severity.low => 'Low',
    _Severity.info => 'Info',
  };

  String get explanation => switch (this) {
    _Severity.critical =>
      'Potentially severe or active compromise requiring immediate incident response. This does NOT, by itself, confirm a breach.',
    _Severity.high =>
      'Significant security risk that needs prompt investigation, such as suspected unauthorized access. High does NOT automatically mean data was breached.',
    _Severity.medium =>
      'Suspicious or policy-relevant activity that needs timely review; impact is not yet established.',
    _Severity.low =>
      'Minor anomaly or low-impact event that should be checked as part of routine monitoring.',
    _Severity.info =>
      'Normal, informational security or audit activity. No threat is implied without additional evidence.',
  };

  Color get foreground => switch (this) {
    _Severity.critical => const Color(0xFF921D37),
    _Severity.high => const Color(0xFFA34224),
    _Severity.medium => const Color(0xFF8D680B),
    _Severity.low => const Color(0xFF176C79),
    _Severity.info => _green,
  };

  Color get background => switch (this) {
    _Severity.critical => const Color(0xFFFDE7EC),
    _Severity.high => const Color(0xFFFFEDE4),
    _Severity.medium => const Color(0xFFFFF5D9),
    _Severity.low => const Color(0xFFE4F4F6),
    _Severity.info => _mint,
  };
}

extension _StateInfo on _CaseState {
  String get label => switch (this) {
    _CaseState.newEvent => 'New',
    _CaseState.investigating => 'Investigating',
    _CaseState.resolved => 'Resolved',
    _CaseState.falsePositive => 'False positive',
  };
}

extension _TypeInfo on _EventType {
  String get label => switch (this) {
    _EventType.authentication => 'Authentication',
    _EventType.account => 'Account management',
    _EventType.access => 'Access control',
    _EventType.configuration => 'Configuration',
    _EventType.monitoring => 'Monitoring',
  };
}

class _SecurityEvent {
  final String id;
  final String title;
  final String actor;
  final String source;
  final String description;
  final DateTime timestamp;
  final _Severity severity;
  final _EventType type;
  _CaseState state;
  String? triageNote;
  DateTime? reviewedAt;

  _SecurityEvent({
    required this.id,
    required this.title,
    required this.actor,
    required this.source,
    required this.description,
    required this.timestamp,
    required this.severity,
    required this.type,
    this.state = _CaseState.newEvent,
    this.triageNote,
    this.reviewedAt,
  });
}

class _TriageEntry {
  final String id;
  final _CaseState state;
  final String reason;
  final DateTime time;
  _TriageEntry(this.id, this.state, this.reason, this.time);
}

class SecurityLogsPage extends StatefulWidget {
  const SecurityLogsPage({super.key});

  @override
  State<SecurityLogsPage> createState() => _SecurityLogsPageState();
}

class _SecurityLogsPageState extends State<SecurityLogsPage> {
  final _searchController = TextEditingController();
  late final List<_SecurityEvent> _events;
  final List<_TriageEntry> _triage = [];
  String _query = '';
  String _severityFilter = 'All';
  String _stateFilter = 'All';
  String _typeFilter = 'All';
  String _periodFilter = 'All time';
  bool _showOnlyOpen = false;

  @override
  void initState() {
    super.initState();
    // Fixed sample dates: never presented as live or current incidents.
    _events = [
      _SecurityEvent(
        id: 'SEC-DEMO-101',
        title: 'Unusual sign-in pattern',
        actor: 'demo.user01',
        source: 'Authentication',
        description:
            'Multiple fictional sign-in attempts from unfamiliar client fingerprints. Requires investigation; no compromise is confirmed.',
        timestamp: DateTime(2026, 11, 17, 9, 42),
        severity: _Severity.high,
        type: _EventType.authentication,
      ),
      _SecurityEvent(
        id: 'SEC-DEMO-102',
        title: 'Privileged role change requested',
        actor: 'demo.it.admin',
        source: 'Role governance',
        description:
            'Simulated request to change a privileged access assignment. No real role was changed.',
        timestamp: DateTime(2026, 11, 17, 9, 5),
        severity: _Severity.medium,
        type: _EventType.access,
        state: _CaseState.investigating,
      ),
      _SecurityEvent(
        id: 'SEC-DEMO-103',
        title: 'Potential token misuse detected',
        actor: 'demo.integration',
        source: 'API monitor',
        description:
            'Fictional indicator of repeated requests with an invalid token. This is not a confirmed account or data breach.',
        timestamp: DateTime(2026, 11, 16, 17, 16),
        severity: _Severity.critical,
        type: _EventType.monitoring,
      ),
      _SecurityEvent(
        id: 'SEC-DEMO-104',
        title: 'Account suspension reviewed',
        actor: 'demo.it.admin',
        source: 'Account management',
        description:
            'A fictional account status change was checked against an illustrative policy.',
        timestamp: DateTime(2026, 11, 16, 14, 30),
        severity: _Severity.low,
        type: _EventType.account,
        state: _CaseState.resolved,
        triageNote: 'Sample administrative review completed.',
        reviewedAt: DateTime(2026, 11, 16, 15, 10),
      ),
      _SecurityEvent(
        id: 'SEC-DEMO-105',
        title: 'Configuration review completed',
        actor: 'demo.it.admin',
        source: 'System settings',
        description:
            'Routine configuration review recorded for demonstration purposes.',
        timestamp: DateTime(2026, 11, 15, 11, 8),
        severity: _Severity.info,
        type: _EventType.configuration,
        state: _CaseState.resolved,
        triageNote: 'No issue in simulated review.',
        reviewedAt: DateTime(2026, 11, 15, 11, 20),
      ),
      _SecurityEvent(
        id: 'SEC-DEMO-106',
        title: 'Repeated verification attempts',
        actor: 'demo.user02',
        source: 'Authentication',
        description:
            'Illustrative pattern of repeated failed verification steps; investigate before concluding malicious intent.',
        timestamp: DateTime(2026, 11, 14, 8, 18),
        severity: _Severity.medium,
        type: _EventType.authentication,
      ),
      _SecurityEvent(
        id: 'SEC-DEMO-107',
        title: 'Access denial recorded',
        actor: 'demo.user03',
        source: 'Access control',
        description:
            'A protected function rejected a fictional unauthorized request.',
        timestamp: DateTime(2026, 11, 13, 16, 25),
        severity: _Severity.low,
        type: _EventType.access,
        state: _CaseState.falsePositive,
        triageNote: 'Expected denial in sample scenario.',
        reviewedAt: DateTime(2026, 11, 13, 16, 40),
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _stamp(DateTime date) {
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
    final h = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final mins = date.minute.toString().padLeft(2, '0');
    return '${months[date.month - 1]} ${date.day}, ${date.year} · $h:$mins ${date.hour >= 12 ? 'PM' : 'AM'}';
  }

  List<_SecurityEvent> get _filtered {
    final result = _events.where((e) {
      final q = _query.trim().toLowerCase();
      final haystack =
          '${e.id} ${e.title} ${e.actor} ${e.source} ${e.description}'
              .toLowerCase();
      if (q.isNotEmpty && !haystack.contains(q)) return false;
      if (_severityFilter != 'All' && e.severity.label != _severityFilter)
        return false;
      if (_stateFilter != 'All' && e.state.label != _stateFilter) return false;
      if (_typeFilter != 'All' && e.type.label != _typeFilter) return false;
      if (_showOnlyOpen &&
          (e.state == _CaseState.resolved ||
              e.state == _CaseState.falsePositive))
        return false;
      if (_periodFilter == 'Nov 17, 2026' &&
          !(e.timestamp.year == 2026 &&
              e.timestamp.month == 11 &&
              e.timestamp.day == 17))
        return false;
      if (_periodFilter == 'Nov 16, 2026' &&
          !(e.timestamp.year == 2026 &&
              e.timestamp.month == 11 &&
              e.timestamp.day == 16))
        return false;
      return true;
    }).toList();
    result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return result;
  }

  Future<void> _triageEvent(_SecurityEvent event, _CaseState next) async {
    final ctrl = TextEditingController();
    try {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text('Mark as ${next.label}'),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${event.id} · ${event.title}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                const Text(
                  'This updates the local demo triage status only. It does not alter real logs, accounts, or backend incidents.',
                  style: TextStyle(fontSize: 12, color: _muted),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: ctrl,
                  maxLines: 3,
                  maxLength: 300,
                  decoration: const InputDecoration(
                    labelText: 'Triage justification (required)',
                    hintText: 'Document the basis for this decision',
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
                if (ctrl.text.trim().length < 5) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Enter at least five characters of justification.',
                      ),
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Confirm demo action'),
            ),
          ],
        ),
      );
      if (!mounted || accepted != true) return;
      setState(() {
        event.state = next;
        event.triageNote = ctrl.text.trim();
        event.reviewedAt = DateTime.now();
        _triage.insert(
          0,
          _TriageEntry(event.id, next, event.triageNote!, event.reviewedAt!),
        );
      });
    } finally {
      ctrl.dispose();
    }
  }

  void _showDetails(_SecurityEvent event) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Security event details'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailLine('Event ID', event.id),
                _detailLine('Event', event.title),
                _detailLine('Occurred', _stamp(event.timestamp)),
                _detailLine('Severity', event.severity.label),
                _detailLine('Case state', event.state.label),
                _detailLine('Type', event.type.label),
                _detailLine('Actor (fictional)', event.actor),
                _detailLine('Source', event.source),
                const Divider(height: 24),
                const Text(
                  'Event description',
                  style: TextStyle(fontWeight: FontWeight.bold, color: _ink),
                ),
                const SizedBox(height: 6),
                Text(event.description),
                const SizedBox(height: 16),
                const Text(
                  'Severity interpretation',
                  style: TextStyle(fontWeight: FontWeight.bold, color: _ink),
                ),
                const SizedBox(height: 6),
                Text(event.severity.explanation),
                if (event.triageNote != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Latest triage note',
                    style: TextStyle(fontWeight: FontWeight.bold, color: _ink),
                  ),
                  Text(event.triageNote!),
                  if (event.reviewedAt != null)
                    Text(
                      _stamp(event.reviewedAt!),
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailLine(String name, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            name,
            style: const TextStyle(fontSize: 12, color: _muted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: _ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  String _csvCell(String value) {
    // Guard spreadsheet imports against formula execution.
    final safe = RegExp(r'^[\s]*[=+@\-]').hasMatch(value) ? "'$value" : value;
    return '"${safe.replaceAll('"', '""')}"';
  }

  Future<void> _copyCsv() async {
    final lines = [
      'Event ID,Date and time,Event,Type,Severity,State,Actor,Source,Description,Triage note',
      for (final e in _filtered)
        [
          e.id,
          _stamp(e.timestamp),
          e.title,
          e.type.label,
          e.severity.label,
          e.state.label,
          e.actor,
          e.source,
          e.description,
          e.triageNote ?? '',
        ].map(_csvCell).join(','),
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\r\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Filtered demo events copied as CSV. Paste into a .csv file or spreadsheet.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _filtered;
    final open = _events
        .where(
          (e) =>
              e.state == _CaseState.newEvent ||
              e.state == _CaseState.investigating,
        )
        .length;
    final urgent = _events
        .where(
          (e) =>
              (e.severity == _Severity.critical ||
                  e.severity == _Severity.high) &&
              (e.state == _CaseState.newEvent ||
                  e.state == _CaseState.investigating),
        )
        .length;
    final resolved = _events
        .where((e) => e.state == _CaseState.resolved)
        .length;
    return ColoredBox(
      color: _paper,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              compact ? 14 : 26,
              22,
              compact ? 14 : 26,
              40,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1320),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _hero(compact),
                      const SizedBox(height: 17),
                      _notice(),
                      const SizedBox(height: 23),
                      LayoutBuilder(
                        builder: (context, c) {
                          final cols = c.maxWidth > 900
                              ? 4
                              : (c.maxWidth >= 520 ? 2 : 1);
                          const gap = 12.0;
                          final w = (c.maxWidth - (cols - 1) * gap) / cols;
                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              _stat(
                                'Demo events',
                                '${_events.length}',
                                Icons.receipt_long_outlined,
                                w,
                              ),
                              _stat(
                                'Open cases',
                                '$open',
                                Icons.track_changes_outlined,
                                w,
                              ),
                              _stat(
                                'High / critical open',
                                '$urgent',
                                Icons.priority_high_rounded,
                                w,
                              ),
                              _stat(
                                'Resolved cases',
                                '$resolved',
                                Icons.verified_outlined,
                                w,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, c) {
                          final wide = c.maxWidth >= 820;
                          return Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              SizedBox(
                                width: wide
                                    ? (c.maxWidth - 16) * .55
                                    : c.maxWidth,
                                child: _severityPanel(),
                              ),
                              SizedBox(
                                width: wide
                                    ? (c.maxWidth - 16) * .45
                                    : c.maxWidth,
                                child: _playbookPanel(),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _eventDirectory(visible),
                      const SizedBox(height: 20),
                      _activityPanel(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _hero(bool compact) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(compact ? 23 : 30),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(25),
      gradient: const LinearGradient(
        colors: [_deep, _forest, Color(0xFF247953)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 18,
      spacing: 18,
      children: [
        SizedBox(
          width: compact ? 280 : 510,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'KAISA  /  SECURITY OPERATIONS',
                style: TextStyle(
                  color: _yellow,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 13),
              Text(
                'Security Event Center',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 27 : 33,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Investigate suspicious activity, document findings, and review administrative security events in one workspace.',
                style: TextStyle(
                  color: Color(0xFFDAE9DF),
                  height: 1.55,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_outlined, color: _yellow),
              SizedBox(width: 8),
              Text(
                'IT SUPERADMIN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _notice() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF6D8),
      borderRadius: BorderRadius.circular(13),
    ),
    child: const Row(
      children: [
        Icon(Icons.info_outline, color: Color(0xFF966D12)),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'DEVELOPMENT PREVIEW — All security events are fictional. Triage actions are stored only on this screen. No live Supabase security logs are accessed or modified.',
            style: TextStyle(
              color: Color(0xFF765B1D),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _stat(String title, String value, IconData icon, double width) =>
      Container(
        width: width,
        padding: const EdgeInsets.all(19),
        decoration: _surface(),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _mint,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: _green),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 25,
                      color: _ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
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

  Widget _severityPanel() => _panel(
    'Severity guide & distribution',
    Icons.donut_large_rounded,
    [
      const Text(
        'Hover over or tap any severity to read its meaning.',
        style: TextStyle(fontSize: 12, color: _muted),
      ),
      const SizedBox(height: 16),
      for (final s in _Severity.values) ...[
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  _severityBadge(s),
                  const SizedBox(width: 9),
                  Text(
                    '${_events.where((e) => e.severity == s).length} demo events',
                    style: const TextStyle(fontSize: 11, color: _muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${((_events.where((e) => e.severity == s).length / _events.length) * 100).round()}%',
              style: const TextStyle(
                fontSize: 12,
                color: _ink,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value:
                _events.where((e) => e.severity == s).length / _events.length,
            minHeight: 8,
            color: s.foreground,
            backgroundColor: _mint,
          ),
        ),
        const SizedBox(height: 13),
      ],
      const Text(
        'Severity measures urgency and potential impact—not proof of a data breach.',
        style: TextStyle(
          fontSize: 11,
          color: _muted,
          fontStyle: FontStyle.italic,
        ),
      ),
    ],
  );

  Widget _playbookPanel() => _panel(
    'Incident-response playbook',
    Icons.menu_book_outlined,
    [
      const Text(
        'Suggested IT response sequence',
        style: TextStyle(fontSize: 12, color: _muted),
      ),
      const SizedBox(height: 14),
      _playbookStep(
        '01',
        'Detect & validate',
        'Review evidence and rule out false positives.',
      ),
      _playbookStep(
        '02',
        'Assess impact',
        'Classify severity; identify affected systems.',
      ),
      _playbookStep(
        '03',
        'Contain safely',
        'Escalate through approved procedures.',
      ),
      _playbookStep(
        '04',
        'Resolve & document',
        'Record justification and follow-up.',
      ),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _mint,
          borderRadius: BorderRadius.circular(11),
        ),
        child: const Row(
          children: [
            Icon(Icons.lock_outline, color: _forest, size: 19),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'No automatic account blocking or incident mitigation is performed here.',
                style: TextStyle(color: _forest, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _playbookStep(String number, String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _mint,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: _forest,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: _muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _severityBadge(_Severity s) => Tooltip(
    message: '${s.label} severity\n\n${s.explanation}',
    preferBelow: false,
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
          Icon(Icons.info_outline, size: 12, color: s.foreground),
          const SizedBox(width: 5),
          Text(
            s.label,
            style: TextStyle(
              color: s.foreground,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _stateBadge(_CaseState state) {
    final color = switch (state) {
      _CaseState.newEvent => const Color(0xFF9B4C1C),
      _CaseState.investigating => const Color(0xFF946500),
      _CaseState.resolved => _green,
      _CaseState.falsePositive => _muted,
    };
    return Text(
      state.label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
    );
  }

  Widget _eventDirectory(
    List<_SecurityEvent> visible,
  ) => _panel('Security event directory', Icons.list_alt_outlined, [
    const Text(
      'Search fictional events, review details, or document a local triage decision.',
      style: TextStyle(fontSize: 12, color: _muted),
    ),
    const SizedBox(height: 18),
    LayoutBuilder(
      builder: (context, c) => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          SizedBox(
            width: c.maxWidth >= 500 ? 280 : c.maxWidth,
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: _input(
                'Search event, ID, actor...',
                Icons.search_rounded,
              ),
            ),
          ),
          _filter('Severity', _severityFilter, [
            'All',
            ..._Severity.values.map((e) => e.label),
          ], (s) => setState(() => _severityFilter = s)),
          _filter('State', _stateFilter, [
            'All',
            ..._CaseState.values.map((e) => e.label),
          ], (s) => setState(() => _stateFilter = s)),
          _filter('Type', _typeFilter, [
            'All',
            ..._EventType.values.map((e) => e.label),
          ], (s) => setState(() => _typeFilter = s)),
          _filter('Sample date', _periodFilter, const [
            'All time',
            'Nov 17, 2026',
            'Nov 16, 2026',
          ], (s) => setState(() => _periodFilter = s)),
        ],
      ),
    ),
    const SizedBox(height: 6),
    Wrap(
      spacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 8,
      children: [
        FilterChip(
          label: const Text('Open cases only'),
          selected: _showOnlyOpen,
          onSelected: (v) => setState(() => _showOnlyOpen = v),
        ),
        TextButton.icon(
          onPressed: () => setState(() {
            _query = '';
            _searchController.clear();
            _severityFilter = 'All';
            _stateFilter = 'All';
            _typeFilter = 'All';
            _periodFilter = 'All time';
            _showOnlyOpen = false;
          }),
          icon: const Icon(Icons.refresh, size: 17),
          label: const Text('Reset filters'),
        ),
        OutlinedButton.icon(
          onPressed: _copyCsv,
          icon: const Icon(Icons.file_copy_outlined, size: 17),
          label: const Text('Copy filtered CSV'),
        ),
      ],
    ),
    const SizedBox(height: 8),
    Text(
      'Showing ${visible.length} of ${_events.length} demo events  ·  newest first',
      style: const TextStyle(fontSize: 11, color: _muted),
    ),
    const SizedBox(height: 13),
    if (visible.isEmpty)
      const Padding(
        padding: EdgeInsets.all(28),
        child: Center(
          child: Text(
            'No events match your filters.',
            style: TextStyle(color: _muted),
          ),
        ),
      )
    else
      LayoutBuilder(
        builder: (context, c) {
          // Stretch the table through the full card; scroll only when the viewport is narrow.
          final width = c.maxWidth < 1060 ? 1060.0 : c.maxWidth;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              child: DataTable(
                columnSpacing: 15,
                horizontalMargin: 12,
                headingRowColor: WidgetStateProperty.all(_mint),
                columns: const [
                  DataColumn(label: Text('EVENT / ID')),
                  DataColumn(label: Text('OCCURRED')),
                  DataColumn(label: Text('TYPE')),
                  DataColumn(label: Text('SEVERITY')),
                  DataColumn(label: Text('STATE')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: [
                  for (final event in visible)
                    DataRow(
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 235,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _ink,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  event.id,
                                  style: const TextStyle(
                                    color: _muted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            _stamp(event.timestamp),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        DataCell(
                          Text(
                            event.type.label,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        DataCell(_severityBadge(event.severity)),
                        DataCell(_stateBadge(event.state)),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () => _showDetails(event),
                                child: const Text('Details'),
                              ),
                              PopupMenuButton<_CaseState>(
                                tooltip: 'Triage actions',
                                icon: const Icon(Icons.more_horiz_rounded),
                                onSelected: (next) => _triageEvent(event, next),
                                itemBuilder: (_) => [
                                  for (final state in _CaseState.values)
                                    if (state != event.state)
                                      PopupMenuItem(
                                        value: state,
                                        child: Text(
                                          'Mark ${state.label.toLowerCase()}',
                                        ),
                                      ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
  ]);

  Widget _filter(
    String label,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) => SizedBox(
    width: 175,
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
        for (final option in options)
          DropdownMenuItem(
            value: option,
            child: Text(
              option,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
      ],
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    ),
  );

  InputDecoration _input(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon),
    isDense: true,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );

  Widget
  _activityPanel() => _panel('Local triage activity', Icons.history_rounded, [
    const Text(
      'This audit-like list tracks only your decisions in the current demo session. It is NOT an independent, tamper-resistant audit log.',
      style: TextStyle(fontSize: 12, color: _muted, height: 1.5),
    ),
    const SizedBox(height: 13),
    if (_triage.isEmpty)
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(21),
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'No demo triage actions yet. Select an event’s ••• menu to document an investigation.',
          style: TextStyle(color: _muted, fontSize: 12),
        ),
      )
    else
      for (final entry in _triage.take(8))
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.task_alt, color: _green, size: 19),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.id} → ${entry.state.label}',
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      entry.reason,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                    Text(
                      _stamp(entry.time),
                      style: const TextStyle(color: _muted, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
  ]);

  Widget _panel(String title, IconData icon, List<Widget> children) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
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
                  child: Icon(icon, color: _green, size: 20),
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
            ...children,
          ],
        ),
      );

  BoxDecoration _surface() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: _line),
    boxShadow: const [
      BoxShadow(color: Color(0x0B164E32), blurRadius: 22, offset: Offset(0, 7)),
    ],
  );
}
