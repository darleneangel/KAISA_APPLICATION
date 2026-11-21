import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

// KAISA LGU Verification — dashboard-only prototype.
// All records and charts below are fictional and stored in this widget.
// No Supabase verification decisions, identity documents or user roles are changed.
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

enum _VerificationType { resident, organization }

enum _VerificationStatus {
  pending,
  reviewing,
  approved,
  rejected,
  resubmission,
}

class _VerificationApplication {
  const _VerificationApplication({
    required this.id,
    required this.name,
    required this.platform,
    required this.type,
    required this.status,
    required this.submitted,
    required this.description,
    required this.priority,
  });

  final String id;
  final String name;
  final String platform;
  final _VerificationType type;
  final _VerificationStatus status;
  final DateTime submitted;
  final String description;
  final String priority;

  String get typeLabel => type == _VerificationType.resident
      ? 'Resident Tier 2'
      : 'Org Accreditation';

  String get statusLabel => switch (status) {
    _VerificationStatus.pending => 'Pending',
    _VerificationStatus.reviewing => 'Under Review',
    _VerificationStatus.approved => 'Approved',
    _VerificationStatus.rejected => 'Rejected',
    _VerificationStatus.resubmission => 'Resubmission',
  };
}

class VerificationDashboardPage extends StatefulWidget {
  const VerificationDashboardPage({super.key});

  @override
  State<VerificationDashboardPage> createState() =>
      _VerificationDashboardPageState();
}

class _VerificationDashboardPageState extends State<VerificationDashboardPage> {
  final _search = TextEditingController();
  String _type = 'All';
  String _status = 'Needs Action';
  String _sort = 'Newest';
  String _metric = 'Applications';
  int _trendSelected = 5;
  int _donutSelected = 0;
  String? _platformSelected;
  int _visibleRows = 6;

  // Reuses the five original demonstration residents and adds fictional
  // organization accreditation examples so both verification responsibilities
  // can be demonstrated. Dates and counts are NOT LGU statistics.
  static final _cases = <_VerificationApplication>[
    _VerificationApplication(
      id: 'VER-DEMO-001',
      name: 'Demo Resident A',
      platform: 'Web',
      type: _VerificationType.resident,
      status: _VerificationStatus.pending,
      submitted: DateTime(2026, 11, 16, 9, 10),
      description: 'Tier 1 → Tier 2 identity verification',
      priority: 'High',
    ),
    _VerificationApplication(
      id: 'VER-DEMO-002',
      name: 'Demo Resident B',
      platform: 'Mobile',
      type: _VerificationType.resident,
      status: _VerificationStatus.reviewing,
      submitted: DateTime(2026, 11, 16, 10, 20),
      description: 'Supporting identity-evidence review',
      priority: 'Normal',
    ),
    _VerificationApplication(
      id: 'VER-DEMO-003',
      name: 'Demo Resident C',
      platform: 'Mobile',
      type: _VerificationType.resident,
      status: _VerificationStatus.pending,
      submitted: DateTime(2026, 11, 15, 8, 25),
      description: 'Tier 1 → Tier 2 identity verification',
      priority: 'Normal',
    ),
    _VerificationApplication(
      id: 'VER-DEMO-004',
      name: 'Demo Resident D',
      platform: 'Web',
      type: _VerificationType.resident,
      status: _VerificationStatus.approved,
      submitted: DateTime(2026, 11, 15, 11, 30),
      description: 'Completed demonstration application',
      priority: 'Normal',
    ),
    _VerificationApplication(
      id: 'VER-DEMO-005',
      name: 'Demo Resident E',
      platform: 'Mobile',
      type: _VerificationType.resident,
      status: _VerificationStatus.resubmission,
      submitted: DateTime(2026, 11, 14, 15, 5),
      description: 'Clearer identity document requested',
      priority: 'High',
    ),
    _VerificationApplication(
      id: 'ORG-DEMO-001',
      name: 'Demo Youth Association',
      platform: 'Mobile',
      type: _VerificationType.organization,
      status: _VerificationStatus.pending,
      submitted: DateTime(2026, 11, 16, 9, 40),
      description: 'Accreditation and representative authorization',
      priority: 'High',
    ),
    _VerificationApplication(
      id: 'ORG-DEMO-002',
      name: 'Demo Civic Volunteers',
      platform: 'Web',
      type: _VerificationType.organization,
      status: _VerificationStatus.reviewing,
      submitted: DateTime(2026, 11, 13, 14, 5),
      description: 'By-laws and officer roster review',
      priority: 'Normal',
    ),
    _VerificationApplication(
      id: 'ORG-DEMO-003',
      name: 'Demo Neighborhood Network',
      platform: 'Web',
      type: _VerificationType.organization,
      status: _VerificationStatus.approved,
      submitted: DateTime(2026, 11, 12, 13, 15),
      description: 'Completed demonstration accreditation',
      priority: 'Normal',
    ),
    _VerificationApplication(
      id: 'VER-DEMO-006',
      name: 'Demo Resident F',
      platform: 'Web',
      type: _VerificationType.resident,
      status: _VerificationStatus.rejected,
      submitted: DateTime(2026, 11, 10, 9, 5),
      description: 'Demonstration rejection; review reasons not recorded here',
      priority: 'Normal',
    ),
    _VerificationApplication(
      id: 'VER-DEMO-007',
      name: 'Demo Resident G',
      platform: 'Web',
      type: _VerificationType.resident,
      status: _VerificationStatus.approved,
      submitted: DateTime(2026, 11, 9, 11, 45),
      description: 'Completed demonstration application',
      priority: 'Normal',
    ),
  ];

  // Separate, explicitly simulated monthly trend to demonstrate how a future
  // real verification analytics API would present time-series results.
  static const _monthNames = ['Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov'];
  static const List<double> _trendApplications = [14, 18, 16, 22, 27, 31];
  static const List<double> _trendApprovals = [7, 11, 10, 14, 18, 21];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  int _count(_VerificationStatus s) =>
      _cases.where((c) => c.status == s).length;
  bool _needsAction(_VerificationApplication c) =>
      c.status == _VerificationStatus.pending ||
      c.status == _VerificationStatus.reviewing ||
      c.status == _VerificationStatus.resubmission;

  List<_VerificationApplication> get _filtered {
    final q = _search.text.trim().toLowerCase();
    final results = _cases.where((c) {
      final typeMatch = _type == 'All' || c.typeLabel == _type;
      final statusMatch =
          _status == 'All' ||
          (_status == 'Needs Action' && _needsAction(c)) ||
          c.statusLabel == _status;
      final queryMatch =
          q.isEmpty ||
          '${c.id} ${c.name} ${c.platform} ${c.description} ${c.statusLabel}'
              .toLowerCase()
              .contains(q);
      return typeMatch && statusMatch && queryMatch;
    }).toList();
    results.sort(
      (a, b) => _sort == 'Oldest'
          ? a.submitted.compareTo(b.submitted)
          : b.submitted.compareTo(a.submitted),
    );
    return results;
  }

  String _date(DateTime d) {
    const names = [
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
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '${names[d.month - 1]} ${d.day}, ${d.year} · $hour:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  Color _statusColor(_VerificationStatus s) => switch (s) {
    _VerificationStatus.approved => _green,
    _VerificationStatus.rejected => _red,
    _VerificationStatus.reviewing => _blue,
    _VerificationStatus.resubmission => _amber,
    _VerificationStatus.pending => _amber,
  };

  BoxDecoration _surface({double radius = 19}) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: _stroke),
    boxShadow: const [
      BoxShadow(color: Color(0x0800492C), blurRadius: 20, offset: Offset(0, 5)),
    ],
  );

  Widget _card(
    Widget child, {
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
  }) => Container(padding: padding, decoration: _surface(), child: child);

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .11),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
    ),
  );

  Widget _header(bool compact) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(compact ? 22 : 30),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        colors: [_deep, _forest, Color(0xFF258357)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Wrap(
      spacing: 20,
      runSpacing: 18,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'KAISA  /  LGU VERIFICATION',
                style: TextStyle(
                  color: _gold,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Verification Command Center',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.8,
                  fontSize: compact ? 27 : 34,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Review identity-verification requests from the wider KAISA community, organization accreditation, and verification workload in one protected workspace.',
                style: TextStyle(
                  color: Color(0xFFE0EFE5),
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: () => context.go('/lgu-admin/verification/applications'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: _forest,
            padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 15),
          ),
          icon: const Icon(Icons.fact_check_outlined, size: 18),
          label: const Text(
            'Open Review Queue',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );

  Widget _notice() => Container(
    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7E7),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFFF4E2B8)),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.science_outlined, color: _amber, size: 19),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'PROTOTYPE ANALYTICS — All applications, monthly trends, approval counts and organization names are fictional. No real Supabase verification records or private identity documents are accessed.',
            style: TextStyle(
              color: Color(0xFF836013),
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _section(String heading, String description, {Widget? action}) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 12,
    runSpacing: 7,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ),
      ?action,
    ],
  );

  Widget _metricCard(
    String name,
    String count,
    String context,
    IconData icon, {
    Color color = _forest,
  }) => Tooltip(
    message:
        '$name: $count. $context. Fictional sample figures; no live verification data.',
    child: _card(
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _mint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: const TextStyle(
                    color: _forest,
                    fontWeight: FontWeight.w900,
                    fontSize: 27,
                  ),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  context,
                  style: const TextStyle(color: _muted, fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _metricGrid() => LayoutBuilder(
    builder: (context, bounds) {
      final cols = bounds.maxWidth >= 1000
          ? 4
          : bounds.maxWidth >= 590
          ? 2
          : 1;
      const gap = 12.0;
      final w = (bounds.maxWidth - gap * (cols - 1)) / cols;
      final pending = _count(_VerificationStatus.pending);
      final review = _count(_VerificationStatus.reviewing);
      final resubmit = _count(_VerificationStatus.resubmission);
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          SizedBox(
            width: w,
            child: _metricCard(
              'Total applications',
              '${_cases.length}',
              'Resident and organization',
              Icons.folder_open_rounded,
            ),
          ),
          SizedBox(
            width: w,
            child: _metricCard(
              'Needs action',
              '${pending + review + resubmit}',
              '$pending pending · $review reviewing · $resubmit resubmission',
              Icons.pending_actions_rounded,
              color: _amber,
            ),
          ),
          SizedBox(
            width: w,
            child: _metricCard(
              'Resident Tier 2',
              '${_cases.where((c) => c.type == _VerificationType.resident).length}',
              'Identity verification requests',
              Icons.verified_user_outlined,
            ),
          ),
          SizedBox(
            width: w,
            child: _metricCard(
              'Org accreditation',
              '${_cases.where((c) => c.type == _VerificationType.organization).length}',
              'Legitimacy and representative',
              Icons.apartment_rounded,
            ),
          ),
        ],
      );
    },
  );

  Widget _actionLinks() => LayoutBuilder(
    builder: (context, bounds) {
      final columns = bounds.maxWidth >= 740
          ? 3
          : bounds.maxWidth >= 440
          ? 2
          : 1;
      const gap = 10.0;
      final width = (bounds.maxWidth - gap * (columns - 1)) / columns;
      final actions =
          <({String title, String detail, IconData icon, VoidCallback tap})>[
            (
              title: 'Resident verification',
              detail: 'Review Tier 2 submissions',
              icon: Icons.person_search_rounded,
              tap: () {
                setState(() {
                  _type = 'Resident Tier 2';
                  _status = 'Needs Action';
                  _visibleRows = 6;
                });
              },
            ),
            (
              title: 'Organization vetting',
              detail: 'Inspect accreditation queue',
              icon: Icons.domain_verification_outlined,
              tap: () {
                setState(() {
                  _type = 'Org Accreditation';
                  _status = 'Needs Action';
                  _visibleRows = 6;
                });
              },
            ),
            (
              title: 'All applications',
              detail: 'Open detailed review module',
              icon: Icons.open_in_new_rounded,
              tap: () => context.go('/lgu-admin/verification/applications'),
            ),
          ];
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final a in actions)
            SizedBox(
              width: width,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                child: InkWell(
                  onTap: a.tap,
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      border: Border.all(color: _stroke),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Icon(a.icon, color: _forest, size: 21),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: _ink,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                a.detail,
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: _muted,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );

  Widget _trendChart() {
    final vals = _metric == 'Applications'
        ? _trendApplications
        : _trendApprovals;
    final peak = (vals.reduce((a, b) => a > b ? a : b) * 1.14)
        .clamp(1.0, double.infinity)
        .toDouble();
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly verification activity',
            style: TextStyle(
              color: _ink,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Simulated six-month trend · hover or tap a point',
            style: TextStyle(color: _muted, fontSize: 11),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'Applications',
                    label: Text('Submitted'),
                  ),
                  ButtonSegment(value: 'Approvals', label: Text('Approved')),
                ],
                selected: {_metric},
                showSelectedIcon: false,
                onSelectionChanged: (selection) => setState(() {
                  _metric = selection.first;
                  _trendSelected = 5;
                }),
              ),
              _badge(
                '${_monthNames[_trendSelected]} · ${vals[_trendSelected].toInt()} (demo)',
                _forest,
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 205,
            child: LayoutBuilder(
              builder: (context, bounds) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 34,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final tick in [peak, peak / 2, 0.0])
                            Text(
                              tick.toInt().toString(),
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: CustomPaint(
                        painter: _TrendPainter(
                          values: vals,
                          maxY: peak,
                          selected: _trendSelected,
                        ),
                        child: Row(
                          children: [
                            for (var i = 0; i < vals.length; i++)
                              Expanded(
                                child: Tooltip(
                                  message:
                                      '${_monthNames[i]} 2026 · ${vals[i].toInt()} ${_metric == 'Applications' ? 'submitted applications' : 'approved applications'} (simulated monthly trend). '
                                      'Month-on-month: ${i == 0 ? 'No preceding month' : '${vals[i] >= vals[i - 1] ? '+' : ''}${(vals[i] - vals[i - 1]).toInt()}'}',
                                  child: MouseRegion(
                                    onEnter: (_) =>
                                        setState(() => _trendSelected = i),
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () =>
                                          setState(() => _trendSelected = i),
                                      child: const SizedBox.expand(),
                                    ),
                                  ),
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
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 34),
            child: Row(
              children: [
                for (var i = 0; i < _monthNames.length; i++)
                  Expanded(
                    child: Text(
                      _monthNames[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: i == _trendSelected ? _forest : _muted,
                        fontWeight: i == _trendSelected
                            ? FontWeight.w800
                            : FontWeight.normal,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${_monthNames[_trendSelected]} 2026: ${vals[_trendSelected].toInt()} ${_metric == 'Applications' ? 'submissions' : 'approvals'} · simulated monthly values, not actual database statistics.',
            style: const TextStyle(
              color: _forest,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _outcomeChart() {
    final categories = [
      ('Pending', _count(_VerificationStatus.pending), _amber),
      ('Under Review', _count(_VerificationStatus.reviewing), _blue),
      ('Approved', _count(_VerificationStatus.approved), _green),
      ('Rejected', _count(_VerificationStatus.rejected), _red),
      (
        'Resubmission',
        _count(_VerificationStatus.resubmission),
        const Color(0xFFE8AF30),
      ),
    ];
    final total = categories.fold<int>(0, (v, e) => v + e.$2);
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Decision distribution',
            style: TextStyle(
              color: _ink,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Current fictional case statuses · select a legend item',
            style: TextStyle(color: _muted, fontSize: 11),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              height: 174,
              width: 174,
              child: CustomPaint(
                painter: _DonutPainter(
                  sections: categories.map((e) => (e.$2, e.$3)).toList(),
                  selected: _donutSelected,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${categories[_donutSelected].$2} · ${total == 0 ? '0' : (categories[_donutSelected].$2 * 100 / total).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: _forest,
                        ),
                      ),
                      Text(
                        categories[_donutSelected].$1,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          for (var i = 0; i < categories.length; i++)
            Tooltip(
              message:
                  '${categories[i].$1}: ${categories[i].$2} of $total cases (${total == 0 ? '0' : (categories[i].$2 * 100 / total).toStringAsFixed(0)}%). Click to inspect this status.',
              child: MouseRegion(
                onEnter: (_) => setState(() => _donutSelected = i),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _donutSelected = i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 6,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: categories[i].$3,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            categories[i].$1,
                            style: TextStyle(
                              fontSize: 12,
                              color: i == _donutSelected ? _ink : _muted,
                              fontWeight: i == _donutSelected
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '${categories[i].$2} · ${total == 0 ? '0' : (categories[i].$2 * 100 / total).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _platformChart() {
    final counts = <String, int>{};
    for (final item in _cases) {
      counts[item.platform] = (counts[item.platform] ?? 0) + 1;
    }
    final rows = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxCount = rows.isEmpty ? 1 : rows.first.value;
    final selected = _platformSelected == null
        ? null
        : counts[_platformSelected];
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Applications by submission platform',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: _ink,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Web and Mobile submissions · fictional demonstration data',
            style: TextStyle(color: _muted, fontSize: 11),
          ),
          const SizedBox(height: 16),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Tooltip(
                message:
                    '${row.key}: ${row.value} of ${_cases.length} applications (${(row.value * 100 / _cases.length).toStringAsFixed(0)}%). '
                    'Resident requests: ${_cases.where((c) => c.platform == row.key && c.type == _VerificationType.resident).length}; '
                    'organization requests: ${_cases.where((c) => c.platform == row.key && c.type == _VerificationType.organization).length}.',
                child: MouseRegion(
                  onEnter: (_) => setState(() => _platformSelected = row.key),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _platformSelected = row.key),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 74,
                          child: Text(
                            row.key,
                            style: TextStyle(
                              fontSize: 12,
                              color: row.key == _platformSelected
                                  ? _forest
                                  : _muted,
                              fontWeight: row.key == _platformSelected
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: row.value / maxCount,
                              minHeight: 14,
                              backgroundColor: _mint,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                row.key == _platformSelected ? _gold : _green,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${row.value} · ${(row.value * 100 / _cases.length).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (selected != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _mint,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                '$_platformSelected · $selected applications · ${(selected * 100 / _cases.length).toStringAsFixed(0)}% of all sample requests. '
                'Resident Tier 2: ${_cases.where((c) => c.platform == _platformSelected && c.type == _VerificationType.resident).length} · '
                'Organization accreditation: ${_cases.where((c) => c.platform == _platformSelected && c.type == _VerificationType.organization).length}.',
                style: const TextStyle(
                  color: _forest,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filters() => Wrap(
    spacing: 9,
    runSpacing: 10,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      SizedBox(
        width: 255,
        child: TextField(
          controller: _search,
          onChanged: (_) => setState(() => _visibleRows = 6),
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: _forest,
              size: 19,
            ),
            hintText: 'Search application, name or ID',
            hintStyle: const TextStyle(fontSize: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(11)),
          ),
        ),
      ),
      _selector(
        'Request type',
        _type,
        ['All', 'Resident Tier 2', 'Org Accreditation'],
        (v) => setState(() {
          _type = v;
          _visibleRows = 6;
        }),
      ),
      _selector(
        'Status',
        _status,
        [
          'All',
          'Needs Action',
          'Pending',
          'Under Review',
          'Approved',
          'Rejected',
          'Resubmission',
        ],
        (v) => setState(() {
          _status = v;
          _visibleRows = 6;
        }),
      ),
      _selector('Sort', _sort, [
        'Newest',
        'Oldest',
      ], (v) => setState(() => _sort = v)),
      TextButton.icon(
        onPressed: () => setState(() {
          _search.clear();
          _type = 'All';
          _status = 'Needs Action';
          _sort = 'Newest';
          _visibleRows = 6;
        }),
        icon: const Icon(Icons.restart_alt_rounded),
        label: const Text('Clear'),
      ),
    ],
  );

  Widget _selector(
    String label,
    String value,
    List<String> choices,
    ValueChanged<String> onChange,
  ) => SizedBox(
    width: 165,
    child: DropdownButtonFormField<String>(
      key: ValueKey('$label:$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(11)),
      ),
      items: [
        for (final c in choices)
          DropdownMenuItem(
            value: c,
            child: Text(
              c,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChange(v);
      },
    ),
  );

  void _inspect(_VerificationApplication item) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
        title: Row(
          children: [
            const Icon(Icons.fact_check_outlined, color: _forest),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.id,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detail('Applicant', item.name),
                _detail('Request', item.typeLabel),
                _detail('Submission platform', item.platform),
                _detail('Submitted', _date(item.submitted)),
                _detail('Status', item.statusLabel),
                _detail('Priority', item.priority),
                _detail('Purpose', item.description),
                const SizedBox(height: 10),
                const Text(
                  'Demo metadata only. Review submitted proof and record final decisions in the authorized Verification Review module.',
                  style: TextStyle(color: _muted, fontSize: 11, height: 1.4),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/lgu-admin/verification/applications');
            },
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('Open Queue'),
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
          width: 95,
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

  void _copyCsv() {
    String cell(String value) {
      // Spreadsheet formula-injection guard followed by RFC 4180 quoting.
      var clean = value.replaceAll(RegExp(r'[\r\n]+'), ' ').trim();
      if (RegExp(r'^[=+\-@]').hasMatch(clean)) clean = "'$clean";
      return '"${clean.replaceAll('"', '""')}"';
    }

    final rows = <String>[
      'Application ID,Applicant,Type,Submission Platform,Submitted (local),Status,Priority',
    ];
    for (final item in _filtered) {
      rows.add(
        [
          item.id,
          item.name,
          item.typeLabel,
          item.platform,
          _date(item.submitted),
          item.statusLabel,
          item.priority,
        ].map(cell).join(','),
      );
    }
    Clipboard.setData(ClipboardData(text: '\uFEFF${rows.join('\r\n')}'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Filtered fictional applications copied as CSV (not downloaded).',
        ),
      ),
    );
  }

  Widget _queue() {
    final items = _filtered;
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section(
            'Review workload',
            'Search, filter and inspect resident or accreditation requests.',
            action: TextButton.icon(
              onPressed: () =>
                  context.go('/lgu-admin/verification/applications'),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('Full Queue'),
            ),
          ),
          const SizedBox(height: 16),
          _filters(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${items.length} matching fictional records',
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ),
              TextButton.icon(
                onPressed: items.isEmpty ? null : _copyCsv,
                icon: const Icon(Icons.copy_all_rounded, size: 16),
                label: const Text('Copy filtered CSV'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No applications match your filters.')),
            )
          else
            LayoutBuilder(
              builder: (context, bounds) => Scrollbar(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: math.max(bounds.maxWidth, 1050.0).toDouble(),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(_mint),
                      columnSpacing: 17,
                      dataRowMinHeight: 63,
                      dataRowMaxHeight: 75,
                      showCheckboxColumn: false,
                      columns: const [
                        DataColumn(label: Text('APPLICANT / ID')),
                        DataColumn(label: Text('REQUEST TYPE')),
                        DataColumn(label: Text('PLATFORM')),
                        DataColumn(label: Text('SUBMITTED')),
                        DataColumn(label: Text('STATUS')),
                        DataColumn(label: Text('PRIORITY')),
                        DataColumn(label: Text('DETAILS')),
                      ],
                      rows: [
                        for (final item in items.take(_visibleRows))
                          DataRow(
                            onSelectChanged: (_) => _inspect(item),
                            cells: [
                              DataCell(
                                Tooltip(
                                  message:
                                      '${item.id} · ${item.name} · ${item.description} · ${item.statusLabel} · ${item.priority} priority. Submitted through ${item.platform} on ${_date(item.submitted)}. Click row for full details.',
                                  child: SizedBox(
                                    width: 176,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: _ink,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.id,
                                          style: const TextStyle(
                                            color: _muted,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 115,
                                  child: Text(
                                    item.typeLabel,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  item.platform,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 153,
                                  child: Text(
                                    _date(item.submitted),
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                _badge(
                                  item.statusLabel,
                                  _statusColor(item.status),
                                ),
                              ),
                              DataCell(
                                _badge(
                                  item.priority,
                                  item.priority == 'High' ? _amber : _muted,
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  tooltip: 'Inspect application metadata',
                                  onPressed: () => _inspect(item),
                                  icon: const Icon(
                                    Icons.open_in_new_rounded,
                                    color: _forest,
                                    size: 19,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (items.length > _visibleRows) ...[
            const SizedBox(height: 12),
            Center(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _visibleRows += 6),
                icon: const Icon(Icons.expand_more),
                label: Text(
                  'Load more (${items.length - _visibleRows} remaining)',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _workflow() => _card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verification process & access boundaries',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: _ink,
          ),
        ),
        const SizedBox(height: 11),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _badge('1  Submit evidence', _forest),
            _badge('2  Review credentials', _forest),
            _badge('3  Decide with policy reason', _forest),
            _badge('4  Notify applicant (planned)', _forest),
          ],
        ),
        const SizedBox(height: 12),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline_rounded, color: _green, size: 19),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Only Verification staff should inspect sensitive identity evidence. Technical account enforcement belongs to IT; organization operations belong to Operations. Production Tier 2 upgrades, approvals, document expiry reminders and immutable audit records require a secured Supabase backend.',
                style: TextStyle(color: _muted, fontSize: 11.5, height: 1.6),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final compact = bounds.maxWidth < 640;
      return ColoredBox(
        color: _paper,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            compact ? 14 : 28,
            23,
            compact ? 14 : 28,
            45,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1260),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(compact),
                    const SizedBox(height: 15),
                    _notice(),
                    const SizedBox(height: 24),
                    _section(
                      'Verification at a glance',
                      'Current sample workload and application types.',
                    ),
                    const SizedBox(height: 12),
                    _metricGrid(),
                    const SizedBox(height: 14),
                    _actionLinks(),
                    const SizedBox(height: 26),
                    _section(
                      'Verification analytics',
                      'Three focused interactive prototype charts.',
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, inner) {
                        if (inner.maxWidth < 860) {
                          return Column(
                            children: [
                              _trendChart(),
                              const SizedBox(height: 12),
                              _outcomeChart(),
                              const SizedBox(height: 12),
                              _platformChart(),
                            ],
                          );
                        }
                        final left = (inner.maxWidth - 12) * .61;
                        final right = (inner.maxWidth - 12) - left;
                        return Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(width: left, child: _trendChart()),
                                const SizedBox(width: 12),
                                SizedBox(width: right, child: _outcomeChart()),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _platformChart(),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _queue(),
                    const SizedBox(height: 14),
                    _workflow(),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({
    required this.values,
    required this.maxY,
    required this.selected,
  });
  final List<double> values;
  final double maxY;
  final int selected;
  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.width <= 0 || size.height <= 0) return;
    final plot = Rect.fromLTWH(0, 9, size.width, size.height - 18);
    final grid = Paint()
      ..color = _stroke
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = plot.top + plot.height * i / 4;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
    }
    Offset point(int i) => Offset(
      plot.left + plot.width * (i + .5) / values.length,
      plot.bottom - (values[i] / maxY) * plot.height,
    );
    final path = Path()..moveTo(point(0).dx, point(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(point(i).dx, point(i).dy);
    }
    final fill = Path.from(path)
      ..lineTo(point(values.length - 1).dx, plot.bottom)
      ..lineTo(point(0).dx, plot.bottom)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _green.withValues(alpha: .25),
            _green.withValues(alpha: .015),
          ],
        ).createShader(plot),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = _forest
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    for (var i = 0; i < values.length; i++) {
      final p = point(i);
      canvas.drawCircle(
        p,
        i == selected ? 6 : 4,
        Paint()..color = i == selected ? _gold : _forest,
      );
      canvas.drawCircle(
        p,
        i == selected ? 2.4 : 1.6,
        Paint()..color = Colors.white,
      );
    }
    final selectedPoint = point(selected.clamp(0, values.length - 1));
    canvas.drawLine(
      Offset(selectedPoint.dx, plot.top),
      Offset(selectedPoint.dx, plot.bottom),
      Paint()
        ..color = _gold.withValues(alpha: .55)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.values != values || old.selected != selected || old.maxY != maxY;
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.sections, required this.selected});
  final List<(int, Color)> sections;
  final int selected;
  @override
  void paint(Canvas canvas, Size size) {
    final total = sections.fold<int>(0, (sum, e) => sum + e.$1);
    if (total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2 - 10).toDouble();
    final rect = Rect.fromCircle(center: center, radius: radius);
    var start = -math.pi / 2;
    for (var i = 0; i < sections.length; i++) {
      final e = sections[i];
      if (e.$1 <= 0) continue;
      final sweep = math.pi * 2 * e.$1 / total;
      final paint = Paint()
        ..color = e.$2
        ..style = PaintingStyle.stroke
        ..strokeWidth = i == selected ? 23 : 19
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        rect,
        start + .025,
        math.max(0.0, sweep - .05).toDouble(),
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.selected != selected || old.sections != sections;
}
