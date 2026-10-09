import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class LguAdminShell extends StatelessWidget {
  final Widget child;

  const LguAdminShell({super.key, required this.child});

  static const _items = [
    _NavItem('Overview', Icons.dashboard_rounded, '/lgu-admin/dashboard'),
    _NavItem(
      'Organizations',
      Icons.apartment_rounded,
      '/lgu-admin/organizations',
    ),
    _NavItem(
      'Admin Assignments',
      Icons.admin_panel_settings_rounded,
      '/lgu-admin/assignments',
    ),
    _NavItem(
      'Event Monitoring',
      Icons.event_available_rounded,
      '/lgu-admin/events',
    ),
    _NavItem('Reports', Icons.bar_chart_rounded, '/lgu-admin/reports'),
    _NavItem('Audit Logs', Icons.history_rounded, '/lgu-admin/audit-logs'),
    _NavItem('Settings', Icons.settings_rounded, '/lgu-admin/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1000;
    final location = GoRouterState.of(context).uri.path;

    final selected = _items.firstWhere(
      (item) => item.path == location,
      orElse: () => _items.first,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: isDesktop ? null : Drawer(child: _navigation(context, location)),
      body: Row(
        children: [
          if (isDesktop)
            SizedBox(width: 264, child: _navigation(context, location)),
          Expanded(
            child: Column(
              children: [
                _header(context, selected.title, isDesktop),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navigation(BuildContext context, String location) {
    return Container(
      color: AppColors.blueDark,
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.yellow,
                    child: Icon(
                      Icons.groups_rounded,
                      color: AppColors.blueDark,
                    ),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KAISA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'LGU Administration',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final active = location == item.path;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      selected: active,
                      selectedTileColor: Colors.white.withValues(alpha: .15),
                      leading: Icon(
                        item.icon,
                        color: active ? AppColors.yellow : Colors.white70,
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                      onTap: () {
                        final router = GoRouter.of(context);
                        final navigator = Navigator.maybeOf(context);

                        if (MediaQuery.sizeOf(context).width < 1000) {
                          navigator?.pop();
                        }

                        if (location != item.path) {
                          router.go(item.path);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            const Divider(color: Colors.white24),
            const Padding(
              padding: EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.green,
                    child: Icon(Icons.person_rounded, color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LGU Administrator',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Prototype account',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, String title, bool isDesktop) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (!isDesktop)
            Builder(
              builder: (buttonContext) => IconButton(
                onPressed: () => Scaffold.of(buttonContext).openDrawer(),
                icon: const Icon(Icons.menu_rounded),
              ),
            ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 16),
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.blueLight,
            child: Icon(Icons.person_rounded, color: AppColors.blue),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String title;
  final IconData icon;
  final String path;

  const _NavItem(this.title, this.icon, this.path);
}
