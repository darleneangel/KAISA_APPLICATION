import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class MyOrganizationsPage extends StatefulWidget {
  const MyOrganizationsPage({super.key});

  @override
  State<MyOrganizationsPage> createState() =>
      _MyOrganizationsPageState();
}

class _MyOrganizationsPageState extends State<MyOrganizationsPage> {
  String selectedFilter = 'All';

  final List<String> filters = [
    'All',
    'Member',
    'Officer',
    'Admin',
  ];

  // ------------------------------------------------------------
  // PROTOTYPE DATA ONLY
  // Later, these will come from the database.
  // ------------------------------------------------------------
  final List<_MembershipData> memberships = const [
    _MembershipData(
      organizationName: 'KAISA Youth Volunteers',
      category: 'Youth',
      description:
          'Empowering young residents through volunteer work, '
          'leadership, and community participation.',
      members: 128,
      role: 'Member',
      joinedDate: 'September 15, 2026',
      icon: Icons.volunteer_activism_outlined,
    ),
    _MembershipData(
      organizationName: 'Community Environment Network',
      category: 'Environment',
      description:
          'Promoting environmental responsibility through clean-up '
          'drives and sustainability projects.',
      members: 94,
      role: 'Officer',
      joinedDate: 'August 20, 2026',
      icon: Icons.eco_outlined,
    ),
    _MembershipData(
      organizationName: 'Community Development Council',
      category: 'Community',
      description:
          'Encouraging residents to participate in programs that '
          'strengthen the local community.',
      members: 203,
      role: 'Admin',
      joinedDate: 'July 5, 2026',
      icon: Icons.groups_2_outlined,
    ),
  ];

  List<_MembershipData> get filteredMemberships {
    if (selectedFilter == 'All') {
      return memberships;
    }

    return memberships
        .where((membership) => membership.role == selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final displayedMemberships = filteredMemberships;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Organizations',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Your community memberships',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),

      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ========================================================
            // SUMMARY
            // ========================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Container(
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
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.groups_2_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Organizations',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${memberships.length} memberships',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ========================================================
            // FILTERS
            // ========================================================

            SizedBox(
              height: 58,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = filters[index];

                  return ChoiceChip(
                    label: Text(filter),
                    selected: selectedFilter == filter,
                    onSelected: (_) {
                      setState(() {
                        selectedFilter = filter;
                      });
                    },
                  );
                },
              ),
            ),

            // ========================================================
            // ORGANIZATIONS
            // ========================================================

            Expanded(
              child: displayedMemberships.isEmpty
                  ? _EmptyMemberships(
                      filter: selectedFilter,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        10,
                        20,
                        100,
                      ),
                      itemCount: displayedMemberships.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final membership =
                            displayedMemberships[index];

                        return _MembershipCard(
                          membership: membership,
                          onTap: () {
                            context.push(
                              '/resident/organization-details',
                              extra: {
                                'name':
                                    membership.organizationName,
                                'category':
                                    membership.category,
                                'description':
                                    membership.description,
                                'members':
                                    membership.members,
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// MEMBERSHIP DATA
// ============================================================================

class _MembershipData {
  final String organizationName;
  final String category;
  final String description;
  final int members;
  final String role;
  final String joinedDate;
  final IconData icon;

  const _MembershipData({
    required this.organizationName,
    required this.category,
    required this.description,
    required this.members,
    required this.role,
    required this.joinedDate,
    required this.icon,
  });
}

// ============================================================================
// MEMBERSHIP CARD
// ============================================================================

class _MembershipCard extends StatelessWidget {
  final _MembershipData membership;
  final VoidCallback onTap;

  const _MembershipCard({
    required this.membership,
    required this.onTap,
  });

  Color _roleBackground() {
    switch (membership.role) {
      case 'Admin':
        return AppColors.yellowLight;

      case 'Officer':
        return AppColors.greenLight;

      default:
        return AppColors.blueLight;
    }
  }

  Color _roleColor() {
    switch (membership.role) {
      case 'Admin':
        return AppColors.yellowDark;

      case 'Officer':
        return AppColors.greenDark;

      default:
        return AppColors.blueDark;
    }
  }

  IconData _roleIcon() {
    switch (membership.role) {
      case 'Admin':
        return Icons.admin_panel_settings_outlined;

      case 'Officer':
        return Icons.workspace_premium_outlined;

      default:
        return Icons.person_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Organization icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.blueLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      membership.icon,
                      color: AppColors.blue,
                      size: 27,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          membership.organizationName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          membership.category,
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

              const SizedBox(height: 16),

              // Role
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _roleBackground(),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _roleIcon(),
                      size: 15,
                      color: _roleColor(),
                    ),

                    const SizedBox(width: 6),

                    Text(
                      membership.role,
                      style: TextStyle(
                        color: _roleColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              const Divider(),

              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 15,
                    color: AppColors.textMuted,
                  ),

                  const SizedBox(width: 6),

                  Expanded(
                    child: Text(
                      'Joined ${membership.joinedDate}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),

                  const Icon(
                    Icons.people_outline_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),

                  const SizedBox(width: 5),

                  Text(
                    '${membership.members}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              // Admin indicator
              if (membership.role == 'Admin') ...[
                const SizedBox(height: 14),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.yellowLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings_outlined,
                        size: 18,
                        color: AppColors.yellowDark,
                      ),

                      SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          'You have administrative access to '
                          'this organization.',
                          style: TextStyle(
                            color: AppColors.yellowDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// EMPTY STATE
// ============================================================================

class _EmptyMemberships extends StatelessWidget {
  final String filter;

  const _EmptyMemberships({
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.groups_outlined,
              size: 58,
              color: AppColors.textMuted,
            ),

            const SizedBox(height: 16),

            Text(
              filter == 'All'
                  ? 'No organizations yet'
                  : 'No $filter organizations',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              filter == 'All'
                  ? 'Organizations you join will appear here.'
                  : 'You currently have no organizations '
                      'with this role.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),

            if (filter == 'All') ...[
              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: () {
                  context.pop();
                },
                icon: const Icon(Icons.search_rounded),
                label: const Text('Discover Organizations'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}