import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/kaisa_ui.dart';

class ResidentHomePage extends StatelessWidget {
  const ResidentHomePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('KAISA · Community'),
      actions: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: () => context.push('/resident/notifications'),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        const SizedBox(width: 12),
      ],
    ),
    body: KaisaPageLayout(
      children: [
        const KaisaHero(
          eyebrow: 'WELCOME TO YOUR COMMUNITY',
          title: 'Together, we make\na difference.',
          subtitle:
              'Discover meaningful opportunities, connect with local organizations, and stay involved in Cavite City.',
          icon: Icons.handshake_rounded,
        ),
        const SizedBox(height: 24),
        const Text(
          'Explore KAISA',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 13),
        KaisaResponsiveGrid(
          children: [
            KaisaTile(
              title: 'Discover events',
              subtitle:
                  'Find volunteer activities, workshops and community gatherings.',
              icon: Icons.event_available_rounded,
              onTap: () => context.go('/resident/events'),
            ),
            KaisaTile(
              title: 'Find organizations',
              subtitle: 'Connect with local community groups and initiatives.',
              icon: Icons.groups_rounded,
              onTap: () => context.go('/resident/organizations'),
            ),
            KaisaTile(
              title: 'Community feed',
              subtitle: 'See updates and announcements in your community.',
              icon: Icons.campaign_rounded,
              onTap: () => context.go('/resident/feed'),
            ),
          ],
        ),
        const SizedBox(height: 26),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 18,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unlock more ways to participate',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'Identity verification is required for certain KAISA activities.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: () =>
                    context.push('/resident/identity-verification'),
                icon: const Icon(Icons.verified_user_outlined),
                label: const Text('Get verified'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 27),
        Text(
          'Your community, your impact',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Text(
          'Discover opportunities that bring residents and local organizations together.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => context.go('/resident/about'),
          icon: const Icon(Icons.info_outline),
          label: const Text('Learn about KAISA'),
        ),
      ],
    ),
  );
}
