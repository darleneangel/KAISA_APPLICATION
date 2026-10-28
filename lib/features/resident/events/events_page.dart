import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/kaisa_resident_design.dart';
import 'kaisa_event_widgets.dart';
import 'kaisa_events_repository.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});
  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final _search = TextEditingController();
  List<KaisaEvent> _events = [];
  String _category = 'All';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await KaisaEventsRepository.instance.listEvents();
      if (mounted) setState(() => _events = result);
    } catch (e) {
      debugPrint('KAISA events load: $e');
      if (mounted)
        setState(
          () => _error =
              'Could not load events from Supabase. Check your connection or Events migration.',
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventCategories = _events.map((e) => e.category).toSet().toList()
      ..sort();
    final categories = ['All', ...eventCategories];
    final term = _search.text.trim().toLowerCase();
    final shown =
        _events
            .where(
              (e) =>
                  !e.isPast &&
                  (_category == 'All' || e.category == _category) &&
                  (term.isEmpty ||
                      '${e.title} ${e.organization} ${e.location} ${e.category}'
                          .toLowerCase()
                          .contains(term)),
            )
            .toList()
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return Scaffold(
      backgroundColor: KaisaResidentDesign.paper,
      body: RefreshIndicator(
        onRefresh: _reload,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 600;
            final padding = KaisaResidentDesign.pagePadding(
              constraints.maxWidth,
            );
            return ListView(
              padding: EdgeInsets.fromLTRB(padding, 22, padding, 90),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: KaisaResidentDesign.desktopWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        KaisaEventsHeading(
                          eyebrow: 'DISCOVER LOCAL ACTIVITIES',
                          title: 'Community Events',
                          subtitle:
                              'Find meaningful ways to participate in your community.',
                          action: IconButton(
                            tooltip: 'Refresh events',
                            icon: const Icon(
                              Icons.refresh_rounded,
                              color: KaisaResidentDesign.forest,
                            ),
                            onPressed: _reload,
                          ),
                        ),
                        const SizedBox(height: 24),
                        KaisaEventsHero(
                          title: 'Great moments begin\nwith showing up.',
                          subtitle:
                              'Explore upcoming programs, meet neighbors and contribute to your community.',
                          icon: Icons.calendar_month_rounded,
                          action: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: KaisaResidentDesign.yellow,
                              foregroundColor: KaisaResidentDesign.forest,
                            ),
                            onPressed: () => context.go('/resident/my-events'),
                            icon: const Icon(Icons.event_available_outlined),
                            label: const Text('My registrations'),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _search,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText:
                                'Search events, locations or organizations',
                            prefixIcon: const Icon(Icons.search_rounded),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(
                                color: KaisaResidentDesign.border,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(
                                color: KaisaResidentDesign.border,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 13),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final category in categories)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(category),
                                    selected: _category == category,
                                    selectedColor: const Color(0xFFE4F2E8),
                                    onSelected: (_) =>
                                        setState(() => _category = category),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 23),
                        KaisaResidentSectionHeading(
                          title: 'Upcoming opportunities',
                          subtitle: _loading
                              ? 'Loading events...'
                              : '${shown.length} available event${shown.length == 1 ? '' : 's'}',
                        ),
                        const SizedBox(height: 14),
                        if (_loading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_error != null)
                          KaisaResidentCard(
                            child: Column(
                              children: [
                                Text(_error!, textAlign: TextAlign.center),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: _reload,
                                  child: const Text('Try again'),
                                ),
                              ],
                            ),
                          )
                        else if (shown.isEmpty)
                          KaisaResidentCard(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.event_busy_outlined,
                                  size: 43,
                                  color: KaisaResidentDesign.green,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No upcoming events found',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Try another search or check back for newly published activities.',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        else
                          LayoutBuilder(
                            builder: (context, c) {
                              final cols = c.maxWidth >= 850
                                  ? 3
                                  : c.maxWidth >= 520
                                  ? 2
                                  : 1;
                              const gap = 14.0;
                              final itemWidth =
                                  (c.maxWidth - gap * (cols - 1)) / cols;
                              return Wrap(
                                spacing: gap,
                                runSpacing: gap,
                                children: [
                                  for (final e in shown)
                                    SizedBox(
                                      width: itemWidth,
                                      child: KaisaEventCard(
                                        event: e,
                                        onTap: () => context.push(
                                          '/resident/event-details',
                                          extra: e.toRouteExtra(),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        if (narrow) const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
