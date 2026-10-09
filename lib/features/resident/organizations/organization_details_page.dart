import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class OrganizationDetailsPage extends StatelessWidget {
  final String name;
  final String category;
  final String description;
  final int members;

  const OrganizationDetailsPage({
    super.key,
    required this.name,
    required this.category,
    required this.description,
    required this.members,
  });

  // PROTOTYPE ONLY:
  // Tier 1 = false
  // Tier 2 = true
  static const bool isTier2Verified = false;

  void _handleJoinOrganization(BuildContext context) {
    if (!isTier2Verified) {
      _showVerificationRequiredDialog(context);
      return;
    }

    _showJoinConfirmation(context);
  }

  void _showVerificationRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.verified_user_outlined,
            size: 42,
            color: AppColors.blue,
          ),
          title: const Text(
            'Identity Verification Required',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'You need a Tier 2 verified account before you can join '
            'organizations and participate in their activities.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Not Now'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                // We'll create this route when we build
                // the Tier 2 verification module.
                // context.go('/resident/verification');
              },
              child: const Text('Get Verified'),
            ),
          ],
        );
      },
    );
  }

  void _showJoinConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Join Organization?'),
          content: Text(
            'Would you like to join $name?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Your request to join $name has been submitted.',
                    ),
                  ),
                );
              },
              child: const Text('Join'),
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
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Organization',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Share',
            onPressed: () {
              // Share functionality later.
            },
            icon: const Icon(Icons.share_outlined),
          ),
          IconButton(
            tooltip: 'More',
            onPressed: () {
              // Report / other options later.
            },
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========================================================
            // ORGANIZATION HEADER
            // ========================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.blue,
                    AppColors.blueDark,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.groups_2_outlined,
                      size: 42,
                      color: AppColors.blue,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.people_outline_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$members members',
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ========================================================
            // MAIN CONTENT
            // ========================================================

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Join button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        _handleJoinOrganization(context);
                      },
                      icon: const Icon(Icons.group_add_outlined),
                      label: const Text('Join Organization'),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // About
                  const _SectionTitle(
                    title: 'About',
                  ),

                  const SizedBox(height: 10),

                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Officers
                  const _SectionTitle(
                    title: 'Organization Officers',
                    action: 'View all',
                  ),

                  const SizedBox(height: 14),

                  const _OfficerCard(
                    name: 'Juan Dela Cruz',
                    role: 'President',
                    initials: 'JD',
                  ),

                  const SizedBox(height: 10),

                  const _OfficerCard(
                    name: 'Maria Santos',
                    role: 'Vice President',
                    initials: 'MS',
                  ),

                  const SizedBox(height: 30),

                  // Upcoming events
                  const _SectionTitle(
                    title: 'Upcoming Events',
                    action: 'See all',
                  ),

                  const SizedBox(height: 14),

                  const _OrganizationEventCard(
                    day: '12',
                    month: 'OCT',
                    title: 'Community Clean-Up Drive',
                    time: '8:00 AM',
                    location: 'Barangay Covered Court',
                  ),

                  const SizedBox(height: 30),

                  // Recent activity
                  const _SectionTitle(
                    title: 'Recent Posts',
                    action: 'See all',
                  ),

                  const SizedBox(height: 14),

                  const _RecentPostCard(
                    time: '2 hours ago',
                    content:
                        'Thank you to everyone who participated in our '
                        'recent community activity! We appreciate your '
                        'continued support and participation.',
                  ),

                  const SizedBox(height: 30),

                  // Verification reminder for Tier 1
                  if (!isTier2Verified)
                    const _VerificationReminder(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SECTION TITLE
// ============================================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? action;

  const _SectionTitle({
    required this.title,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: () {
              // Connect later.
            },
            child: Text(action!),
          ),
      ],
    );
  }
}

// ============================================================================
// OFFICER
// ============================================================================

class _OfficerCard extends StatelessWidget {
  final String name;
  final String role;
  final String initials;

  const _OfficerCard({
    required this.name,
    required this.role,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.blueLight,
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.blueDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  role,
                  style: const TextStyle(
                    fontSize: 12,
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
    );
  }
}

// ============================================================================
// ORGANIZATION EVENT
// ============================================================================

class _OrganizationEventCard extends StatelessWidget {
  final String day;
  final String month;
  final String title;
  final String time;
  final String location;

  const _OrganizationEventCard({
    required this.day,
    required this.month,
    required this.title,
    required this.time,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            padding: const EdgeInsets.symmetric(
              vertical: 10,
            ),
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
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 9),

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
    );
  }
}

// ============================================================================
// RECENT POST
// ============================================================================

class _RecentPostCard extends StatelessWidget {
  final String time;
  final String content;

  const _RecentPostCard({
    required this.time,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 12),

          const Row(
            children: [
              Icon(
                Icons.favorite_border_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 6),
              Text(
                'Like',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              SizedBox(width: 18),
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 17,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 6),
              Text(
                'Comment',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TIER 1 VERIFICATION REMINDER
// ============================================================================

class _VerificationReminder extends StatelessWidget {
  const _VerificationReminder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: AppColors.blueDark,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Want to participate?',
                  style: TextStyle(
                    color: AppColors.blueDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Complete Tier 2 identity verification to join '
                  'organizations and participate in community activities.',
                  style: TextStyle(
                    color: AppColors.blueDark,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}