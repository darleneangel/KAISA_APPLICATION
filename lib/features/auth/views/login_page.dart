import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../widgets/auth_ui.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthResponsivePage(
      showBack: true,
      backRoute: '/welcome',
      hero: const _LoginHero(),
      panel: _LoginPanel(
        emailController: emailController,
        passwordController: passwordController,
        obscurePassword: obscurePassword,
        onTogglePassword: () {
          setState(() {
            obscurePassword = !obscurePassword;
          });
        },
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            AuthTag(label: 'Secure sign in', icon: Icons.shield_rounded),
            AuthTag(label: 'Resident access', icon: Icons.person_rounded),
          ],
        ),
        SizedBox(height: compact ? 24 : 36),
        Text(
          'Welcome back.Let\'s continue making impact.',
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 38 : 60,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.6,
            height: 1.02,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Sign in to manage your profile, discover new activities, stay updated with community announcements, and keep participating through KAISA.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: .84),
            fontSize: compact ? 15 : 16,
            height: 1.7,
          ),
        ),
        SizedBox(height: compact ? 22 : 30),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoUp = constraints.maxWidth >= 520;
            return GridView.count(
              shrinkWrap: true,
              crossAxisCount: twoUp ? 2 : 1,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: twoUp ? 1.05 : 1.55,
              children: const [
                AuthInfoCard(
                  title: 'Community feed',
                  subtitle:
                      'Catch up on important updates and community-driven stories.',
                  icon: Icons.dynamic_feed_rounded,
                ),
                AuthInfoCard(
                  title: 'Events and organizations',
                  subtitle:
                      'Find where you can join, support, and participate next.',
                  icon: Icons.event_note_rounded,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _LoginPanel extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;

  const _LoginPanel({
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hello again 👋',
          style: TextStyle(
            color: Color(0xFF14352C),
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Log in to your KAISA account and continue exploring your community.',
          style: TextStyle(color: Color(0xFF667970), fontSize: 15, height: 1.6),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF0),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF5E3A9)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_rounded, color: Color(0xFF9A6A02)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Prototype login: the current button still routes to the resident home page while backend authentication is being connected.',
                  style: TextStyle(
                    color: Color(0xFF775A11),
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email address',
            hintText: 'Enter your email address',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: passwordController,
          obscureText: obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Enter your password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              onPressed: onTogglePassword,
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.go('/forgot-password'),
            child: const Text('Forgot Password?'),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => context.go('/resident/home'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.forest,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.login_rounded),
          label: const Text('Log In'),
        ),
        const SizedBox(height: 14),
        AuthGhostButton(
          label: 'Create a new account',
          icon: Icons.person_add_alt_1_rounded,
          onTap: () => context.go('/signup'),
        ),
        const SizedBox(height: 26),
        const Row(
          children: [
            Expanded(child: Divider(color: Color(0xFFD6E1DB))),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'WHY KAISA',
                style: TextStyle(
                  color: Color(0xFF7A8A83),
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            Expanded(child: Divider(color: Color(0xFFD6E1DB))),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 520;
            return GridView.count(
              shrinkWrap: true,
              crossAxisCount: wide ? 2 : 1,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: wide ? 1.22 : 1.8,
              children: const [
                AuthInfoCard(
                  title: 'Stronger communication',
                  subtitle:
                      'Residents and organizations stay connected through one shared platform.',
                  icon: Icons.forum_rounded,
                  light: true,
                ),
                AuthInfoCard(
                  title: 'Meaningful participation',
                  subtitle:
                      'Discover opportunities to volunteer, collaborate, and take part in civic life.',
                  icon: Icons.volunteer_activism_rounded,
                  light: true,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
