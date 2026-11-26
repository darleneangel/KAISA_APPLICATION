import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../widgets/kaisa_resident_design.dart';
import 'kaisa_event_widgets.dart';
import 'event_details_modal.dart';
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
    this.inDialog = false,
    this.coverAsset,
    this.openOrganizer,
    this.onRegistrationChanged,
  });
  final String? eventId;
  final String title, organization, category, description, date, time, location;
  final int participants, capacity;
  final bool inDialog;
  final String? coverAsset;
  final VoidCallback? openOrganizer;
  final VoidCallback? onRegistrationChanged;
  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  KaisaEvent? _event;
  Map<String, dynamic>? _eventInfo;
  List<Map<String, dynamic>>? _feedback;
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
        if (widget.inDialog)
          KaisaEventsRepository.instance.getPublishedEventInfo(widget.eventId!),
        if (widget.inDialog) _loadFeedback(widget.eventId!),
      ]);
      if (!mounted) return;
      setState(() {
        _event = details[0] as KaisaEvent?;
        _tier2 = details[1] == true;
        _eventInfo = widget.inDialog
            ? details[2] as Map<String, dynamic>?
            : null;
        _feedback = widget.inDialog
            ? details[3] as List<Map<String, dynamic>>?
            : null;
      });
      if (_event == null) _error = 'This event is no longer available.';
    } catch (e) {
      debugPrint('KAISA event detail load: $e');
      if (mounted) {
        setState(
          () => _error =
              'Unable to load the event. Check the database migration and route event ID.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<Map<String, dynamic>>?> _loadFeedback(String id) async {
    try {
      return await KaisaEventsRepository.instance.getVerifiedFeedback(id);
    } catch (_) {
      return null;
    }
  }

  void _notice(String value) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(value)));
    }
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
      if (go == true && mounted) {
        final router = GoRouter.of(context);
        if (widget.inDialog) Navigator.of(context).pop();
        router.push('/resident/identity-verification');
      }
      return;
    }
    final cancel = event.isRegistered;
    if (!cancel) {
      setState(() => _busy = true);
      Map<String, dynamic>? details;
      try {
        details = await KaisaEventsRepository.instance.getPublishedEventInfo(
          event.id,
        );
      } catch (_) {
        _notice('Could not check registration requirements. Please try again.');
        return;
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      if (!mounted) return;
      if (details == null) {
        _notice('This event is no longer available for registration.');
        return;
      }
      final requirement = eventRegistrationRequirement(
        details['instructions'] as String?,
      );
      if (requirement != null) {
        final email = details['contact_email'] as String?;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Organizer approval required'),
            content: SelectableText(
              '$requirement\n\nContact the organizer for registration instructions.${email == null || email.isEmpty ? '' : '\n$email'}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
        return;
      }
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(
          cancel
              ? 'Cancel registration?'
              : 'Are you sure you want to register for this event?',
        ),
        content: Text(
          cancel
              ? 'Cancel your registration for “${event.title}”?'
              : 'Confirm your participation in “${event.title}”.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(cancel ? 'Go back' : 'No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(cancel ? 'Cancel registration' : 'Yes'),
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
      widget.onRegistrationChanged?.call();
      await _reload();
      if (cancel) {
        _notice('Your registration has been cancelled.');
      } else if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            icon: const Icon(
              Icons.check_circle_rounded,
              size: 42,
              color: KaisaResidentDesign.forest,
            ),
            title: const Text('You’re registered!'),
            content: Text(
              'Your registration for “${event.title}” is confirmed.',
            ),
            actions: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: KaisaResidentDesign.forest,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
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
    if (widget.inDialog) {
      final event = _event;
      return EventDetailsModal(
        title: event?.title ?? widget.title,
        coverAsset: widget.coverAsset,
        openOrganizer: widget.openOrganizer,
        event: event,
        info: _eventInfo,
        feedback: _feedback,
        loading: _loading,
        error: _error,
        retry: _reload,
        registrationLabel: _busy
            ? 'Saving…'
            : event?.isRegistered == true
            ? 'Cancel registration'
            : event?.isPast == true
            ? 'Event finished'
            : event?.isFull == true
            ? 'Registration full'
            : eventRegistrationRequirement(
                    _eventInfo?['instructions'] as String?,
                  ) !=
                  null
            ? 'View registration requirements'
            : _tier2
            ? 'Register for event'
            : 'Get Tier 2 verified',
        register:
            event == null ||
                _busy ||
                (!event.isRegistered && (event.isPast || event.isFull))
            ? null
            : _changeRegistration,
      );
    }
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
