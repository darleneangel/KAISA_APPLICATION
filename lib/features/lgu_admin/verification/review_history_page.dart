import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:file_saver/file_saver.dart';
import '../../../shared/repositories/verification_case_repository.dart';

// KAISA · Verification Superadmin · Screening & Decision History
// Demonstration only. No face recognition, identity images, or Supabase calls.
const _forest = Color(0xFF00492C);
const _green = Color(0xFF237A50);
const _gold = Color(0xFFFBC02D);
const _paper = Color(0xFFF7F9F6);
const _ink = Color(0xFF173D2B);
const _muted = Color(0xFF687B70);
const _stroke = Color(0xFFE2EBE4);
const _mint = Color(0xFFEAF5EE);
const _amber = Color(0xFF98650B);
const _red = Color(0xFFAB352B);

class ReviewHistoryPage extends StatefulWidget {
  const ReviewHistoryPage({super.key});

  @override
  State<ReviewHistoryPage> createState() => _ReviewHistoryPageState();
}

class _ReviewHistoryPageState extends State<ReviewHistoryPage> {
  final _searchController = TextEditingController();
  String _decision = 'All';
  String _screening = 'All';
  String _reviewMode = 'All';
  String _sort = 'Newest first';
  int _visibleCount = 6;
  bool _showArchived = false;
  bool _exporting = false;
  // Archive visibility for orphaned fictional history rows only. Shared cases
  // are archived through VerificationCaseRepository instead.
  final Map<String, String> _localArchiveReasons = {};

  // Entirely fictional screening/decision metadata. Never use these rows to
  // assert that an ID, selfie, or person has actually been verified.
  static final List<_HistoryEntry> _records = [
    _HistoryEntry(
      'REV-DEMO-001',
      'VER-DEMO-004',
      'Demo Resident D',
      DateTime(2026, 11, 16, 15, 20),
      'Passed screening',
      'Manual quality review',
      'Approved',
      'Demo Verification Admin',
      'REQUIREMENTS_MET',
      'Document and application checks recorded for demo.',
      'ID and selfie inputs supplied (mock)',
      'No facial comparison performed',
    ),
    _HistoryEntry(
      'REV-DEMO-002',
      'VER-DEMO-005',
      'Demo Resident E',
      DateTime(2026, 11, 16, 10, 45),
      'Needs manual review',
      'Manual review',
      'Resubmission Requested',
      'Demo Verification Admin',
      'UNCLEAR_EVIDENCE',
      'Selfie/document quality insufficient in scenario; request clearer submission.',
      'ID and selfie inputs supplied (mock)',
      'Fictional quality issue; not a real mismatch',
    ),
    _HistoryEntry(
      'REV-DEMO-003',
      'VER-DEMO-006',
      'Demo Resident F',
      DateTime(2026, 11, 15, 14, 15),
      'Inconclusive',
      'Manual review',
      'Rejected',
      'Demo Verification Admin',
      'REQUIREMENTS_NOT_MET',
      'Simulated evidence failed the documented review checklist.',
      'ID and selfie inputs supplied (mock)',
      'Fictional assessment; no biometric conclusion',
    ),
    _HistoryEntry(
      'REV-DEMO-004',
      'VER-DEMO-007',
      'Demo Resident G',
      DateTime(2026, 11, 15, 9, 30),
      'Passed screening',
      'Manual quality review',
      'Approved',
      'Demo Verification Admin',
      'REQUIREMENTS_MET',
      'Illustrative applicant and credential details reviewed.',
      'ID and selfie inputs supplied (mock)',
      'No facial comparison performed',
    ),
    _HistoryEntry(
      'REV-DEMO-005',
      'VER-DEMO-008',
      'Demo Resident H',
      DateTime(2026, 11, 14, 11, 5),
      'Needs manual review',
      'Manual review',
      'Resubmission Requested',
      'Demo Verification Admin',
      'DOCUMENT_UNREADABLE',
      'Uploaded evidence requires a clearer replacement in this scenario.',
      'ID and selfie inputs supplied (mock)',
      'Fictional document-quality flag',
    ),
    _HistoryEntry(
      'REV-DEMO-006',
      'VER-DEMO-009',
      'Demo Resident I',
      DateTime(2026, 11, 13, 16, 50),
      'Inconclusive',
      'Manual review',
      'Approved',
      'Demo Verification Admin',
      'ALTERNATE_EVIDENCE_REVIEWED',
      'Illustrative secondary manual checks satisfied requirements.',
      'ID and selfie inputs supplied (mock)',
      'Fictional low-quality capture',
    ),
    _HistoryEntry(
      'REV-DEMO-007',
      'VER-DEMO-010',
      'Demo Resident J',
      DateTime(2026, 11, 12, 8, 25),
      'Passed screening',
      'Manual quality review',
      'Approved',
      'Demo Verification Admin',
      'REQUIREMENTS_MET',
      'Illustrative application review complete.',
      'ID and selfie inputs supplied (mock)',
      'No facial comparison performed',
    ),
    _HistoryEntry(
      'REV-DEMO-008',
      'VER-DEMO-011',
      'Demo Resident K',
      DateTime(2026, 11, 11, 13, 40),
      'Needs manual review',
      'Manual review',
      'Rejected',
      'Demo Verification Admin',
      'INCONSISTENT_DOCUMENT_DETAILS',
      'Fictional review found unresolved document inconsistencies.',
      'ID and selfie inputs supplied (mock)',
      'Fictional document metadata issue',
    ),
  ];

  final VerificationCaseRepository _repo = VerificationCaseRepository.instance;

  bool _archived(_HistoryEntry r) =>
      _repo.find(r.applicationId)?.archived ??
      _localArchiveReasons.containsKey(r.id);

  String? _archiveReason(_HistoryEntry r) =>
      _repo.find(r.applicationId)?.archiveReason ?? _localArchiveReasons[r.id];

  bool _canArchive(_HistoryEntry r) {
    final application = _repo.find(r.applicationId);
    return application == null
        ? const ['Approved', 'Rejected'].contains(r.decision)
        : (!application.archived && !application.needsAction);
  }

  Future<void> _archiveEntry(_HistoryEntry record) async {
    final application = _repo.find(record.applicationId);
    if (application != null && application.needsAction) {
      _message('Resolve this application before archiving it.');
      return;
    }
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Archive review record?'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Application: ${record.applicationId}'),
              const SizedBox(height: 10),
              const Text(
                'Archiving hides completed records from the active view. '
                'It does not delete the decision or audit history.',
                style: TextStyle(fontSize: 12, color: _muted),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: reasonController,
                autofocus: true,
                minLines: 2,
                maxLines: 3,
                maxLength: 300,
                decoration: const InputDecoration(
                  labelText: 'Reason (at least 10 characters)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              if (reasonController.text.trim().length < 10) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Enter at least 10 characters.'),
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext, reasonController.text.trim());
            },
            icon: const Icon(Icons.archive_outlined),
            label: const Text('Archive'),
          ),
        ],
      ),
    );
    // Dialog is closed before disposing a controller referenced by its widget.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => reasonController.dispose(),
    );
    if (!mounted || reason == null) return;
    if (application == null) {
      setState(() => _localArchiveReasons[record.id] = reason);
      _message('Fictional history row archived locally.');
    } else {
      final saved = _repo.archive(application.id, reason);
      _message(
        saved
            ? 'Application archived in shared prototype state.'
            : 'Archive failed. Check whether the case is complete.',
      );
    }
  }

  Future<void> _restoreEntry(_HistoryEntry record) async {
    final application = _repo.find(record.applicationId);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore archived record?'),
        content: Text(
          'Return ${record.applicationId} to the active directory?',
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
    if (application == null) {
      setState(() => _localArchiveReasons.remove(record.id));
      _message('Fictional history row restored.');
    } else {
      _message(
        _repo.restore(application.id)
            ? 'Application restored.'
            : 'Restore failed.',
      );
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  /// Exports unique resident applications with actual Approved status in the
  /// shared demo repository. Never implies an ID or selfie was verified.
  Future<void> _exportApprovedTier2() async {
    if (_exporting) return;
    final residents =
        _repo.applications
            .where((a) => a.type == 'Resident Tier 2' && a.status == 'Approved')
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    if (residents.isEmpty) {
      _message('No approved Tier 2 resident records are available for export.');
      return;
    }
    final rows = <List<String>>[
      [
        'Application ID',
        'Resident Name (Demo)',
        'Application Type',
        'Verification Status (Demo)',
        'Submission Platform',
        'Submitted At',
        'Decision At (if recorded)',
        'Archived',
        'Archived At',
        'Data Source',
      ],
      for (final a in residents)
        [
          a.id,
          a.name,
          a.type,
          a.status,
          a.platform,
          a.submitted.toIso8601String(),
          _decisionEventFor(a.id)?.at.toIso8601String() ?? 'Not recorded',
          a.archived ? 'Yes' : 'No',
          a.archivedAt?.toIso8601String() ?? '',
          'Fictional in-memory prototype',
        ],
    ];
    final csv =
        '\uFEFF${rows.map((r) => r.map(_csvCell).join(',')).join('\r\n')}\r\n';
    setState(() => _exporting = true);
    try {
      await FileSaver.instance.saveFile(
        name: 'kaisa_approved_tier2_residents_demo',
        bytes: Uint8List.fromList(utf8.encode(csv)),
        fileExtension: 'csv',
        mimeType: MimeType.csv,
      );
      _message(
        'Approved Tier 2 demonstration records exported (${residents.length}).',
      );
    } catch (error) {
      _message('Could not save CSV: $error');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  VerificationCaseEvent? _decisionEventFor(String caseId) {
    for (final event in _repo.events) {
      if (event.caseId == caseId && event.action == 'Approved') return event;
    }
    return null;
  }

  List<_HistoryEntry> get _allRecords {
    final liveDemo = _repo.events.map((e) {
      final app = _repo.find(e.caseId);
      return _HistoryEntry(
        'LOCAL-${e.at.microsecondsSinceEpoch}',
        e.caseId,
        app?.name ?? 'Demo applicant',
        e.at,
        'Not performed',
        'Manual demo decision',
        e.action == 'Resubmission' ? 'Resubmission Requested' : e.action,
        'Prototype reviewer',
        'LOCAL_DEMO',
        e.reason,
        'No real evidence provided',
        'No AI screening performed',
      );
    }).toList();
    return [...liveDemo, ..._records];
  }

  @override
  void initState() {
    super.initState();
    _repo.addListener(_repaint);
  }

  void _repaint() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _repo.removeListener(_repaint);
    _searchController.dispose();
    super.dispose();
  }

  String _date(DateTime date) {
    final h = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final min = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} · $h:$min $ampm';
  }

  List<_HistoryEntry> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    final result = _allRecords.where((r) {
      if (_archived(r) != _showArchived) return false;
      final inSearch =
          q.isEmpty ||
          '${r.id} ${r.applicationId} ${r.applicant} ${r.reviewer} ${r.code}'
              .toLowerCase()
              .contains(q);
      return inSearch &&
          (_decision == 'All' || r.decision == _decision) &&
          (_screening == 'All' || r.screening == _screening) &&
          (_reviewMode == 'All' || r.reviewMode == _reviewMode);
    }).toList();
    result.sort(
      (a, b) =>
          _sort == 'Oldest first' ? a.at.compareTo(b.at) : b.at.compareTo(a.at),
    );
    return result;
  }

  BoxDecoration _surface({double radius = 18}) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: _stroke),
    boxShadow: const [
      BoxShadow(color: Color(0x0800492C), blurRadius: 18, offset: Offset(0, 4)),
    ],
  );

  Widget _card(Widget child, {EdgeInsets padding = const EdgeInsets.all(20)}) =>
      Container(
        width: double.infinity,
        padding: padding,
        decoration: _surface(),
        child: child,
      );

  Widget _tag(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
    ),
  );

  Color _screeningColor(String screening) => switch (screening) {
    'Passed screening' => _green,
    'Needs manual review' => _amber,
    _ => const Color(0xFF456DA6),
  };

  Color _decisionColor(String decision) => switch (decision) {
    'Approved' => _green,
    'Rejected' => _red,
    _ => _amber,
  };

  Widget _metric(
    String label,
    String value,
    String description,
    IconData icon,
  ) => Tooltip(
    message: description,
    child: _card(
      Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _mint,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: _forest),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: _forest,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _metrics() {
    final referred = _allRecords
        .where((r) => r.reviewMode == 'Manual review')
        .length;
    final approved = _allRecords.where((r) => r.decision == 'Approved').length;
    final resubmitted = _allRecords
        .where((r) => r.decision == 'Resubmission Requested')
        .length;
    final cards = [
      _metric(
        'History entries',
        '${_allRecords.length}',
        'Completed fictional review outcomes',
        Icons.history_rounded,
      ),
      _metric(
        'Manual referrals',
        '$referred',
        'Inconclusive/flagged cases in demo',
        Icons.person_search_rounded,
      ),
      _metric(
        'Approved',
        '$approved',
        'Recorded reviewer approvals, not AI approvals',
        Icons.verified_user_outlined,
      ),
      _metric(
        'Resubmissions',
        '$resubmitted',
        'Cases returned for clearer or corrected evidence',
        Icons.refresh_rounded,
      ),
    ];
    return LayoutBuilder(
      builder: (_, c) {
        final n = c.maxWidth >= 1000
            ? 4
            : c.maxWidth >= 540
            ? 2
            : 1;
        const gap = 12.0;
        final w = (c.maxWidth - (n - 1) * gap) / n;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final card in cards) SizedBox(width: w, child: card)],
        );
      },
    );
  }

  Widget _header(bool compact) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(compact ? 22 : 30),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(23),
      gradient: const LinearGradient(
        colors: [Color(0xFF0A3225), _forest, Color(0xFF247B51)],
      ),
    ),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 14,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'KAISA  /  LGU VERIFICATION  /  AUDIT HISTORY',
                style: TextStyle(
                  color: _gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Verification Review History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 25 : 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Trace ID-and-selfie screening outcomes, manual referrals, and documented reviewer decisions.',
                style: TextStyle(
                  color: Color(0xFFE1F2E8),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_outlined, color: _gold, size: 18),
              SizedBox(width: 8),
              Text(
                'READ-ONLY HISTORY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
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
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF6DC),
      border: Border.all(color: const Color(0xFFF2E0A5)),
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, color: _amber, size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'PROTOTYPE DATA — All screening labels, review decisions, applicants and dates are fictional. '
            'No photos are processed and no facial recognition model runs in Flutter. '
            'An inconclusive or flagged AI result must go to human review, not automatic rejection.',
            style: TextStyle(
              color: Color(0xFF795813),
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _workflow() => _card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Proposed ID + Selfie Verification Flow',
          style: TextStyle(
            color: _ink,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Screening is an aid to human review, not the sole basis for identity decisions.',
          style: TextStyle(color: _muted, fontSize: 12),
        ),
        const SizedBox(height: 15),
        LayoutBuilder(
          builder: (context, c) => Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _step('1', 'Submit ID + selfie', Icons.upload_file_outlined),
              const Icon(Icons.arrow_forward_rounded, color: _muted, size: 18),
              _step('2', 'Python screening', Icons.psychology_outlined),
              const Icon(Icons.arrow_forward_rounded, color: _muted, size: 18),
              _step(
                '3',
                'Flag / inconclusive → human review',
                Icons.person_search_outlined,
              ),
              const Icon(Icons.arrow_forward_rounded, color: _muted, size: 18),
              _step('4', 'Decision + audit entry', Icons.fact_check_outlined),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'A screening pass still requires applicable document and eligibility checks. Review History records finalized decisions; unresolved referrals belong in the Applications/Identity Review queue.',
          style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
        ),
      ],
    ),
  );

  Widget _step(String index, String label, IconData icon) => Tooltip(
    message: label,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: _mint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: _forest,
            child: Text(
              index,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, color: _forest, size: 17),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _forest,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _analytics() {
    final buckets = [
      (
        'Passed screening',
        _allRecords.where((r) => r.screening == 'Passed screening').length,
      ),
      (
        'Needs manual review',
        _allRecords.where((r) => r.screening == 'Needs manual review').length,
      ),
      (
        'Inconclusive',
        _allRecords.where((r) => r.screening == 'Inconclusive').length,
      ),
      (
        'Not performed',
        _allRecords.where((r) => r.screening == 'Not performed').length,
      ),
    ];
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Screening outcomes · demonstration',
            style: TextStyle(
              color: _ink,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Screening outcome groups. Hover or tap a bar for details.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 19),
          for (final group in buckets)
            Padding(
              padding: const EdgeInsets.only(bottom: 17),
              child: Tooltip(
                message:
                    '${group.$1}: ${group.$2} of ${_allRecords.length} sample records (${(group.$2 * 100 / _allRecords.length).toStringAsFixed(1)}%). This is not model accuracy.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.$1,
                            style: const TextStyle(
                              color: _ink,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Text(
                          '${group.$2} · ${(group.$2 * 100 / _allRecords.length).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: _muted,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: group.$2 / _allRecords.length,
                        minHeight: 12,
                        backgroundColor: _mint,
                        color: _screeningColor(group.$1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> callback,
  ) => SizedBox(
    width: 210,
    child: DropdownButtonFormField<String>(
      key: ValueKey('$label-$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(11)),
      ),
      items: [
        for (final option in options)
          DropdownMenuItem(
            value: option,
            child: Text(option, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: callback,
    ),
  );

  Widget _filters() => Wrap(
    spacing: 10,
    runSpacing: 11,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      SizedBox(
        width: 255,
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {
            _visibleCount = 6;
          }),
          decoration: InputDecoration(
            hintText: 'Search applicant, ID or reviewer',
            prefixIcon: const Icon(Icons.search_rounded),
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(11)),
          ),
        ),
      ),
      _dropdown(
        'Decision',
        _decision,
        [
          'All',
          'Approved',
          'Rejected',
          'Resubmission Requested',
          'Archived',
          'Restored',
        ],
        (v) => setState(() {
          _decision = v ?? 'All';
          _visibleCount = 6;
        }),
      ),
      _dropdown(
        'Screening',
        _screening,
        [
          'All',
          'Passed screening',
          'Needs manual review',
          'Inconclusive',
          'Not performed',
        ],
        (v) => setState(() {
          _screening = v ?? 'All';
          _visibleCount = 6;
        }),
      ),
      _dropdown(
        'Review method',
        _reviewMode,
        [
          'All',
          'Manual review',
          'Manual quality review',
          'Manual demo decision',
        ],
        (v) => setState(() {
          _reviewMode = v ?? 'All';
          _visibleCount = 6;
        }),
      ),
      _dropdown('Sort', _sort, [
        'Newest first',
        'Oldest first',
      ], (v) => setState(() => _sort = v ?? 'Newest first')),
      TextButton.icon(
        onPressed: () => setState(() {
          _searchController.clear();
          _decision = 'All';
          _screening = 'All';
          _reviewMode = 'All';
          _sort = 'Newest first';
          _visibleCount = 6;
        }),
        icon: const Icon(Icons.restart_alt_rounded),
        label: const Text('Reset filters'),
      ),
    ],
  );

  String _csvCell(String value) {
    var safe = value.replaceAll('\r', ' ').replaceAll('\n', ' ');
    // Prefix spreadsheet formula-looking values to prevent CSV injection.
    if (RegExp(r'^\s*[=+@\-]').hasMatch(safe)) safe = "'$safe";
    return '"${safe.replaceAll('"', '""')}"';
  }

  Future<void> _copyCsv() async {
    final rows = <List<String>>[
      [
        'Review ID',
        'Application ID',
        'Applicant',
        'AI Screening (demo)',
        'Review Method',
        'Decision',
        'Reviewer',
        'Reviewed At',
        'Policy Code',
        'Notes',
      ],
      for (final r in _filtered)
        [
          r.id,
          r.applicationId,
          r.applicant,
          r.screening,
          r.reviewMode,
          r.decision,
          r.reviewer,
          _date(r.at),
          r.code,
          r.notes,
        ],
    ];
    await Clipboard.setData(
      ClipboardData(
        text:
            '\uFEFF${rows.map((row) => row.map(_csvCell).join(',')).join('\r\n')}',
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filtered demo review history copied as CSV.'),
      ),
    );
  }

  Widget _directory() {
    final results = _filtered;
    final shown = results.take(_visibleCount).toList();
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 12,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verification decision records',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Review outcomes, audit details, and non-destructive archiving.',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: _copyCsv,
                icon: const Icon(Icons.copy_all_outlined, size: 18),
                label: const Text('Copy filtered CSV'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Active history'),
                    icon: Icon(Icons.history),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Archived'),
                    icon: Icon(Icons.archive_outlined),
                  ),
                ],
                selected: {_showArchived},
                onSelectionChanged: (value) => setState(() {
                  _showArchived = value.first;
                  _visibleCount = 6;
                }),
              ),
              FilledButton.icon(
                onPressed: _exporting ? null : _exportApprovedTier2,
                icon: const Icon(Icons.file_download_outlined, size: 18),
                label: Text(
                  _exporting ? 'Exporting...' : 'Export Approved Tier 2 CSV',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Tier 2 export contains only the shared repository’s approved resident '
            'application fields. It does not contain private ID photos, selfies, '
            'addresses, contact details, or a certified verification result.',
            style: TextStyle(color: _muted, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 17),
          _filters(),
          const SizedBox(height: 14),
          Text(
            'Showing ${shown.length} of ${results.length} matching records · ${_allRecords.length} total demo decisions',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 11),
          if (shown.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(
                child: Text(
                  'No matching review records. Try resetting the filters.',
                  style: TextStyle(color: _muted),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, c) {
                if (c.maxWidth < 690) {
                  return Column(
                    children: [
                      for (final r in shown)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            onTap: () => _details(r),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                border: Border.all(color: _stroke),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.applicant,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: _ink,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${r.applicationId} · ${_date(r.at)}',
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 7,
                                    runSpacing: 7,
                                    children: [
                                      _tag(
                                        r.screening,
                                        _screeningColor(r.screening),
                                      ),
                                      _tag(
                                        r.decision,
                                        _decisionColor(r.decision),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 9),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: _archived(r)
                                          ? () => _restoreEntry(r)
                                          : (_canArchive(r)
                                                ? () => _archiveEntry(r)
                                                : null),
                                      icon: Icon(
                                        _archived(r)
                                            ? Icons.unarchive_outlined
                                            : Icons.archive_outlined,
                                        size: 17,
                                      ),
                                      label: Text(
                                        _archived(r) ? 'Restore' : 'Archive',
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    'Tap to view review details',
                                    style: TextStyle(
                                      color: _muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: c.maxWidth),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(_mint),
                      columnSpacing: 18,
                      columns: const [
                        DataColumn(label: Text('REVIEW ID')),
                        DataColumn(label: Text('APPLICATION')),
                        DataColumn(label: Text('SCREENING')),
                        DataColumn(label: Text('REVIEW METHOD')),
                        DataColumn(label: Text('DECISION')),
                        DataColumn(label: Text('REVIEWED AT')),
                        DataColumn(label: Text('DETAILS')),
                      ],
                      rows: [
                        for (final r in shown)
                          DataRow(
                            cells: [
                              DataCell(
                                Tooltip(
                                  message: 'Review record ${r.id}',
                                  child: Text(r.id),
                                ),
                              ),
                              DataCell(
                                Tooltip(
                                  message: '${r.applicant}\n${r.applicationId}',
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.applicant,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        r.applicationId,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: _muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(
                                Tooltip(
                                  message: '${r.screening}. ${r.screeningNote}',
                                  child: _tag(
                                    r.screening,
                                    _screeningColor(r.screening),
                                  ),
                                ),
                              ),
                              DataCell(Text(r.reviewMode)),
                              DataCell(
                                Tooltip(
                                  message: '${r.decision}\nPolicy: ${r.code}',
                                  child: _tag(
                                    r.decision,
                                    _decisionColor(r.decision),
                                  ),
                                ),
                              ),
                              DataCell(Text(_date(r.at))),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Inspect review details',
                                      onPressed: () => _details(r),
                                      icon: const Icon(
                                        Icons.open_in_new_rounded,
                                        color: _forest,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: _archived(r)
                                          ? 'Restore record'
                                          : (_canArchive(r)
                                                ? 'Archive completed record'
                                                : 'Unresolved case cannot be archived'),
                                      onPressed: _archived(r)
                                          ? () => _restoreEntry(r)
                                          : (_canArchive(r)
                                                ? () => _archiveEntry(r)
                                                : null),
                                      icon: Icon(
                                        _archived(r)
                                            ? Icons.unarchive_outlined
                                            : Icons.archive_outlined,
                                        color: _forest,
                                      ),
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
          if (results.length > shown.length) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _visibleCount += 6),
                icon: const Icon(Icons.expand_more_rounded),
                label: const Text('Load more'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
        const SizedBox(height: 3),
        SelectableText(
          value,
          style: const TextStyle(
            color: _ink,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  void _details(_HistoryEntry record) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Verification Review Details'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FICTIONAL SCREENING AND REVIEW METADATA',
                style: TextStyle(
                  color: _green,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              _detail('Review ID', record.id),
              _detail('Application ID', record.applicationId),
              _detail('Applicant', record.applicant),
              _detail('ID + selfie submission', record.evidence),
              _detail('Python screening result (simulated)', record.screening),
              _detail('Screening explanation', record.screeningNote),
              _detail('Review method', record.reviewMode),
              const Divider(height: 24),
              _detail('Final reviewer decision', record.decision),
              _detail('Policy reason code', record.code),
              _detail('Reviewer', record.reviewer),
              _detail('Reviewed at', _date(record.at)),
              _detail('Recorded rationale', record.notes),
              const Text(
                'No ID photograph or selfie is stored in this prototype. Real evidence requires private storage, verified authorization and an approved retention policy.',
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
        OutlinedButton.icon(
          onPressed: _archived(record)
              ? () {
                  Navigator.pop(dialogContext);
                  _restoreEntry(record);
                }
              : (_canArchive(record)
                    ? () {
                        Navigator.pop(dialogContext);
                        _archiveEntry(record);
                      }
                    : null),
          icon: Icon(
            _archived(record)
                ? Icons.unarchive_outlined
                : Icons.archive_outlined,
          ),
          label: Text(_archived(record) ? 'Restore' : 'Archive'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _paper,
    child: LayoutBuilder(
      builder: (context, c) {
        final compact = c.maxWidth < 650;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            compact ? 14 : 26,
            24,
            compact ? 14 : 26,
            45,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(compact),
                    const SizedBox(height: 15),
                    _notice(),
                    const SizedBox(height: 22),
                    _metrics(),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, bounds) {
                        if (bounds.maxWidth < 980) {
                          return Column(
                            children: [
                              _analytics(),
                              const SizedBox(height: 14),
                              _workflow(),
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 4, child: _analytics()),
                            const SizedBox(width: 14),
                            Expanded(flex: 5, child: _workflow()),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                    _directory(),
                    const SizedBox(height: 14),
                    const Text(
                      'Decisions and audit events remain read-only. Archiving only changes which records appear in the active view. Pending AI referrals belong in Applications / Identity Review.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 11,
                        height: 1.4,
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

class _HistoryEntry {
  const _HistoryEntry(
    this.id,
    this.applicationId,
    this.applicant,
    this.at,
    this.screening,
    this.reviewMode,
    this.decision,
    this.reviewer,
    this.code,
    this.notes,
    this.evidence,
    this.screeningNote,
  );

  final String id;
  final String applicationId;
  final String applicant;
  final DateTime at;
  final String screening;
  final String reviewMode;
  final String decision;
  final String reviewer;
  final String code;
  final String notes;
  final String evidence;
  final String screeningNote;
}
