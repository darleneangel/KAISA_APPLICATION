import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class OrganizationAdminShell extends StatelessWidget {
  final Widget child;
  const OrganizationAdminShell({super.key, required this.child});

  static const destinations = [
    ('Dashboard', Icons.dashboard_rounded, '/organization-admin/dashboard'),
    ('Members', Icons.groups_rounded, '/organization-admin/members'),
    ('Events', Icons.event_rounded, '/organization-admin/events'),
    ('Attendance', Icons.fact_check_rounded, '/organization-admin/attendance'),
    ('Certificate Studio', Icons.workspace_premium_rounded, '/organization-admin/certificates'),
    ('Reports', Icons.bar_chart_rounded, '/organization-admin/reports'),
    ('Settings', Icons.settings_rounded, '/organization-admin/settings'),
  ];

  Widget _navigation(BuildContext context) {
    final uri = GoRouterState.of(context).uri;
    final location = uri.path;
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Padding(
          padding: EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('KAISA', style: TextStyle(color: AppColors.blue, fontSize: 25, fontWeight: FontWeight.w900)),
              SizedBox(height: 5),
              Text('ORGANIZATION ADMIN', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const Divider(),
        const SizedBox(height: 8),
        for (final destination in destinations)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              selected: location == destination.$3,
              selectedTileColor: AppColors.blueLight,
              leading: Icon(destination.$2, color: location == destination.$3 ? AppColors.blue : AppColors.textSecondary),
              title: Text(destination.$1),
              onTap: () => context.go(Uri(path: destination.$3, queryParameters: uri.queryParameters.isEmpty ? null : uri.queryParameters).toString()),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final desktop = constraints.maxWidth >= 900;
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: Colors.white, title: const Text('KAISA Organization Workspace')),
        drawer: desktop ? null : Drawer(child: _navigation(context)),
        body: Row(children: [
          if (desktop) SizedBox(width: 260, child: Material(color: Colors.white, child: _navigation(context))),
          Expanded(child: child),
        ]),
      );
    });
  }
}

/// Explicit placeholder until the organization-scoped backend is available.
class OrganizationModulePlaceholder extends StatelessWidget {
  const OrganizationModulePlaceholder({super.key, required this.title, this.description = 'This module will be implemented next.'});
  final String title;
  final String description;
  @override
  Widget build(BuildContext context) => Center(child: SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.construction_outlined, size: 40, color: Color(0xFF2C6A4A)),
      const SizedBox(height: 16),
      Text(title, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      Text(description, textAlign: TextAlign.center),
    ])),
  ));
}
