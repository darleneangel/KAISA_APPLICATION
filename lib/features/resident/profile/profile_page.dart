import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../widgets/resident_bottom_nav.dart';
import '../widgets/notification_bell.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // ============================================================
  // PROTOTYPE USER DATA
  // Later these values will come from Supabase.
  // ============================================================

  static const String residentName = 'Darlene Custodio';
  static const String residentEmail = 'darlene@example.com';

  // false = Tier 1
  // true  = Tier 2
  static const bool isTier2Verified = false;

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.logout_rounded,
            size: 40,
            color: AppColors.error,
          ),
          title: const Text(
            'Log Out?',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'Are you sure you want to log out of your KAISA account?',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                // Prototype logout only.
                // Supabase signOut() will be added later.
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

  void _showComingSoon(
    BuildContext context,
    String feature,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature will be connected soon.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          const NotificationBell(),

          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              _showComingSoon(
                context,
                'Settings',
              );
            },
            icon: const Icon(
              Icons.settings_outlined,
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            110,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // PROFILE HEADER
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.blue,
                      AppColors.blueDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'DC',
                            style: TextStyle(
                              color: AppColors.blueDark,
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                        Positioned(
                          right: -2,
                          bottom: 2,
                          child: Container(
                            width: 29,
                            height: 29,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.blue,
                                width: 2,
                              ),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              iconSize: 15,
                              tooltip: 'Change Profile Photo',
                              onPressed: () {
                                _showComingSoon(
                                  context,
                                  'Profile photo',
                                );
                              },
                              icon: const Icon(
                                Icons.camera_alt_outlined,
                                color: AppColors.blue,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      residentName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      residentEmail,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isTier2Verified
                                ? Icons.verified_rounded
                                : Icons
                                    .verified_user_outlined,
                            size: 17,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isTier2Verified
                                ? 'Tier 2 • Identity Verified'
                                : 'Tier 1 • Basic Account',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // VERIFICATION
              // ==================================================

              if (!isTier2Verified) ...[
                const SizedBox(height: 18),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons
                                .verified_user_outlined,
                            color: AppColors.blueDark,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Complete Identity Verification',
                              style: TextStyle(
                                color: AppColors.blueDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Verify your identity to join organizations, '
                        'register for events, and request the creation '
                        'of an organization.',
                        style: TextStyle(
                          color: AppColors.blueDark,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                              context.push(
                                '/resident/identity-verification',
                              );
                            },
                          icon: const Icon(
                            Icons.verified_outlined,
                          ),
                          label: const Text(
                            'Get Verified',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // ==================================================
              // COMMUNITY
              // ==================================================

              const _SectionTitle(
                title: 'My Community',
              ),

              const SizedBox(height: 12),

              _ProfileMenuCard(
                icon: Icons.groups_outlined,
                title: 'My Organizations',
                subtitle:
                    'View your memberships and organization roles',
                onTap: () {
                  context.push(
                    '/resident/my-organizations',
                  );
                },
              ),

              const SizedBox(height: 10),

              _ProfileMenuCard(
                icon: Icons.event_available_outlined,
                title: 'My Events',
                subtitle:
                    'View your event registrations and activity',
                onTap: () {
                  context.push(
                    '/resident/my-events',
                  );
                },
              ),

              const SizedBox(height: 10),

              _ProfileMenuCard(
                icon: Icons.add_business_outlined,
                title: 'Request Organization',
                subtitle:
                    'Submit a new organization request',
                locked: !isTier2Verified,
                onTap: () {
                  context.push(
                    '/resident/request-organization',
                  );
                },
              ),

              const SizedBox(height: 28),

              // ==================================================
              // ACCOUNT
              // ==================================================

              const _SectionTitle(
                title: 'Account',
              ),

              const SizedBox(height: 12),

              _ProfileMenuCard(
                icon: Icons.person_outline_rounded,
                title: 'Personal Information',
                subtitle:
                    'View and manage your personal details',
                onTap: () {
                  _showComingSoon(
                    context,
                    'Personal information',
                  );
                },
              ),

              const SizedBox(height: 10),

              _ProfileMenuCard(
                icon: Icons.lock_outline_rounded,
                title: 'Security',
                subtitle:
                    'Password and account security',
                onTap: () {
                  _showComingSoon(
                    context,
                    'Security settings',
                  );
                },
              ),

              const SizedBox(height: 10),

              _ProfileMenuCard(
                icon:
                    Icons.notifications_none_rounded,
                title: 'Notification Settings',
                subtitle:
                    'Manage how KAISA notifies you',
                onTap: () {
                  _showComingSoon(
                    context,
                    'Notification settings',
                  );
                },
              ),

              const SizedBox(height: 28),

              // ==================================================
              // SUPPORT
              // ==================================================

              const _SectionTitle(
                title: 'Support',
              ),

              const SizedBox(height: 12),

              _ProfileMenuCard(
                icon: Icons.help_outline_rounded,
                title: 'Help & Support',
                subtitle:
                    'Get help using KAISA',
                onTap: () {
                  _showComingSoon(
                    context,
                    'Help & Support',
                  );
                },
              ),

              const SizedBox(height: 10),

              _ProfileMenuCard(
                icon: Icons.info_outline_rounded,
                title: 'About KAISA',
                subtitle:
                    'Learn more about the application',
                onTap: () {
                  _showComingSoon(
                    context,
                    'About KAISA',
                  );
                },
              ),

              const SizedBox(height: 28),

              // ==================================================
              // LOGOUT
              // ==================================================

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showLogoutDialog(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(
                      color: AppColors.error,
                    ),
                  ),
                  icon: const Icon(
                    Icons.logout_rounded,
                  ),
                  label: const Text(
                    'Log Out',
                  ),
                ),
              ),

              const SizedBox(height: 22),

              const Center(
                child: Text(
                  'KAISA • Resident Portal',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar:
          const ResidentBottomNav(
        currentIndex: 4,
      ),
    );
  }
}

// ============================================================================
// SECTION TITLE
// ============================================================================

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

// ============================================================================
// PROFILE MENU CARD
// ============================================================================

class _ProfileMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool locked;

  const _ProfileMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.blueLight,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: AppColors.blue,
                  size: 22,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w700,
                              color:
                                  AppColors.textPrimary,
                            ),
                          ),
                        ),

                        if (locked) ...[
                          const SizedBox(width: 7),
                          const Icon(
                            Icons.lock_outline_rounded,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color:
                            AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}