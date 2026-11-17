import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _forest = Color(0xFF00492C);
const _green = Color(0xFF2A7F57);
const _paper = Color(0xFFF4F4F0);
const _ink = Color(0xFF0E3A27);
const _muted = Color(0xFF6E7773);
const _stroke = Color(0xFFECECE6);
const _soft = Color(0xFFE3F1E9);
const _gold = Color(0xFFFBBA16);

class VerificationReportsPage extends StatefulWidget {
  const VerificationReportsPage({super.key});

  @override
  State<VerificationReportsPage> createState() =>
      _VerificationReportsPageState();
}

class _VerificationReportsPageState extends State<VerificationReportsPage> {
  String _period = 'All Demo Periods';

  // Fictional, independent reporting dataset.
  // Not connected to the other demo modules or Supabase.
  static const _records = <_ReportRecord>[
    _ReportRecord('VER-DEMO-001', 'Nov 2026', 'Pending'),
    _ReportRecord('VER-DEMO-002', 'Nov 2026', 'Under Review'),
    _ReportRecord('VER-DEMO-003', 'Nov 2026', 'Pending'),
    _ReportRecord('VER-DEMO-004', 'Nov 2026', 'Approved'),
    _ReportRecord('VER-DEMO-005', 'Nov 2026', 'Resubmission Requested'),
    _ReportRecord('VER-DEMO-006', 'Oct 2026', 'Rejected'),
    _ReportRecord('VER-DEMO-007', 'Oct 2026', 'Approved'),
    _ReportRecord('VER-DEMO-008', 'Oct 2026', 'Approved'),
    _ReportRecord('VER-DEMO-009', 'Sep 2026', 'Approved'),
    _ReportRecord('VER-DEMO-010', 'Sep 2026', 'Rejected'),
  ];

  static const _statuses = [
    'Approved',
    'Pending',
    'Under Review',
    'Rejected',
    'Resubmission Requested',
  ];

  static const _months = ['Sep 2026', 'Oct 2026', 'Nov 2026'];

  int _count(List<_ReportRecord> records, String status) {
    return records.where((r) => r.status == status).length;
  }

  void _copyCsv(List<_ReportRecord> records) {
    final rows = [
      'Application ID,Demo Period,Status',
      for (final r in records) '${r.id},${r.period},${r.status}',
    ];

    Clipboard.setData(ClipboardData(text: rows.join('\n')));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fictional report CSV copied to clipboard.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final records = _records.where((r) {
      return _period == 'All Demo Periods' || r.period == _period;
    }).toList();

    final total = records.length;
    final approved = _count(records, 'Approved');
    final pending =
        _count(records, 'Pending') + _count(records, 'Under Review');
    final rejected = _count(records, 'Rejected');
    final resubmission = _count(records, 'Resubmission Requested');

    final completed = approved + rejected;
    final approvalRate = completed == 0 ? 0.0 : approved / completed * 100;

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
                    'Verification Reports',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: _ink,
                      fontSize: 29,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Analyze Tier 2 verification workload '
                    'and application outcomes.',
                    style: TextStyle(color: _muted, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  _notice(),
                  const SizedBox(height: 22),

                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 240,
                        child: DropdownButtonFormField<String>(
                          initialValue: _period,
                          decoration: const InputDecoration(
                            labelText: 'Reporting Period',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                              borderSide: BorderSide(color: _stroke),
                            ),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'All Demo Periods',
                              child: Text('All Demo Periods'),
                            ),
                            DropdownMenuItem(
                              value: 'Sep 2026',
                              child: Text('September 2026'),
                            ),
                            DropdownMenuItem(
                              value: 'Oct 2026',
                              child: Text('October 2026'),
                            ),
                            DropdownMenuItem(
                              value: 'Nov 2026',
                              child: Text('November 2026'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _period = value);
                            }
                          },
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => _copyCsv(records),
                        style: FilledButton.styleFrom(
                          backgroundColor: _forest,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 17,
                          ),
                        ),
                        icon: const Icon(Icons.content_copy_rounded, size: 18),
                        label: const Text('Copy Demo CSV'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 850
                          ? 4
                          : constraints.maxWidth >= 480
                          ? 2
                          : 1;
                      const gap = 12.0;
                      final width =
                          (constraints.maxWidth - gap * (columns - 1)) /
                          columns;

                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          _metric(
                            'Applications',
                            '$total',
                            Icons.description_outlined,
                            width,
                          ),
                          _metric(
                            'Approved',
                            '$approved',
                            Icons.verified_user_outlined,
                            width,
                          ),
                          _metric(
                            'Awaiting Review',
                            '$pending',
                            Icons.pending_actions_outlined,
                            width,
                          ),
                          _metric(
                            'Approval Rate*',
                            '${approvalRate.toStringAsFixed(1)}%',
                            Icons.trending_up_rounded,
                            width,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '*Approval rate = approved / '
                    '(approved + rejected). '
                    'Pending and resubmission records '
                    'are excluded from this rate.',
                    style: TextStyle(fontSize: 11, color: _muted),
                  ),
                  const SizedBox(height: 25),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 850;
                      final width = wide
                          ? (constraints.maxWidth - 18) / 2
                          : constraints.maxWidth;

                      return Wrap(
                        spacing: 18,
                        runSpacing: 18,
                        children: [
                          SizedBox(width: width, child: _breakdown(records)),
                          SizedBox(
                            width: width,
                            child: _summary(
                              total,
                              approved,
                              pending,
                              rejected,
                              resubmission,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _monthlyTable(records),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CF),
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFF92650D)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'DEVELOPMENT PREVIEW — All reporting data '
              'is fictional and independent of the other '
              'demo pages. No actual resident records '
              'or Supabase analytics are accessed.',
              style: TextStyle(
                color: Color(0xFF73550E),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(19),
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 26, color: _green),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: _forest,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _breakdown(List<_ReportRecord> records) {
    return _card('Application Status Breakdown', [
      const Text(
        'Distribution of fictional applications '
        'in the selected reporting period.',
        style: TextStyle(color: _muted, fontSize: 12),
      ),
      const SizedBox(height: 22),
      for (final status in _statuses) ...[
        Row(
          children: [
            Expanded(
              child: Text(
                status,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${_count(records, status)}',
              style: const TextStyle(
                color: _forest,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: records.isEmpty ? 0 : _count(records, status) / records.length,
          minHeight: 10,
          borderRadius: BorderRadius.circular(10),
          backgroundColor: _soft,
          color: status == 'Approved'
              ? _green
              : status == 'Rejected'
              ? const Color(0xFFB95757)
              : status == 'Pending'
              ? _gold
              : const Color(0xFF75A7A0),
        ),
        const SizedBox(height: 20),
      ],
    ]);
  }

  Widget _summary(
    int total,
    int approved,
    int pending,
    int rejected,
    int resubmission,
  ) {
    return _card('Verification Performance Summary', [
      _summaryRow('Applications received', '$total'),
      const Divider(color: _stroke),
      _summaryRow('Approved', '$approved'),
      const Divider(color: _stroke),
      _summaryRow('Awaiting review', '$pending'),
      const Divider(color: _stroke),
      _summaryRow('Rejected', '$rejected'),
      const Divider(color: _stroke),
      _summaryRow('Resubmission requested', '$resubmission'),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _soft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          children: [
            Icon(Icons.insights_rounded, color: _green),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'These indicators demonstrate the '
                'planned reporting interface only. '
                'They do not represent LGU performance.',
                style: TextStyle(color: _forest, fontSize: 12, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: _muted, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: _forest,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthlyTable(List<_ReportRecord> records) {
    return _card('Monthly Verification Activity', [
      const Text(
        'Sample application totals by month.',
        style: TextStyle(color: _muted, fontSize: 12),
      ),
      const SizedBox(height: 15),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(_soft),
          columns: const [
            DataColumn(label: Text('PERIOD')),
            DataColumn(label: Text('APPLICATIONS')),
            DataColumn(label: Text('APPROVED')),
            DataColumn(label: Text('REJECTED')),
            DataColumn(label: Text('AWAITING REVIEW')),
          ],
          rows: [
            for (final month in _months)
              if (records.any((r) => r.period == month))
                DataRow(
                  cells: [
                    DataCell(Text(month)),
                    DataCell(
                      Text('${records.where((r) => r.period == month).length}'),
                    ),
                    DataCell(
                      Text(
                        '${_count(records.where((r) => r.period == month).toList(), 'Approved')}',
                      ),
                    ),
                    DataCell(
                      Text(
                        '${_count(records.where((r) => r.period == month).toList(), 'Rejected')}',
                      ),
                    ),
                    DataCell(
                      Text(
                        '${records.where((r) => r.period == month && (r.status == 'Pending' || r.status == 'Under Review')).length}',
                      ),
                    ),
                  ],
                ),
          ],
        ),
      ),
    ]);
  }

  Widget _card(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 17),
          ...children,
        ],
      ),
    );
  }

  BoxDecoration _surface() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: _stroke),
    boxShadow: const [
      BoxShadow(color: Color(0x0A00492C), blurRadius: 24, offset: Offset(0, 8)),
    ],
  );
}

class _ReportRecord {
  final String id;
  final String period;
  final String status;

  const _ReportRecord(this.id, this.period, this.status);
}
