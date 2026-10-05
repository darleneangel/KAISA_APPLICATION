import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../widgets/resident_bottom_nav.dart';
import '../widgets/notification_bell.dart';



class OrganizationsPage extends StatefulWidget {
  const OrganizationsPage({super.key});

  @override
  State<OrganizationsPage> createState() => _OrganizationsPageState();
}

class _OrganizationsPageState extends State<OrganizationsPage> {
  final TextEditingController searchController = TextEditingController();

  String selectedCategory = 'All';

  final List<String> categories = [
    'All',
    'Youth',
    'Community',
    'Environment',
    'Education',
    'Sports',
  ];

  // Prototype data only.
  final List<_OrganizationData> organizations = const [
    _OrganizationData(
      name: 'KAISA Youth Volunteers',
      category: 'Youth',
      description:
          'Empowering young residents through volunteer work, leadership, and meaningful community participation.',
      members: 128,
      icon: Icons.volunteer_activism_outlined,
    ),
    _OrganizationData(
      name: 'Community Environment Network',
      category: 'Environment',
      description:
          'Promoting environmental responsibility through clean-up drives, sustainability projects, and community action.',
      members: 94,
      icon: Icons.eco_outlined,
    ),
    _OrganizationData(
      name: 'Community Learning Circle',
      category: 'Education',
      description:
          'Supporting residents through learning programs, educational activities, and knowledge-sharing initiatives.',
      members: 76,
      icon: Icons.school_outlined,
    ),
    _OrganizationData(
      name: 'KAISA Sports Club',
      category: 'Sports',
      description:
          'Bringing residents together through sports, recreation, fitness, and community tournaments.',
      members: 156,
      icon: Icons.sports_basketball_outlined,
    ),
    _OrganizationData(
      name: 'Community Development Council',
      category: 'Community',
      description:
          'Encouraging residents to participate in programs and initiatives that strengthen the local community.',
      members: 203,
      icon: Icons.groups_2_outlined,
    ),
  ];

  List<_OrganizationData> get filteredOrganizations {
    final query = searchController.text.trim().toLowerCase();

    return organizations.where((organization) {
      final matchesCategory = selectedCategory == 'All' ||
          organization.category == selectedCategory;

      final matchesSearch = query.isEmpty ||
          organization.name.toLowerCase().contains(query) ||
          organization.description.toLowerCase().contains(query) ||
          organization.category.toLowerCase().contains(query);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayedOrganizations = filteredOrganizations;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Organizations',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Discover your community',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          const NotificationBell(),

          PopupMenuButton<String>(
            tooltip: 'Organization Options',
            icon: const Icon(
              Icons.more_vert_rounded,
            ),
            onSelected: (value) {
              if (value == 'my-organizations') {
                context.push(
                  '/resident/my-organizations',
                );
              }

              if (value == 'request-organization') {
                context.push(
                  '/resident/request-organization',
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'my-organizations',
                child: Row(
                  children: [
                    Icon(Icons.groups_outlined),
                    SizedBox(width: 12),
                    Text('My Organizations'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'request-organization',
                child: Row(
                  children: [
                    Icon(Icons.add_business_outlined),
                    SizedBox(width: 12),
                    Text('Request Organization'),
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
        child: Column(
          children: [
            // ---------------------------------------------------------
            // SEARCH
            // ---------------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: TextField(
                controller: searchController,
                onChanged: (_) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: 'Search organizations...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded),
                        )
                      : null,
                ),
              ),
            ),

            // ---------------------------------------------------------
            // CATEGORY FILTERS
            // ---------------------------------------------------------
            SizedBox(
              height: 54,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = categories[index];

                  return ChoiceChip(
                    label: Text(category),
                    selected: selectedCategory == category,
                    onSelected: (_) {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                  );
                },
              ),
            ),

            // ---------------------------------------------------------
            // RESULTS
            // ---------------------------------------------------------
            Expanded(
              child: displayedOrganizations.isEmpty
                  ? const _EmptyOrganizations()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        14,
                        20,
                        100,
                      ),
                      itemCount: displayedOrganizations.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final organization =
                            displayedOrganizations[index];

                        return _OrganizationCard(
                          organization: organization,
                          onTap: () {
                            context.push(
                              '/resident/organization-details',
                              extra: {
                                'name': organization.name,
                                'category': organization.category,
                                'description': organization.description,
                                'members': organization.members,
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

      bottomNavigationBar: const ResidentBottomNav(
        currentIndex: 2,
      ),
    );
  }
}

// ============================================================================
// ORGANIZATION DATA
// ============================================================================

class _OrganizationData {
  final String name;
  final String category;
  final String description;
  final int members;
  final IconData icon;

  const _OrganizationData({
    required this.name,
    required this.category,
    required this.description,
    required this.members,
    required this.icon,
  });
}

// ============================================================================
// ORGANIZATION CARD
// ============================================================================

class _OrganizationCard extends StatelessWidget {
  final _OrganizationData organization;
  final VoidCallback onTap;

  const _OrganizationCard({
    required this.organization,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Organization icon
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.blueLight,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(
                  organization.icon,
                  color: AppColors.blue,
                  size: 28,
                ),
              ),

              const SizedBox(width: 15),

              // Organization information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      organization.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blueLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        organization.category,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blueDark,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      organization.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        const Icon(
                          Icons.people_outline_rounded,
                          size: 17,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${organization.members} members',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
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

// ============================================================================
// EMPTY SEARCH STATE
// ============================================================================

class _EmptyOrganizations extends StatelessWidget {
  const _EmptyOrganizations();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 52,
              color: AppColors.textMuted,
            ),
            SizedBox(height: 14),
            Text(
              'No organizations found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Try searching for another organization or category.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}