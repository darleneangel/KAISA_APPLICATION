
import 'package:flutter/material.dart';

const _forest = Color(0xFF14532D);
const _green = Color(0xFF237A50);
const _paper = Color(0xFFF8FAF8);
const _ink = Color(0xFF173D2B);
const _muted = Color(0xFF687B70);
const _gold = Color(0xFFFBC02D);
const _stroke = Color(0xFFE2EBE4);
const _soft = Color(0xFFEAF5EE);

class LguItDashboardPage extends StatelessWidget {
  const LguItDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _paper,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 650;

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
                  constraints:
                      const BoxConstraints(maxWidth: 1260),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _header(compact),
                      const SizedBox(height: 22),
                      _previewBanner(),
                      const SizedBox(height: 28),

                      _sectionTitle(
                        'System Overview',
                        'Platform and account monitoring',
                      ),
                      const SizedBox(height: 14),

                      _metricGrid(),
                      const SizedBox(height: 28),

                      _sectionTitle(
                        'Administrative Workspaces',
                        'IT administration responsibilities',
                      ),
                      const SizedBox(height: 14),

                      _moduleGrid(),
                      const SizedBox(height: 28),

                      _sectionTitle(
                        'Platform Monitoring',
                        'Backend health and security information',
                      ),
                      const SizedBox(height: 14),

                      _monitoringPanels(),
                      const SizedBox(height: 28),

                      _accountPanel(),
                      const SizedBox(height: 18),

                      _footerNote(),
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

  Widget _header(bool compact) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 14,
      runSpacing: 14,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'KAISA / LGU ADMINISTRATION / IT',
              style: TextStyle(
                color: _green,
                fontSize: 11,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'IT Administration',
              style: TextStyle(
                color: _ink,
                fontSize: compact ? 26 : 32,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Manage platform security, accounts, '
              'permissions, and system operations.',
              style: TextStyle(
                color: _muted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: _soft,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _stroke),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.admin_panel_settings_rounded,
                color: _forest,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'IT ADMIN WORKSPACE',
                style: TextStyle(
                  color: _forest,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _previewBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8DE),
        border: Border.all(
          color: const Color(0xFFF1E3A7),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.construction_rounded,
            color: Color(0xFF92650D),
            size: 21,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Development Preview — This dashboard is '
              'currently UI-only. System metrics, account '
              'records, and administrative actions will be '
              'connected to authorized backend services later.',
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

  Widget _sectionTitle(
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _ink,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: _muted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _metricGrid() {
    const metrics = [
      _Metric(
        'Registered Accounts',
        '—',
        'Awaiting authorized account data',
        Icons.people_alt_outlined,
      ),
      _Metric(
        'Active Sessions',
        '—',
        'Requires a secure monitoring source',
        Icons.devices_outlined,
      ),
      _Metric(
        'Security Alerts',
        '—',
        'Awaiting security event integration',
        Icons.gpp_maybe_outlined,
      ),
      _Metric(
        'Platform Health',
        'Not connected',
        'Monitoring service not configured',
        Icons.monitor_heart_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 540
                ? 2
                : 1;

        const gap = 13.0;
        final width =
            (constraints.maxWidth - gap * (columns - 1)) /
                columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: _metricCard(metric),
              ),
          ],
        );
      },
    );
  }

  Widget _metricCard(_Metric metric) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: _soft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              metric.icon,
              color: _forest,
              size: 23,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            metric.value,
            style: const TextStyle(
              color: _forest,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            metric.title,
            style: const TextStyle(
              color: _ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            metric.description,
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _moduleGrid() {
    const modules = [
      _Module(
        'Account Management',
        'Account recovery, suspension, and administration.',
        Icons.manage_accounts_rounded,
      ),
      _Module(
        'Roles & Permissions',
        'Review administrator roles and approved access.',
        Icons.admin_panel_settings_outlined,
      ),
      _Module(
        'Security Logs',
        'Authentication events and security activity.',
        Icons.security_rounded,
      ),
      _Module(
        'System Health',
        'Service availability, errors, and uptime.',
        Icons.monitor_heart_outlined,
      ),
      _Module(
        'Backup & Recovery',
        'Review backup and recovery procedures.',
        Icons.backup_outlined,
      ),
      _Module(
        'System Settings',
        'Approved configuration and maintenance.',
        Icons.settings_suggest_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 3
            : constraints.maxWidth >= 540
                ? 2
                : 1;

        const gap = 13.0;
        final width =
            (constraints.maxWidth - gap * (columns - 1)) /
                columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final module in modules)
              SizedBox(
                width: width,
                child: _moduleCard(module),
              ),
          ],
        );
      },
    );
  }

  Widget _moduleCard(_Module module) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: _soft,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  module.icon,
                  color: _green,
                  size: 23,
                ),
              ),
              const Spacer(),
              const Text(
                'PLANNED',
                style: TextStyle(
                  color: _muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Text(
            module.title,
            style: const TextStyle(
              color: _ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            module.description,
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _monitoringPanels() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 780;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            SizedBox(
              width: twoColumns
                  ? (constraints.maxWidth - 14) / 2
                  : constraints.maxWidth,
              child: _infoPanel(
                'System Health',
                Icons.favorite_border_rounded,
                [
                  'Supabase availability: Not connected',
                  'API monitoring: Not configured',
                  'Application error tracking: Not configured',
                  'Backup monitoring: Not configured',
                ],
              ),
            ),
            SizedBox(
              width: twoColumns
                  ? (constraints.maxWidth - 14) / 2
                  : constraints.maxWidth,
              child: _infoPanel(
                'Security Monitoring',
                Icons.shield_outlined,
                [
                  'Authentication logs: Not connected',
                  'Suspicious activity alerts: Not configured',
                  'Access review: Pending integration',
                  'Security audit feed: Pending integration',
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _infoPanel(
    String title,
    IconData icon,
    List<String> rows,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _forest, size: 21),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          for (final row in rows) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.circle_outlined,
                  color: _green,
                  size: 13,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    row,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
          ],
        ],
      ),
    );
  }

  Widget _accountPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.people_outline_rounded,
                color: _forest,
                size: 23,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'User Account Management',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          const Text(
            'View and manage authorized accounts '
            'once the account administration backend is ready.',
            style: TextStyle(
              color: _muted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 35,
            ),
            decoration: BoxDecoration(
              color: _paper,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _stroke),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.manage_accounts_outlined,
                  color: _green,
                  size: 35,
                ),
                SizedBox(height: 12),
                Text(
                  'Account data is not connected',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Account records, search, filters, '
                  'and management actions will appear here '
                  'after secure Supabase integration.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerNote() {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          color: _muted,
          size: 17,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'KAISA IT Administration prototype. '
            'No live user, authentication, security, '
            'or infrastructure records are being queried. '
            'Administrative operations must use '
            'server-enforced authorization.',
            style: TextStyle(
              color: _muted,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _surface() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: _stroke),
    );
  }
}

class _Metric {
  final String title;
  final String value;
  final String description;
  final IconData icon;

  const _Metric(
    this.title,
    this.value,
    this.description,
    this.icon,
  );
}

class _Module {
  final String title;
  final String description;
  final IconData icon;

  const _Module(
    this.title,
    this.description,
    this.icon,
  );
}
