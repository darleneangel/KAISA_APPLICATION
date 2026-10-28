import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../widgets/kaisa_resident_design.dart';
import 'kaisa_event_widgets.dart';
import 'kaisa_events_repository.dart';

/// The constructor keeps the existing named arguments used by app_router.dart.
/// Pass eventId: data['event_id'] in the router for persisted registration.
class EventDetailsPage extends StatefulWidget {
  const EventDetailsPage({
    super.key,
    this.eventId,
    required this.title,
    required this.organization,
    required this.category,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    required this.participants,
    required this.capacity,
  });
  final String? eventId;
  final String title, organization, category, description, date, time, location;
  final int participants, capacity;
  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  KaisaEvent? _event;
  bool _tier2 = false;
  bool _busy = false;
  bool _loading = true;
  String? _error;

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
      if (widget.eventId == null || widget.eventId!.isEmpty) {
        throw StateError(
          'This event needs a database ID. Add eventId: data[\'event_id\'] to the router.',
        );
      }
      final details = await Future.wait<dynamic>([
        KaisaEventsRepository.instance.getEvent(widget.eventId!),
        KaisaEventsRepository.instance.isTier2(),
      ]);
      if (!mounted) return;
      setState(() {
        _event = details[0] as KaisaEvent?;
        _tier2 = details[1] == true;
      });
      if (_event == null) _error = 'This event is no longer available.';
    } catch (e) {
      debugPrint('KAISA event detail load: $e');
      if (mounted)
        setState(
          () => _error =
              'Unable to load the event. Check the database migration and route event ID.',
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _notice(String value) {
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> _changeRegistration() async {
    final event = _event;
    if (event == null || _busy) return;
    if (!event.isRegistered && !_tier2) {
      final go = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Tier 2 verification required'),
          content: const Text(
            'An LGU-approved Tier 2 account is required to register for community events.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Get verified'),
            ),
          ],
        ),
      );
      if (go == true && mounted)
        context.push('/resident/identity-verification');
      return;
    }
    final cancel = event.isRegistered;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(
          cancel ? 'Cancel registration?' : 'Register for this event?',
        ),
        content: Text(
          cancel
              ? 'Cancel your registration for “${event.title}”?'
              : 'Confirm your participation in “${event.title}”.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Go back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(cancel ? 'Cancel registration' : 'Register'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      if (cancel) {
        await KaisaEventsRepository.instance.cancel(event.id);
      } else {
        await KaisaEventsRepository.instance.register(event.id);
      }
      await _reload();
      _notice(
        cancel
            ? 'Your registration has been cancelled.'
            : 'You are registered for this event!',
      );
    } catch (e) {
      debugPrint('KAISA event registration: $e');
      final message = e.toString();
      _notice(
        message.contains('KAISA_')
            ? message
                  .split('KAISA_')
                  .last
                  .replaceAll('_', ' ')
                  .split(' ')
                  .join(' ')
                  .split(')')
                  .first
            : 'Could not update registration. Please retry.',
      );
      await _reload();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    final id = widget.eventId;
    if (id == null) return;
    final uri = Uri.base.replace(
      path: '/resident/events',
      queryParameters: {'event': id},
    );
    await Clipboard.setData(ClipboardData(text: uri.toString()));
    _notice('Events page link copied!');
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;
    return Scaffold(
      backgroundColor: KaisaResidentDesign.paper,
      body: RefreshIndicator(
        onRefresh: _reload,
        child: LayoutBuilder(
          builder: (context, bounds) {
            final pad = KaisaResidentDesign.pagePadding(bounds.maxWidth);
            return ListView(
              padding: EdgeInsets.fromLTRB(pad, 16, pad, 100),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 930),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () => context.canPop()
                                  ? context.pop()
                                  : context.go('/resident/events'),
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: const Text('Back to Events'),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Share event',
                              onPressed: _share,
                              icon: const Icon(
                                Icons.share_outlined,
                                color: KaisaResidentDesign.forest,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (_loading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(55),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_error != null)
                          KaisaResidentCard(
                            child: Column(
                              children: [
                                Text(_error!, textAlign: TextAlign.center),
                                TextButton(
                                  onPressed: _reload,
                                  child: const Text('Try again'),
                                ),
                              ],
                            ),
                          )
                        else if (event != null) ...[
                          KaisaEventsHeading(
                            eyebrow: 'EVENT DETAILS',
                            title: event.title,
                            subtitle: 'Hosted by ${event.organization}',
                          ),
                          const SizedBox(height: 21),
                          KaisaEventsHero(
                            title: 'Be part of something\nmeaningful.',
                            subtitle: event.description,
                            icon: Icons.celebration_outlined,
                          ),
                          const SizedBox(height: 22),
                          const KaisaResidentSectionHeading(
                            title: 'Event information',
                            subtitle: 'Everything you need before joining.',
                          ),
                          const SizedBox(height: 12),
                          KaisaResidentCard(
                            child: Column(
                              children: [
                                _DetailRow(
                                  icon: Icons.calendar_month_outlined,
                                  label: 'Date',
                                  value: event.dateLabel,
                                ),
                                const Divider(
                                  color: KaisaResidentDesign.border,
                                  height: 28,
                                ),
                                _DetailRow(
                                  icon: Icons.schedule_outlined,
                                  label: 'Time',
                                  value: event.timeLabel,
                                ),
                                const Divider(
                                  color: KaisaResidentDesign.border,
                                  height: 28,
                                ),
                                _DetailRow(
                                  icon: Icons.location_on_outlined,
                                  label: 'Location',
                                  value: event.location,
                                ),
                                const Divider(
                                  color: KaisaResidentDesign.border,
                                  height: 28,
                                ),
                                _DetailRow(
                                  icon: Icons.groups_2_outlined,
                                  label: 'Organized by',
                                  value: event.organization,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          const KaisaResidentSectionHeading(
                            title: 'Participation',
                          ),
                          const SizedBox(height: 12),
                          KaisaResidentCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.people_outline_rounded,
                                      color: KaisaResidentDesign.green,
                                    ),
                                    const SizedBox(width: 9),
                                    Expanded(
                                      child: Text(
                                        '${event.registeredCount} of ${event.capacity} registered',
                                        style: const TextStyle(
                                          color: KaisaResidentDesign.ink,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      event.isFull
                                          ? 'Full'
                                          : '${event.capacity - event.registeredCount} open',
                                      style: const TextStyle(
                                        color: KaisaResidentDesign.green,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                LinearProgressIndicator(
                                  value: event.capacity <= 0
                                      ? 0
                                      : (event.registeredCount / event.capacity)
                                            .clamp(0.0, 1.0),
                                  minHeight: 8,
                                  color: KaisaResidentDesign.green,
                                  backgroundColor: const Color(0xFFE5F1E8),
                                ),
                                if (event.isRegistered) ...[
                                  const SizedBox(height: 15),
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: KaisaResidentDesign.green,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'You are registered!',
                                        style: TextStyle(
                                          color: KaisaResidentDesign.forest,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (!_tier2 && !event.isRegistered) ...[
                                  const SizedBox(height: 15),
                                  const Text(
                                    'Tier 2 verification is required before registration.',
                                    style: TextStyle(
                                      color: KaisaResidentDesign.muted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: KaisaResidentDesign.forest,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 17,
                                ),
                              ),
                              onPressed:
                                  _busy ||
                                      (event.isPast && !event.isRegistered) ||
                                      (event.isFull && !event.isRegistered)
                                  ? null
                                  : _changeRegistration,
                              icon: Icon(
                                event.isRegistered
                                    ? Icons.event_busy_outlined
                                    : Icons.event_available_outlined,
                              ),
                              label: Text(
                                _busy
                                    ? 'Saving...'
                                    : event.isRegistered
                                    ? 'Cancel registration'
                                    : event.isPast
                                    ? 'Event finished'
                                    : event.isFull
                                    ? 'Registration full'
                                    : _tier2
                                    ? 'Register for event'
                                    : 'Get Tier 2 verified',
                              ),
                            ),
                          ),
                        ],
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 43,
        height: 43,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFE7F3EA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: KaisaResidentDesign.green),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: KaisaResidentDesign.muted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                color: KaisaResidentDesign.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
