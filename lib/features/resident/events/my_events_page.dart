import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/kaisa_resident_design.dart';
import 'kaisa_event_widgets.dart';
import 'kaisa_events_repository.dart';

class MyEventsPage extends StatefulWidget {
  const MyEventsPage({super.key});
  @override
  State<MyEventsPage> createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage> {
  String _filter = 'Upcoming';
  bool _loading = true;
  String? _error;
  List<KaisaEvent> _events = [];
  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final all = await KaisaEventsRepository.instance.listEvents();
      if (mounted)
        setState(
          () =>
              _events = all.where((e) => e.registrationStatus != null).toList(),
        );
    } catch (e) {
      debugPrint('KAISA my events: $e');
      if (mounted)
        setState(
          () => _error = 'Unable to load your registrations. Please try again.',
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<KaisaEvent> _filtered(String filter) =>
      _events.where((e) => e.statusLabel == filter).toList();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: KaisaResidentDesign.paper,
    body: RefreshIndicator(
      onRefresh: _reload,
      child: LayoutBuilder(
        builder: (context, box) {
          final pad = KaisaResidentDesign.pagePadding(box.maxWidth);
          final shown = _filtered(_filter)
            ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
          return ListView(
            padding: EdgeInsets.fromLTRB(pad, 22, pad, 90),
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
                        eyebrow: 'YOUR KAISA JOURNEY',
                        title: 'My Events',
                        subtitle:
                            'Track your registrations and community participation.',
                        action: IconButton(
                          onPressed: _reload,
                          tooltip: 'Refresh registrations',
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: KaisaResidentDesign.forest,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      KaisaEventsHero(
                        title: 'Every event is a\nchance to make a difference.',
                        subtitle:
                            'Keep track of your upcoming commitments and the experiences you have shared.',
                        icon: Icons.event_available_rounded,
                        action: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: KaisaResidentDesign.yellow,
                            foregroundColor: KaisaResidentDesign.forest,
                          ),
                          onPressed: () => context.go('/resident/events'),
                          icon: const Icon(Icons.explore_outlined),
                          label: const Text('Explore events'),
                        ),
                      ),
                      const SizedBox(height: 23),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final option in const [
                              'Upcoming',
                              'Completed',
                              'Cancelled',
                            ])
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  selected: option == _filter,
                                  selectedColor: const Color(0xFFE4F2E8),
                                  label: Text(
                                    '$option (${_filtered(option).length})',
                                  ),
                                  onSelected: (_) =>
                                      setState(() => _filter = option),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 19),
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
                              Text(_error!),
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
                                Icons.event_note_outlined,
                                size: 48,
                                color: KaisaResidentDesign.green,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'No $_filter events yet',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Your event activity will appear here once you register.',
                                textAlign: TextAlign.center,
                              ),
                              if (_filter == 'Upcoming')
                                TextButton(
                                  onPressed: () =>
                                      context.go('/resident/events'),
                                  child: const Text('Browse events'),
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
                            return Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: [
                                for (final e in shown)
                                  SizedBox(
                                    width:
                                        (c.maxWidth - gap * (cols - 1)) / cols,
                                    child: KaisaEventCard(
                                      event: e,
                                      showStatus: true,
                                      onTap: () async {
                                        await context.push(
                                          '/resident/event-details',
                                          extra: e.toRouteExtra(),
                                        );
                                        if (mounted) _reload();
                                      },
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
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
