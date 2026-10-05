import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/notification_bell.dart';

import '../../../core/theme/app_colors.dart';

import '../widgets/resident_bottom_nav.dart';

class ResidentHomePage extends StatelessWidget {
  const ResidentHomePage({super.key});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log out?'),
          content: const Text(
            'Are you sure you want to log out of your KAISA account?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.go('/login');
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.blue,
              child: Text(
                'K',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 10),
            Text('KAISA'),
          ],
        ),
        actions: [
          const NotificationBell(),

          PopupMenuButton<String>(
            tooltip: 'Account',
            icon: const Icon(
              Icons.account_circle_outlined,
            ),
            onSelected: (value) {
              if (value == 'profile') {
                context.go('/resident/profile');
              }

              if (value == 'logout') {
                _showLogoutDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 12),
                    Text('My Profile'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: AppColors.error,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Log Out',
                      style: TextStyle(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              const Text(
                'Good morning, Darlene!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Stay connected with your community.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 24),

              // Verification card
              _VerificationCard(),

              const SizedBox(height: 28),

              // Quick access
              const Text(
                'Quick Access',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.groups_2_outlined,
                      title: 'Organizations',
                      color: AppColors.blue,
                      backgroundColor: AppColors.blueLight,
                      onTap: () {
                        // Organizations page later.
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.event_outlined,
                      title: 'Events',
                      color: AppColors.green,
                      backgroundColor: AppColors.greenLight,
                      onTap: () {
                        // Events page later.
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.verified_user_outlined,
                      title: 'Verify',
                      color: AppColors.yellowDark,
                      backgroundColor: AppColors.yellowLight,
                      onTap: () {
                        // Tier 2 verification page later.
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Organizations
              _SectionHeader(
                title: 'Discover Organizations',
                actionText: 'See all',
                onPressed: () {
                  // Organizations page later.
                },
              ),

              const SizedBox(height: 12),

              const _OrganizationCard(
                name: 'KAISA Youth Volunteers',
                category: 'Youth Organization',
                description:
                    'Building a stronger community through youth participation and volunteerism.',
                icon: Icons.volunteer_activism_outlined,
              ),

              const SizedBox(height: 12),

              const _OrganizationCard(
                name: 'Community Environment Network',
                category: 'Environment',
                description:
                    'Working together for cleaner and greener communities.',
                icon: Icons.eco_outlined,
              ),

              const SizedBox(height: 30),

              // Events
              _SectionHeader(
                title: 'Upcoming Events',
                actionText: 'View all',
                onPressed: () {
                  // Events page later.
                },
              ),

              const SizedBox(height: 12),

              const _EventCard(
                day: '12',
                month: 'OCT',
                title: 'Community Clean-Up Drive',
                organization: 'KAISA Youth Volunteers',
                time: '8:00 AM',
                location: 'Barangay Covered Court',
              ),

              const SizedBox(height: 30),

              // Community feed
              _SectionHeader(
                title: 'Community Feed',
                actionText: 'See more',
                onPressed: () {
                  // Feed page later.
                },
              ),

              const SizedBox(height: 12),

              const _FeedCard(
                organization: 'KAISA Youth Volunteers',
                time: '2 hours ago',
                content:
                    'Thank you to everyone who participated in our recent community activity! Together, we continue to build a more connected community.',
              ),
            ],
          ),
        ),
      ),

      // Temporary bottom navigation.
      // We will move this to resident_bottom_nav.dart later.
      bottomNavigationBar: const ResidentBottomNav(
         currentIndex: 0,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TIER 1 VERIFICATION CARD
// -----------------------------------------------------------------------------

class _VerificationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.blue,
            AppColors.blueDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  'TIER 1 ACCOUNT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Unlock full community access',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Verify your identity to join organizations, participate in events, and access more KAISA features.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.82),
              fontSize: 14,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 18),

          FilledButton.icon(
            onPressed: () {
              // Connect this to identity verification later.
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.blueDark,
            ),
            icon: const Icon(Icons.verified_user_outlined),
            label: const Text('Get Verified'),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// QUICK ACTION
// -----------------------------------------------------------------------------

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SECTION HEADER
// -----------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback onPressed;

  const _SectionHeader({
    required this.title,
    required this.actionText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        TextButton(
          onPressed: onPressed,
          child: Text(actionText),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// ORGANIZATION CARD
// -----------------------------------------------------------------------------

class _OrganizationCard extends StatelessWidget {
  final String name;
  final String category;
  final String description;
  final IconData icon;

  const _OrganizationCard({
    required this.name,
    required this.category,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.blueLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: AppColors.blue,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    category,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blue,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// EVENT CARD
// -----------------------------------------------------------------------------

class _EventCard extends StatelessWidget {
  final String day;
  final String month;
  final String title;
  final String organization;
  final String time;
  final String location;

  const _EventCard({
    required this.day,
    required this.month,
    required this.title,
    required this.organization,
    required this.time,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 58,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(
                    month,
                    style: const TextStyle(
                      color: AppColors.greenDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    day,
                    style: const TextStyle(
                      color: AppColors.greenDark,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    organization,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_outlined,
                        size: 15,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// COMMUNITY FEED CARD
// -----------------------------------------------------------------------------

class _FeedCard extends StatelessWidget {
  final String organization;
  final String time;
  final String content;

  const _FeedCard({
    required this.organization,
    required this.time,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.blueLight,
                  child: Icon(
                    Icons.groups_2_outlined,
                    color: AppColors.blue,
                    size: 20,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        organization,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.more_horiz,
                  color: AppColors.textSecondary,
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 16),

            const Divider(),

            Row(
              children: [
                TextButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.favorite_border_rounded),
                  label: const Text('Like'),
                ),
                TextButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Comment'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}