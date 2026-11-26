import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../shared/models/organization_membership_model.dart';
import '../../../shared/repositories/organization_membership_repository.dart';

/// Embedded in the existing Organization Admin shell; no second Scaffold.
/// Uses only the membership fields and repository methods in the supplied page.
class OrganizationMembersPage extends StatefulWidget {
  final String organizationId;

  const OrganizationMembersPage({super.key, required this.organizationId});

  @override
  State<OrganizationMembersPage> createState() =>
      _OrganizationMembersPageState();
}

enum _Workspace { requests, directory, history, requirements }

enum _HistoryFilter { all, approved, rejected }

enum _Sort { recent, oldest, name }

enum _Decision { approve, reject }

/// Local presentation record. Mock records never enter the shared repository.
class _MemberRecord {
  final String id, residentId, residentName, residentEmail;
  final DateTime requestedAt;
  final DateTime? reviewedAt;
  final MembershipStatus status;
  final OrganizationMembership? source;

  const _MemberRecord({required this.id, required this.residentId,
    required this.residentName, required this.residentEmail,
    required this.requestedAt, required this.status, this.reviewedAt,
    this.source});

  factory _MemberRecord.live(OrganizationMembership m) => _MemberRecord(
    id: m.id.toString(), residentId: m.residentId,
    residentName: m.residentName, residentEmail: m.residentEmail,
    requestedAt: m.requestedAt, reviewedAt: m.reviewedAt,
    status: m.status, source: m,
  );

  _MemberRecord decided(MembershipStatus next) => _MemberRecord(
    id: id, residentId: residentId, residentName: residentName,
    residentEmail: residentEmail, requestedAt: requestedAt,
    reviewedAt: DateTime.now(), status: next,
  );
}

class _OrganizationMembersPageState extends State<OrganizationMembersPage> {
  static const forest = Color(0xFF00301B);
  static const green = Color(0xFF2C6A4A);
  static const gold = Color(0xFFFDBC19);
  static const ink = Color(0xFF151C27);
  static const muted = Color(0xFF526259);
  static const canvas = Color(0xFFF6F8F6);
  static const soft = Color(0xFFF0F5F1);
  static const line = Color(0xFFDCE5DE);
  static const red = Color(0xFFBA1A1A);
  static const amber = Color(0xFF7B5900);
  static const pageSize = 8;

  final repository = OrganizationMembershipRepository.instance;
  final searchController = TextEditingController();
  _Workspace workspace = _Workspace.requests;
  _HistoryFilter historyFilter = _HistoryFilter.all;
  _Sort sort = _Sort.recent;
  int page = 0;
  bool reviewing = false;
  bool mockMode = kDebugMode && const bool.fromEnvironment('USE_MOCK_DATA');
  List<_MemberRecord> _mockRecords = [];

  void _seedMock() {
    const names = ['Maria Santos', 'Juan Reyes', 'Angela Cruz', 'James Mendoza',
      'Patricia Garcia', 'Alex Rivera', 'Sam Flores', 'Jamie Ramos', 'Casey Lim',
      'Taylor Diaz', 'Robin Torres', 'Jordan Lee', 'Avery Tan', 'Morgan Bautista'];
    final now = DateTime.now();
    _mockRecords = List.generate(names.length, (i) {
      final status = i < 10 ? MembershipStatus.pending :
          i < 13 ? MembershipStatus.approved : MembershipStatus.rejected;
      return _MemberRecord(id: 'mock-$i', residentId: 'DEMO-${1001 + i}',
        residentName: names[i], residentEmail: 'demo${i+1}@example.invalid',
        requestedAt: now.subtract(Duration(days: i+2)), status: status,
        reviewedAt: status == MembershipStatus.pending ? null :
          now.subtract(Duration(days: i)));
    });
  }

  List<_MemberRecord> _readRecords() => mockMode ? List.of(_mockRecords) :
      repository.forOrganization(widget.organizationId).map(_MemberRecord.live).toList();

  void _switchMode(bool value) {
    if (!kDebugMode || reviewing || value == mockMode) return;
    setState(() {
      mockMode = value;
      page = 0;
      searchController.clear();
    });
  }

  Widget _developmentControls() => Container(
    padding: const EdgeInsets.all(14), decoration: _surface(color: soft),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SwitchListTile(contentPadding: EdgeInsets.zero, value: mockMode,
        onChanged: reviewing ? null : _switchMode,
        title: Text(mockMode ? 'Mock data mode' : 'Existing repository mode'),
        subtitle: Text(mockMode ? 'Fictional records. No repository writes.' :
          'Uses your existing membership repository without changing its integration.'),
        secondary: const Icon(Icons.science_outlined, color: green)),
      if (mockMode) Wrap(spacing: 8, runSpacing: 8, children: [
        OutlinedButton(onPressed: reviewing ? null : () => setState(() {
          _seedMock(); page = 0;
        }), child: const Text('Reset mock records')),
        OutlinedButton(onPressed: reviewing ? null : () => setState(() {
          _mockRecords.clear(); page = 0;
        }), child: const Text('Test empty state')),
      ]),
    ]),
  );

  @override
  void initState() {
    super.initState();
    _seedMock();
    repository.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant OrganizationMembersPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.organizationId != widget.organizationId) {
      _seedMock();
      searchController.clear();
      workspace = _Workspace.requests;
      historyFilter = _HistoryFilter.all;
      sort = _Sort.recent;
      page = 0;
    }
  }

  void _refresh() {
    if (mounted && !mockMode) setState(() {});
  }

  @override
  void dispose() {
    repository.removeListener(_refresh);
    searchController.dispose();
    super.dispose();
  }

  void _select(_Workspace next, {_HistoryFilter filter = _HistoryFilter.all}) {
    setState(() {
      workspace = next;
      historyFilter = filter;
      searchController.clear();
      sort = _Sort.recent;
      page = 0;
    });
  }

  DateTime _recordDate(_MemberRecord member) =>
      workspace == _Workspace.requests
          ? member.requestedAt
          : member.reviewedAt ?? member.requestedAt;

  List<_MemberRecord> _filtered(List<_MemberRecord> records) {
    final query = searchController.text.trim().toLowerCase();
    final result = records.where((m) {
      final matchesWorkspace = switch (workspace) {
        _Workspace.requests => m.status == MembershipStatus.pending,
        _Workspace.directory => m.status == MembershipStatus.approved,
        _Workspace.history =>
          m.status != MembershipStatus.pending &&
              (historyFilter == _HistoryFilter.all ||
                  (historyFilter == _HistoryFilter.approved &&
                      m.status == MembershipStatus.approved) ||
                  (historyFilter == _HistoryFilter.rejected &&
                      m.status == MembershipStatus.rejected)),
        _Workspace.requirements => false,
      };
      return matchesWorkspace &&
          (m.residentName.toLowerCase().contains(query) ||
              m.residentEmail.toLowerCase().contains(query) ||
              m.residentId.toLowerCase().contains(query));
    }).toList();
    result.sort((a, b) {
      final comparison = switch (sort) {
        _Sort.recent => _recordDate(b).compareTo(_recordDate(a)),
        _Sort.oldest => _recordDate(a).compareTo(_recordDate(b)),
        _Sort.name => a.residentName.toLowerCase().compareTo(b.residentName.toLowerCase()),
      };
      return comparison == 0
          ? a.id.toString().compareTo(b.id.toString())
          : comparison;
    });
    return result;
  }

  String _date(DateTime? value) {
    if (value == null) return 'Not recorded';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final d = value.toLocal();
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).take(2);
    return parts.isEmpty ? '?' : parts.map((s) => s.characters.first.toUpperCase()).join();
  }

  TextStyle _heading(double size) => TextStyle(
        fontFamily: 'Outfit', fontSize: size, fontWeight: FontWeight.w600, color: ink,
      );

  TextStyle get _body => const TextStyle(
        fontFamily: 'Inter', color: muted, fontSize: 13, height: 1.5,
      );

  BoxDecoration _surface({Color color = Colors.white}) => BoxDecoration(
        color: color, borderRadius: BorderRadius.circular(12), border: Border.all(color: line),
      );

  ButtonStyle _primary({Color color = forest}) => FilledButton.styleFrom(
        backgroundColor: color, foregroundColor: Colors.white,
        minimumSize: const Size(0, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      );

  ButtonStyle _outline({Color color = forest}) => OutlinedButton.styleFrom(
        foregroundColor: color, minimumSize: const Size(0, 40),
        side: BorderSide(color: color.withValues(alpha: .35)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      );

  Widget _avatar(_MemberRecord m) => Container(
        width: 42, height: 42, alignment: Alignment.center,
        decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(10)),
        child: Text(_initials(m.residentName), style: const TextStyle(color: forest, fontWeight: FontWeight.w700)),
      );

  Widget _status(_MemberRecord m) {
    final (label, fg, bg, icon) = switch (m.status) {
      MembershipStatus.pending => ('Pending review', amber, const Color(0xFFFFEDC9), Icons.schedule_rounded),
      MembershipStatus.approved => ('Approved', forest, const Color(0xFFD4F4E0), Icons.check_rounded),
      MembershipStatus.rejected => ('Rejected', red, const Color(0xFFFFE5E2), Icons.close_rounded),
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: fg), const SizedBox(width: 5),
          Flexible(child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600))),
        ]),
      ),
    );
  }

  Widget _notice(String text, {IconData icon = Icons.info_outline, Color color = green}) => Container(
        padding: const EdgeInsets.all(14), decoration: _surface(color: soft),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 19), const SizedBox(width: 10),
          Expanded(child: Text(text, style: _body)),
        ]),
      );

  Widget _detail(String title, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: _body), const SizedBox(height: 4),
          SelectableText(value, style: const TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w500)),
        ]),
      );

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // A single review dialog is used for pending requests and historical records.
  Future<void> _openRecord(_MemberRecord m) async {
    if (reviewing || (!mockMode && widget.organizationId.trim().isEmpty)) return;
    final wasMock = mockMode;
    final organization = widget.organizationId;
    final pending = m.status == MembershipStatus.pending;
    setState(() => reviewing = true);
    try {
      final decision = await showDialog<_Decision>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(pending ? 'Review membership request' : 'Membership record', style: _heading(23)),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(16), decoration: _surface(color: soft),
                  child: Row(children: [
                    _avatar(m), const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m.residentName, style: _heading(19)), const SizedBox(height: 6), _status(m),
                    ])),
                  ]),
                ),
                const SizedBox(height: 20),
                _detail('KAISA resident ID', m.residentId),
                _detail('Contact email', m.residentEmail),
                _detail('Application submitted', _date(m.requestedAt)),
                if (!pending) _detail('Decision recorded', _date(m.reviewedAt)),
                const Divider(), const SizedBox(height: 10),
                Text('Application requirements', style: _heading(17)),
                const SizedBox(height: 8),
                _notice('Identity verification status, application answers and supporting files are not exposed by the current page data. No verification or eligibility result is assumed.'),
                if (pending) ...[
                  const SizedBox(height: 12),
                  _notice('Approval grants membership, not staff or administrator access. This page does not collect rejection reasons.', icon: Icons.shield_outlined, color: amber),
                ],
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close')),
            if (pending) ...[
              OutlinedButton(style: _outline(color: red), onPressed: () => Navigator.pop(dialogContext, _Decision.reject), child: const Text('Reject')),
              FilledButton(style: _primary(), onPressed: () => Navigator.pop(dialogContext, _Decision.approve), child: const Text('Approve')),
            ],
          ],
        ),
      );
      if (!mounted || decision == null || organization != widget.organizationId || wasMock != mockMode || !pending) return;
      final approve = decision == _Decision.approve;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(approve ? 'Approve membership?' : 'Reject application?'),
          content: Text(approve
              ? 'Approve ${m.residentName} as a member of this organization? This will not grant staff permissions.'
              : 'Reject the membership request of ${m.residentName}? The record will remain in application history. This page does not collect a rejection reason.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Back')),
            FilledButton(style: _primary(color: approve ? forest : red), onPressed: () => Navigator.pop(dialogContext, true), child: Text(approve ? 'Confirm approval' : 'Confirm rejection')),
          ],
        ),
      );
      if (!mounted || confirmed != true || organization != widget.organizationId || wasMock != mockMode) return;
      // Recheck the record after the dialogs in case it has changed.
      final stillPending = _readRecords().any(
          (record) => record.id == m.id && record.status == MembershipStatus.pending);
      if (!stillPending) {
        _message('This request has already changed. Please review the latest records.');
        return;
      }
      if (wasMock) {
        setState(() {
          _mockRecords = _mockRecords.map((record) => record.id == m.id
            ? record.decided(approve ? MembershipStatus.approved : MembershipStatus.rejected)
            : record).toList();
        });
      } else {
        final original = m.source!;
        if (approve) {
          await Future<void>.sync(() => repository.approveMembership(original.id, organization));
        } else {
          await Future<void>.sync(() => repository.rejectMembership(original.id, organization));
        }
      }
      if (!mounted || organization != widget.organizationId || wasMock != mockMode) return;
      _message(approve ? 'Membership approved. The resident is now in the Members Directory.' : 'Application rejected. The decision is in Application History.');
    } catch (e) {
      _message(e is StateError ? e.message.toString() : 'Unable to process the membership request.');
    } finally {
      if (mounted) setState(() => reviewing = false);
    }
  }

  Widget _summary(String title, int count, IconData icon, Color color, String subtitle, VoidCallback onTap) => Material(
        color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: line)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12), onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(title, style: _body)), const SizedBox(width: 8), Icon(icon, color: color, size: 23)]),
            const SizedBox(height: 12), Text('$count', style: _heading(32)),
            const SizedBox(height: 5), Text(subtitle, style: _body),
          ])),
        ),
      );

  Widget _summaries(int pending, int approved, int rejected) => LayoutBuilder(builder: (_, c) {
        final n = c.maxWidth >= 760 ? 3 : c.maxWidth >= 460 ? 2 : 1;
        final width = (c.maxWidth - (n - 1) * 12) / n;
        return Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(width: width, child: _summary('Pending requests', pending, Icons.inbox_outlined, amber, 'Awaiting membership review', () => _select(_Workspace.requests))),
          SizedBox(width: width, child: _summary('Approved members', approved, Icons.groups_outlined, green, 'Current approved roster', () => _select(_Workspace.directory))),
          SizedBox(width: width, child: _summary('Rejected applications', rejected, Icons.person_off_outlined, red, 'Previous rejection decisions', () => _select(_Workspace.history, filter: _HistoryFilter.rejected))),
        ]);
      });

  Widget _tab(_Workspace target, String label, IconData icon) {
    final active = workspace == target;
    return TextButton.icon(
      onPressed: () => _select(target), icon: Icon(icon, size: 17), label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: active ? Colors.white : muted, backgroundColor: active ? forest : soft,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String get _sectionTitle => switch (workspace) {
        _Workspace.requests => 'Membership requests',
        _Workspace.directory => 'Members directory',
        _Workspace.history => 'Application history',
        _Workspace.requirements => 'Membership requirements',
      };

  String get _sectionDescription => switch (workspace) {
        _Workspace.requests => 'Review pending applications to join this organization.',
        _Workspace.directory => 'Internal roster of approved membership records.',
        _Workspace.history => 'Previous approval and rejection decisions.',
        _Workspace.requirements => 'Organization-specific eligibility and application requirements.',
      };

  Widget _searchAndSort() => LayoutBuilder(builder: (_, c) {
        final search = TextField(
          controller: searchController, onChanged: (_) => setState(() => page = 0),
          decoration: InputDecoration(
            hintText: 'Search name, email or resident ID', prefixIcon: const Icon(Icons.search),
            filled: true, fillColor: Colors.white, isDense: true,
            suffixIcon: searchController.text.isEmpty ? null : IconButton(
              tooltip: 'Clear search', icon: const Icon(Icons.close),
              onPressed: () => setState(() { searchController.clear(); page = 0; }),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: line)),
          ),
        );
        final order = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12), decoration: _surface(),
          child: DropdownButtonHideUnderline(child: DropdownButton<_Sort>(
            value: sort, isExpanded: true,
            items: const [
              DropdownMenuItem(value: _Sort.recent, child: Text('Most recent')),
              DropdownMenuItem(value: _Sort.oldest, child: Text('Oldest first')),
              DropdownMenuItem(value: _Sort.name, child: Text('Name A–Z')),
            ],
            onChanged: (value) { if (value != null) setState(() { sort = value; page = 0; }); },
          )),
        );
        return c.maxWidth >= 560
            ? Row(children: [Expanded(child: search), const SizedBox(width: 12), SizedBox(width: 190, child: order)])
            : Column(children: [search, const SizedBox(height: 10), order]);
      });

  Widget _person(_MemberRecord m) => Row(children: [
        _avatar(m), const SizedBox(width: 10),
        Expanded(child: Text(m.residentName, style: const TextStyle(color: ink, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)),
      ]);

  Widget _action(_MemberRecord m) => m.status == MembershipStatus.pending
      ? FilledButton(style: _primary(), onPressed: reviewing ? null : () => _openRecord(m), child: const Text('Review request'))
      : OutlinedButton(style: _outline(), onPressed: reviewing ? null : () => _openRecord(m), child: const Text('View record'));

  Widget _desktop(List<_MemberRecord> rows) => LayoutBuilder(builder: (_, c) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(constraints: BoxConstraints(minWidth: c.maxWidth), child: DataTable(
          showCheckboxColumn: false, headingRowColor: WidgetStateProperty.all(soft),
          headingTextStyle: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: muted),
          dataTextStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: ink),
          dataRowMinHeight: 74, dataRowMaxHeight: 100, horizontalMargin: 16, columnSpacing: 16,
          columns: [
            DataColumn(label: Text(workspace == _Workspace.directory ? 'MEMBER' : 'APPLICANT')),
            const DataColumn(label: Text('RESIDENT ID')),
            DataColumn(label: Text(workspace == _Workspace.requests ? 'SUBMITTED' : 'DECISION DATE')),
            const DataColumn(label: Text('STATUS')),
            const DataColumn(label: Text('ACTION')),
          ],
          rows: [for (final m in rows) DataRow(cells: [
            DataCell(SizedBox(width: 170, child: _person(m))),
            DataCell(SizedBox(width: 120, child: Text(m.residentId, maxLines: 2, overflow: TextOverflow.ellipsis))),
            DataCell(Text(_date(workspace == _Workspace.requests ? m.requestedAt : m.reviewedAt))),
            DataCell(SizedBox(width: 130, child: _status(m))),
            DataCell(_action(m)),
          ])],
        )),
      ));

  Widget _mobile(List<_MemberRecord> rows) => Column(children: [
        for (final m in rows) Container(
          width: double.infinity, padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: line))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _person(m), const SizedBox(height: 12), Text('Resident ID: ${m.residentId}', style: _body),
            Text(workspace == _Workspace.requests ? 'Submitted ${_date(m.requestedAt)}' : 'Decision: ${_date(m.reviewedAt)}', style: _body),
            const SizedBox(height: 10), _status(m), const SizedBox(height: 12), _action(m),
          ]),
        ),
      ]);

  Widget _empty() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 44),
        child: Column(children: [
          const Icon(Icons.people_outline, color: green, size: 38), const SizedBox(height: 12),
          Text(searchController.text.trim().isNotEmpty ? 'No matching records' : switch (workspace) {
            _Workspace.requests => 'No pending membership requests',
            _Workspace.directory => 'No approved members yet',
            _Workspace.history => 'No matching decisions yet',
            _Workspace.requirements => 'No records',
          }, style: _heading(19), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(searchController.text.trim().isNotEmpty ? 'Try another name or resident ID.' : 'Records will appear here when available.', style: _body, textAlign: TextAlign.center),
        ]),
      );

  Widget _records(List<_MemberRecord> records) {
    final filtered = _filtered(records);
    final pages = filtered.isEmpty ? 1 : (filtered.length / pageSize).ceil();
    final current = page.clamp(0, pages - 1).toInt();
    final rows = filtered.skip(current * pageSize).take(pageSize).toList();
    return Container(
      decoration: _surface(), clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_sectionTitle, style: _heading(22)), const SizedBox(height: 4), Text(_sectionDescription, style: _body),
          const SizedBox(height: 16),
          if (workspace == _Workspace.history) ...[
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final filter in _HistoryFilter.values) ChoiceChip(
                label: Text(switch (filter) { _HistoryFilter.all => 'All decisions', _HistoryFilter.approved => 'Approved', _HistoryFilter.rejected => 'Rejected' }),
                selected: historyFilter == filter,
                onSelected: (_) => setState(() { historyFilter = filter; page = 0; }),
              ),
            ]),
            const SizedBox(height: 12),
          ],
          _searchAndSort(),
        ])),
        if (rows.isEmpty) _empty() else LayoutBuilder(builder: (_, c) => c.maxWidth >= 820 ? _desktop(rows) : _mobile(rows)),
        Container(color: soft, padding: const EdgeInsets.all(14), child: Wrap(
          alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 12, runSpacing: 8,
          children: [
            Text(filtered.isEmpty ? 'Showing 0 records' : 'Showing ${current * pageSize + 1}–${current * pageSize + rows.length} of ${filtered.length}', style: _body),
            Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(tooltip: 'Previous page', onPressed: current == 0 ? null : () => setState(() => page = current - 1), icon: const Icon(Icons.chevron_left)),
              Text('${current + 1} / $pages', style: _body),
              IconButton(tooltip: 'Next page', onPressed: current >= pages - 1 ? null : () => setState(() => page = current + 1), icon: const Icon(Icons.chevron_right)),
            ]),
          ],
        )),
      ]),
    );
  }

  // Read-only implementation plan, not a fake saved configuration.
  Widget _requirements() => Container(
        padding: const EdgeInsets.all(20), decoration: _surface(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(_sectionTitle, style: _heading(22)), const SizedBox(height: 4), Text(_sectionDescription, style: _body),
          const SizedBox(height: 16),
          _notice('Configuration is not connected yet. The existing repository methods used by this page do not include saving organization requirements. The items below are planned fields, not active eligibility rules.'),
          const SizedBox(height: 18),
          for (final item in const [
            (Icons.verified_user_outlined, 'Verified identity', 'Use the LGU verification result instead of collecting a second government ID.'),
            (Icons.groups_outlined, 'Membership eligibility', 'Optional age, residency, skills or professional qualifications.'),
            (Icons.assignment_outlined, 'Application questions', 'Organization-specific questions and justified supporting documents.'),
            (Icons.rule, 'Membership guidelines', 'Applicant acknowledgement of organization rules.'),
            (Icons.lock_outline, 'Application availability', 'Control whether membership applications are open or closed.'),
          ]) ...[
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(item.$1, color: green, size: 22), const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.$2, style: _heading(16)), const SizedBox(height: 3), Text(item.$3, style: _body),
              ])),
            ]),
            const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1)),
          ],
          Text('Requires the membership model, repository and resident application flow to be extended together.', style: _body),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final hasOrganization = widget.organizationId.trim().isNotEmpty;
    final records = mockMode || hasOrganization ? _readRecords() : <_MemberRecord>[];
    final pending = records.where((m) => m.status == MembershipStatus.pending).length;
    final approved = records.where((m) => m.status == MembershipStatus.approved).length;
    final rejected = records.where((m) => m.status == MembershipStatus.rejected).length;
    return Material(
      color: canvas,
      child: LayoutBuilder(builder: (_, c) => SingleChildScrollView(
        padding: EdgeInsets.all(c.maxWidth < 600 ? 16 : 24),
        child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1400), child: DefaultTextStyle.merge(
          style: const TextStyle(fontFamily: 'Inter', color: ink),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('KAISA / PEOPLE MANAGEMENT', style: TextStyle(color: forest, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.1)),
            const SizedBox(height: 8), Text('Members & Requests', style: _heading(32)),
            const SizedBox(height: 6), Text('Manage membership applications and the internal organization roster.', style: _body),
            if (kDebugMode) ...[const SizedBox(height: 16), _developmentControls()],
            if (!mockMode && !hasOrganization) ...[
              const SizedBox(height: 16), _notice('Select an organization to load repository records.'),
            ],
            const SizedBox(height: 22), _summaries(pending, approved, rejected), const SizedBox(height: 22),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _tab(_Workspace.requests, 'Requests ($pending)', Icons.inbox_outlined),
              _tab(_Workspace.directory, 'Members directory', Icons.groups_outlined),
              _tab(_Workspace.history, 'Application history', Icons.history),
              _tab(_Workspace.requirements, 'Requirements', Icons.fact_check_outlined),
            ]),
            const SizedBox(height: 14),
            if (workspace == _Workspace.requirements) _requirements() else _records(records),
            const SizedBox(height: 16),
            _notice(mockMode ? 'Mock records are fictional and local to this page. Decisions never write to the shared repository.' : 'Records are supplied by the existing repository. Staff invitations are separate; approval does not grant administrative access.'),
          ]),
        ))),
      )),
    );
  }
}
