import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// KAISA IT dashboard — visual prototype. No real monitoring data is queried.
const _forest = Color(0xFF103C2B);
const _deep = Color(0xFF082B21);
const _green = Color(0xFF2B875A);
const _mint = Color(0xFFEAF5ED);
const _paper = Color(0xFFF5F8F4);
const _ink = Color(0xFF18372B);
const _muted = Color(0xFF748479);
const _gold = Color(0xFFFFCA46);
const _line = Color(0xFFE1EAE2);

class LguItDashboardPage extends StatelessWidget {
  const LguItDashboardPage({super.key});

  static const _modules = <_DashboardModule>[
    _DashboardModule(
      'Account Management',
      'Review user accounts and account actions',
      Icons.manage_accounts_rounded,
      '/lgu-admin/it/accounts',
    ),
    _DashboardModule(
      'Roles & Permissions',
      'Review administrator access and responsibilities',
      Icons.admin_panel_settings_outlined,
      '/lgu-admin/it/roles',
    ),
    _DashboardModule(
      'Security Logs',
      'Inspect illustrative authentication and security events',
      Icons.security_rounded,
      '/lgu-admin/it/security-logs',
    ),
    _DashboardModule(
      'System Health',
      'Check the platform monitoring workspace',
      Icons.monitor_heart_outlined,
      '/lgu-admin/it/system-health',
    ),
    _DashboardModule(
      'Backup & Recovery',
      'Review backup and recovery readiness',
      Icons.backup_outlined,
      '/lgu-admin/it/backup-recovery',
    ),
    _DashboardModule(
      'System Settings',
      'Review system configuration options',
      Icons.settings_suggest_outlined,
      '/lgu-admin/it/system-settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _paper,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 640;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 28,
              24,
              compact ? 16 : 28,
              48,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _heading(compact),
                      const SizedBox(height: 22),
                      _welcomeBanner(context),
                      const SizedBox(height: 16),
                      _disclaimer(),
                      const SizedBox(height: 28),
                      _sectionHeading(
                        'Platform snapshot',
                        'System indicators remain unconnected until secure monitoring is configured.',
                      ),
                      const SizedBox(height: 14),
                      _metrics(),
                      const SizedBox(height: 28),
                      _sectionHeading(
                        'Monitoring overview',
                        'Visual examples only — not current KAISA activity or uptime.',
                      ),
                      const SizedBox(height: 14),
                      _charts(),
                      const SizedBox(height: 28),
                      _sectionHeading(
                        'IT workspaces',
                        'Jump directly into your assigned administrative modules.',
                      ),
                      const SizedBox(height: 14),
                      _moduleGrid(context),
                      const SizedBox(height: 28),
                      _sectionHeading(
                        'Operational readiness',
                        'Services that need backend integration before production monitoring.',
                      ),
                      const SizedBox(height: 14),
                      _readinessPanels(),
                      const SizedBox(height: 22),
                      _accountPanel(context),
                      const SizedBox(height: 18),
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, size: 16, color: _muted),
                          SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'IT Administration UI preview. No live resident records, security events, '
                              'system health measurements, or infrastructure metrics are accessed. '
                              'Production actions require verified backend authorization and RLS.',
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.5,
                                color: _muted,
                              ),
                            ),
                          ),
                        ],
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

  Widget _heading(bool compact) => Wrap(
    spacing: 14,
    runSpacing: 12,
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KAISA  /  LGU ADMINISTRATION  /  IT',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w800,
              color: _green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'IT Administration',
            style: TextStyle(
              fontSize: compact ? 27 : 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.9,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your platform operations, security and access command center.',
            style: TextStyle(color: _muted, fontSize: 13),
          ),
        ],
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: _line),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined, color: _green, size: 17),
            SizedBox(width: 8),
            Text(
              'IT SUPERADMIN',
              style: TextStyle(
                color: _forest,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _welcomeBanner(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(25),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_deep, _forest, Color(0xFF237752)],
      ),
      boxShadow: [
        BoxShadow(
          color: _forest.withValues(alpha: .14),
          blurRadius: 24,
          offset: const Offset(0, 9),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      children: [
        const Positioned(
          right: -70,
          top: -75,
          child: _DecorativeOrb(diameter: 280),
        ),
        const Positioned(
          right: 82,
          bottom: -80,
          child: _DecorativeOrb(diameter: 170),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 27, vertical: 27),
          child: Wrap(
            spacing: 24,
            runSpacing: 15,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '✦  KAISA CONTROL CENTER',
                      style: TextStyle(
                        color: _gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 13),
                    const Text(
                      'A safer, stronger platform\nstarts here.',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 27,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Monitor readiness, review administrative tools, and '
                      'prepare secure services for the KAISA community.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        color: Colors.white.withValues(alpha: .79),
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _deep,
                  backgroundColor: _gold,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 19,
                    vertical: 16,
                  ),
                ),
                onPressed: () => context.go('/lgu-admin/it/system-health'),
                icon: const Icon(Icons.monitor_heart_outlined, size: 17),
                label: const Text(
                  'System Health',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _disclaimer() => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8DE),
      borderRadius: BorderRadius.circular(13),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, color: Color(0xFF936C18), size: 19),
        SizedBox(width: 11),
        Expanded(
          child: Text(
            'DEVELOPMENT PREVIEW  •  Charts use fictional sample values. '
            'Cards show unavailable live metrics rather than invented counts. '
            'This screen does not read or modify Supabase data.',
            style: TextStyle(
              color: Color(0xFF80621D),
              fontSize: 11,
              height: 1.55,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _sectionHeading(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: _ink,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: -.4,
        ),
      ),
      const SizedBox(height: 5),
      Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
    ],
  );

  Widget _metrics() {
    const data = [
      _DashboardMetric(
        'Registered accounts',
        '—',
        'Awaiting authorized account data',
        Icons.groups_2_outlined,
        Color(0xFFE9F5ED),
        _green,
      ),
      _DashboardMetric(
        'Active sessions',
        '—',
        'Secure session monitor required',
        Icons.devices_outlined,
        Color(0xFFEAF2FA),
        Color(0xFF4185BA),
      ),
      _DashboardMetric(
        'Security alerts',
        '—',
        'Awaiting event integration',
        Icons.shield_outlined,
        Color(0xFFFFF5D9),
        Color(0xFFB58A20),
      ),
      _DashboardMetric(
        'Platform health',
        'Not connected',
        'Monitoring not configured',
        Icons.monitor_heart_outlined,
        Color(0xFFF2ECFC),
        Color(0xFF8C66B3),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1040
            ? 4
            : constraints.maxWidth >= 540
            ? 2
            : 1;
        const gap = 13.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in data)
              SizedBox(
                width: width,
                child: Container(
                  padding: const EdgeInsets.all(19),
                  decoration: _surface(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: item.bg,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(
                              item.icon,
                              size: 22,
                              color: item.accent,
                            ),
                          ),
                          const Icon(
                            Icons.more_horiz_rounded,
                            size: 19,
                            color: _muted,
                          ),
                        ],
                      ),
                      const SizedBox(height: 19),
                      Text(
                        item.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: item.value.length > 9 ? 19 : 30,
                          fontWeight: FontWeight.w900,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.label,
                        style: const TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        item.description,
                        style: const TextStyle(
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
    );
  }

  Widget _charts() => LayoutBuilder(
    builder: (context, constraints) {
      final sideBySide = constraints.maxWidth >= 850;
      final leftWidth = sideBySide
          ? (constraints.maxWidth - 14) * .58
          : constraints.maxWidth;
      final rightWidth = sideBySide
          ? (constraints.maxWidth - 14) * .42
          : constraints.maxWidth;
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          SizedBox(
            width: leftWidth,
            child: _panel(
              'Illustrative activity',
              'Sample event volume across seven days',
              Icons.show_chart_rounded,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _DemoTag(),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: CustomPaint(painter: _ActivityChartPainter()),
                  ),
                  const SizedBox(height: 11),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final day in [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun',
                      ])
                        Text(
                          day,
                          style: const TextStyle(color: _muted, fontSize: 10),
                        ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Example activity pattern • not platform analytics',
                    style: TextStyle(color: _muted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: rightWidth,
            child: _panel(
              'Illustrative categories',
              'Example security event distribution',
              Icons.donut_large_rounded,
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const _DemoTag(),
                  const SizedBox(height: 17),
                  SizedBox(
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const CustomPaint(
                          size: Size(160, 160),
                          painter: _RingChartPainter(),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'SAMPLE',
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 1.4,
                                color: _muted,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '100%',
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                                color: _forest,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 14,
                    runSpacing: 8,
                    children: [
                      _LegendDot('Routine 60%', _green),
                      _LegendDot('Review 25%', _gold),
                      _LegendDot('Alerts 15%', Color(0xFF85B9D3)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );

  Widget _moduleGrid(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1000
          ? 3
          : constraints.maxWidth >= 590
          ? 2
          : 1;
      const gap = 13.0;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final module in _modules)
            SizedBox(
              width: width,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => context.go(module.route),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      border: Border.all(color: _line),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                color: _mint,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(module.icon, color: _green, size: 23),
                            ),
                            const Icon(
                              Icons.arrow_outward_rounded,
                              color: _muted,
                              size: 19,
                            ),
                          ],
                        ),
                        const SizedBox(height: 17),
                        Text(
                          module.title,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          module.description,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 11,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'OPEN WORKSPACE',
                          style: TextStyle(
                            color: _green,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .7,
                          ),
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

  Widget _readinessPanels() => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 760;
      final width = wide
          ? (constraints.maxWidth - 14) / 2
          : constraints.maxWidth;
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          SizedBox(
            width: width,
            child: _panel(
              'System health',
              'Connection checklist',
              Icons.monitor_heart_outlined,
              const Column(
                children: [
                  _ReadinessRow('Supabase availability', 'Not connected'),
                  _ReadinessRow('API monitoring', 'Not configured'),
                  _ReadinessRow('Error tracking', 'Not configured'),
                  _ReadinessRow('Backup monitoring', 'Not configured'),
                ],
              ),
            ),
          ),
          SizedBox(
            width: width,
            child: _panel(
              'Security monitoring',
              'Integration checklist',
              Icons.shield_outlined,
              const Column(
                children: [
                  _ReadinessRow('Authentication logs', 'Not connected'),
                  _ReadinessRow('Suspicious activity alerts', 'Not configured'),
                  _ReadinessRow('Access review', 'Pending integration'),
                  _ReadinessRow('Security audit feed', 'Pending integration'),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );

  Widget _accountPanel(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: _surface(),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 20,
      runSpacing: 15,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 690),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.manage_accounts_outlined, color: _green, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'User Account Management',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _ink,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Account administration exists as a separate prototype workspace. '
                'Live account listings, filters and management actions still require '
                'secure Supabase integration.',
                style: TextStyle(color: _muted, fontSize: 12, height: 1.6),
              ),
              const SizedBox(height: 10),
              const Text(
                'Live account data: Not connected',
                style: TextStyle(
                  color: _green,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: () => context.go('/lgu-admin/it/accounts'),
          style: FilledButton.styleFrom(
            backgroundColor: _forest,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
          ),
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          label: const Text('Open accounts'),
        ),
      ],
    ),
  );

  Widget _panel(String title, String subtitle, IconData icon, Widget content) =>
      Container(
        padding: const EdgeInsets.all(21),
        decoration: _surface(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: _mint,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: _green, size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(color: _muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            content,
          ],
        ),
      );

  BoxDecoration _surface() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(19),
    border: Border.all(color: _line),
    boxShadow: [
      BoxShadow(
        color: _deep.withValues(alpha: .025),
        blurRadius: 20,
        offset: const Offset(0, 7),
      ),
    ],
  );
}

class _DashboardMetric {
  final String label, value, description;
  final IconData icon;
  final Color bg, accent;
  const _DashboardMetric(
    this.label,
    this.value,
    this.description,
    this.icon,
    this.bg,
    this.accent,
  );
}

class _DashboardModule {
  final String title, description, route;
  final IconData icon;
  const _DashboardModule(this.title, this.description, this.icon, this.route);
}

class _DecorativeOrb extends StatelessWidget {
  final double diameter;
  const _DecorativeOrb({required this.diameter});
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: .12),
          width: 36,
        ),
      ),
    ),
  );
}

class _DemoTag extends StatelessWidget {
  const _DemoTag();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF6DE),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Text(
      'ILLUSTRATIVE DATA',
      style: TextStyle(
        fontSize: 9,
        letterSpacing: .7,
        fontWeight: FontWeight.w900,
        color: Color(0xFF936C18),
      ),
    ),
  );
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendDot(this.label, this.color);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(color: _muted, fontSize: 10)),
    ],
  );
}

class _ReadinessRow extends StatelessWidget {
  final String label, status;
  const _ReadinessRow(this.label, this.status);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        const Icon(Icons.circle_outlined, color: _green, size: 13),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            status,
            textAlign: TextAlign.right,
            style: const TextStyle(color: _muted, fontSize: 11),
          ),
        ),
      ],
    ),
  );
}

// Purely decorative sample graph; intentionally does not imply live monitoring.
class _ActivityChartPainter extends CustomPainter {
  const _ActivityChartPainter();
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final grid = Paint()
      ..color = _line
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = 6 + (size.height - 14) * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    const data = [.34, .52, .46, .78, .61, .89, .71];
    final step = size.width / (data.length - 1);
    final points = <Offset>[
      for (int i = 0; i < data.length; i++)
        Offset(i * step, size.height - 12 - data[i] * (size.height - 24)),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final midX = (points[i - 1].dx + points[i].dx) / 2;
      path.cubicTo(
        midX,
        points[i - 1].dy,
        midX,
        points[i].dy,
        points[i].dx,
        points[i].dy,
      );
    }
    final area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _green.withValues(alpha: .25),
            _green.withValues(alpha: .015),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = _green
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    for (final point in points) {
      canvas.drawCircle(point, 4, Paint()..color = Colors.white);
      canvas.drawCircle(point, 2.4, Paint()..color = _green);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RingChartPainter extends CustomPainter {
  const _RingChartPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(size.width, size.height) / 2 - 10;
    if (radius <= 0) return;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: radius,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 17
      ..strokeCap = StrokeCap.butt;
    double start = -math.pi / 2;
    for (final (fraction, color) in [
      (.60, _green),
      (.25, _gold),
      (.15, const Color(0xFF85B9D3)),
    ]) {
      final sweep = math.pi * 2 * fraction;
      paint.color = color;
      canvas.drawArc(rect, start + .025, sweep - .05, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
