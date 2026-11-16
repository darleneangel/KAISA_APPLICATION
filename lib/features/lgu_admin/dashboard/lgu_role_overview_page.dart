
import 'package:flutter/material.dart';


import '../../../shared/models/lgu_admin_role.dart';


class LguRoleOverviewPage extends StatelessWidget {
  final LguAdminRole role;

  const LguRoleOverviewPage({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final isIt = role == LguAdminRole.it;

    final title = isIt
        ? 'IT Administration'
        : 'Verification Administration';

    final description = isIt
        ? 'Manage system operations, account security, '
            'permissions, and platform health.'
        : 'Review resident identity applications, '
            'verification decisions, and Tier 2 status.';

    final modules = isIt
        ? <_Module>[
            _Module('Account Management',
                Icons.manage_accounts_outlined,
                'Account recovery and suspension'),
            _Module('Roles & Permissions',
                Icons.admin_panel_settings_outlined,
                'Approved administrator assignments'),
            _Module('Security Logs',
                Icons.security_outlined,
                'Authentication and security events'),
            _Module('System Health',
                Icons.monitor_heart_outlined,
                'Backend availability and health'),
            _Module('Maintenance',
                Icons.build_outlined,
                'Approved maintenance operations'),
            _Module('Settings',
                Icons.settings_outlined,
                'System configuration'),
          ]
        : <_Module>[
            _Module('Pending Applications',
                Icons.pending_actions_outlined,
                'Tier 2 verification queue'),
            _Module('Identity Reviews',
                Icons.fact_check_outlined,
                'Review submitted credentials'),
            _Module('Approved Applications',
                Icons.verified_user_outlined,
                'Completed approvals'),
            _Module('Rejected Applications',
                Icons.cancel_outlined,
                'Rejected submissions'),
            _Module('Review History',
                Icons.history_outlined,
                'Reviewer actions and decisions'),
            _Module('Verification Reports',
                Icons.assessment_outlined,
                'Verification statistics'),
          ];

    return ColoredBox(
      color: const Color(0xFFF8FAF8),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'KAISA / LGU ADMINISTRATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: Color(0xFF237A50),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF173D2B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF687B70),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF5EE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF14532D),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Frontend prototype: these modules are '
                          'not connected to live administrative '
                          'data or actions yet.',
                          style: TextStyle(
                            color: Color(0xFF173D2B),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Administrative Modules',
                  style: TextStyle(
                    color: Color(0xFF173D2B),
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns =
                        constraints.maxWidth >= 900
                            ? 3
                            : constraints.maxWidth >= 550
                                ? 2
                                : 1;

                    const gap = 14.0;
                    final cardWidth =
                        (constraints.maxWidth -
                            gap * (columns - 1)) / columns;

                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (final module in modules)
                          SizedBox(
                            width: cardWidth,
                            child: _ModuleCard(module: module),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Module {
  final String title;
  final IconData icon;
  final String description;

  const _Module(
    this.title,
    this.icon,
    this.description,
  );
}

class _ModuleCard extends StatelessWidget {
  final _Module module;

  const _ModuleCard({required this.module});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFE2EBE4),
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5EE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              module.icon,
              color: const Color(0xFF14532D),
              size: 25,
            ),
          ),
          const SizedBox(height: 17),
          Text(
            module.title,
            style: const TextStyle(
              color: Color(0xFF173D2B),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            module.description,
            style: const TextStyle(
              color: Color(0xFF687B70),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'UI PLANNED',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1,
              fontWeight: FontWeight.w800,
              color: Color(0xFF237A50),
            ),
          ),
        ],
      ),
    );
  }
}
