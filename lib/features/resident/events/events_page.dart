import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../widgets/resident_bottom_nav.dart';
import '../widgets/notification_bell.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final TextEditingController searchController =
      TextEditingController();

  String selectedCategory = 'All';

  final List<String> categories = [
    'All',
    'Community',
    'Environment',
    'Youth',
    'Education',
    'Sports',
  ];

  // ============================================================
  // PROTOTYPE DATA
  // Later, these will come from the database.
  // ============================================================

  final List<_EventData> events = const [
    _EventData(
      title: 'Community Clean-Up Drive',
      organization: 'Community Environment Network',
      category: 'Environment',
      description:
          'Join fellow residents in keeping our community clean '
          'and promoting environmental responsibility.',
      month: 'OCT',
      day: '12',
      date: 'October 12, 2026',
      time: '8:00 AM - 11:00 AM',
      location: 'Barangay Covered Court',
      participants: 42,
      capacity: 80,
      icon: Icons.eco_outlined,
    ),
    _EventData(
      title: 'Youth Leadership Workshop',
      organization: 'KAISA Youth Volunteers',
      category: 'Youth',
      description:
          'A leadership development workshop designed to empower '
          'young residents to become active community leaders.',
      month: 'OCT',
      day: '18',
      date: 'October 18, 2026',
      time: '1:00 PM - 5:00 PM',
      location: 'Community Hall',
      participants: 35,
      capacity: 50,
      icon: Icons.groups_outlined,
    ),
    _EventData(
      title: 'Community Basketball Tournament',
      organization: 'KAISA Sports Club',
      category: 'Sports',
      description:
          'Build teamwork and community spirit through a friendly '
          'basketball tournament for residents.',
      month: 'OCT',
      day: '24',
      date: 'October 24, 2026',
      time: '7:00 AM - 4:00 PM',
      location: 'Community Sports Center',
      participants: 64,
      capacity: 100,
      icon: Icons.sports_basketball_outlined,
    ),
    _EventData(
      title: 'Free Learning Session',
      organization: 'Community Learning Circle',
      category: 'Education',
      description:
          'An educational session featuring learning activities '
          'and knowledge-sharing for community residents.',
      month: 'NOV',
      day: '05',
      date: 'November 5, 2026',
      time: '9:00 AM - 12:00 PM',
      location: 'Community Learning Center',
      participants: 28,
      capacity: 60,
      icon: Icons.school_outlined,
    ),
    _EventData(
      title: 'Community Consultation',
      organization: 'Community Development Council',
      category: 'Community',
      description:
          'Share your ideas and concerns and take part in discussions '
          'about upcoming community programs.',
      month: 'NOV',
      day: '14',
      date: 'November 14, 2026',
      time: '2:00 PM - 5:00 PM',
      location: 'Barangay Hall',
      participants: 51,
      capacity: 100,
      icon: Icons.forum_outlined,
    ),
  ];

  List<_EventData> get filteredEvents {
    final query =
        searchController.text.trim().toLowerCase();

    return events.where((event) {
      final matchesCategory =
          selectedCategory == 'All' ||
              event.category == selectedCategory;

      final matchesSearch =
          query.isEmpty ||
              event.title.toLowerCase().contains(query) ||
              event.organization
                  .toLowerCase()
                  .contains(query) ||
              event.location
                  .toLowerCase()
                  .contains(query);

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
    final displayedEvents = filteredEvents;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Events',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Discover community activities',
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

          IconButton(
            tooltip: 'My Events',
            onPressed: () {
              context.push('/resident/my-events');
            },
            icon: const Icon(
              Icons.event_available_outlined,
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ====================================================
            // SEARCH
            // ====================================================

            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                18,
                20,
                8,
              ),
              child: TextField(
                controller: searchController,
                onChanged: (_) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: 'Search events...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                  ),
                  suffixIcon:
                      searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                searchController
                                    .clear();

                                setState(() {});
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                              ),
                            )
                          : null,
                ),
              ),
            ),

            // ====================================================
            // CATEGORY FILTERS
            // ====================================================

            SizedBox(
              height: 56,
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 7,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category =
                      categories[index];

                  return ChoiceChip(
                    label: Text(category),
                    selected:
                        selectedCategory == category,
                    onSelected: (_) {
                      setState(() {
                        selectedCategory =
                            category;
                      });
                    },
                  );
                },
              ),
            ),

            // ====================================================
            // EVENTS
            // ====================================================

            Expanded(
              child: displayedEvents.isEmpty
                  ? const _EmptyEvents()
                  : ListView.separated(
                      padding:
                          const EdgeInsets.fromLTRB(
                        20,
                        12,
                        20,
                        100,
                      ),
                      itemCount:
                          displayedEvents.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 14),
                      itemBuilder:
                          (context, index) {
                        final event =
                            displayedEvents[index];

                        return _EventCard(
                          event: event,
                          onTap: () {
                            context.push(
                              '/resident/event-details',
                              extra: {
                                'title': event.title,
                                'organization':
                                    event.organization,
                                'category': event.category,
                                'description':
                                    event.description,
                                'date': event.date,
                                'time': event.time,
                                'location': event.location,
                                'participants':
                                    event.participants,
                                'capacity': event.capacity,
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

      bottomNavigationBar:
          const ResidentBottomNav(
        currentIndex: 3,
      ),
    );
  }
}

// ================================================================
// EVENT DATA
// ================================================================

class _EventData {
  final String title;
  final String organization;
  final String category;
  final String description;

  final String month;
  final String day;
  final String date;
  final String time;
  final String location;

  final int participants;
  final int capacity;

  final IconData icon;

  const _EventData({
    required this.title,
    required this.organization,
    required this.category,
    required this.description,
    required this.month,
    required this.day,
    required this.date,
    required this.time,
    required this.location,
    required this.participants,
    required this.capacity,
    required this.icon,
  });
}

// ================================================================
// EVENT CARD
// ================================================================

class _EventCard extends StatelessWidget {
  final _EventData event;
  final VoidCallback onTap;

  const _EventCard({
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool almostFull =
        event.participants >=
            (event.capacity * 0.8);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ------------------------------------------------
              // DATE
              // ------------------------------------------------

              Container(
                width: 62,
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: AppColors.blueLight,
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      event.month,
                      style: const TextStyle(
                        color: AppColors.blueDark,
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      event.day,
                      style: const TextStyle(
                        color: AppColors.blueDark,
                        fontSize: 24,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // ------------------------------------------------
              // INFORMATION
              // ------------------------------------------------

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      event.organization,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.blue,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        const Icon(
                          Icons
                              .schedule_outlined,
                          size: 15,
                          color:
                              AppColors.textMuted,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            event.time,
                            style:
                                const TextStyle(
                              fontSize: 12,
                              color: AppColors
                                  .textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Icon(
                          Icons
                              .location_on_outlined,
                          size: 15,
                          color:
                              AppColors.textMuted,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            event.location,
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              fontSize: 12,
                              color: AppColors
                                  .textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ------------------------------------------
                    // PARTICIPANTS
                    // ------------------------------------------

                    Row(
                      children: [
                        Icon(
                          Icons
                              .people_outline_rounded,
                          size: 16,
                          color: almostFull
                              ? AppColors.yellowDark
                              : AppColors
                                  .textMuted,
                        ),

                        const SizedBox(width: 5),

                        Text(
                          '${event.participants}/${event.capacity} participants',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: almostFull
                                ? FontWeight.w700
                                : FontWeight.normal,
                            color: almostFull
                                ? AppColors.yellowDark
                                : AppColors
                                    .textSecondary,
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

// ================================================================
// EMPTY STATE
// ================================================================

class _EmptyEvents extends StatelessWidget {
  const _EmptyEvents();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 56,
              color: AppColors.textMuted,
            ),
            SizedBox(height: 16),
            Text(
              'No events found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 7),
            Text(
              'Try searching for another event or category.',
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