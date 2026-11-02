import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Read-only first version of Events Management; scoped to the active organization.
/// Creating/editing/publishing events requires a separate protected write workflow.
class KaisaOrgEventsManagementPage extends StatefulWidget {
  const KaisaOrgEventsManagementPage({super.key});

  @override
  State<KaisaOrgEventsManagementPage> createState() =>
      _KaisaOrgEventsManagementPageState();
}

class _KaisaOrgEventsManagementPageState
    extends State<KaisaOrgEventsManagementPage> {
  static const forest = Color(0xFF14532D);
  List<Map<String, dynamic>> events = [];
  bool loading = true;
  String? error;
  String? organizationId;
  String? filterDate;
  String? eventId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final params = GoRouterState.of(context).uri.queryParameters;
    final next = params['organizationId'];
    final nextDate = params['date'];
    final nextEvent = params['eventId'];
    if (organizationId != next ||
        filterDate != nextDate ||
        eventId != nextEvent) {
      organizationId = next;
      filterDate = nextDate;
      eventId = nextEvent;
      _load();
    }
  }

  Future<void> _load() async {
    final id = organizationId;
    if (id == null || id.isEmpty) {
      setState(() {
        error = 'No organization selected';
        loading = false;
      });
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await Supabase.instance.client.rpc(
        'kaisa_admin_event_schedule',
        params: {'p_organization_id': id},
      );
      if (!mounted || organizationId != id) return;
      setState(() {
        events = (result as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        loading = false;
      });
    } catch (e) {
      if (mounted && organizationId == id)
        setState(() {
          error = e.toString();
          loading = false;
        });
    }
  }

  DateTime? _date(Object? input) =>
      input == null ? null : DateTime.tryParse(input.toString())?.toLocal();
  String _stamp(Object? input) {
    final d = _date(input);
    if (d == null) return 'TBA';
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}  $hour:${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  void _clearFilters() {
    if (organizationId == null) return;
    context.go(
      Uri(
        path: '/organization-admin/events',
        queryParameters: {'organizationId': organizationId!},
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = events.where((e) {
      final date = _date(e['starts_at']);
      final dayKey = date == null
          ? ''
          : '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      return (filterDate == null || dayKey == filterDate) &&
          (eventId == null || e['event_id'].toString() == eventId);
    }).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ORGANIZATION MANAGEMENT',
                style: TextStyle(
                  color: Color(0xFF237A50),
                  fontSize: 11,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Events Management',
                style: TextStyle(
                  color: forest,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Events assigned to your organization, with schedule and participation information.',
              ),
              const SizedBox(height: 16),
              if (filterDate != null || eventId != null)
                Wrap(
                  spacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Chip(
                      label: Text(
                        filterDate != null
                            ? 'Date: $filterDate'
                            : 'Selected event',
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.close),
                      label: const Text('Show all events'),
                    ),
                  ],
                ),
              if (loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(),
                  ),
                ),
              if (error != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text('Could not load organization events: $error'),
                  ),
                ),
              if (!loading && error == null && visible.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('No events found for this selection.'),
                  ),
                ),
              for (final event in visible)
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (event['title'] ?? 'Event').toString(),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: forest,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            Text('Starts: ${_stamp(event['starts_at'])}'),
                            Text('Ends: ${_stamp(event['ends_at'])}'),
                            Text('Venue: ${event['location'] ?? 'TBA'}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Registered ${event['registered'] ?? 0}  •  Checked in ${event['present'] ?? 0}  •  Capacity ${event['capacity'] ?? '—'}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              const Text(
                'Event creation, editing and publishing require a separate authorized workflow. This page currently provides secure read-only event management.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
