import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/repositories/verification_case_repository.dart';

// KAISA / LGU Verification — applications queue PROTOTYPE.
// Fictional records only. No database reads, document access, credential
// decisions, role changes, approval, or security-sensitive mutations.
const _forest = Color(0xFF00492C);
const _deep = Color(0xFF0D3325);
const _green = Color(0xFF267C55);
const _gold = Color(0xFFFBBA16);
const _paper = Color(0xFFF6F8F5);
const _ink = Color(0xFF173D2B);
const _muted = Color(0xFF6B7D71);
const _stroke = Color(0xFFE1EAE4);
const _mint = Color(0xFFEAF5EE);
const _amber = Color(0xFFA66B08);
const _blue = Color(0xFF3678A3);
const _red = Color(0xFFAE4B43);

class PendingApplicationsPage extends StatefulWidget {
  const PendingApplicationsPage({super.key});

  @override
  State<PendingApplicationsPage> createState() =>
      _PendingApplicationsPageState();
}

class _PendingApplicationsPageState extends State<PendingApplicationsPage> {
  final TextEditingController _search = TextEditingController();
  String _type = 'All';
  String _status = 'Needs Action';
  String _priority = 'All';
  String _platform = 'All';
  String _sort = 'Newest first';
  int _visibleCount = 6;

  final VerificationCaseRepository _repo = VerificationCaseRepository.instance;
  List<VerificationApplication> get _applications => _repo.applications;
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _repo.removeListener(_refresh);
    _search.dispose();
    super.dispose();
  }

  List<VerificationApplication> get _filtered {
    final term = _search.text.trim().toLowerCase();
    final result = _applications.where((app) {
      final matchesText =
          term.isEmpty ||
          '${app.id} ${app.name} ${app.purpose} ${app.type} ${app.platform}'
              .toLowerCase()
              .contains(term);
      return (app.archived == _showArchived) &&
          matchesText &&
          (_status == 'All' ||
              (_status == 'Needs Action'
                  ? app.needsAction
                  : app.status == _status)) &&
          (_priority == 'All' || app.priority == _priority) &&
          (_type == 'All' || app.type == _type) &&
          (_platform == 'All' || app.platform == _platform);
    }).toList();
    result.sort((a, b) {
      if (_sort == 'High priority') {
        final priorityOrder = (b.priority == 'High' ? 1 : 0).compareTo(
          a.priority == 'High' ? 1 : 0,
        );
        if (priorityOrder != 0) return priorityOrder;
      }
      return _sort == 'Oldest first'
          ? a.submitted.compareTo(b.submitted)
          : b.submitted.compareTo(a.submitted);
    });
    return result;
  }

  void _changeFilters(VoidCallback changes) {
    setState(() {
      changes();
      _visibleCount = 6;
    });
  }

  void _clearFilters() => _changeFilters(() {
    _search.clear();
    _status = _showArchived ? 'All' : 'Needs Action';
    _priority = 'All';
    _type = 'All';
    _platform = 'All';
    _sort = 'Newest first';
  });

  String _date(DateTime dt) => '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';
  String _dateTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '${_date(dt)} · $hour:$minute $period';
  }

  static const _months = [
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

  Color _colorFor(String label) => switch (label) {
    'High' || 'Pending' || 'Resubmission' => _amber,
    'Rejected' => _red,
    'Under Review' => _blue,
    _ => _forest,
  };

  Widget _pill(String label, {bool compact = false}) {
    final color = _colorFor(label);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 11,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: compact ? 11 : 12,
        ),
      ),
    );
  }

  Widget _surface(
    Widget child, {
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
  }) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _stroke),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0900492C),
          blurRadius: 20,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );

  Widget _heading(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 18,
          color: _ink,
        ),
      ),
      const SizedBox(height: 4),
      Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
    ],
  );

  Widget _banner(bool mobile) => Container(
    padding: EdgeInsets.all(mobile ? 21 : 30),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [_deep, _forest, Color(0xFF288259)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(23),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.verified_user_outlined, color: _gold, size: 19),
            SizedBox(width: 9),
            Flexible(
              child: Text(
                'KAISA / LGU VERIFICATION',
                style: TextStyle(
                  color: _gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Verification Applications',
          style: TextStyle(
            color: Colors.white,
            fontSize: mobile ? 26 : 33,
            fontWeight: FontWeight.w900,
            letterSpacing: -.4,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Prioritize resident Tier 2 and organization accreditation '
          'requests in one review queue.',
          style: TextStyle(color: Color(0xFFE1EFE6), height: 1.5, fontSize: 13),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _forest,
              ),
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
              label: const Text('Reset filters'),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                side: const BorderSide(color: Colors.white54),
              ),
              onPressed: () => _copyCsv(_filtered),
              icon: const Icon(Icons.content_copy_rounded, size: 18),
              label: const Text('Copy CSV'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _metric(
    String label,
    String number,
    String detail,
    IconData icon,
    double width,
  ) => Tooltip(
    message: '$label: $number\n$detail\nPrototype records only.',
    child: SizedBox(
      width: width,
      child: _surface(
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _mint,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: _forest, size: 23),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    number,
                    style: const TextStyle(
                      color: _forest,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    detail,
                    style: const TextStyle(color: _muted, fontSize: 10),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        padding: const EdgeInsets.all(17),
      ),
    ),
  );

  Widget _metrics() {
    final active = _applications.where((x) => !x.archived).toList();
    final needsAction = active.where((x) => x.needsAction).length;
    final pending = active.where((x) => x.status == 'Pending').length;
    final high = active
        .where((x) => x.needsAction && x.priority == 'High')
        .length;
    return LayoutBuilder(
      builder: (context, c) {
        final n = c.maxWidth >= 1120
            ? 5
            : c.maxWidth >= 620
            ? 2
            : 1;
        const gap = 12.0;
        final width = (c.maxWidth - (n - 1) * gap) / n;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            _metric(
              'Active applications',
              '${active.length}',
              'Resident and organization requests',
              Icons.description_outlined,
              width,
            ),
            _metric(
              'Needs action',
              '$needsAction',
              'Pending, in review, or awaiting resubmission',
              Icons.pending_actions_rounded,
              width,
            ),
            _metric(
              'Pending',
              '$pending',
              'Not yet under active review',
              Icons.hourglass_empty,
              width,
            ),
            _metric(
              'High priority',
              '$high',
              'High-priority records requiring action',
              Icons.priority_high_rounded,
              width,
            ),
            _metric(
              'Archived',
              '${_applications.where((x) => x.archived).length}',
              'Completed records stored outside the active queue',
              Icons.archive_outlined,
              width,
            ),
          ],
        );
      },
    );
  }

  Widget _distribution() {
    final active = _applications.where((x) => !x.archived).toList();
    final statuses = [
      'Pending',
      'Under Review',
      'Resubmission',
      'Approved',
      'Rejected',
    ];
    return _surface(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(
            'Queue breakdown',
            'Application status distribution · demo data',
          ),
          const SizedBox(height: 18),
          for (final status in statuses) ...[
            Builder(
              builder: (context) {
                final count = active.where((a) => a.status == status).length;
                final percent = active.isEmpty
                    ? 0.0
                    : count * 100 / active.length;
                return Tooltip(
                  message:
                      '$status: $count of ${active.length} '
                      '(${percent.toStringAsFixed(0)}%)',
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 102,
                          child: Text(
                            status,
                            style: const TextStyle(color: _muted, fontSize: 11),
                          ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: active.isEmpty ? 0 : count / active.length,
                              minHeight: 10,
                              backgroundColor: _mint,
                              color: _colorFor(status),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 30,
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: _ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
          const Text(
            'Hover or long-press bars for counts and percentages.',
            style: TextStyle(color: _muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _filter(
    String title,
    String value,
    List<String> choices,
    ValueChanged<String> onSelected, {
    double width = 168,
  }) => SizedBox(
    width: width,
    child: DropdownButtonFormField<String>(
      key: ValueKey('$title:$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: title,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(11)),
        isDense: true,
      ),
      items: choices
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          )
          .toList(),
      onChanged: (next) {
        if (next != null) _changeFilters(() => onSelected(next));
      },
    ),
  );

  Widget _filters() => _surface(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          'Find applications',
          'Search, filter and sort the verification directory.',
        ),
        const SizedBox(height: 12),
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
          onSelectionChanged: (v) => _changeFilters(() {
            _showArchived = v.first;
            _status = _showArchived ? 'All' : 'Needs Action';
          }),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 265,
              child: TextField(
                controller: _search,
                onChanged: (_) => _changeFilters(() {}),
                decoration: InputDecoration(
                  hintText: 'Name, ID, type or purpose',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
            ),
            _filter(
              'Request type',
              _type,
              ['All', 'Resident Tier 2', 'Org Accreditation'],
              (v) => _type = v,
              width: 183,
            ),
            _filter(
              'Status',
              _status,
              [
                'Needs Action',
                'All',
                'Pending',
                'Under Review',
                'Resubmission',
                'Approved',
                'Rejected',
              ],
              (v) => _status = v,
              width: 170,
            ),
            _filter(
              'Priority',
              _priority,
              ['All', 'High', 'Normal'],
              (v) => _priority = v,
              width: 135,
            ),
            _filter(
              'Platform',
              _platform,
              ['All', 'Web', 'Mobile'],
              (v) => _platform = v,
              width: 130,
            ),
            _filter(
              'Sort by',
              _sort,
              ['Newest first', 'Oldest first', 'High priority'],
              (v) => _sort = v,
              width: 160,
            ),
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Clear'),
            ),
          ],
        ),
      ],
    ),
  );

  Future<void> _copyCsv(List<VerificationApplication> records) async {
    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No applications match the current filters.'),
        ),
      );
      return;
    }
    final header =
        'Application ID,Applicant,Request Type,Platform,Submitted,'
        'Priority,Status,Purpose,Archived At,Archive Reason';
    final lines = records
        .map(
          (a) => [
            a.id,
            a.name,
            a.type,
            a.platform,
            _dateTime(a.submitted),
            a.priority,
            a.status,
            a.purpose,
            a.archivedAt == null ? '' : _dateTime(a.archivedAt!),
            a.archiveReason ?? '',
          ].map(_csvCell).join(','),
        )
        .toList();
    final csv = '\uFEFF$header\r\n${lines.join('\r\n')}';
    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${records.length} fictional application records copied as CSV.',
        ),
      ),
    );
  }

  String _csvCell(String original) {
    // Quote fields and neutralize potential spreadsheet formula execution.
    final sanitized = RegExp(r'^\s*[=+@\-]').hasMatch(original)
        ? "'$original"
        : original;
    final escaped = sanitized.replaceAll('"', '""');
    return '"$escaped"';
  }

  Widget _appTooltip(VerificationApplication a, Widget child) => Tooltip(
    waitDuration: const Duration(milliseconds: 300),
    message:
        '${a.name}  ·  ${a.id}\n'
        '${a.type} · ${a.platform}\n${a.purpose}\n'
        '${a.status} · ${a.priority} priority\nSubmitted ${_dateTime(a.submitted)}',
    child: child,
  );

  Future<void> _details(VerificationApplication app) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.fact_check_outlined, color: _forest),
            const SizedBox(width: 10),
            Expanded(child: Text(app.name, overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FICTIONAL APPLICATION',
                  style: TextStyle(
                    color: _green,
                    letterSpacing: 1,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 15),
                _detailRow('Application ID', app.id),
                _detailRow('Applicant', app.name),
                _detailRow('Request', app.type),
                _detailRow('Submission platform', app.platform),
                _detailRow('Submitted', _dateTime(app.submitted)),
                _detailRow('Priority', app.priority),
                _detailRow('Status', app.status),
                _detailRow('Archived', app.archived ? 'Yes' : 'No'),
                if (app.archiveReason != null)
                  _detailRow('Archive reason', app.archiveReason!),
                _detailRow('Review purpose', app.purpose),
                const SizedBox(height: 13),
                const Text(
                  'No actual credentials, identity images or private '
                  'documents are loaded. Tier upgrades and accreditation '
                  'decisions require a protected backend.',
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
          if (!app.archived && app.needsAction)
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _forest),
              onPressed: () {
                Navigator.pop(dialogContext);
                context.go('/lgu-admin/verification/review/${app.id}');
              },
              icon: const Icon(Icons.arrow_forward, size: 17),
              label: const Text('Open Review'),
            ),
          if (!app.archived && !app.needsAction)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                _archive(app);
              },
              icon: const Icon(Icons.archive_outlined),
              label: const Text('Archive'),
            ),
          if (app.archived)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                _restore(app);
              },
              icon: const Icon(Icons.unarchive_outlined),
              label: const Text('Restore'),
            ),
        ],
      ),
    );
  }

  Future<void> _archive(VerificationApplication app) async {
    if (app.needsAction || app.archived) return;
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive completed application?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Archive ${app.id}? This hides it from the active queue, but does not delete the record or evidence.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().length < 10) return;
              Navigator.pop(ctx, controller.text.trim());
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || reason == null) return;
    if (_repo.archive(app.id, reason)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Demo application archived. Open Archived to restore it.',
          ),
        ),
      );
    }
  }

  Future<void> _restore(VerificationApplication app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore archived application?'),
        content: Text('Return ${app.id} to the active directory?'),
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
    if (_repo.restore(app.id)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Application restored.')));
    }
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 145,
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

  Widget _directory(bool compact) {
    final all = _filtered;
    final visible = all.take(_visibleCount).toList();
    return _surface(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _heading(
                  _showArchived
                      ? 'Archived applications'
                      : 'Application directory',
                  'Inspect, archive completed cases, or restore archived records.',
                ),
              ),
              if (!compact)
                IconButton(
                  tooltip: 'Copy filtered CSV',
                  onPressed: () => _copyCsv(all),
                  icon: const Icon(Icons.copy_rounded, color: _forest),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Showing ${visible.length} of ${all.length} ${_showArchived ? 'archived' : 'active'} applications '
            '· ${_applications.length} total demo records',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.all(35),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off_outlined, size: 32, color: _muted),
                    SizedBox(height: 9),
                    Text(
                      'No applications match your filters.',
                      style: TextStyle(color: _muted),
                    ),
                  ],
                ),
              ),
            )
          else if (compact)
            ...visible.map(
              (app) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _appTooltip(
                  app,
                  Material(
                    color: _paper,
                    borderRadius: BorderRadius.circular(13),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(13),
                      onTap: () => _details(app),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    app.name,
                                    style: const TextStyle(
                                      color: _ink,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                _pill(app.status, compact: true),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${app.id} · ${app.type}',
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_dateTime(app.submitted)} · ${app.platform}',
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _pill(app.priority, compact: true),
                                const Spacer(),
                                Text(
                                  app.archived
                                      ? 'Archived record'
                                      : 'View details',
                                  style: const TextStyle(
                                    color: _green,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: _forest,
                                  size: 19,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, bounds) => Scrollbar(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: bounds.maxWidth > 1170 ? bounds.maxWidth : 1170,
                    child: DataTable(
                      dataRowMinHeight: 62,
                      dataRowMaxHeight: 72,
                      columnSpacing: 22,
                      horizontalMargin: 14,
                      headingRowColor: WidgetStateProperty.all(_mint),
                      columns: const [
                        DataColumn(label: Text('APPLICATION')),
                        DataColumn(label: Text('TYPE')),
                        DataColumn(label: Text('PLATFORM')),
                        DataColumn(label: Text('SUBMITTED')),
                        DataColumn(label: Text('PRIORITY')),
                        DataColumn(label: Text('STATUS')),
                        DataColumn(label: Text('DETAILS')),
                      ],
                      rows: visible
                          .map(
                            (app) => DataRow(
                              cells: [
                                DataCell(
                                  _appTooltip(
                                    app,
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          app.name,
                                          style: const TextStyle(
                                            color: _ink,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          app.id,
                                          style: const TextStyle(
                                            color: _muted,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  onTap: () => _details(app),
                                ),
                                DataCell(_appTooltip(app, Text(app.type))),
                                DataCell(Text(app.platform)),
                                DataCell(Text(_dateTime(app.submitted))),
                                DataCell(
                                  Tooltip(
                                    message:
                                        'Demo priority only — not an '
                                        'automated risk score.',
                                    child: _pill(app.priority, compact: true),
                                  ),
                                ),
                                DataCell(_pill(app.status, compact: true)),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: _forest,
                                        ),
                                        onPressed: () => _details(app),
                                        icon: const Icon(
                                          Icons.visibility_outlined,
                                          size: 17,
                                        ),
                                        label: const Text('Inspect'),
                                      ),
                                      if (!app.archived && !app.needsAction)
                                        IconButton(
                                          tooltip: 'Archive completed case',
                                          icon: const Icon(
                                            Icons.archive_outlined,
                                          ),
                                          onPressed: () => _archive(app),
                                        ),
                                      if (app.archived)
                                        IconButton(
                                          tooltip: 'Restore archived case',
                                          icon: const Icon(
                                            Icons.unarchive_outlined,
                                          ),
                                          onPressed: () => _restore(app),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
          if (all.length > _visibleCount) ...[
            const SizedBox(height: 12),
            Center(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: _forest),
                onPressed: () => setState(() => _visibleCount += 6),
                icon: const Icon(Icons.expand_more_rounded),
                label: Text(
                  'Load more (${all.length - _visibleCount} remaining)',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _paper,
    child: LayoutBuilder(
      builder: (context, bounds) {
        final compact = bounds.maxWidth < 740;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            compact ? 14 : 26,
            23,
            compact ? 14 : 26,
            40,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1300),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _banner(compact),
                    const SizedBox(height: 15),
                    _surface(
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: _amber,
                            size: 21,
                          ),
                          SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              'DEVELOPMENT PREVIEW · All records '
                              'and review priorities are fictional. This queue does not '
                              'read Supabase data or grant verification status. '
                              'Real decisions belong to an authorized backend workflow.',
                              style: TextStyle(
                                color: _muted,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(15),
                    ),
                    const SizedBox(height: 19),
                    _metrics(),
                    const SizedBox(height: 20),
                    _distribution(),
                    const SizedBox(height: 20),
                    _filters(),
                    const SizedBox(height: 14),
                    _directory(compact),
                    const SizedBox(height: 18),
                    const Text(
                      'Sensitive document inspection, Tier 2 decisions, '
                      'accreditation outcomes, and notifications require '
                      'role-protected Supabase services.',
                      style: TextStyle(color: _muted, fontSize: 11),
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
