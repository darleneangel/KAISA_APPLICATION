
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/lgu_admin/layout/lgu_admin_shell.dart';
import 'features/lgu_admin/dashboard/lgu_admin_dashboard_page.dart';
import 'features/lgu_admin/organizations/organization_registry_page.dart';
import 'features/lgu_admin/assignments/admin_assignments_page.dart';

import 'features/lgu_admin/events/event_monitoring_page.dart';
import 'features/lgu_admin/events/event_monitoring_page.dart';

import 'features/lgu_admin/reports/lgu_reports_page.dart';
import 'features/lgu_admin/audit_logs/lgu_audit_logs_page.dart';
import 'features/lgu_admin/settings/lgu_settings_page.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KaisaLguPreviewApp());
}

class KaisaLguPreviewApp extends StatefulWidget {
  const KaisaLguPreviewApp({super.key});

  @override
  State<KaisaLguPreviewApp> createState() =>
      _KaisaLguPreviewAppState();
}

class _KaisaLguPreviewAppState extends State<KaisaLguPreviewApp> {
  late final GoRouter _router = GoRouter(
    initialLocation: '/lgu-admin/dashboard',
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            LguAdminShell(child: child),
        routes: [
          // 1. LGU Dashboard
          GoRoute(
            path: '/lgu-admin/dashboard',
            builder: (context, state) =>
                const LguAdminDashboardPage(),
          ),

          // 2. Organization Registry
          GoRoute(
            path: '/lgu-admin/organizations',
            builder: (context, state) =>
                const OrganizationRegistryPage(),
          ),

          // 3. Admin Assignments
          GoRoute(
            path: '/lgu-admin/assignments',
            builder: (context, state) =>
                const AdminAssignmentsPage(),
          ),
          // 4. Event Monitoring
GoRoute(
  path: '/lgu-admin/events',
  builder: (context, state) =>
      const EventMonitoringPage(),
),
// 5. LGU Reports
GoRoute(
  path: '/lgu-admin/reports',
  builder: (context, state) =>
      const LguReportsPage(),
),

// 6. LGU Audit Logs
GoRoute(
  path: '/lgu-admin/audit-logs',
  builder: (context, state) =>
      const LguAuditLogsPage(),
),

// 7. LGU Settings
GoRoute(
  path: '/lgu-admin/settings',
  builder: (context, state) =>
      const LguSettingsPage(),
),

        ],
      ),
    ],
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'KAISA | LGU Admin Preview',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}
