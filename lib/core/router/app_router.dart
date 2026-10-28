import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../features/resident/widgets/kaisa_responsive_shell.dart';
import '../services/social_otp_service.dart';
import '../../features/resident/about/about_kaisa_page.dart';

import '../../features/auth/views/loading_screen.dart';
import '../../features/auth/views/welcome_page.dart';
import '../../features/auth/views/login_page.dart';
import '../../features/auth/views/signup_page.dart';
import '../../features/auth/views/forgot_password_page.dart';
import '../../features/auth/views/reset_password_page.dart';
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

import '../../features/resident/profile/public_resident_profile_page.dart';
import '../../features/resident/profile/resident_chat_page.dart';

import '../../features/resident/messaging/messages_page.dart';

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
  initialLocation: '/loading',
  refreshListenable: _authRefresh,
  redirect: (context, state) async {
    final user = Supabase.instance.client.auth.currentUser;
    final path = state.matchedLocation;
    // Recovery screens are public even if Supabase creates a temporary
    // recovery session. Never redirect them to resident or social OTP.
    if (path == '/loading' ||
        path == '/welcome' ||
        path == '/forgot-password' ||
        path == '/reset-password')
      return null;
    if (user == null) {
      if (path.startsWith('/resident/') || path == '/profile-setup')
        return '/login';
      return null;
    }
    // Only a backend-verified record can satisfy this gate.
    // IMPORTANT: Apply equivalent RLS policies to every sensitive resident table.
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
    // Do not automatically bypass the public login/signup pages.
    // A saved Supabase session still exists until the user signs out.
    if (path == '/login' || path == '/signup') return null;
    return null;
  },
  routes: [
    GoRoute(
      path: '/loading',
      builder: (context, state) => const LoadingScreen(),
    ),
    GoRoute(path: '/welcome', builder: (context, state) => const WelcomePage()),

    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),

    GoRoute(path: '/signup', builder: (context, state) => const SignUpPage()),

    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordPage(),
    ),

    GoRoute(
      path: '/reset-password',
      builder: (context, state) =>
          ResetPasswordPage(email: state.uri.queryParameters['email'] ?? ''),
    ),

    GoRoute(
      path: '/profile-setup',
      builder: (context, state) => const ProfileSetupPage(),
    ),

    GoRoute(
      path: '/verification',
      builder: (context, state) => VerificationPage(
        social: state.uri.queryParameters['mode'] == 'social',
      ),
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

        //FOR MESSAGE
        GoRoute(
          path: '/resident/user/:userId',
          builder: (context, state) => PublicResidentProfilePage(
            userId: state.pathParameters['userId']!,
          ),
        ),

        GoRoute(
          path: '/resident/messages/:recipientId',
          builder: (context, state) => ResidentChatPage(
            recipientId: state.pathParameters['recipientId']!,
          ),
        ),

        GoRoute(
          path: '/resident/messages',
          builder: (context, state) => const MessagesPage(),
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
            final data = state.extra as Map<String, dynamic>?;

            return VerificationStatusPage(status: data?['status'] ?? 'Pending');
          },
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
  ],
);
