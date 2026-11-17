import 'package:flutter/material.dart';

const _forest = Color(0xFF00492C);
const _green = Color(0xFF2A7F57);
const _paper = Color(0xFFF4F4F0);
const _ink = Color(0xFF0E3A27);
const _muted = Color(0xFF6E7773);
const _stroke = Color(0xFFECECE6);
const _soft = Color(0xFFE3F1E9);

class ReviewHistoryPage extends StatefulWidget {
  const ReviewHistoryPage({super.key});

  @override
  State<ReviewHistoryPage> createState() => _ReviewHistoryPageState();
}

class _ReviewHistoryPageState extends State<ReviewHistoryPage> {
  String _search = '';
  String _decisionFilter = 'All';

  // Fictional review history for development only.
  static const _reviews = <_DemoReview>[
    _DemoReview(
      id: 'REV-DEMO-001',
      applicationId: 'VER-DEMO-004',
      applicant: 'Demo Resident D',
      decision: 'Approved',
      reviewer: 'Demo Verification Admin',
      date: 'Nov 15, 2026 · 03:20 PM',
      notes:
          'Sample identity details were reviewed and '
          'marked complete for the prototype.',
    ),
    _DemoReview(
      id: 'REV-DEMO-002',
      applicationId: 'VER-DEMO-005',
      applicant: 'Demo Resident E',
      decision: 'Resubmission Requested',
      reviewer: 'Demo Verification Admin',
      date: 'Nov 14, 2026 · 10:45 AM',
      notes:
          'Sample document is incomplete. '
          'A clearer replacement is requested.',
    ),
    _DemoReview(
      id: 'REV-DEMO-003',
      applicationId: 'VER-DEMO-006',
      applicant: 'Demo Resident F',
      decision: 'Rejected',
      reviewer: 'Demo Verification Admin',
      date: 'Nov 13, 2026 · 02:15 PM',
      notes:
          'Sample application did not satisfy '
          'the illustrative verification requirements.',
    ),
    _DemoReview(
      id: 'REV-DEMO-004',
      applicationId: 'VER-DEMO-007',
      applicant: 'Demo Resident G',
      decision: 'Approved',
      reviewer: 'Demo Verification Admin',
      date: 'Nov 12, 2026 · 09:30 AM',
      notes: 'Sample verification checklist completed.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final query = _search.trim().toLowerCase();

    final filtered = _reviews.where((review) {
      final matchesSearch =
          review.applicant.toLowerCase().contains(query) ||
          review.applicationId.toLowerCase().contains(query) ||
          review.id.toLowerCase().contains(query) ||
          review.reviewer.toLowerCase().contains(query);

      final matchesDecision =
          _decisionFilter == 'All' || review.decision == _decisionFilter;

      return matchesSearch && matchesDecision;
    }).toList();

    final approved = _reviews.where((r) => r.decision == 'Approved').length;

    final rejected = _reviews.where((r) => r.decision == 'Rejected').length;

    final resubmission = _reviews
        .where((r) => r.decision == 'Resubmission Requested')
        .length;

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
                    'Review History',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: _ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 29,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Review historical identity verification '
                    'decisions and reviewer notes.',
                    style: TextStyle(color: _muted, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  _notice(),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 750 ? 3 : 1;
                      const gap = 12.0;
                      final width =
                          (constraints.maxWidth - gap * (columns - 1)) /
                          columns;

                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          _statCard(
                            'Demo Approved',
                            '$approved',
                            Icons.verified_user_outlined,
                            width,
                          ),
                          _statCard(
                            'Demo Rejected',
                            '$rejected',
                            Icons.cancel_outlined,
                            width,
                          ),
                          _statCard(
                            'Demo Resubmissions',
                            '$resubmission',
                            Icons.refresh_rounded,
                            width,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 25),
                  _historyTable(filtered),
                  const SizedBox(height: 18),
                  const Text(
                    'These are fictional review records. '
                    'Live reviewer histories will require '
                    'an authorized audit trail and '
                    'backend-enforced access control.',
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
          Icon(Icons.info_outline_rounded, color: Color(0xFF92650D)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'DEVELOPMENT PREVIEW — Review records '
              'are fictional. Decisions from Identity '
              'Review are not yet synchronized here.',
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

  Widget _statCard(String label, String value, IconData icon, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(19),
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
              fontSize: 29,
              fontWeight: FontWeight.w700,
              color: _forest,
            ),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _historyTable(List<_DemoReview> filtered) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verification Decision Records',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Search or filter completed demo reviews.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 310,
                child: TextField(
                  onChanged: (value) => setState(() => _search = value),
                  decoration: const InputDecoration(
                    hintText: 'Search name, ID, or reviewer',
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
                width: 225,
                child: DropdownButtonFormField<String>(
                  initialValue: _decisionFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Decision',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: _stroke),
                    ),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(
                      value: 'Approved',
                      child: Text('Approved'),
                    ),
                    DropdownMenuItem(
                      value: 'Rejected',
                      child: Text('Rejected'),
                    ),
                    DropdownMenuItem(
                      value: 'Resubmission Requested',
                      child: Text('Resubmission Requested'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _decisionFilter = value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Text(
            'Showing ${filtered.length} of '
            '${_reviews.length} demo reviews',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(
                child: Text(
                  'No review records match your filters.',
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
                  DataColumn(label: Text('REVIEW ID')),
                  DataColumn(label: Text('APPLICATION ID')),
                  DataColumn(label: Text('APPLICANT')),
                  DataColumn(label: Text('DECISION')),
                  DataColumn(label: Text('REVIEWED AT')),
                  DataColumn(label: Text('ACTION')),
                ],
                rows: [
                  for (final review in filtered)
                    DataRow(
                      cells: [
                        DataCell(Text(review.id)),
                        DataCell(Text(review.applicationId)),
                        DataCell(Text(review.applicant)),
                        DataCell(_decisionChip(review.decision)),
                        DataCell(Text(review.date)),
                        DataCell(
                          TextButton.icon(
                            onPressed: () => _showDetails(review),
                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 17,
                            ),
                            label: const Text('View Details'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _decisionChip(String decision) {
    final Color textColor;
    final Color background;

    switch (decision) {
      case 'Approved':
        textColor = _green;
        background = _soft;
        break;
      case 'Rejected':
        textColor = const Color(0xFF9B2C2C);
        background = const Color(0xFFFFE9E9);
        break;
      default:
        textColor = const Color(0xFF92650D);
        background = const Color(0xFFFFF4D9);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        decision,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showDetails(_DemoReview review) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Verification Review Details'),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fictional review record',
                  style: TextStyle(color: _green, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 18),
                _detail('Review ID', review.id),
                _detail('Application ID', review.applicationId),
                _detail('Applicant', review.applicant),
                _detail('Decision', review.decision),
                _detail('Reviewer', review.reviewer),
                _detail('Reviewed At', review.date),
                const Divider(height: 28),
                const Text(
                  'Reviewer Notes',
                  style: TextStyle(color: _ink, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  review.notes,
                  style: const TextStyle(color: _muted, height: 1.5),
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
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
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
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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

class _DemoReview {
  final String id;
  final String applicationId;
  final String applicant;
  final String decision;
  final String reviewer;
  final String date;
  final String notes;

  const _DemoReview({
    required this.id,
    required this.applicationId,
    required this.applicant,
    required this.decision,
    required this.reviewer,
    required this.date,
    required this.notes,
  });
}
