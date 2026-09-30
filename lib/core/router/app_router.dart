import 'package:go_router/go_router.dart';

import '../../features/auth/views/welcome_page.dart';
import '../../features/auth/views/login_page.dart';
import '../../features/auth/views/signup_page.dart';
import '../../features/auth/views/forgot_password_page.dart';
import '../../features/auth/views/profile_setup_page.dart';
import '../../features/auth/views/verification_page.dart';
import '../../features/resident/views/resident_home_page.dart';

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
  ],
);
