import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

const _forest = Color(0xFF00492C);
const _green = Color(0xFF2A7F57);
const _paper = Color(0xFFF4F4F0);
const _ink = Color(0xFF0E3A27);
const _muted = Color(0xFF6E7773);
const _stroke = Color(0xFFECECE6);
const _soft = Color(0xFFE3F1E9);

class VerificationDashboardPage extends StatelessWidget {
  const VerificationDashboardPage({super.key});

  // Fictional applicants for frontend development only.
  static const _applications = <_DemoApplication>[
    _DemoApplication(
      'VER-DEMO-001',
      'Demo Resident A',
      'Pending',
      'Nov 16, 2026',
    ),
    _DemoApplication(
      'VER-DEMO-002',
      'Demo Resident B',
      'Under Review',
      'Nov 16, 2026',
    ),
    _DemoApplication(
      'VER-DEMO-003',
      'Demo Resident C',
      'Pending',
      'Nov 15, 2026',
    ),
    _DemoApplication(
      'VER-DEMO-004',
      'Demo Resident D',
      'Approved',
      'Nov 15, 2026',
    ),
    _DemoApplication(
      'VER-DEMO-005',
      'Demo Resident E',
      'Resubmission Requested',
      'Nov 14, 2026',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pending = _applications.where((a) => a.status == 'Pending').length;

    final reviewing = _applications
        .where((a) => a.status == 'Under Review')
        .length;

    final approved = _applications.where((a) => a.status == 'Approved').length;

    final needsAction = _applications
        .where((a) => a.status == 'Pending' || a.status == 'Under Review')
        .toList();

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
                    'Verification Dashboard',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: _ink,
                      fontSize: 29,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Monitor resident identity verification '
                    'applications and review workload.',
                    style: TextStyle(color: _muted, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  _notice(),
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
                            'Total Applications',
                            '${_applications.length}',
                            Icons.description_outlined,
                            width,
                          ),
                          _metric(
                            'Pending Review',
                            '$pending',
                            Icons.pending_actions_outlined,
                            width,
                          ),
                          _metric(
                            'Under Review',
                            '$reviewing',
                            Icons.fact_check_outlined,
                            width,
                          ),
                          _metric(
                            'Approved',
                            '$approved',
                            Icons.verified_user_outlined,
                            width,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 25),
                  _reviewQueue(context, needsAction),
                  const SizedBox(height: 25),
                  _workflowInfo(),
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
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'DEVELOPMENT PREVIEW — All resident '
              'applications and verification statistics '
              'are fictional. No real identity data '
              'is being accessed.',
              style: TextStyle(color: Color(0xFF73550E), fontSize: 12),
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
              color: _forest,
              fontSize: 29,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _reviewQueue(
    BuildContext context,
    List<_DemoApplication> applications,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Applications Requiring Review',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: _ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  context.go('/lgu-admin/verification/applications');
                },

                icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                label: const Text('View Queue'),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            'Sample Tier 2 applications awaiting action.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(_soft),
              columns: const [
                DataColumn(label: Text('APPLICATION ID')),
                DataColumn(label: Text('APPLICANT')),
                DataColumn(label: Text('DATE SUBMITTED')),
                DataColumn(label: Text('STATUS')),
              ],
              rows: [
                for (final app in applications)
                  DataRow(
                    cells: [
                      DataCell(Text(app.id)),
                      DataCell(Text(app.name)),
                      DataCell(Text(app.date)),
                      DataCell(_statusChip(app.status)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final color = status == 'Pending' ? const Color(0xFF94650D) : _green;

    final background = status == 'Pending' ? const Color(0xFFFFF5DA) : _soft;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _workflowInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _surface(),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Planned Verification Workflow',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 15),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _WorkflowStep('1. Application Submitted'),
              _WorkflowStep('2. Identity Review'),
              _WorkflowStep('3. Verification Decision'),
              _WorkflowStep('4. Resident Notified'),
            ],
          ),
          SizedBox(height: 13),
          Text(
            'Possible review outcomes: Approved, '
            'Rejected, or Resubmission Requested. '
            'Actual document requirements and approval '
            'rules must be confirmed before backend '
            'integration.',
            style: TextStyle(color: _muted, fontSize: 12, height: 1.6),
          ),
        ],
      ),
    );
  }

  BoxDecoration _surface() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _stroke),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A00492C),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ],
    );
  }
}

class _WorkflowStep extends StatelessWidget {
  final String text;

  const _WorkflowStep(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: _soft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _forest,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _DemoApplication {
  final String id;
  final String name;
  final String status;
  final String date;

  const _DemoApplication(this.id, this.name, this.status, this.date);
}
