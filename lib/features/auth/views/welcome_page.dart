import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../widgets/auth_ui.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthResponsivePage(
      hero: const _WelcomeHero(),
      panel: const _WelcomePanel(),
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            AuthTag(label: 'Community-first', icon: Icons.favorite_rounded),
            AuthTag(label: 'Events & Updates', icon: Icons.campaign_rounded),
          ],
        ),
        SizedBox(height: compact ? 24 : 32),
        Text(
          'Connect with Cavite City in a smarter way.',
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 40 : 64,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.7,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'KAISA helps residents discover organizations, join local events, receive community updates, and participate in city initiatives through one creative and accessible platform.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .84),
              fontSize: compact ? 15 : 16,
              height: 1.7,
            ),
          ),
        ),
        SizedBox(height: compact ? 24 : 30),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            SizedBox(
              width: compact ? double.infinity : null,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/signup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD54F),
                  foregroundColor: const Color(0xFF14352C),
                  minimumSize: const Size(190, 58),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text(
                  'Create account',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            SizedBox(
              width: compact ? double.infinity : null,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/login'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: .30)),
                  minimumSize: const Size(170, 58),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(Icons.login_rounded),
                label: const Text('Log in'),
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 28 : 34),
        compact ? const _MobileHeroCards() : const _DesktopHeroCards(),
      ],
    );
  }
}

class _DesktopHeroCards extends StatelessWidget {
  const _DesktopHeroCards();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: AuthInfoCard(
            title: 'Resident-friendly',
            subtitle:
                'Browse events, connect with organizations, and stay informed through one organized digital experience.',
            icon: Icons.people_alt_rounded,
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: AuthInfoCard(
            title: 'Built for participation',
            subtitle:
                'Promote volunteerism, boost visibility of local groups, and strengthen communication with the community.',
            icon: Icons.rocket_launch_rounded,
          ),
        ),
      ],
    );
  }
}

class _MobileHeroCards extends StatelessWidget {
  const _MobileHeroCards();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AuthInfoCard(
          title: 'Resident-friendly',
          subtitle:
              'Browse events, connect with organizations, and stay informed through one organized digital experience.',
          icon: Icons.people_alt_rounded,
        ),
        SizedBox(height: 12),
        AuthInfoCard(
          title: 'Built for participation',
          subtitle:
              'Promote volunteerism, boost visibility of local groups, and strengthen communication with the community.',
          icon: Icons.rocket_launch_rounded,
        ),
      ],
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF6EF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Your community, your impact',
            style: TextStyle(
              color: AppColors.forest,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: .2,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Start your KAISA journey',
          style: TextStyle(
            color: Color(0xFF14352C),
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'A colorful civic platform where residents can discover, engage, and contribute. Choose where you want to begin.',
          style: TextStyle(
            color: Color(0xFF667970),
            fontSize: 15,
            height: 1.65,
          ),
        ),
        const SizedBox(height: 26),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 520;
            return GridView.count(
              shrinkWrap: true,
              crossAxisCount: wide ? 2 : 1,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: wide ? 1.16 : 1.58,
              children: const [
                AuthInfoCard(
                  title: 'Explore Events',
                  subtitle:
                      'Discover local activities, workshops, and service opportunities in the city.',
                  icon: Icons.event_available_rounded,
                  light: true,
                ),
                AuthInfoCard(
                  title: 'Join Organizations',
                  subtitle:
                      'Find organizations that match your interests and stay active in your community.',
                  icon: Icons.groups_2_rounded,
                  light: true,
                ),
                AuthInfoCard(
                  title: 'Receive Updates',
                  subtitle:
                      'Read community announcements and keep track of opportunities that matter.',
                  icon: Icons.notifications_active_rounded,
                  light: true,
                ),
                AuthInfoCard(
                  title: 'Build Impact',
                  subtitle:
                      'Participate in local initiatives and help strengthen community collaboration.',
                  icon: Icons.volunteer_activism_rounded,
                  light: true,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => context.go('/signup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forest,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Create Account'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AuthGhostButton(
                label: 'Log in instead',
                icon: Icons.arrow_forward_rounded,
                onTap: () => context.go('/login'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
