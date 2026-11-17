import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// KAISA · IT SUPERADMIN · BACKUP & RECOVERY
// UI demonstration only. No Supabase backup APIs or production restore actions.
const _deep = Color(0xFF0A3025);
const _forest = Color(0xFF124632);
const _green = Color(0xFF26805A);
const _paper = Color(0xFFF5F8F5);
const _ink = Color(0xFF173A2B);
const _muted = Color(0xFF718276);
const _line = Color(0xFFE3ECE5);
const _mint = Color(0xFFE9F4ED);
const _yellow = Color(0xFFFFCC47);

enum _BackupState { completed, failed, verifying }

enum _BackupKind { database, storage }

extension _BackupStateDisplay on _BackupState {
  String get label => switch (this) {
    _BackupState.completed => 'Completed',
    _BackupState.failed => 'Failed',
    _BackupState.verifying => 'Verifying',
  };

  String get explanation => switch (this) {
    _BackupState.completed =>
      'The simulated backup job finished. Completion alone does not prove a successful restoration.',
    _BackupState.failed =>
      'The simulated backup job did not finish successfully. Investigate and verify recovery coverage.',
    _BackupState.verifying =>
      'The simulated job is awaiting integrity checks. Restore readiness is not confirmed.',
  };

  Color get foreground => switch (this) {
    _BackupState.completed => _green,
    _BackupState.failed => const Color(0xFF9E3A33),
    _BackupState.verifying => const Color(0xFF8B680D),
  };

  Color get background => switch (this) {
    _BackupState.completed => _mint,
    _BackupState.failed => const Color(0xFFFFEDEB),
    _BackupState.verifying => const Color(0xFFFFF5D9),
  };
}

extension _BackupKindDisplay on _BackupKind {
  String get label => switch (this) {
    _BackupKind.database => 'Database snapshot',
    _BackupKind.storage => 'Storage backup',
  };
}

class _DemoBackup {
  final String id;
  final _BackupKind type;
  final DateTime createdAt;
  final _BackupState status;
  final String scope;
  final String description;
  final String? failureHint;

  const _DemoBackup({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.status,
    required this.scope,
    required this.description,
    this.failureHint,
  });
}

class _RecoveryPlan {
  final String id;
  final String backupId;
  final String environment;
  final DateTime plannedAt;
  final String reason;
  final DateTime requestedAt;

  const _RecoveryPlan({
    required this.id,
    required this.backupId,
    required this.environment,
    required this.plannedAt,
    required this.reason,
    required this.requestedAt,
  });
}

class _FailureReview {
  final String backupId;
  final String disposition;
  final String note;
  final DateTime reviewedAt;
  const _FailureReview(
    this.backupId,
    this.disposition,
    this.note,
    this.reviewedAt,
  );
}

class BackupRecoveryPage extends StatefulWidget {
  const BackupRecoveryPage({super.key});

  @override
  State<BackupRecoveryPage> createState() => _BackupRecoveryPageState();
}

class _BackupRecoveryPageState extends State<BackupRecoveryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  String _filter = 'All';
  String _typeFilter = 'All';
  final Set<int> _checkedItems = {};
  final List<_RecoveryPlan> _plans = [];
  final List<_FailureReview> _reviews = [];

  // Original four fictional records retained, with extra descriptive metadata.
  static final List<_DemoBackup> _backups = [
    _DemoBackup(
      id: 'DEMO-BK-001',
      type: _BackupKind.database,
      createdAt: DateTime(2026, 11, 16, 2),
      status: _BackupState.completed,
      scope: 'Illustrative application database',
      description:
          'Example scheduled database backup. No underlying file is available.',
    ),
    _DemoBackup(
      id: 'DEMO-BK-002',
      type: _BackupKind.database,
      createdAt: DateTime(2026, 11, 15, 2),
      status: _BackupState.completed,
      scope: 'Illustrative application database',
      description:
          'Example completed database snapshot for interface demonstration.',
    ),
    _DemoBackup(
      id: 'DEMO-BK-003',
      type: _BackupKind.storage,
      createdAt: DateTime(2026, 11, 14, 2),
      status: _BackupState.failed,
      scope: 'Illustrative storage objects',
      description:
          'Example failed job used to demonstrate an investigation workflow.',
      failureHint:
          'Sample failure: storage export interrupted. Not a real incident.',
    ),
    _DemoBackup(
      id: 'DEMO-BK-004',
      type: _BackupKind.database,
      createdAt: DateTime(2026, 11, 13, 2),
      status: _BackupState.completed,
      scope: 'Illustrative application database',
      description:
          'Example completed database backup. Restoration has not been tested.',
    ),
  ];

  static const _recoveryItems = [
    'Document the authorized recovery procedure',
    'Verify the backup retention policy',
    'Identify responsible recovery personnel',
    'Plan a recovery test in a non-production environment',
    'Record approval before any production restoration',
  ];

  // Checklist items are planning prompts, not independent verified controls.
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
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    return '${months[date.month - 1]} ${date.day}, ${date.year} · $hour:$minute ${date.hour >= 12 ? 'PM' : 'AM'}';
  }

  List<_DemoBackup> get _visible {
    final query = _search.toLowerCase().trim();
    final rows = _backups.where((backup) {
      final matchesText =
          query.isEmpty ||
          '${backup.id} ${backup.type.label} ${backup.scope} ${backup.status.label}'
              .toLowerCase()
              .contains(query);
      final matchesStatus = _filter == 'All' || backup.status.label == _filter;
      final matchesType =
          _typeFilter == 'All' || backup.type.label == _typeFilter;
      return matchesText && matchesStatus && matchesType;
    }).toList();
    rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return rows;
  }

  String _csvCell(String value) {
    // Quote for CSV and prefix potential spreadsheet-formula strings.
    final safe = RegExp(r'^\s*[=+@\-]').hasMatch(value) ? "'$value" : value;
    return '"${safe.replaceAll('"', '""')}"';
  }

  Future<void> _copyCsv() async {
    final lines = [
      'Backup ID,Type,Created at,Status,Scope,Description',
      for (final b in _visible)
        [
          b.id,
          b.type.label,
          _stamp(b.createdAt),
          b.status.label,
          b.scope,
          b.description,
        ].map(_csvCell).join(','),
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\r\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filtered fictional backup records copied as CSV.'),
      ),
    );
  }

  void _viewBackup(_DemoBackup backup) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Backup record details'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detail('Backup ID', backup.id),
                _detail('Type', backup.type.label),
                _detail('Created', _stamp(backup.createdAt)),
                _detail('Status', backup.status.label),
                _detail('Scope', backup.scope),
                const Divider(height: 28),
                Text(backup.description),
                if (backup.failureHint != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    backup.failureHint!,
                    style: const TextStyle(color: Color(0xFF9E3A33)),
                  ),
                ],
                const SizedBox(height: 14),
                const Text(
                  'No actual backup artifact, checksum, restore point, or storage path is available in this prototype.',
                  style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          if (backup.status == _BackupState.failed)
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _reviewFailure(backup);
              },
              child: const Text('Review failure'),
            ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _reviewFailure(_DemoBackup backup) async {
    final controller = TextEditingController();
    String disposition = 'Needs investigation';
    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Document failure review'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: SizedBox(
              width: 470,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${backup.id} · ${backup.type.label}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Select a triage disposition. This records a local review only; it does not restart the backup job.',
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                    const SizedBox(height: 17),
                    DropdownButtonFormField<String>(
                      initialValue: disposition,
                      decoration: const InputDecoration(
                        labelText: 'Review disposition',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Needs investigation',
                          child: Text('Needs investigation'),
                        ),
                        DropdownMenuItem(
                          value: 'Escalate to infrastructure team',
                          child: Text('Escalate to infrastructure team'),
                        ),
                        DropdownMenuItem(
                          value: 'Retest in staging',
                          child: Text('Retest in staging'),
                        ),
                        DropdownMenuItem(
                          value: 'Awaiting vendor support',
                          child: Text('Awaiting vendor support'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null)
                          setDialogState(() => disposition = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: controller,
                      maxLines: 3,
                      maxLength: 400,
                      decoration: const InputDecoration(
                        labelText: 'Investigation note (required)',
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
                  if (controller.text.trim().length < 8) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Enter at least 8 characters of investigation notes.',
                        ),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('Save demo review'),
              ),
            ],
          ),
        ),
      );
      if (!mounted || saved != true) return;
      setState(
        () => _reviews.insert(
          0,
          _FailureReview(
            backup.id,
            disposition,
            controller.text.trim(),
            DateTime.now(),
          ),
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _planRecoveryTest() async {
    String selectedId = _backups
        .firstWhere((b) => b.status == _BackupState.completed)
        .id;
    String environment = 'Staging (isolated)';
    DateTime scheduledAt = DateTime.now().add(const Duration(days: 1));
    final note = TextEditingController();
    try {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Plan a recovery test'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: SizedBox(
              width: 490,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Planning only. This will not execute a restoration or create a real test job.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Example completed backup',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final b in _backups.where(
                          (b) => b.status == _BackupState.completed,
                        ))
                          DropdownMenuItem(
                            value: b.id,
                            child: Text(
                              '${b.id} · ${b.type.label}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null)
                          setDialogState(() => selectedId = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: environment,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Safe test environment',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Staging (isolated)',
                          child: Text('Staging (isolated)'),
                        ),
                        DropdownMenuItem(
                          value: 'Dedicated test sandbox',
                          child: Text('Dedicated test sandbox'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null)
                          setDialogState(() => environment = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: dialogContext,
                          initialDate: scheduledAt,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date == null || !dialogContext.mounted) return;
                        final time = await showTimePicker(
                          context: dialogContext,
                          initialTime: TimeOfDay.fromDateTime(scheduledAt),
                        );
                        if (time == null || !dialogContext.mounted) return;
                        setDialogState(
                          () => scheduledAt = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          ),
                        );
                      },
                      icon: const Icon(Icons.event_outlined),
                      label: Text('Test time: ${_stamp(scheduledAt)}'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: note,
                      maxLines: 3,
                      maxLength: 400,
                      decoration: const InputDecoration(
                        labelText: 'Purpose / test scope (required)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const Text(
                      'Production restores require separate written approval and a server-side execution workflow.',
                      style: TextStyle(color: _muted, fontSize: 11),
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
                  if (note.text.trim().length < 8 ||
                      !scheduledAt.isAfter(DateTime.now())) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Enter a valid future time and a purpose of at least 8 characters.',
                        ),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('Save demo plan'),
              ),
            ],
          ),
        ),
      );
      if (!mounted || accepted != true) return;
      setState(
        () => _plans.insert(
          0,
          _RecoveryPlan(
            id: 'PLAN-DEMO-${(_plans.length + 1).toString().padLeft(3, '0')}',
            backupId: selectedId,
            environment: environment,
            plannedAt: scheduledAt,
            reason: note.text.trim(),
            requestedAt: DateTime.now(),
          ),
        ),
      );
    } finally {
      note.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _visible;
    final completed = _backups
        .where((b) => b.status == _BackupState.completed)
        .length;
    final failed = _backups
        .where((b) => b.status == _BackupState.failed)
        .length;
    return ColoredBox(
      color: _paper,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 650;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              compact ? 14 : 26,
              22,
              compact ? 14 : 26,
              44,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1340),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _hero(compact),
                      const SizedBox(height: 17),
                      _notice(),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, c) {
                          final cols = c.maxWidth >= 900
                              ? 4
                              : (c.maxWidth >= 500 ? 2 : 1);
                          const gap = 12.0;
                          final width = (c.maxWidth - (cols - 1) * gap) / cols;
                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              _metric(
                                'Demo backup jobs',
                                '${_backups.length}',
                                'Illustrative history',
                                Icons.cloud_outlined,
                                width,
                              ),
                              _metric(
                                'Completed jobs',
                                '$completed',
                                'Restore not independently tested',
                                Icons.check_circle_outline,
                                width,
                              ),
                              _metric(
                                'Failed jobs',
                                '$failed',
                                'Require investigation',
                                Icons.warning_amber_rounded,
                                width,
                              ),
                              _metric(
                                'Recovery plans',
                                '${_plans.length}',
                                'Local drafts only',
                                Icons.event_note_outlined,
                                width,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 22),
                      LayoutBuilder(
                        builder: (context, c) {
                          final wide = c.maxWidth >= 860;
                          return Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              SizedBox(
                                width: wide
                                    ? (c.maxWidth - 16) * .56
                                    : c.maxWidth,
                                child: _performancePanel(),
                              ),
                              SizedBox(
                                width: wide
                                    ? (c.maxWidth - 16) * .44
                                    : c.maxWidth,
                                child: _continuityPanel(),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 22),
                      _historyPanel(filtered),
                      const SizedBox(height: 22),
                      LayoutBuilder(
                        builder: (context, c) {
                          final wide = c.maxWidth >= 860;
                          return Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              SizedBox(
                                width: wide
                                    ? (c.maxWidth - 16) / 2
                                    : c.maxWidth,
                                child: _checklistPanel(),
                              ),
                              SizedBox(
                                width: wide
                                    ? (c.maxWidth - 16) / 2
                                    : c.maxWidth,
                                child: _recoveryPanel(),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 22),
                      _triagePanel(),
                      const SizedBox(height: 18),
                      const Text(
                        'UI DEMO ONLY · No actual Supabase backups are accessed, verified, created, downloaded, restored, or deleted. Local plans and investigation notes are not durable audit records.',
                        style: TextStyle(
                          fontSize: 11,
                          color: _muted,
                          height: 1.5,
                        ),
                      ),
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
      borderRadius: BorderRadius.circular(26),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_deep, _forest, Color(0xFF257754)],
      ),
    ),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(
          width: compact ? 280 : 550,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'KAISA  /  IT INFRASTRUCTURE',
                style: TextStyle(
                  color: _yellow,
                  fontSize: 10,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 13),
              Text(
                'Backup & Recovery Center',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 27 : 33,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Inspect backup history, prepare recovery tests, and document continuity planning without putting production data at risk.',
                style: TextStyle(
                  color: Color(0xFFDEEBE2),
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: _planRecoveryTest,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color.fromARGB(255, 0, 0, 0),
            side: const BorderSide(color: Color(0x88FFFFFF)),
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 17),
          ),
          icon: const Icon(Icons.event_available_outlined),
          label: const Text('Plan recovery test'),
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
            'DEVELOPMENT PREVIEW — These records are fictional, and the charts show sample outcomes only. No production backup, restore, or disaster-recovery service is connected.',
            style: TextStyle(
              color: Color(0xFF765B1D),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _metric(
    String title,
    String value,
    String note,
    IconData icon,
    double width,
  ) => Container(
    width: width,
    padding: const EdgeInsets.all(19),
    decoration: _surface(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _mint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _green, size: 23),
        ),
        const SizedBox(height: 15),
        Text(
          value,
          style: const TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w900,
            color: _ink,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            color: _ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(note, style: const TextStyle(fontSize: 11, color: _muted)),
      ],
    ),
  );

  Widget _performancePanel() {
    final completed = _backups
        .where((b) => b.status == _BackupState.completed)
        .length;
    final failed = _backups
        .where((b) => b.status == _BackupState.failed)
        .length;
    final completionRate = completed / _backups.length;
    return _panel('Sample backup job outcomes', Icons.donut_large_rounded, [
      const Text(
        'Chart calculated from the four fictional backup records.',
        style: TextStyle(fontSize: 12, color: _muted),
      ),
      const SizedBox(height: 22),
      Row(
        children: [
          SizedBox(
            width: 132,
            height: 132,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: completionRate,
                    strokeWidth: 15,
                    backgroundColor: const Color(0xFFFFDCD8),
                    color: _green,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(completionRate * 100).round()}%',
                      style: const TextStyle(
                        color: _forest,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'completed',
                      style: TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _legend(_green, 'Completed', '$completed jobs'),
                const SizedBox(height: 14),
                _legend(const Color(0xFFBC544D), 'Failed', '$failed jobs'),
                const SizedBox(height: 15),
                const Text(
                  'Completion is not the same as a successful recovery test.',
                  style: TextStyle(color: _muted, fontSize: 11, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: _mint,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.fact_check_outlined, color: _forest, size: 19),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Restore verification: NOT CONNECTED · Artifact integrity: NOT VERIFIED',
                style: TextStyle(
                  color: _forest,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _legend(Color color, String label, String count) => Row(
    children: [
      Container(
        height: 10,
        width: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(
            color: _ink,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      Text(count, style: const TextStyle(color: _muted, fontSize: 11)),
    ],
  );

  Widget _continuityPanel() => _panel(
    'Recovery objectives explained',
    Icons.info_outline_rounded,
    [
      const Text(
        'These targets must be agreed with the LGU and verified through real recovery testing.',
        style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
      ),
      const SizedBox(height: 19),
      _concept(
        'RPO',
        'Recovery Point Objective',
        'Maximum acceptable data loss measured in time. Example: a 1-hour RPO means up to one hour of data may need recovery.',
      ),
      const Divider(height: 25),
      _concept(
        'RTO',
        'Recovery Time Objective',
        'Target time to restore an essential service after a disruption.',
      ),
      const Divider(height: 25),
      _concept(
        'Retention',
        'Backup retention policy',
        'How long copies are kept and when they may be securely removed.',
      ),
      const SizedBox(height: 15),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6D8),
          borderRadius: BorderRadius.circular(11),
        ),
        child: const Text(
          'KAISA RPO, RTO and retention targets: NOT CONFIGURED. These are explanations, not approved commitments.',
          style: TextStyle(fontSize: 11, color: Color(0xFF765B1D), height: 1.4),
        ),
      ),
    ],
  );

  Widget _concept(String short, String title, String description) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 63,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _mint,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          short,
          style: const TextStyle(
            color: _forest,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: _ink,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              description,
              style: const TextStyle(color: _muted, fontSize: 11, height: 1.5),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _historyPanel(List<_DemoBackup> filtered) =>
      _panel('Backup job directory', Icons.history_rounded, [
        const Text(
          'Review sample backup history and investigate failed jobs.',
          style: TextStyle(color: _muted, fontSize: 12),
        ),
        const SizedBox(height: 17),
        LayoutBuilder(
          builder: (context, c) => Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: c.maxWidth > 450 ? 275 : c.maxWidth,
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _search = value),
                  decoration: _input(
                    'Search backup ID, type...',
                    Icons.search_rounded,
                  ),
                ),
              ),
              _filterField('Status', _filter, const [
                'All',
                'Completed',
                'Failed',
                'Verifying',
              ], (v) => setState(() => _filter = v)),
              _filterField('Type', _typeFilter, const [
                'All',
                'Database snapshot',
                'Storage backup',
              ], (v) => setState(() => _typeFilter = v)),
              OutlinedButton.icon(
                onPressed: _copyCsv,
                icon: const Icon(Icons.content_copy_rounded, size: 17),
                label: const Text('Copy CSV'),
              ),
              TextButton.icon(
                onPressed: () => setState(() {
                  _searchController.clear();
                  _search = '';
                  _filter = 'All';
                  _typeFilter = 'All';
                }),
                icon: const Icon(Icons.refresh, size: 17),
                label: const Text('Reset'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Showing ${filtered.length} of ${_backups.length} fictional records',
          style: const TextStyle(fontSize: 11, color: _muted),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.all(22),
            child: Center(
              child: Text('No sample backup records match these filters.'),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, c) {
              final width = c.maxWidth < 930 ? 930.0 : c.maxWidth;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: width,
                  child: DataTable(
                    columnSpacing: 14,
                    horizontalMargin: 12,
                    headingRowColor: WidgetStateProperty.all(_mint),
                    columns: const [
                      DataColumn(label: Text('BACKUP ID')),
                      DataColumn(label: Text('TYPE')),
                      DataColumn(label: Text('CREATED (LOCAL)')),
                      DataColumn(label: Text('STATUS')),
                      DataColumn(label: Text('ACTION')),
                    ],
                    rows: [
                      for (final backup in filtered)
                        DataRow(
                          cells: [
                            DataCell(
                              Text(
                                backup.id,
                                style: const TextStyle(
                                  color: _ink,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            DataCell(Text(backup.type.label)),
                            DataCell(Text(_stamp(backup.createdAt))),
                            DataCell(_statusBadge(backup.status)),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () => _viewBackup(backup),
                                    child: const Text('Details'),
                                  ),
                                  if (backup.status == _BackupState.failed)
                                    TextButton(
                                      onPressed: () => _reviewFailure(backup),
                                      child: const Text('Triage'),
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

  Widget _statusBadge(_BackupState state) => Tooltip(
    message: state.explanation,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: state.background,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, size: 13, color: state.foreground),
          const SizedBox(width: 6),
          Text(
            state.label,
            style: TextStyle(
              color: state.foreground,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _filterField(
    String label,
    String value,
    List<String> values,
    ValueChanged<String> changed,
  ) => SizedBox(
    width: 170,
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
        for (final item in values)
          DropdownMenuItem(
            value: item,
            child: Text(item, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (next) {
        if (next != null) changed(next);
      },
    ),
  );

  InputDecoration _input(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon),
    isDense: true,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );

  Widget _checklistPanel() => _panel(
    'Recovery readiness checklist',
    Icons.fact_check_outlined,
    [
      const Text(
        'Planning checklist only. Ticking a box does not verify an actual control.',
        style: TextStyle(color: _muted, fontSize: 12),
      ),
      const SizedBox(height: 15),
      LinearProgressIndicator(
        value: _checkedItems.length / _recoveryItems.length,
        minHeight: 8,
        color: _green,
        backgroundColor: _mint,
        borderRadius: BorderRadius.circular(8),
      ),
      const SizedBox(height: 9),
      Text(
        '${_checkedItems.length} of ${_recoveryItems.length} example planning steps checked',
        style: const TextStyle(fontSize: 11, color: _muted),
      ),
      const SizedBox(height: 8),
      for (var i = 0; i < _recoveryItems.length; i++)
        CheckboxListTile(
          value: _checkedItems.contains(i),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: _green,
          title: Text(
            _recoveryItems[i],
            style: const TextStyle(color: _ink, fontSize: 12),
          ),
          onChanged: (value) => setState(() {
            if (value == true) {
              _checkedItems.add(i);
            } else {
              _checkedItems.remove(i);
            }
          }),
        ),
      TextButton.icon(
        onPressed: () => setState(_checkedItems.clear),
        icon: const Icon(Icons.restart_alt_outlined, size: 18),
        label: const Text('Reset checklist'),
      ),
    ],
  );

  Widget
  _recoveryPanel() => _panel('Recovery test planning', Icons.event_note_outlined, [
    const Text(
      'A real restore should be tested in an isolated environment and approved before production execution.',
      style: TextStyle(fontSize: 12, color: _muted, height: 1.5),
    ),
    const SizedBox(height: 15),
    FilledButton.icon(
      onPressed: _planRecoveryTest,
      style: FilledButton.styleFrom(backgroundColor: _forest),
      icon: const Icon(Icons.add_task_rounded, size: 18),
      label: const Text('Create demo test plan'),
    ),
    const SizedBox(height: 17),
    if (_plans.isEmpty)
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'No recovery test plans drafted. A plan here does not schedule an actual backup service.',
          style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
        ),
      )
    else
      for (final plan in _plans.take(6))
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: _paper,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.pending_actions_rounded,
                      color: _green,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${plan.id} · ${plan.backupId}',
                        style: const TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  '${plan.environment} · ${_stamp(plan.plannedAt)}',
                  style: const TextStyle(fontSize: 11, color: _muted),
                ),
                const SizedBox(height: 5),
                Text(
                  plan.reason,
                  style: const TextStyle(color: _ink, fontSize: 11),
                ),
                const SizedBox(height: 5),
                Text(
                  'Draft only · Created ${_stamp(plan.requestedAt)} · Not approved or executed',
                  style: const TextStyle(
                    color: Color(0xFF8B680D),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
  ]);

  Widget _triagePanel() => _panel(
    'Backup failure investigation',
    Icons.support_agent_rounded,
    [
      const Text(
        'Use these notes to plan responses to the fictional failed backup. Real jobs and incidents are unchanged.',
        style: TextStyle(color: _muted, fontSize: 12),
      ),
      const SizedBox(height: 14),
      if (_reviews.isEmpty)
        const Text(
          'No local failure investigations recorded yet. Choose Triage in the backup directory.',
          style: TextStyle(color: _muted, fontSize: 12),
        )
      else
        for (final review in _reviews.take(6))
          Padding(
            padding: const EdgeInsets.only(bottom: 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.assignment_turned_in_outlined,
                  color: _green,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${review.backupId} · ${review.disposition}',
                        style: const TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        review.note,
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _stamp(review.reviewedAt),
                        style: const TextStyle(color: _muted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    ],
  );

  Widget _panel(String title, IconData icon, List<Widget> content) => Container(
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
            const SizedBox(width: 11),
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
        const SizedBox(height: 16),
        ...content,
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
