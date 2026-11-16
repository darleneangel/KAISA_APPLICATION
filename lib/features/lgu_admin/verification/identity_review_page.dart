
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _forest = Color(0xFF14532D);
const _green = Color(0xFF237A50);
const _paper = Color(0xFFF8FAF8);
const _ink = Color(0xFF173D2B);
const _muted = Color(0xFF687B70);
const _stroke = Color(0xFFE2EBE4);
const _soft = Color(0xFFEAF5EE);

class IdentityReviewPage extends StatefulWidget {
  final String applicationId;

  const IdentityReviewPage({
    super.key,
    required this.applicationId,
  });

  @override
  State<IdentityReviewPage> createState() =>
      _IdentityReviewPageState();
}

class _IdentityReviewPageState extends State<IdentityReviewPage> {
  final _notesController = TextEditingController();

  final Set<int> _checked = {};
  String? _previewDecision;

  static const _requirements = [
    'Submitted identity information is readable',
    'Applicant details are consistent',
    'Document appears complete for review',
  ];

  // Demo records matching the Pending Applications page.
  static const _applications = <String, _DemoApplicant>{
    'VER-DEMO-001': _DemoApplicant(
      'Demo Resident A',
      'Pending',
      'High',
      'Tier 1',
      'Nov 16, 2026',
    ),
    'VER-DEMO-002': _DemoApplicant(
      'Demo Resident B',
      'Under Review',
      'Normal',
      'Tier 1',
      'Nov 16, 2026',
    ),
    'VER-DEMO-003': _DemoApplicant(
      'Demo Resident C',
      'Pending',
      'Normal',
      'Tier 1',
      'Nov 15, 2026',
    ),
    'VER-DEMO-004': _DemoApplicant(
      'Demo Resident D',
      'Approved',
      'Normal',
      'Tier 2',
      'Nov 15, 2026',
    ),
    'VER-DEMO-005': _DemoApplicant(
      'Demo Resident E',
      'Resubmission Requested',
      'High',
      'Tier 1',
      'Nov 14, 2026',
    ),
  };

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _review(String decision) async {
    if (decision == 'Approved' &&
        _checked.length != _requirements.length) {
      _message('Complete all review checklist items first.');
      return;
    }

    if (decision != 'Approved' &&
        _notesController.text.trim().isEmpty) {
      _message('Enter a review reason before proceeding.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Preview: $decision'),
        content: Text(
          'Simulate "$decision" for '
          '${widget.applicationId}?\n\n'
          'This is a local UI preview. No real application '
          'status, account tier, or database record '
          'will be changed.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('Confirm Preview'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    setState(() {
      _previewDecision = decision;
    });

    _message(
      'Demo decision recorded on this page only: $decision',
    );
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final applicant = _applications[widget.applicationId];

    if (applicant == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 44),
            const SizedBox(height: 12),
            const Text('Demo application not found.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(
                '/lgu-admin/verification/applications',
              ),
              child: const Text('Back to Applications'),
            ),
          ],
        ),
      );
    }

    final status = _previewDecision ?? applicant.status;

    return ColoredBox(
      color: _paper,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: 1260),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: () => context.go(
                      '/lgu-admin/verification/applications',
                    ),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                    ),
                    label: const Text(
                      'Back to Pending Applications',
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'KAISA / LGU ADMINISTRATION / VERIFICATION',
                    style: TextStyle(
                      color: _green,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Identity Review',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 29,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Application ${widget.applicationId}',
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _notice(),
                  const SizedBox(height: 23),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide =
                          constraints.maxWidth >= 900;
                      final sectionWidth = wide
                          ? (constraints.maxWidth - 18) / 2
                          : constraints.maxWidth;

                      return Wrap(
                        spacing: 18,
                        runSpacing: 18,
                        children: [
                          SizedBox(
                            width: sectionWidth,
                            child: Column(
                              children: [
                                _applicantCard(
                                  applicant,
                                  status,
                                ),
                                const SizedBox(height: 18),
                                _documentCard(),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: sectionWidth,
                            child: Column(
                              children: [
                                _checklistCard(),
                                const SizedBox(height: 18),
                                _decisionCard(
                                  applicant,
                                  status,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notice() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8DE),
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Color(0xFF92650D),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'DEVELOPMENT PREVIEW — Applicant information '
                'and document placeholders are fictional. '
                'Review decisions do not change Supabase data.',
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

  Widget _applicantCard(
    _DemoApplicant applicant,
    String status,
  ) {
    return _card(
      'Applicant Information',
      Icons.person_outline_rounded,
      [
        _detail('Applicant', applicant.name),
        _detail('Application ID', widget.applicationId),
        _detail('Current Tier', applicant.tier),
        _detail('Submitted', applicant.date),
        _detail('Priority', applicant.priority),
        _detail('Review Status', status),
        if (_previewDecision != null)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Status shown above is a temporary preview '
              'and will reset when this page is reopened.',
              style: TextStyle(
                color: _muted,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }

  Widget _documentCard() {
    return _card(
      'Identity Documents',
      Icons.badge_outlined,
      [
        const Text(
          'Document preview placeholders',
          style: TextStyle(
            color: _muted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns =
                constraints.maxWidth >= 360 ? 2 : 1;
            final width =
                (constraints.maxWidth -
                    10 * (columns - 1)) / columns;

            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _documentPlaceholder(
                  'ID Front',
                  Icons.credit_card_rounded,
                  width,
                ),
                _documentPlaceholder(
                  'ID Back',
                  Icons.badge_outlined,
                  width,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 15),
        const Text(
          'No actual ID images are loaded. Approved '
          'document types and secure access requirements '
          'must be confirmed before backend integration.',
          style: TextStyle(
            color: _muted,
            fontSize: 12,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _documentPlaceholder(
    String title,
    IconData icon,
    double width,
  ) {
    return Container(
      width: width,
      height: 160,
      decoration: BoxDecoration(
        color: _soft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _stroke),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: _green),
          const SizedBox(height: 11),
          Text(
            title,
            style: const TextStyle(
              color: _forest,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Demo placeholder',
            style: TextStyle(
              color: _muted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _checklistCard() {
    return _card(
      'Verification Checklist',
      Icons.fact_check_outlined,
      [
        const Text(
          'Illustrative checks only. Mark each item '
          'after completing your demo review.',
          style: TextStyle(
            color: _muted,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        LinearProgressIndicator(
          value: _checked.length / _requirements.length,
          minHeight: 7,
          color: _green,
          backgroundColor: _soft,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 10),
        Text(
          '${_checked.length} of '
          '${_requirements.length} checks selected',
          style: const TextStyle(
            color: _muted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < _requirements.length; i++)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity:
                ListTileControlAffinity.leading,
            activeColor: _green,
            value: _checked.contains(i),
            title: Text(
              _requirements[i],
              style: const TextStyle(
                color: _ink,
                fontSize: 13,
              ),
            ),
            onChanged: (selected) {
              setState(() {
                if (selected == true) {
                  _checked.add(i);
                } else {
                  _checked.remove(i);
                }
              });
            },
          ),
      ],
    );
  }

  Widget _decisionCard(
    _DemoApplicant applicant,
    String status,
  ) {
    final closed = applicant.status == 'Approved';
    final previewCompleted = _previewDecision != null;

    return _card(
      'Verification Decision',
      Icons.verified_user_outlined,
      [
        Text(
          'Current display status: $status',
          style: const TextStyle(
            color: _forest,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _notesController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Review Notes',
            hintText:
                'Explain your findings or required corrections...',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Notes are not saved. A reason is required '
          'for demo rejection and resubmission requests.',
          style: TextStyle(
            color: _muted,
            fontSize: 11,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: closed || previewCompleted
                  ? null
                  : () => _review('Approved'),
              style: FilledButton.styleFrom(
                backgroundColor: _forest,
              ),
              icon: const Icon(
                Icons.check_circle_outline,
                size: 18,
              ),
              label: const Text('Approve'),
            ),
            OutlinedButton.icon(
              onPressed: closed || previewCompleted
                  ? null
                  : () => _review('Resubmission Requested'),
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
              ),
              label: const Text('Request Resubmission'),
            ),
            OutlinedButton.icon(
              onPressed: closed || previewCompleted
                  ? null
                  : () => _review('Rejected'),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    const Color(0xFF9B2C2C),
              ),
              icon: const Icon(
                Icons.cancel_outlined,
                size: 18,
              ),
              label: const Text('Reject'),
            ),
          ],
        ),
        if (closed) ...[
          const SizedBox(height: 13),
          const Text(
            'This fictional application is already '
            'approved. Actions are disabled.',
            style: TextStyle(
              color: _muted,
              fontSize: 12,
            ),
          ),
        ],
        if (previewCompleted) ...[
          const SizedBox(height: 13),
          const Text(
            'Demo decision completed. Reopen the page '
            'to reset this local preview.',
            style: TextStyle(
              color: _green,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _ink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _green, size: 23),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

class _DemoApplicant {
  final String name;
  final String status;
  final String priority;
  final String tier;
  final String date;

  const _DemoApplicant(
    this.name,
    this.status,
    this.priority,
    this.tier,
    this.date,
  );
}
