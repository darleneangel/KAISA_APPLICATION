import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// KAISA IT Superadmin dashboard. ALL numbers below are simulated test data.
// Replace these constants with authorized, aggregated backend telemetry later.
const _forest = Color(0xFF00492C);
const _gold = Color(0xFFFBBA16);
const _crimson = Color(0xFFD64545);
const _paper = Color(0xFFF5F8F4);
const _ink = Color(0xFF18372B);
const _muted = Color(0xFF687B70);
const _line = Color(0xFFE1EAE2);
const _mint = Color(0xFFEAF5ED);

class _DayActivity {
  const _DayActivity(this.day, this.success, this.failed);
  final String day;
  final int success;
  final int failed;
}

// Simulated requests/events for 12–18 November 2026, not unique people.
const _activity = <_DayActivity>[
  _DayActivity('Thu 12', 162, 11),
  _DayActivity('Fri 13', 185, 17),
  _DayActivity('Sat 14', 147, 13),
  _DayActivity('Sun 15', 169, 9),
  _DayActivity('Mon 16', 208, 35),
  _DayActivity('Tue 17', 236, 62),
  _DayActivity('Wed 18', 222, 19),
];

// Separate simulated classification of logged security/system events.
const _routineEvents = 1108;
const _warningEvents = 227;
const _criticalEvents = 85;
const _loggedEvents = _routineEvents + _warningEvents + _criticalEvents;

class LguItDashboardPage extends StatefulWidget {
  const LguItDashboardPage({super.key});

  @override
  State<LguItDashboardPage> createState() => _LguItDashboardPageState();
}

class _LguItDashboardPageState extends State<LguItDashboardPage> {
  int _selectedDay = 6;

  int get _successful => _activity.fold(0, (sum, day) => sum + day.success);
  int get _failed => _activity.fold(0, (sum, day) => sum + day.failed);

  static const _modules = <(String, IconData, String)>[
    (
      'Account Management',
      Icons.manage_accounts_outlined,
      '/lgu-admin/it/accounts',
    ),
    (
      'Roles & Permissions',
      Icons.admin_panel_settings_outlined,
      '/lgu-admin/it/roles',
    ),
    ('Security Logs', Icons.security_outlined, '/lgu-admin/it/security-logs'),

    (
      'System Health',
      Icons.monitor_heart_outlined,
      '/lgu-admin/it/system-health',
    ),
    (
      'System Settings',
      Icons.settings_outlined,
      '/lgu-admin/it/system-settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _paper,
      child: LayoutBuilder(
        builder: (context, outer) {
          final compact = outer.maxWidth < 640;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              compact ? 14 : 26,
              22,
              compact ? 14 : 26,
              40,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(compact),
                      const SizedBox(height: 14),
                      _notice(),
                      const SizedBox(height: 24),
                      _heading(
                        '7-day platform snapshot',
                        'Counts calculated from the same sample authentication activity and security event datasets.',
                      ),
                      const SizedBox(height: 13),
                      _kpis(),
                      const SizedBox(height: 27),
                      _heading(
                        'Security monitoring',
                        'Select or hover a day to inspect its figures. These graphs contain numerical data, not decorative artwork.',
                      ),
                      const SizedBox(height: 13),
                      _charts(),
                      const SizedBox(height: 25),
                      _heading(
                        'IT administration modules',
                        'Open the relevant workspace for account, permission, security, or system management.',
                      ),
                      const SizedBox(height: 12),
                      _moduleGrid(context),
                      const SizedBox(height: 18),
                      const Text(
                        'Production note: connect this dashboard only to authorized, aggregated Supabase Auth, API gateway, and audit events. '
                        'Do not expose raw tokens, passwords, or private log payloads to the Flutter client.',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 11,
                          height: 1.5,
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

  Widget _header(bool compact) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(compact ? 20 : 28),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: const LinearGradient(
        colors: [Color(0xFF082B21), _forest, Color(0xFF237752)],
      ),
    ),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 15,
      runSpacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'KAISA  /  LGU ADMINISTRATION  /  IT',
              style: TextStyle(
                color: _gold,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              'IT Administration',
              style: TextStyle(
                fontSize: compact ? 26 : 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Authentication, security events, and essential IT controls',
              style: TextStyle(color: Color(0xFFE0F1E7), fontSize: 12),
            ),
          ],
        ),
        const Chip(
          avatar: Icon(Icons.science_outlined, color: _forest, size: 17),
          label: Text(
            'SIMULATED DATA',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: _forest,
              fontSize: 11,
            ),
          ),
          backgroundColor: Color(0xFFFFF0C0),
          side: BorderSide.none,
        ),
      ],
    ),
  );

  Widget _notice() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF6DC),
      borderRadius: BorderRadius.circular(13),
    ),
    child: const Row(
      children: [
        Icon(Icons.info_outline, color: Color(0xFF98650B), size: 20),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'CAPSTONE PROTOTYPE — All figures are fixed demonstration records for 12–18 Nov 2026, '
            'not real logins, active users, Supabase uptime, or detected security incidents.',
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

  Widget _heading(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: _ink,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 4),
      Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
    ],
  );

  BoxDecoration _surface() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: _line),
  );

  Widget _kpis() {
    final items = <(String, String, String, IconData, Color)>[
      (
        'Authenticated / API requests',
        '$_successful',
        'Successful requests across 7 days',
        Icons.login_rounded,
        _forest,
      ),
      (
        'Failed / blocked requests',
        '$_failed',
        'Failed login or blocked request events',
        Icons.gpp_bad_outlined,
        _crimson,
      ),
      (
        'Logged security events',
        '$_loggedEvents',
        'Routine + warning + critical events',
        Icons.receipt_long_outlined,
        _forest,
      ),
      (
        'Critical alerts',
        '$_criticalEvents',
        'Categorized sample critical events',
        Icons.warning_amber_rounded,
        _crimson,
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth >= 980 ? 4 : (c.maxWidth >= 510 ? 2 : 1);
        const gap = 12.0;
        final width = (c.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: Container(
                  decoration: _surface(),
                  padding: const EdgeInsets.all(17),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item.$4, color: item.$5, size: 24),
                      const SizedBox(height: 11),
                      Text(
                        item.$2,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 29,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.$1,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.$3,
                        style: const TextStyle(color: _muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _charts() => LayoutBuilder(
    builder: (context, c) {
      final wide = c.maxWidth >= 860;
      final leftWidth = wide ? (c.maxWidth - 14) * .58 : c.maxWidth;
      final rightWidth = wide ? (c.maxWidth - 14) * .42 : c.maxWidth;
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          SizedBox(width: leftWidth, child: _activityPanel()),
          SizedBox(width: rightWidth, child: _eventPanel()),
        ],
      );
    },
  );

  Widget _activityPanel() {
    final current = _activity[_selectedDay];
    return Container(
      decoration: _surface(),
      padding: const EdgeInsets.all(19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '7-Day System & Auth Activity',
            style: TextStyle(
              fontSize: 16,
              color: _ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Daily successful requests vs failed/blocked requests',
            style: TextStyle(color: _muted, fontSize: 11),
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: const [
              _Legend('Authenticated / API', _forest),
              _Legend('Failed / blocked', _gold),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 205,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, c) => MouseRegion(
                onHover: (event) {
                  final x = event.localPosition.dx.clamp(
                    26.0,
                    math.max(26.0, c.maxWidth - 12),
                  );
                  final fraction = (x - 26) / math.max(1, c.maxWidth - 38);
                  final i = (fraction * (_activity.length - 1)).round().clamp(
                    0,
                    _activity.length - 1,
                  );
                  if (i != _selectedDay) setState(() => _selectedDay = i);
                },
                child: GestureDetector(
                  onTapDown: (details) {
                    final fraction =
                        (details.localPosition.dx - 26) /
                        math.max(1, c.maxWidth - 38);
                    setState(
                      () => _selectedDay = (fraction * (_activity.length - 1))
                          .round()
                          .clamp(0, _activity.length - 1),
                    );
                  },
                  child: CustomPaint(
                    painter: _AuthChartPainter(_activity, _selectedDay),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              for (var i = 0; i < _activity.length; i++)
                Expanded(
                  child: Text(
                    _activity[i].day.split(' ').first,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: i == _selectedDay
                          ? FontWeight.w900
                          : FontWeight.normal,
                      color: i == _selectedDay ? _forest : _muted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _mint,
              borderRadius: BorderRadius.circular(11),
            ),
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 15,
              runSpacing: 6,
              children: [
                Text(
                  current.day,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _ink,
                  ),
                ),
                Text(
                  'Successful: ${current.success}',
                  style: const TextStyle(
                    color: _forest,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Failed / blocked: ${current.failed}',
                  style: const TextStyle(
                    color: Color(0xFF94650D),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Each plotted point comes from the seven numerical samples defined in this file.',
            style: TextStyle(color: _muted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _eventPanel() {
    const groups = <(String, int, Color, String)>[
      (
        'Routine',
        _routineEvents,
        _forest,
        'Sign-ins, password resets, backup completions',
      ),
      (
        'Warnings / Review',
        _warningEvents,
        _gold,
        'Role changes, suspensions, rate-limit triggers',
      ),
      (
        'Critical Alerts',
        _criticalEvents,
        _crimson,
        'Lockouts, unauthorized requests, API errors',
      ),
    ];
    return Container(
      decoration: _surface(),
      padding: const EdgeInsets.all(19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Security & System Event Breakdown',
            style: TextStyle(
              fontSize: 16,
              color: _ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Categorized system and audit events over the sample 7 days',
            style: TextStyle(color: _muted, fontSize: 11),
          ),
          const SizedBox(height: 15),
          Center(
            child: SizedBox(
              height: 195,
              width: 195,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(195, 195),
                    painter: const _EventDonutPainter([
                      _routineEvents,
                      _warningEvents,
                      _criticalEvents,
                    ]),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        '1,420',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: _ink,
                          fontSize: 29,
                        ),
                      ),
                      Text(
                        'DEMO EVENTS',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final group in groups)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Tooltip(
                message: group.$4,
                child: Row(
                  children: [
                    Container(
                      height: 10,
                      width: 10,
                      decoration: BoxDecoration(
                        color: group.$3,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        group.$1,
                        style: const TextStyle(color: _ink, fontSize: 12),
                      ),
                    ),
                    Text(
                      '${group.$2}  (${(group.$2 / _loggedEvents * 100).toStringAsFixed(1)}%)',
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 7),
          const Text(
            'Event categories are a separate demo dataset; they are not a sum of the login chart.',
            style: TextStyle(color: _muted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _moduleGrid(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final columns = c.maxWidth >= 960 ? 3 : (c.maxWidth >= 560 ? 2 : 1);
      const gap = 12.0;
      final width = (c.maxWidth - (columns - 1) * gap) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final item in _modules)
            SizedBox(
              width: width,
              child: Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: const BorderSide(color: _line),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () => context.go(item.$3),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 18,
                    ),
                    child: Row(
                      children: [
                        Icon(item.$2, color: _forest, size: 22),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            item.$1,
                            style: const TextStyle(
                              color: _ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: _muted,
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
}

class _Legend extends StatelessWidget {
  const _Legend(this.name, this.color);
  final String name;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(name, style: const TextStyle(color: _muted, fontSize: 11)),
    ],
  );
}

// Plot real numerical values from the seven-day sample (not normalized decorative points).
class _AuthChartPainter extends CustomPainter {
  const _AuthChartPainter(this.days, this.selected);
  final List<_DayActivity> days;
  final int selected;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 50 || size.height < 50) return;
    const left = 26.0;
    const right = 12.0;
    const top = 13.0;
    const bottom = 13.0;
    final width = size.width - left - right;
    final height = size.height - top - bottom;
    final highest = days.fold<int>(
      0,
      (n, d) => math.max(n, math.max(d.success, d.failed)),
    );
    final ymax = ((highest + 49) ~/ 50) * 50;
    final grid = Paint()
      ..color = _line
      ..strokeWidth = 1;
    final labelStyle = const TextStyle(fontSize: 9, color: _muted);
    for (var i = 0; i <= 4; i++) {
      final y = top + height * i / 4;
      canvas.drawLine(Offset(left, y), Offset(left + width, y), grid);
      final text = TextPainter(
        text: TextSpan(
          text: '${(ymax * (4 - i) / 4).round()}',
          style: labelStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset(0, y - 6));
    }
    List<Offset> points(int Function(_DayActivity) value) => [
      for (var i = 0; i < days.length; i++)
        Offset(
          left + width * i / (days.length - 1),
          top + height * (1 - value(days[i]) / ymax),
        ),
    ];
    void drawSeries(List<Offset> pts, Color color) {
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
      for (var i = 0; i < pts.length; i++) {
        canvas.drawCircle(
          pts[i],
          i == selected ? 5 : 3.0,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          pts[i],
          i == selected ? 3.5 : 2.2,
          Paint()..color = color,
        );
      }
    }

    drawSeries(points((e) => e.success), _forest);
    drawSeries(points((e) => e.failed), _gold);
    final selectedX = left + width * selected / (days.length - 1);
    canvas.drawLine(
      Offset(selectedX, top),
      Offset(selectedX, top + height),
      Paint()
        ..color = _forest.withValues(alpha: .3)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _AuthChartPainter oldDelegate) =>
      oldDelegate.selected != selected || oldDelegate.days != days;
}

class _EventDonutPainter extends CustomPainter {
  const _EventDonutPainter(this.values);
  final List<int> values;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(size.width, size.height) / 2 - 13;
    final bounds = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: radius,
    );
    final total = values.fold(0, (int a, int b) => a + b);
    if (total <= 0) return;
    const colors = [_forest, _gold, _crimson];
    var start = -math.pi / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 19;
    for (var i = 0; i < values.length; i++) {
      final sweep = 2 * math.pi * values[i] / total;
      paint.color = colors[i];
      canvas.drawArc(
        bounds,
        start + .012,
        math.max(0, sweep - .024),
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _EventDonutPainter oldDelegate) =>
      oldDelegate.values != values;
}
