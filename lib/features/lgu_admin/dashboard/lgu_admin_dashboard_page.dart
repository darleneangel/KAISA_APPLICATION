import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

import 'package:go_router/go_router.dart';
import '../../../shared/repositories/organization_repository.dart';

class LguAdminDashboardPage extends StatefulWidget {
  const LguAdminDashboardPage({super.key});

  @override
  State<LguAdminDashboardPage> createState() => _LguAdminDashboardPageState();
}

class _LguAdminDashboardPageState extends State<LguAdminDashboardPage> {
  int selectedIndex = 0;
  String searchQuery = '';

  static const sections = [
    ('Overview', Icons.dashboard_rounded),
    ('Organizations', Icons.apartment_rounded),
    ('Admin Assignments', Icons.admin_panel_settings_rounded),
    ('Event Monitoring', Icons.event_available_rounded),
    ('Reports', Icons.bar_chart_rounded),
    ('Audit Logs', Icons.history_rounded),
    ('Settings', Icons.settings_rounded),
  ];

  final OrganizationRepository repository =
    OrganizationRepository.instance;

  @override
  void initState() {
    super.initState();
    repository.addListener(_refreshDashboard);
  }

  void _refreshDashboard() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    repository.removeListener(_refreshDashboard);
    super.dispose();
  }

  final organizations = const [
    _Organization(
      'Cavite City Youth Volunteers',
      'Youth',
      'Active',
      'Maria Santos',
      128,
    ),
    _Organization(
      'Community Health Advocates',
      'Health',
      'Active',
      'Juan Dela Cruz',
      86,
    ),
    _Organization(
      'Coastal Care Network',
      'Environment',
      'Pending',
      'Unassigned',
      42,
    ),
    _Organization(
      'Cavite Heritage Society',
      'Civic',
      'Active',
      'Ana Reyes',
      64,
    ),
  ];

  void selectSection(int index) {
    if (index == 1) {
      context.go('/lgu-admin/organizations');
    } else {
      const paths = [
        '/lgu-admin/dashboard',
        '/lgu-admin/organizations',
        '/lgu-admin/assignments',
        '/lgu-admin/events',
        '/lgu-admin/reports',
        '/lgu-admin/audit-logs',
        '/lgu-admin/settings',
      ];

      context.go(paths[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: _overview(),
        ),
      ),
    );
  }


  Widget _overview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome to KAISA Administration',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Monitor organizations, community activities, '
          'and administrative operations in Cavite City.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width >= 950
                ? 4
                : width >= 540
                ? 2
                : 1;
            const spacing = 14.0;
            final cardWidth = (width - spacing * (columns - 1)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                _statCard(
                  'Registered Organizations',
                  '${repository.totalOrganizations}',
                  Icons.apartment_rounded,
                  AppColors.blue,
                  cardWidth,
                ),
                _statCard(
                  'Active Organizations',
                  '${repository.activeOrganizations}',
                  Icons.verified_rounded,
                  AppColors.green,
                  cardWidth,
                ),
                _statCard(
                  'Pending Assignments',
                  '5',
                  Icons.assignment_ind_rounded,
                  const Color(0xFFB7791F),
                  cardWidth,
                ),
                _statCard(
                  'Upcoming Events',
                  '12',
                  Icons.event_rounded,
                  AppColors.blueDark,
                  cardWidth,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        _sectionHeading(
          'Organization Registry',
          'View all',
          () => selectSection(1),
        ),
        const SizedBox(height: 12),
        _organizationList(organizations),
        const SizedBox(height: 28),
        const Text(
          'Recent Administrative Activity',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        _panel(
          Column(
            children: const [
              _ActivityTile(
                Icons.person_add_alt_1_rounded,
                'Organization administrator assigned',
                'Cavite City Youth Volunteers',
              ),
              Divider(height: 1),
              _ActivityTile(
                Icons.apartment_rounded,
                'Organization record updated',
                'Community Health Advocates',
              ),
              Divider(height: 1),
              _ActivityTile(
                Icons.pending_actions_rounded,
                'Organization requires review',
                'Coastal Care Network',
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color color,
    double width,
  ) {
    return SizedBox(
      width: width,
      child: _panel(
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: .10),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeading(String title, String action, VoidCallback onTap) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
        ),
        TextButton(onPressed: onTap, child: Text(action)),
      ],
    );
  }

  Widget _organizationList(List<_Organization> items) {
    if (items.isEmpty) {
      return _panel(
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('No matching organizations found.')),
        ),
      );
    }

    return _panel(
      Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.blueLight,
                    child: Icon(Icons.groups_rounded, color: AppColors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[i].name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${items[i].category} • '
                          '${items[i].members} members • '
                          'Admin: ${items[i].admin}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _statusChip(items[i].status),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final active = status == 'Active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppColors.greenLight : AppColors.yellowLight,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: active ? AppColors.greenDark : const Color(0xFF9A6700),
        ),
      ),
    );
  }

  Widget _panel(Widget child) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _Organization {
  final String name;
  final String category;
  final String status;
  final String admin;
  final int members;

  const _Organization(
    this.name,
    this.category,
    this.status,
    this.admin,
    this.members,
  );
}

class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ActivityTile(this.icon, this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}
