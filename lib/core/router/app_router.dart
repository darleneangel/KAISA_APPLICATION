import 'package:flutter/material.dart';
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
// LGU ADMIN
import '../../features/lgu_admin/dashboard/lgu_admin_dashboard_page.dart';
import '../../features/lgu_admin/organizations/organization_registry_page.dart';
import '../../features/lgu_admin/layout/lgu_admin_shell.dart';

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
    // ORGANIZATION ADMIN ROUTES
    // =========================
    GoRoute(
      path: '/organization-admin/dashboard',
      builder: (context, state) => const _DashboardPlaceholder(
        title: 'Organization Admin',
        description:
            'Manage organization members, events, '
            'announcements, and certificates.',
        icon: Icons.groups_rounded,
      ),
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
          builder: (context, state) => const _LguModulePlaceholder(
            title: 'Admin Assignments',
            icon: Icons.admin_panel_settings_rounded,
          ),
        ),
        GoRoute(
          path: '/lgu-admin/events',
          builder: (context, state) => const _LguModulePlaceholder(
            title: 'Event Monitoring',
            icon: Icons.event_available_rounded,
          ),
        ),
        GoRoute(
          path: '/lgu-admin/reports',
          builder: (context, state) => const _LguModulePlaceholder(
            title: 'Reports',
            icon: Icons.bar_chart_rounded,
          ),
        ),
        GoRoute(
          path: '/lgu-admin/audit-logs',
          builder: (context, state) => const _LguModulePlaceholder(
            title: 'Audit Logs',
            icon: Icons.history_rounded,
          ),
        ),
        GoRoute(
          path: '/lgu-admin/settings',
          builder: (context, state) => const _LguModulePlaceholder(
            title: 'Settings',
            icon: Icons.settings_rounded,
          ),
        ),
      ],
    ),
  ],
);

class _LguModulePlaceholder extends StatelessWidget {
  final String title;
  final IconData icon;

  const _LguModulePlaceholder({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'This module will be developed next.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// TEMPORARY SCREEN
// Replace with actual dashboards in the next step.
class _DashboardPlaceholder extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _DashboardPlaceholder({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('KAISA | $title')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  '$title Dashboard',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(description, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.go('/resident/home'),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Go to Resident Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
