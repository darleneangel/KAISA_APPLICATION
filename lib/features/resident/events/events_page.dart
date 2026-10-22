import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/kaisa_ui.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});
  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final search = TextEditingController();
  String category = 'All';
  final events = const [
    (
      'Community Clean-Up Drive',
      'Community Environment Network',
      'Environment',
      'October 12, 2026',
      '8:00 AM - 11:00 AM',
      'Barangay Covered Court',
      42,
      80,
      Icons.eco_rounded,
    ),
    (
      'Youth Leadership Workshop',
      'KAISA Youth Volunteers',
      'Youth',
      'October 18, 2026',
      '1:00 PM - 5:00 PM',
      'Community Hall',
      35,
      50,
      Icons.groups_rounded,
    ),
    (
      'Community Basketball Tournament',
      'KAISA Sports Club',
      'Sports',
      'October 24, 2026',
      '7:00 AM - 4:00 PM',
      'Community Sports Center',
      64,
      100,
      Icons.sports_basketball_rounded,
    ),
    (
      'Free Learning Session',
      'Community Learning Circle',
      'Education',
      'November 5, 2026',
      '9:00 AM - 12:00 PM',
      'Community Learning Center',
      28,
      60,
      Icons.school_rounded,
    ),
    (
      'Community Consultation',
      'Community Development Council',
      'Community',
      'November 14, 2026',
      '2:00 PM - 5:00 PM',
      'Barangay Hall',
      51,
      100,
      Icons.forum_rounded,
    ),
  ];
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = events
        .where(
          (e) =>
              (category == 'All' || e.$3 == category) &&
              ('${e.$1} ${e.$2} ${e.$6}'.toLowerCase().contains(
                search.text.trim().toLowerCase(),
              )),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          IconButton(
            tooltip: 'My Events',
            onPressed: () => context.push('/resident/my-events'),
            icon: const Icon(Icons.event_available_outlined),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: KaisaPageLayout(
        children: [
          const KaisaHero(
            eyebrow: 'DISCOVER LOCAL ACTIVITIES',
            title: 'Find your next\ncommunity moment.',
            subtitle:
                'Explore upcoming programs and activities in Cavite City.',
            icon: Icons.calendar_month_rounded,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search events or locations',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in [
                'All',
                'Community',
                'Environment',
                'Youth',
                'Education',
                'Sports',
              ])
                ChoiceChip(
                  label: Text(c),
                  selected: category == c,
                  onSelected: (_) => setState(() => category = c),
                ),
            ],
          ),
          const SizedBox(height: 21),
          Text(
            '${matches.length} opportunities to discover',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
          ),
          const SizedBox(height: 14),
          if (matches.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('No events match your search. Try another category.'),
            ),
          KaisaResponsiveGrid(
            children: [
              for (final e in matches)
                KaisaTile(
                  title: e.$1,
                  subtitle: '${e.$2}  •  ${e.$4}\n${e.$6}',
                  icon: e.$9,
                  onTap: () => context.push(
                    '/resident/event-details',
                    extra: {
                      'title': e.$1,
                      'organization': e.$2,
                      'category': e.$3,
                      'description':
                          'Join this community event and connect with other residents.',
                      'date': e.$4,
                      'time': e.$5,
                      'location': e.$6,
                      'participants': e.$7,
                      'capacity': e.$8,
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
