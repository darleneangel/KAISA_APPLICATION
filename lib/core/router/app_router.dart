import 'package:go_router/go_router.dart';

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

final appRouter = GoRouter(
  initialLocation: '/welcome',
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
      builder: (context, state) =>
          const MyOrganizationsPage(),
    ),
    GoRoute(
      path: '/resident/request-organization',
      builder: (context, state) =>
          const RequestOrganizationPage(),
    ),
    GoRoute(
      path: '/resident/events',
      builder: (context, state) =>
          const EventsPage(),
    ),
    GoRoute(
      path: '/resident/event-details',
      builder: (context, state) {
        final data =
            state.extra as Map<String, dynamic>;

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
      builder: (context, state) =>
          const MyEventsPage(),
    ),
    GoRoute(
      path: '/resident/profile',
      builder: (context, state) =>
          const ProfilePage(),
    ),
    GoRoute(
      path: '/resident/identity-verification',
      builder: (context, state) =>
          const IdentityVerificationPage(),
    ),

    GoRoute(
      path: '/resident/verification-status',
      builder: (context, state) {
        final data =
            state.extra as Map<String, dynamic>?;

        return VerificationStatusPage(
          status: data?['status'] ?? 'Pending',
        );
      },
    ),
    GoRoute(
      path: '/resident/notifications',
      builder: (context, state) =>
          const NotificationsPage(),
    ),
  ],
);
