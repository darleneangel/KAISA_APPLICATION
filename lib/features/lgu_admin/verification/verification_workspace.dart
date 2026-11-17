import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/repositories/verification_case_repository.dart';

const _forest = Color(0xFF00492C);
const _green = Color(0xFF287D55);
const _gold = Color(0xFFFBBA16);
const _paper = Color(0xFFF6F8F5);
const _mint = Color(0xFFEAF5EE);
const _ink = Color(0xFF173D2B);
const _muted = Color(0xFF687B70);
const _line = Color(0xFFE2EBE4);

/// Verification Superadmin prototype. Uses the SAME local repository as the
/// standalone Pending Applications, Identity Review and Review History pages.
/// No AI matching, private storage access, tier upgrades or notifications occur.
class VerificationWorkspace extends StatefulWidget {
  const VerificationWorkspace({
    super.key,
    this.initialSection = 0,
    this.caseId,
  });
  final int initialSection;
  final String? caseId;

  @override
  State<VerificationWorkspace> createState() => _VerificationWorkspaceState();
}

class _VerificationWorkspaceState extends State<VerificationWorkspace> {
  final VerificationCaseRepository _repo = VerificationCaseRepository.instance;
  final TextEditingController _search = TextEditingController();
  static const _sections = [
    'Overview',
    'Applications',
    'Identity Review',
    'Decision History',
    'Reports',
    'Renewals',
  ];
  late int _section;
  String? _selectedId;
  String _status = 'All';
  String _type = 'All';
  String _platform = 'All';
  String _priority = 'All';
  String _sort = 'Newest';
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _section = widget.initialSection.clamp(0, _sections.length - 1).toInt();
    _selectedId = widget.caseId;
    _repo.addListener(_update);
  }

  @override
  void didUpdateWidget(covariant VerificationWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSection != widget.initialSection ||
        oldWidget.caseId != widget.caseId) {
      _section = widget.initialSection.clamp(0, _sections.length - 1).toInt();
      _selectedId = widget.caseId;
    }
  }

  void _update() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _repo.removeListener(_update);
    _search.dispose();
    super.dispose();
  }

  String _date(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _dateTime(DateTime date) =>
      '${_date(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  List<VerificationApplication> get _filtered {
    final query = _search.text.trim().toLowerCase();
    final rows = _repo.applications.where((a) {
      return a.archived == _showArchived &&
          (_status == 'All' || a.status == _status) &&
          (_type == 'All' || a.type == _type) &&
          (_platform == 'All' || a.platform == _platform) &&
          (_priority == 'All' || a.priority == _priority) &&
          ('${a.id} ${a.name} ${a.purpose} ${a.type} ${a.platform}'
              .toLowerCase()
              .contains(query));
    }).toList();
    rows.sort((a, b) {
      if (_sort == 'High Priority') {
        final priority = (a.priority == 'High' ? 0 : 1).compareTo(
          b.priority == 'High' ? 0 : 1,
        );
        if (priority != 0) return priority;
      }
      return _sort == 'Oldest'
          ? a.submitted.compareTo(b.submitted)
          : b.submitted.compareTo(a.submitted);
    });
    return rows;
  }

  Widget _surface(
    Widget child, {
    EdgeInsets padding = const EdgeInsets.all(20),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0800492C),
            blurRadius: 22,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      color: color.withValues(alpha: .10),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
    ),
  );

  Color _statusColor(String status) => switch (status) {
    'Approved' => _green,
    'Rejected' => const Color(0xFFB42318),
    'Under Review' => const Color(0xFF2465A2),
    'Resubmission' => const Color(0xFF9B6710),
    _ => const Color(0xFF87620A),
  };

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _openReview(VerificationApplication app) {
    setState(() {
      _selectedId = app.id;
      _section = 2;
    });
  }

  Widget _metric(
    String title,
    int count,
    IconData icon, {
    String? explanation,
  }) {
    final child = _surface(
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _mint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _forest),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return Tooltip(message: explanation ?? title, child: child);
  }

  Widget _metrics() {
    final active = _repo.applications.where((a) => !a.archived).toList();
    final values = [
      (
        'Active applications',
        active.length,
        Icons.folder_open_outlined,
        'Non-archived applications',
      ),
      (
        'Needs action',
        active.where((a) => a.needsAction).length,
        Icons.pending_actions_outlined,
        'Pending, under review, or resubmission',
      ),
      (
        'Approved',
        active.where((a) => a.status == 'Approved').length,
        Icons.verified_user_outlined,
        'Approved demonstration applications',
      ),
      (
        'Archived',
        _repo.applications.where((a) => a.archived).length,
        Icons.archive_outlined,
        'Completed applications in the local archive',
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 540
            ? 2
            : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final value in values)
              SizedBox(
                width: width,
                child: _metric(
                  value.$1,
                  value.$2,
                  value.$3,
                  explanation: value.$4,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String> changed,
  ) {
    return SizedBox(
      width: 175,
      child: DropdownButtonFormField<String>(
        key: ValueKey('$label:$value'),
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: [
          for (final item in options)
            DropdownMenuItem(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (next) {
          if (next != null) setState(() => changed(next));
        },
      ),
    );
  }

  Widget _filters() => _surface(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Applications directory',
          style: TextStyle(
            fontSize: 18,
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Search, inspect and manage local demonstration records.',
          style: TextStyle(fontSize: 12, color: _muted),
        ),
        const SizedBox(height: 16),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              label: Text('Active'),
              icon: Icon(Icons.inbox_outlined),
            ),
            ButtonSegment(
              value: true,
              label: Text('Archived'),
              icon: Icon(Icons.archive_outlined),
            ),
          ],
          selected: {_showArchived},
          onSelectionChanged: (next) {
            setState(() => _showArchived = next.first);
          },
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 235,
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search applicant, ID, purpose',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            _dropdown('Request type', _type, const [
              'All',
              'Resident Tier 2',
              'Org Accreditation',
            ], (v) => _type = v),
            _dropdown('Status', _status, const [
              'All',
              'Pending',
              'Under Review',
              'Resubmission',
              'Approved',
              'Rejected',
            ], (v) => _status = v),
            _dropdown('Platform', _platform, const [
              'All',
              'Web',
              'Mobile',
            ], (v) => _platform = v),
            _dropdown('Priority', _priority, const [
              'All',
              'High',
              'Normal',
            ], (v) => _priority = v),
            _dropdown('Sort', _sort, const [
              'Newest',
              'Oldest',
              'High Priority',
            ], (v) => _sort = v),
            TextButton.icon(
              onPressed: () => setState(() {
                _search.clear();
                _type = 'All';
                _status = 'All';
                _platform = 'All';
                _priority = 'All';
                _sort = 'Newest';
              }),
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _directory() {
    final rows = _filtered;
    return _surface(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_showArchived ? 'Archived' : 'Active'} applications · ${rows.length}',
                  style: const TextStyle(
                    fontSize: 17,
                    color: _ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Copy filtered CSV',
                icon: const Icon(Icons.copy_all_outlined),
                onPressed: () {
                  final data = <List<String>>[
                    [
                      'ID',
                      'Applicant',
                      'Type',
                      'Platform',
                      'Submitted',
                      'Status',
                      'Priority',
                      'Archived',
                      'Archive Reason',
                    ],
                    for (final a in rows)
                      [
                        a.id,
                        a.name,
                        a.type,
                        a.platform,
                        _dateTime(a.submitted),
                        a.status,
                        a.priority,
                        a.archived ? 'Yes' : 'No',
                        a.archiveReason ?? '',
                      ],
                  ];
                  String quote(String text) {
                    final safe = text
                        .replaceAll('\r', ' ')
                        .replaceAll('\n', ' ');
                    final guarded = RegExp(r'^\s*[=+@\-]').hasMatch(safe)
                        ? "'$safe"
                        : safe;
                    return '"${guarded.replaceAll('"', '""')}"';
                  }

                  Clipboard.setData(
                    ClipboardData(
                      text: data
                          .map((r) => r.map(quote).join(','))
                          .join('\r\n'),
                    ),
                  );
                  _message('Filtered demo application CSV copied.');
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(
                child: Text('No applications match these filters.'),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 650) {
                  return Column(
                    children: [
                      for (final app in rows)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _caseTile(app),
                        ),
                    ],
                  );
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(_mint),
                    columns: const [
                      DataColumn(label: Text('APPLICANT / ID')),
                      DataColumn(label: Text('REQUEST')),
                      DataColumn(label: Text('PLATFORM')),
                      DataColumn(label: Text('SUBMITTED')),
                      DataColumn(label: Text('STATUS')),
                      DataColumn(label: Text('PRIORITY')),
                      DataColumn(label: Text('ACTION')),
                    ],
                    rows: [
                      for (final app in rows)
                        DataRow(
                          cells: [
                            DataCell(
                              Tooltip(
                                message: '${app.id}\n${app.purpose}',
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      app.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      app.id,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: _muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(Text(app.type)),
                            DataCell(Text(app.platform)),
                            DataCell(Text(_date(app.submitted))),
                            DataCell(
                              _pill(app.status, _statusColor(app.status)),
                            ),
                            DataCell(
                              _pill(
                                app.priority,
                                app.priority == 'High'
                                    ? const Color(0xFF9B6710)
                                    : _green,
                              ),
                            ),
                            DataCell(_rowActions(app)),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _caseTile(VerificationApplication app) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          app.name,
          style: const TextStyle(color: _ink, fontWeight: FontWeight.w800),
        ),
        Text(
          '${app.id} · ${app.type} · ${app.platform}',
          style: const TextStyle(fontSize: 12, color: _muted),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _pill(app.status, _statusColor(app.status)),
            _pill(
              app.priority,
              app.priority == 'High' ? const Color(0xFF9B6710) : _green,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _rowActions(app),
      ],
    ),
  );

  Widget _rowActions(VerificationApplication app) => Wrap(
    spacing: 4,
    children: [
      TextButton.icon(
        onPressed: () => _openReview(app),
        icon: const Icon(Icons.visibility_outlined, size: 18),
        label: const Text('Inspect'),
      ),
      if (!app.archived && !app.needsAction)
        IconButton(
          tooltip: 'Archive completed application',
          onPressed: () => _archiveDialog(app),
          icon: const Icon(Icons.archive_outlined),
        ),
      if (app.archived)
        IconButton(
          tooltip: 'Restore application',
          onPressed: () => _restoreDialog(app),
          icon: const Icon(Icons.unarchive_outlined),
        ),
    ],
  );

  Future<void> _archiveDialog(VerificationApplication app) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Archive ${app.id}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This hides a completed demo application from the active queue. It does not delete the record or its history.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLength: 400,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Archive reason (at least 10 characters)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().length < 10) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Provide at least 10 characters.'),
                  ),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    final reason = controller.text;
    // Dialog is closed before the controller is disposed.
    controller.dispose();
    if (!mounted || confirmed != true) return;
    _message(
      _repo.archive(app.id, reason)
          ? 'Application archived locally.'
          : 'Unable to archive this application.',
    );
  }

  Future<void> _restoreDialog(VerificationApplication app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Restore ${app.id}?'),
        content: const Text(
          'Return this demo application to the active directory? The audit event will remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    _message(
      _repo.restore(app.id)
          ? 'Application restored locally.'
          : 'Unable to restore this application.',
    );
  }

  Widget _overview() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _metrics(),
      const SizedBox(height: 16),
      _surface(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Verification workflow',
              style: TextStyle(
                fontSize: 18,
                color: _ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Submitted → Screening (future Python service) → Manual review when needed → Decision → Review history.',
              style: TextStyle(color: _muted),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => setState(() {
                    _section = 1;
                    _showArchived = false;
                  }),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Open applications'),
                ),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _section = 3),
                  icon: const Icon(Icons.history),
                  label: const Text('Review history'),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _filters(),
      const SizedBox(height: 12),
      _directory(),
    ],
  );

  Widget _field(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );

  Widget _review() {
    final app = _selectedId == null ? null : _repo.find(_selectedId!);
    if (app == null) {
      return _surface(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose an application to inspect',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text('Open a record from the Applications section.'),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => setState(() => _section = 1),
              child: const Text('Open applications'),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _section = 1),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to applications'),
        ),
        _surface(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    app.name,
                    style: const TextStyle(
                      fontSize: 22,
                      color: _ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  _pill(app.status, _statusColor(app.status)),
                  if (app.archived) _pill('Archived', _muted),
                ],
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, c) {
                  final details = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _field('Application ID', app.id),
                      _field('Request type', app.type),
                      _field('Platform', app.platform),
                      _field('Priority', app.priority),
                      _field('Submitted', _dateTime(app.submitted)),
                      _field('Purpose', app.purpose),
                      if (app.archived) ...[
                        _field('Archived at', _dateTime(app.archivedAt!)),
                        _field(
                          'Archive reason',
                          app.archiveReason ?? 'Not recorded',
                        ),
                      ],
                    ],
                  );
                  final evidence = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Evidence & AI screening',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _ink,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 13),
                      const Icon(
                        Icons.lock_outline_rounded,
                        color: _forest,
                        size: 37,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        app.type == 'Resident Tier 2'
                            ? 'Government ID and selfie verification'
                            : 'Organization accreditation document verification',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 9),
                      const Text(
                        'No private images are loaded. Python face matching, document checks, and signed Storage URLs are not connected in this prototype.',
                        style: TextStyle(color: _muted, height: 1.5),
                      ),
                      const SizedBox(height: 9),
                      const Text(
                        'Do not approve a real identity based on these mock records. Uncertain or failed automated checks must be reviewed by authorized personnel.',
                        style: TextStyle(color: _muted, fontSize: 12),
                      ),
                    ],
                  );
                  if (c.maxWidth < 700)
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [details, const Divider(height: 30), evidence],
                    );
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: details),
                      const SizedBox(width: 24),
                      Expanded(child: evidence),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              if (app.needsAction && !app.archived)
                FilledButton.icon(
                  onPressed: () => _decisionDialog(app),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Record demonstration decision'),
                )
              else
                const Text(
                  'This application is closed or archived; no additional decision can be made.',
                  style: TextStyle(color: _muted),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _decisionDialog(VerificationApplication app) async {
    final notes = TextEditingController();
    String decision = 'Resubmission';
    bool checked = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, refresh) => AlertDialog(
          title: Text('Review ${app.id}'),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PROTOTYPE ONLY — saves a local decision; no Tier 2 changes, document checks, accreditation or notifications.',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    key: ValueKey(decision),
                    initialValue: decision,
                    decoration: const InputDecoration(
                      labelText: 'Decision',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Approved',
                        child: Text('Approve'),
                      ),
                      DropdownMenuItem(
                        value: 'Rejected',
                        child: Text('Reject'),
                      ),
                      DropdownMenuItem(
                        value: 'Resubmission',
                        child: Text('Request resubmission'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) refresh(() => decision = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notes,
                    maxLength: 400,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Decision rationale (min. 10 characters)',
                      hintText: 'Describe findings, not private ID numbers',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (decision == 'Approved')
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: checked,
                      title: const Text(
                        'I confirm I completed the required manual evidence checks for this demonstration.',
                      ),
                      onChanged: (value) =>
                          refresh(() => checked = value ?? false),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (notes.text.trim().length < 10 ||
                    (decision == 'Approved' && !checked)) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Enter a reason of at least 10 characters and complete the approval confirmation.',
                      ),
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Save demo decision'),
            ),
          ],
        ),
      ),
    );
    final reason = notes.text;
    notes.dispose();
    if (!mounted || confirmed != true) return;
    final saved = _repo.recordDecision(app.id, decision, reason);
    if (saved) {
      setState(() {
        _section = 1;
        _showArchived = false;
        _status = 'All';
      });
      _message('Decision saved locally. Applications refreshed.');
    } else {
      _message('Unable to record decision; refresh the case and try again.');
    }
  }

  Widget _history() {
    final events = _repo.events;
    return _surface(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review and archive activity',
            style: TextStyle(
              fontSize: 18,
              color: _ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Events recorded in the current running prototype session. Existing sample decisions have no event records.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No new decisions or archive events recorded in this session.',
              ),
            )
          else
            for (final e in events)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: _mint,
                  child: Icon(
                    e.action == 'Archived'
                        ? Icons.archive_outlined
                        : e.action == 'Restored'
                        ? Icons.unarchive_outlined
                        : Icons.fact_check_outlined,
                    color: _forest,
                  ),
                ),
                title: Text(
                  '${e.caseId} · ${e.action}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('${_dateTime(e.at)}\n${e.reason}'),
                isThreeLine: true,
                trailing: TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedId = e.caseId;
                      _section = 2;
                    });
                  },
                  child: const Text('Inspect'),
                ),
              ),
        ],
      ),
    );
  }

  Widget _bar(String title, int value, int total, Color color) => Tooltip(
    message:
        '$title: $value of $total (${total == 0 ? 0 : (value * 100 / total).toStringAsFixed(1)}%)',
    child: Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text('$value'),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : value / total,
              minHeight: 10,
              color: color,
              backgroundColor: _mint,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _reports() {
    final all = _repo.applications;
    final total = all.length;
    final finished = all
        .where((a) => a.status == 'Approved' || a.status == 'Rejected')
        .toList();
    final approved = finished.where((a) => a.status == 'Approved').length;
    final web = all.where((a) => a.platform == 'Web').length;
    final mobile = all.where((a) => a.platform == 'Mobile').length;
    final residents = all.where((a) => a.type == 'Resident Tier 2').length;
    return Column(
      children: [
        _surface(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Application analytics',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Calculated from the same fictional records used in the queue.',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
              const SizedBox(height: 22),
              const Text(
                'Verification outcomes',
                style: TextStyle(fontWeight: FontWeight.w700, color: _ink),
              ),
              const SizedBox(height: 14),
              for (final status in const [
                'Pending',
                'Under Review',
                'Resubmission',
                'Approved',
                'Rejected',
              ])
                _bar(
                  status,
                  all.where((a) => a.status == status).length,
                  total,
                  _statusColor(status),
                ),
              const Divider(height: 28),
              const Text(
                'Submission platform',
                style: TextStyle(fontWeight: FontWeight.w700, color: _ink),
              ),
              const SizedBox(height: 14),
              _bar('Web', web, total, _forest),
              _bar('Mobile', mobile, total, _green),
              const Divider(height: 28),
              const Text(
                'Request category',
                style: TextStyle(fontWeight: FontWeight.w700, color: _ink),
              ),
              const SizedBox(height: 14),
              _bar('Resident Tier 2', residents, total, _forest),
              _bar(
                'Organization Accreditation',
                total - residents,
                total,
                _green,
              ),
              Text(
                'Finalized approval rate: ${finished.isEmpty ? 'N/A' : '${(approved * 100 / finished.length).toStringAsFixed(1)}%'}',
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _surface(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Copy reporting summary',
                style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
              ),
              const SizedBox(height: 8),
              const Text(
                'Aggregate fictional counts only — no uploaded ID images.',
                style: TextStyle(color: _muted),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  final csv =
                      'Metric,Count\r\nTotal,$total\r\nResident,$residents\r\nOrganization,${total - residents}\r\nWeb,$web\r\nMobile,$mobile\r\nFinalized,${finished.length}\r\nApproved,$approved\r\nArchived,${all.where((a) => a.archived).length}\r\n';
                  Clipboard.setData(ClipboardData(text: csv));
                  _message('Demonstration reporting summary copied.');
                },
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copy summary CSV'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _renewals() => _surface(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.event_repeat_outlined, size: 38, color: _forest),
        const SizedBox(height: 12),
        const Text(
          'Credential renewals — backend not configured',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        const SizedBox(height: 9),
        const Text(
          'The current VerificationApplication model does not store credential type, expiration dates or renewal status. No expiry dates or automated reminders are generated by this prototype.',
          style: TextStyle(color: _muted, height: 1.5),
        ),
        const SizedBox(height: 12),
        const Text(
          'Future implementation: authenticated credential records, expiry schedules, notification queue, renewal requests and policy-based evidence checks.',
          style: TextStyle(fontSize: 12, color: _muted),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final content = switch (_section) {
      0 => _overview(),
      1 => Column(
        children: [_filters(), const SizedBox(height: 12), _directory()],
      ),
      2 => _review(),
      3 => _history(),
      4 => _reports(),
      _ => _renewals(),
    };
    return ColoredBox(
      color: _paper,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: ListView(
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width < 650 ? 14 : 24,
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_forest, Color(0xFF0F6946)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.verified_user_outlined, color: _gold),
                        SizedBox(width: 8),
                        Text(
                          'KAISA  /  LGU VERIFICATION',
                          style: TextStyle(
                            color: _gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    Text(
                      _sections[_section],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Resident identity and organization accreditation oversight',
                      style: TextStyle(color: Color(0xFFE2F1E8)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),
              _surface(
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF956B0B)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'DEVELOPMENT PREVIEW · Fictional applications only. No AI identity matching, real document access, actual verification decisions or Supabase updates.',
                        style: TextStyle(fontSize: 12, color: _ink),
                      ),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < _sections.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_sections[i]),
                          selected: _section == i,
                          selectedColor: _mint,
                          labelStyle: TextStyle(
                            color: _section == i ? _forest : _muted,
                            fontWeight: FontWeight.w700,
                          ),
                          onSelected: (_) => setState(() => _section = i),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              content,
              const SizedBox(height: 22),
              const Text(
                'KAISA prototype workspace · Production identity decisions require protected storage, role-based authorization and immutable server-side audit logs.',
                style: TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
