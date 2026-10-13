import 'package:go_router/go_router.dart';

// AUTHENTICATION
import '../../features/auth/views/welcome_page.dart';
import '../../features/auth/views/login_page.dart';
import '../../features/auth/views/signup_page.dart';
import '../../features/auth/views/forgot_password_page.dart';
import '../../features/auth/views/profile_setup_page.dart';
import '../../features/auth/views/verification_page.dart';

// RESIDENT
import '../../features/resident/home/resident_home_page.dart';
import '../../features/resident/feed/feed_page.dart';
import '../../features/resident/organizations/organizations_page.dart';
import '../../features/resident/organizations/organization_details_page.dart';
import '../../features/resident/organizations/my_organizations_page.dart';
import '../../features/resident/organizations/request_organization_page.dart';
import '../../features/resident/events/events_page.dart';
import '../../features/resident/events/event_details_page.dart';
import '../../features/resident/events/my_events_page.dart';
import '../../features/resident/profile/profile_page.dart';
import '../../features/resident/verification/identity_verification_page.dart';
import '../../features/resident/verification/verification_status_page.dart';
import '../../features/resident/notifications/notifications_page.dart';

//LGU ADMIN
import '../../features/lgu_admin/dashboard/lgu_admin_dashboard_page.dart';
import '../../features/lgu_admin/organizations/organization_registry_page.dart';
import '../../features/lgu_admin/layout/lgu_admin_shell.dart';
import '../../features/lgu_admin/assignments/admin_assignments_page.dart';
import '../../features/lgu_admin/events/event_monitoring_page.dart';
import '../../features/lgu_admin/reports/lgu_reports_page.dart';
import '../../features/lgu_admin/audit_logs/lgu_audit_logs_page.dart';
import '../../features/lgu_admin/settings/lgu_settings_page.dart';

//ORGANIZATION ADMIN
import '../../features/organization_admin/dashboard/organization_admin_dashboard_page.dart';
import '../../features/organization_admin/shell/organization_admin_shell.dart';
import '../../features/organization_admin/members/organization_members_page.dart';

final appRouter = GoRouter(
  initialLocation: '/welcome',
  routes: [
    // =========================
    // PUBLIC / AUTH ROUTES
    // =========================
    GoRoute(path: '/welcome', builder: (context, state) => const WelcomePage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpPage()),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: '/profile-setup',
      builder: (context, state) => const ProfileSetupPage(),
    ),
    GoRoute(
      path: '/verification',
      builder: (context, state) => const VerificationPage(),
    ),

    // =========================
    // RESIDENT ROUTES
    // =========================
    GoRoute(
      path: '/resident/home',
      builder: (context, state) => const ResidentHomePage(),
    ),
    GoRoute(
      path: '/resident/feed',
      builder: (context, state) => const FeedPage(),
    ),
    GoRoute(
      path: '/resident/organizations',
      builder: (context, state) => const OrganizationsPage(),
    ),
    GoRoute(
      path: '/resident/organization-details',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;

        return OrganizationDetailsPage(
          organizationId: data['id'] as String?,
          name: data['name'],
          category: data['category'],
          description: data['description'],
          members: data['members'],
        );
      },
    ),
    GoRoute(
      path: '/resident/my-organizations',
      builder: (context, state) => const MyOrganizationsPage(),
    ),
    GoRoute(
      path: '/resident/request-organization',
      builder: (context, state) => const RequestOrganizationPage(),
    ),
    GoRoute(
      path: '/resident/events',
      builder: (context, state) => const EventsPage(),
    ),
    GoRoute(
      path: '/resident/event-details',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;

        return EventDetailsPage(
          title: data['title'],
          organization: data['organization'],
          category: data['category'],
          description: data['description'],
          date: data['date'],
          time: data['time'],
          location: data['location'],
          participants: data['participants'],
          capacity: data['capacity'],
        );
      },
    ),
    GoRoute(
      path: '/resident/my-events',
      builder: (context, state) => const MyEventsPage(),
    ),
    GoRoute(
      path: '/resident/profile',
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: '/resident/identity-verification',
      builder: (context, state) => const IdentityVerificationPage(),
    ),
    GoRoute(
      path: '/resident/verification-status',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>?;

        return VerificationStatusPage(status: data?['status'] ?? 'Pending');
      },
    ),
    GoRoute(
      path: '/resident/notifications',
      builder: (context, state) => const NotificationsPage(),
    ),

    // =========================
    // LGU ADMIN ROUTES
    // =========================
    ShellRoute(
      builder: (context, state, child) {
        return LguAdminShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/lgu-admin/dashboard',
          builder: (context, state) => const LguAdminDashboardPage(),
        ),
        GoRoute(
          path: '/lgu-admin/organizations',
          builder: (context, state) => const OrganizationRegistryPage(),
        ),
        GoRoute(
          path: '/lgu-admin/assignments',
          builder: (context, state) => const AdminAssignmentsPage(),
        ),
        GoRoute(
          path: '/lgu-admin/events',
          builder: (context, state) => const EventMonitoringPage(),
        ),
        GoRoute(
          path: '/lgu-admin/reports',
          builder: (context, state) => const LguReportsPage(),
        ),
        GoRoute(
          path: '/lgu-admin/audit-logs',
          builder: (context, state) => const LguAuditLogsPage(),
        ),
        GoRoute(
          path: '/lgu-admin/settings',
          builder: (context, state) => const LguSettingsPage(),
        ),
      ],
    ),

    // =========================
    // ORGANIZATION ADMIN ROUTES
    // =========================
    ShellRoute(
      builder: (context, state, child) => OrganizationAdminShell(child: child),
      routes: [
        GoRoute(
          path: '/organization-admin/dashboard',
          builder: (context, state) =>
              const OrganizationAdminDashboardPage(organizationId: 'ORG-001'),
        ),
        GoRoute(
          path: '/organization-admin/members',
          builder: (context, state) =>
              const OrganizationMembersPage(organizationId: 'ORG-001'),
        ),
        for (final module in const [
          ('events', 'Events'),
          ('attendance', 'Attendance'),
          ('certificates', 'Certificate Studio'),
          ('reports', 'Reports'),
          ('settings', 'Settings'),
        ])
          GoRoute(
            path: '/organization-admin/${module.$1}',
            builder: (context, state) =>
                OrganizationModulePlaceholder(title: module.$2),
          ),
      ],
    ),
  ],
);
