import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class MyEventsPage extends StatefulWidget {
  const MyEventsPage({super.key});

  @override
  State<MyEventsPage> createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage> {
  String selectedFilter = 'Upcoming';

  final List<String> filters = [
    'Upcoming',
    'Completed',
    'Cancelled',
  ];

  // ============================================================
  // PROTOTYPE DATA ONLY
  //
  // Later these registrations will come from the database.
  // ============================================================

  final List<_MyEventData> registeredEvents = const [
    _MyEventData(
      title: 'Community Clean-Up Drive',
      organization: 'Community Environment Network',
      category: 'Environment',
      description:
          'Join fellow residents in keeping our community clean '
          'and promoting environmental responsibility.',
      date: 'October 12, 2026',
      month: 'OCT',
      day: '12',
      time: '8:00 AM - 11:00 AM',
      location: 'Barangay Covered Court',
      participants: 42,
      capacity: 80,
      status: 'Upcoming',
    ),
    _MyEventData(
      title: 'Youth Leadership Workshop',
      organization: 'KAISA Youth Volunteers',
      category: 'Youth',
      description:
          'A leadership development workshop designed to empower '
          'young residents to become active community leaders.',
      date: 'October 18, 2026',
      month: 'OCT',
      day: '18',
      time: '1:00 PM - 5:00 PM',
      location: 'Community Hall',
      participants: 35,
      capacity: 50,
      status: 'Upcoming',
    ),
    _MyEventData(
      title: 'Community Health Seminar',
      organization: 'Community Development Council',
      category: 'Health & Wellness',
      description:
          'A community seminar focused on health awareness, '
          'wellness, and preventive care.',
      date: 'September 20, 2026',
      month: 'SEP',
      day: '20',
      time: '9:00 AM - 12:00 PM',
      location: 'Barangay Hall',
      participants: 67,
      capacity: 80,
      status: 'Completed',
    ),
    _MyEventData(
      title: 'Youth Sports Day',
      organization: 'KAISA Sports Club',
      category: 'Sports',
      description:
          'A recreational sports activity promoting teamwork, '
          'fitness, and community participation.',
      date: 'September 5, 2026',
      month: 'SEP',
      day: '05',
      time: '7:00 AM - 3:00 PM',
      location: 'Community Sports Center',
      participants: 89,
      capacity: 100,
      status: 'Completed',
    ),
    _MyEventData(
      title: 'Tree Planting Activity',
      organization: 'Community Environment Network',
      category: 'Environment',
      description:
          'A community tree planting initiative promoting '
          'environmental sustainability.',
      date: 'October 3, 2026',
      month: 'OCT',
      day: '03',
      time: '6:30 AM - 10:00 AM',
      location: 'Community Eco Park',
      participants: 38,
      capacity: 60,
      status: 'Cancelled',
    ),
  ];

  List<_MyEventData> get filteredEvents {
    return registeredEvents
        .where(
          (event) => event.status == selectedFilter,
        )
        .toList();
  }

  int _countStatus(String status) {
    return registeredEvents
        .where((event) => event.status == status)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final events = filteredEvents;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Events',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Your event registrations',
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
            // ==================================================
            // SUMMARY
            // ==================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                14,
              ),
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
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.event_available_outlined,
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
                            'Event Activity',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            '${_countStatus('Upcoming')} upcoming '
                            'event${_countStatus('Upcoming') == 1 ? '' : 's'}',
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

            // ==================================================
            // FILTERS
            // ==================================================

            SizedBox(
              height: 58,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = filters[index];

                  return ChoiceChip(
                    label: Text(
                      '$filter (${_countStatus(filter)})',
                    ),
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

            // ==================================================
            // EVENT LIST
            // ==================================================

            Expanded(
              child: events.isEmpty
                  ? _EmptyMyEvents(
                      status: selectedFilter,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        10,
                        20,
                        50,
                      ),
                      itemCount: events.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final event = events[index];

                        return _RegisteredEventCard(
                          event: event,
                          onTap: () {
                            context.push(
                              '/resident/event-details',
                              extra: {
                                'title': event.title,
                                'organization':
                                    event.organization,
                                'category':
                                    event.category,
                                'description':
                                    event.description,
                                'date': event.date,
                                'time': event.time,
                                'location':
                                    event.location,
                                'participants':
                                    event.participants,
                                'capacity':
                                    event.capacity,
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
// EVENT DATA
// ============================================================================

class _MyEventData {
  final String title;
  final String organization;
  final String category;
  final String description;

  final String date;
  final String month;
  final String day;
  final String time;
  final String location;

  final int participants;
  final int capacity;

  final String status;

  const _MyEventData({
    required this.title,
    required this.organization,
    required this.category,
    required this.description,
    required this.date,
    required this.month,
    required this.day,
    required this.time,
    required this.location,
    required this.participants,
    required this.capacity,
    required this.status,
  });
}

// ============================================================================
// REGISTERED EVENT CARD
// ============================================================================

class _RegisteredEventCard extends StatelessWidget {
  final _MyEventData event;
  final VoidCallback onTap;

  const _RegisteredEventCard({
    required this.event,
    required this.onTap,
  });

  Color _statusBackground() {
    switch (event.status) {
      case 'Completed':
        return AppColors.greenLight;

      case 'Cancelled':
        return AppColors.blueLight;

      default:
        return AppColors.blueLight;
    }
  }

  Color _statusColor() {
    switch (event.status) {
      case 'Completed':
        return AppColors.greenDark;

      case 'Cancelled':
        return AppColors.textSecondary;

      default:
        return AppColors.blueDark;
    }
  }

  IconData _statusIcon() {
    switch (event.status) {
      case 'Completed':
        return Icons.check_circle_outline_rounded;

      case 'Cancelled':
        return Icons.cancel_outlined;

      default:
        return Icons.schedule_rounded;
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
                  // --------------------------------------------
                  // DATE
                  // --------------------------------------------

                  Container(
                    width: 60,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: event.status == 'Cancelled'
                          ? AppColors.border
                          : AppColors.blueLight,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Text(
                          event.month,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: event.status == 'Cancelled'
                                ? AppColors.textMuted
                                : AppColors.blueDark,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          event.day,
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            color: event.status == 'Cancelled'
                                ? AppColors.textMuted
                                : AppColors.blueDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 14),

                  // --------------------------------------------
                  // EVENT INFO
                  // --------------------------------------------

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: event.status == 'Cancelled'
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          event.organization,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.blue,
                            fontWeight: FontWeight.w600,
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
                            Expanded(
                              child: Text(
                                event.time,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color:
                                      AppColors.textSecondary,
                                ),
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
                                event.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color:
                                      AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 5),

                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              const Divider(),

              const SizedBox(height: 8),

              // --------------------------------------------
              // STATUS
              // --------------------------------------------

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _statusBackground(),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _statusIcon(),
                          size: 15,
                          color: _statusColor(),
                        ),

                        const SizedBox(width: 5),

                        Text(
                          event.status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _statusColor(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  if (event.status == 'Upcoming')
                    const Text(
                      'Registered',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.greenDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
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

class _EmptyMyEvents extends StatelessWidget {
  final String status;

  const _EmptyMyEvents({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              status == 'Completed'
                  ? Icons.history_rounded
                  : status == 'Cancelled'
                      ? Icons.event_busy_outlined
                      : Icons.event_available_outlined,
              size: 58,
              color: AppColors.textMuted,
            ),

            const SizedBox(height: 16),

            Text(
              'No $status events',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              status == 'Upcoming'
                  ? 'Events you register for will appear here.'
                  : status == 'Completed'
                      ? 'Your completed events will appear here.'
                      : 'Cancelled event registrations will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),

            if (status == 'Upcoming') ...[
              const SizedBox(height: 20),

              FilledButton.icon(
                onPressed: () {
                  context.pop();
                },
                icon: const Icon(
                  Icons.explore_outlined,
                ),
                label: const Text(
                  'Browse Events',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}