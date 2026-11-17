import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/repositories/verification_case_repository.dart';
import '../../../shared/repositories/verification_auth_audit_store.dart';

const _forest = Color(0xFF00492C);
const _green = Color(0xFF287D55);
const _gold = Color(0xFFFBBA16);
const _paper = Color(0xFFF6F8F5);
const _ink = Color(0xFF173D2B);
const _muted = Color(0xFF687B70);
const _stroke = Color(0xFFE2EBE4);
const _mint = Color(0xFFEAF5EE);

/// Two separate LOCAL prototype event streams:
///   1. Supabase sign-in / sign-out signals for verification admins.
///   2. VerificationCaseRepository decision and archive events.
/// They are not reliable/persistent records of user activity.
class VerificationAuditLogsPage extends StatefulWidget {
  const VerificationAuditLogsPage({super.key});

  @override
  State<VerificationAuditLogsPage> createState() =>
      _VerificationAuditLogsPageState();
}

class _VerificationAuditLogsPageState extends State<VerificationAuditLogsPage> {
  final _cases = VerificationCaseRepository.instance;
  final _auth = VerificationAuthAuditStore.instance;
  final _search = TextEditingController();
  String _filter = 'All events';
  String _period = 'All time';

  @override
  void initState() {
    super.initState();
    _cases.addListener(_refresh);
    _auth.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _cases.removeListener(_refresh);
    _auth.removeListener(_refresh);
    _search.dispose();
    super.dispose();
  }

  String _date(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  // Merge the two event sources for a unified, sortable table.
  // A review event does NOT have a trustworthy reviewer identity yet.
  List<_AuditRow> get _rows {
    final rows = <_AuditRow>[
      for (final event in _auth.events)
        _AuditRow(
          at: event.timestamp,
          category: 'Authentication',
          action: event.action,
          subject: event.email,
          identifier: event.userId,
          details: 'Supabase authentication event (local observation)',
        ),
      for (final event in _cases.events)
        _AuditRow(
          at: event.at,
          category: 'Verification',
          action: event.action,
          subject: _cases.find(event.caseId)?.name ?? event.caseId,
          identifier: event.caseId,
          details: event.reason,
        ),
    ];
    final q = _search.text.trim().toLowerCase();
    final now = DateTime.now();
    rows.removeWhere((r) {
      if (_filter != 'All events' && _filter != r.action) return true;
      if (_period != 'All time') {
        final age = now.difference(r.at);
        final maxDays = _period == 'Last 7 days' ? 7 : 30;
        if (age.isNegative || age >= Duration(days: maxDays)) return true;
      }
      return !'${r.action} ${r.category} ${r.subject} ${r.identifier} ${r.details}'
          .toLowerCase()
          .contains(q);
    });
    rows.sort((a, b) => b.at.compareTo(a.at));
    return rows;
  }

  String _csvCell(String s) {
    var v = s.replaceAll('\r', ' ').replaceAll('\n', ' ');
    if (RegExp(r'^\s*[=+@\-]').hasMatch(v)) v = "'$v";
    return '"${v.replaceAll('"', '""')}"';
  }

  Future<void> _copyCsv() async {
    final lines = <List<String>>[
      [
        'Timestamp (device local)',
        'Category',
        'Action',
        'Subject',
        'Reference',
        'Details',
      ],
      for (final row in _rows)
        [
          row.at.toIso8601String(),
          row.category,
          row.action,
          row.subject,
          row.identifier,
          row.details,
        ],
    ];
    await Clipboard.setData(
      ClipboardData(
        text:
            '\uFEFF${lines.map((r) => r.map(_csvCell).join(',')).join('\r\n')}\r\n',
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filtered local audit records copied as CSV.'),
      ),
    );
  }

  BoxDecoration _surface() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: _stroke),
  );

  Widget _stat(String label, int count, IconData icon) => Container(
    padding: const EdgeInsets.all(19),
    decoration: _surface(),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _mint,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: _forest, size: 23),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  color: _forest,
                ),
              ),
              Text(label, style: const TextStyle(fontSize: 12, color: _muted)),
            ],
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    final authEvents = _auth.events;
    final reviewEvents = _cases.events;
    return ColoredBox(
      color: _paper,
      child: LayoutBuilder(
        builder: (context, viewport) {
          final compact = viewport.maxWidth < 650;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              compact ? 15 : 27,
              24,
              compact ? 15 : 27,
              40,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1260),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(compact ? 22 : 30),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF0A3325),
                              _forest,
                              Color(0xFF237A50),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(23),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KAISA  /  VERIFICATION ADMINISTRATION  /  AUDIT',
                              style: TextStyle(
                                color: _gold,
                                fontSize: 11,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Audit Logs',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 31,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Administrator login/logout activity and verification actions.',
                              style: TextStyle(color: Color(0xFFDFEFE5)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5DA),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Color(0xFF93650B)),
                            SizedBox(width: 11),
                            Expanded(
                              child: Text(
                                'PROTOTYPE ONLY — Login/logout events are observed from Supabase '
                                'in this running app and kept in memory. Browser refreshes and app '
                                'restarts clear this history. This is not a complete or tamper-proof '
                                'security audit. No IP addresses are collected.',
                                style: TextStyle(
                                  color: Color(0xFF765618),
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 19),
                      LayoutBuilder(
                        builder: (context, c) {
                          final columns = c.maxWidth >= 950
                              ? 4
                              : c.maxWidth >= 560
                              ? 2
                              : 1;
                          const gap = 12.0;
                          final width =
                              (c.maxWidth - gap * (columns - 1)) / columns;
                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              SizedBox(
                                width: width,
                                child: _stat(
                                  'Total events',
                                  authEvents.length + reviewEvents.length,
                                  Icons.receipt_long_outlined,
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: _stat(
                                  'Admin logins',
                                  authEvents
                                      .where((e) => e.action == 'Login')
                                      .length,
                                  Icons.login_rounded,
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: _stat(
                                  'Admin logouts',
                                  authEvents
                                      .where((e) => e.action == 'Logout')
                                      .length,
                                  Icons.logout_rounded,
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: _stat(
                                  'Verification actions',
                                  reviewEvents.length,
                                  Icons.fact_check_outlined,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 19),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(19),
                        decoration: _surface(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              runSpacing: 12,
                              spacing: 12,
                              children: [
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Administrator & Verification Activity',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: _ink,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'Live updates from local prototype event streams',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _muted,
                                      ),
                                    ),
                                  ],
                                ),
                                OutlinedButton.icon(
                                  onPressed: _copyCsv,
                                  icon: const Icon(
                                    Icons.copy_all_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Copy CSV'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 17),
                            Wrap(
                              spacing: 11,
                              runSpacing: 11,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                SizedBox(
                                  width: compact ? 235 : 280,
                                  child: TextField(
                                    controller: _search,
                                    onChanged: (_) => setState(() {}),
                                    decoration: const InputDecoration(
                                      labelText:
                                          'Search admin, application or action',
                                      prefixIcon: Icon(Icons.search),
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 190,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _filter,
                                    key: ValueKey('action-$_filter'),
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Action',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                    items:
                                        const [
                                              'All events',
                                              'Login',
                                              'Logout',
                                              'Approved',
                                              'Rejected',
                                              'Resubmission',
                                              'Archived',
                                              'Restored',
                                            ]
                                            .map(
                                              (s) => DropdownMenuItem(
                                                value: s,
                                                child: Text(
                                                  s,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            )
                                            .toList(),
                                    onChanged: (v) => setState(
                                      () => _filter = v ?? 'All events',
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 180,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _period,
                                    key: ValueKey('period-$_period'),
                                    decoration: const InputDecoration(
                                      labelText: 'Period',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                    items:
                                        const [
                                              'All time',
                                              'Last 7 days',
                                              'Last 30 days',
                                            ]
                                            .map(
                                              (s) => DropdownMenuItem(
                                                value: s,
                                                child: Text(s),
                                              ),
                                            )
                                            .toList(),
                                    onChanged: (v) => setState(
                                      () => _period = v ?? 'All time',
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => setState(() {
                                    _search.clear();
                                    _filter = 'All events';
                                    _period = 'All time';
                                  }),
                                  icon: const Icon(Icons.restart_alt),
                                  label: const Text('Reset'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${rows.length} matching events',
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (rows.isEmpty)
                              Container(
                                alignment: Alignment.center,
                                width: double.infinity,
                                padding: const EdgeInsets.all(30),
                                color: _paper,
                                child: const Text(
                                  'No events yet. Sign in or sign out '
                                  'with a Verification Administrator account to record '
                                  'authentication activity in this app session.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: _muted),
                                ),
                              )
                            else if (compact)
                              Column(
                                children: [
                                  for (final r in rows)
                                    Card(
                                      child: ListTile(
                                        title: Text(
                                          '${r.action} · ${r.subject}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                          '${_date(r.at)} · ${r.category}\n${r.details}',
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        onTap: () => _showDetails(r),
                                      ),
                                    ),
                                ],
                              )
                            else
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: const WidgetStatePropertyAll(
                                    _mint,
                                  ),
                                  columns: const [
                                    DataColumn(label: Text('TIME')),
                                    DataColumn(label: Text('CATEGORY')),
                                    DataColumn(label: Text('ACTION')),
                                    DataColumn(
                                      label: Text('ADMIN / APPLICANT'),
                                    ),
                                    DataColumn(label: Text('REFERENCE')),
                                    DataColumn(label: Text('DETAILS')),
                                  ],
                                  rows: [
                                    for (final r in rows)
                                      DataRow(
                                        cells: [
                                          DataCell(Text(_date(r.at))),
                                          DataCell(Text(r.category)),
                                          DataCell(
                                            Text(
                                              r.action,
                                              style: TextStyle(
                                                color:
                                                    r.action == 'Logout' ||
                                                        r.action == 'Rejected'
                                                    ? const Color(0xFFB42318)
                                                    : _green,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            SizedBox(
                                              width: 190,
                                              child: Text(
                                                r.subject,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            SizedBox(
                                              width: 150,
                                              child: Text(
                                                r.identifier,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            IconButton(
                                              onPressed: () => _showDetails(r),
                                              icon: const Icon(
                                                Icons.visibility_outlined,
                                              ),
                                              tooltip: 'Details',
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Production: Sign-in and sign-out events must be '
                        'written and retained by a trusted server-side audit mechanism '
                        'with immutable actor IDs and server timestamps. This local '
                        'recorder cannot capture activity on other devices or browser '
                        'sessions.',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 11,
                          height: 1.6,
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

  void _showDetails(_AuditRow r) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Audit Event Details'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Action: ${r.action}'),
              const SizedBox(height: 8),
              Text('Category: ${r.category}'),
              const SizedBox(height: 8),
              Text('Subject: ${r.subject}'),
              const SizedBox(height: 8),
              Text('Reference: ${r.identifier}'),
              const SizedBox(height: 8),
              Text('Local time: ${_date(r.at)}'),
              const SizedBox(height: 8),
              Text('Details: ${r.details}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _AuditRow {
  const _AuditRow({
    required this.at,
    required this.category,
    required this.action,
    required this.subject,
    required this.identifier,
    required this.details,
  });
  final DateTime at;
  final String category, action, subject, identifier, details;
}
