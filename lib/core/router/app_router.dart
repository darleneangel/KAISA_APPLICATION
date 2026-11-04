import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/resident/widgets/kaisa_responsive_shell.dart';
import '../services/social_otp_service.dart';
import '../../features/resident/about/about_kaisa_page.dart';
import '../../features/organization_admin/dashboard/organization_admin_dashboard_page.dart';
import '../../features/organization_admin/reports/kaisa_org_reports_page.dart';
import '../../features/organization_admin/attendance/kaisa_attendance_scanner_page.dart';
import '../../features/organization_admin/widgets/kaisa_org_admin_shell.dart';
import '../../features/organization_admin/invitations/kaisa_org_admin_gate.dart';
import '../../features/organization_admin/invitations/kaisa_invite_staff_page.dart';
import '../../features/organization_admin/certificates/ecertificate_studio_page.dart';
import '../../features/organization_admin/announcements/kaisa_org_announcements_page.dart';
import '../../features/organization_admin/profile/kaisa_org_profile_page.dart';
import '../../features/organization_admin/events/kaisa_org_events_management_page.dart';

import '../../features/auth/views/welcome_page.dart';
import '../../features/auth/views/login_page.dart';
import '../../features/auth/views/signup_page.dart';
import '../../features/auth/views/forgot_password_page.dart';
import '../../features/auth/views/profile_setup_page.dart';
import '../../features/auth/views/verification_page.dart';
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
import '../../features/resident/messaging/messages_page.dart';
import '../../features/resident/my-qr/kaisa_my_qr_page.dart';

import '../../features/auth/views/reset_password_page.dart';

final _authRefresh = _AuthRouterRefresh();

class _AuthRouterRefresh extends ChangeNotifier {
  late final StreamSubscription<AuthState> _subscription;

  _AuthRouterRefresh() {
    _subscription = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appRouter = GoRouter(
  initialLocation: '/welcome',
  refreshListenable: _authRefresh,
  redirect: (context, state) async {
    final user = Supabase.instance.client.auth.currentUser;
    final path = state.matchedLocation;

    if (user == null) {
      if (path.startsWith('/resident/') ||
          path.startsWith('/organization-admin/') ||
          path.startsWith('/organization_admin/') ||
          path == '/profile-setup') {
        return '/login';
      }
      return null;
    }

    // Only a backend-verified record can satisfy this gate.
    // Apply equivalent RLS policies to every sensitive resident table.
    if (SocialOtpService.instance.isSocial(user)) {
      try {
        final verified = await SocialOtpService.instance.hasCompleted(user);
        if (!verified &&
            (path != '/verification' ||
                state.uri.queryParameters['mode'] != 'social')) {
          return '/verification?mode=social';
        }
        if (verified &&
            path == '/verification' &&
            state.uri.queryParameters['mode'] == 'social') {
          return '/profile-setup';
        }
      } catch (error) {
        debugPrint('KAISA social OTP status unavailable: $error');
        // Fail closed: never grant access because the database lookup failed.
        if (path != '/verification' ||
            state.uri.queryParameters['mode'] != 'social') {
          return '/verification?mode=social';
        }
      }
    }

    if (path == '/login' || path == '/signup' || path == '/welcome') {
      return '/resident/home';
    }
    return null;
  },
  routes: [
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
    GoRoute(
      path: '/reset-password',
      builder: (context, state) =>
          ResetPasswordPage(email: state.uri.queryParameters['email'] ?? ''),
    ),

    ShellRoute(
      builder: (context, state, child) => KaisaResponsiveShell(child: child),
      routes: [
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
            final data = state.extra is Map<String, dynamic>
                ? state.extra! as Map<String, dynamic>
                : <String, dynamic>{};
            return OrganizationDetailsPage(
              organizationId: data['organization_id'] as String?,
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
            final data = state.extra is Map<String, dynamic>
                ? state.extra! as Map<String, dynamic>
                : <String, dynamic>{};
            return EventDetailsPage(
              eventId: data['event_id'] as String?,
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
            final data = state.extra is Map<String, dynamic>
                ? state.extra! as Map<String, dynamic>
                : <String, dynamic>{};
            return VerificationStatusPage(status: data['status'] ?? 'Pending');
          },
        ),
        GoRoute(
          path: '/resident/messaging',
          builder: (context, state) => const MessagesPage(),
        ),
        GoRoute(
          path: '/resident/my-qr',
          builder: (context, state) => const KaisaMyQrPage(),
        ),
        GoRoute(
          path: '/resident/notifications',
          builder: (context, state) => const NotificationsPage(),
        ),
        GoRoute(
          path: '/resident/about',
          builder: (context, state) => const AboutKaisaPage(),
        ),
      ],
    ),

    // Legacy links: redirect to canonical, protected Organization Admin routes.
    // Query parameters (including organizationId) are preserved.
    GoRoute(
      path: '/organization_admin/announcements',
      redirect: (context, state) => Uri(
        path: '/organization-admin/announcements',
        queryParameters: state.uri.queryParameters,
      ).toString(),
    ),
    GoRoute(
      path: '/organization_admin/attendance',
      redirect: (context, state) => Uri(
        path: '/organization-admin/attendance',
        queryParameters: state.uri.queryParameters,
      ).toString(),
    ),
    GoRoute(
      path: '/organization_admin/dashboard',
      redirect: (context, state) => Uri(
        path: '/organization-admin/dashboard',
        queryParameters: state.uri.queryParameters,
      ).toString(),
    ),
    // Organization Admin workspace uses its own shell and access guard.
    // The guard checks authorization for the selected organizationId.
    ShellRoute(
      builder: (context, state, child) =>
          KaisaOrgAdminGate(child: KaisaOrgAdminShell(child: child)),
      routes: [
        GoRoute(
          path: '/organization-admin/reports',
          builder: (context, state) => const KaisaOrgReportsPage(),
        ),
        GoRoute(
          path: '/organization-admin/dashboard',
          builder: (context, state) => const KaisaOrgAdminDashboardPage(),
        ),
        GoRoute(
          path: '/organization-admin/attendance',
          builder: (context, state) => const KaisaAttendanceScannerPage(),
        ),
        // Preserve existing E-Certificate Studio URL used by your project.
        GoRoute(
          path: '/organization-admin/ecertificate-studio',
          builder: (context, state) => const ECertificateStudioPage(),
        ),
        // Also support the shorter path used by earlier sidebar packages.
        GoRoute(
          path: '/organization-admin/certificates',
          builder: (context, state) => const ECertificateStudioPage(),
        ),
        // Staff invitations: both menu URLs share the same protected page.
        GoRoute(
          path: '/organization-admin/invitations',
          builder: (context, state) => KaisaInviteStaffPage(
            organizationId: state.uri.queryParameters['organizationId'] ?? '',
          ),
        ),
        GoRoute(
          path: '/organization-admin/events',
          builder: (context, state) => const KaisaOrgEventsManagementPage(),
        ),
        GoRoute(
          path: '/organization-admin/invitations/staff',
          redirect: (context, state) => Uri(
            path: '/organization-admin/invitations',
            queryParameters: state.uri.queryParameters,
          ).toString(),
        ),
        // Legacy certificate navigation path.
        GoRoute(
          path: '/organization-admin/certificates/ecertificate_studio_page',
          redirect: (context, state) => Uri(
            path: '/organization-admin/certificates',
            queryParameters: state.uri.queryParameters,
          ).toString(),
        ),
        // New: public / members-only announcements with notification choices.
        GoRoute(
          path: '/organization-admin/announcements',
          builder: (context, state) => const KaisaOrgAnnouncementsPage(),
        ),
        GoRoute(
          path: '/organization-admin/settings',
          builder: (context, state) => const KaisaOrgProfilePage(),
        ),
        GoRoute(
          path: '/organization-admin/profile',
          redirect: (context, state) => Uri(
            path: '/organization-admin/settings',
            queryParameters: state.uri.queryParameters,
          ).toString(),
        ),
      ],
    ),
  ],
);
