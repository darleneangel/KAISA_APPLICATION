
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/community_event_model.dart';
import '../../../shared/models/organization_model.dart';
import '../../../shared/repositories/community_event_repository.dart';
import '../../../shared/repositories/organization_repository.dart';

class EventMonitoringPage extends StatefulWidget {
  const EventMonitoringPage({super.key});

  @override
  State<EventMonitoringPage> createState() =>
      _EventMonitoringPageState();
}

class _EventMonitoringPageState extends State<EventMonitoringPage> {
  final eventRepository = CommunityEventRepository.instance;
  final organizationRepository = OrganizationRepository.instance;
  final searchController = TextEditingController();

  String statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    eventRepository.addListener(_refresh);
    organizationRepository.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    eventRepository.removeListener(_refresh);
    organizationRepository.removeListener(_refresh);
    searchController.dispose();
    super.dispose();
  }

  RegistryOrganization? _findOrganization(String id) {
    for (final organization in organizationRepository.organizations) {
      if (organization.id == id) return organization;
    }
    return null;
  }

  String _organizationName(String id) {
    return _findOrganization(id)?.name ?? 'Unknown Organization';
  }

  List<CommunityEvent> get filteredEvents {
    final query = searchController.text.trim().toLowerCase();

    final results = eventRepository.events.where((event) {
      final matchesStatus =
          statusFilter == 'All' || event.status.label == statusFilter;

      final matchesSearch =
          event.title.toLowerCase().contains(query) ||
          event.location.toLowerCase().contains(query) ||
          event.id.toLowerCase().contains(query) ||
          _organizationName(event.organizationId)
              .toLowerCase()
              .contains(query);

      return matchesStatus && matchesSearch;
    }).toList();

    results.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return results;
  }

  String _date(DateTime date) {
    final month = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ][date.month - 1];

    return '$month ${date.day}, ${date.year}';
  }

  String _time(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Color _statusColor(CommunityEventStatus status) {
    switch (status) {
      case CommunityEventStatus.upcoming:
        return AppColors.blue;
      case CommunityEventStatus.ongoing:
        return AppColors.green;
      case CommunityEventStatus.completed:
        return const Color(0xFF64748B);
      case CommunityEventStatus.cancelled:
        return const Color(0xFFB45309);
    }
  }

  void _showEventDetails(CommunityEvent event) {
    final organization = _findOrganization(event.organizationId);
    final attendanceRate = event.registrationCount == 0
        ? 0.0
        : event.attendanceCount / event.registrationCount * 100;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(event.title),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('Event ID', event.id),
                _detailRow(
                  'Organization',
                  organization?.name ?? 'Unknown Organization',
                ),
                _detailRow('Status', event.status.label),
                _detailRow('Date', _date(event.startsAt)),
                _detailRow(
                  'Time',
                  '${_time(event.startsAt)} – ${_time(event.endsAt)}',
                ),
                _detailRow('Location', event.location),
                _detailRow(
                  'Registered Participants',
                  '${event.registrationCount}',
                ),
                _detailRow('Capacity', '${event.capacity}'),
                _detailRow(
                  'Recorded Attendance',
                  '${event.attendanceCount}',
                ),
                _detailRow(
                  'Attendance Rate',
                  '${attendanceRate.toStringAsFixed(1)}%',
                ),
                const Divider(height: 24),
                const Text(
                  'Description',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(event.description),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = filteredEvents;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Event Monitoring',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Monitor community events, registrations, '
              'and attendance across registered organizations.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 900
                    ? 4
                    : constraints.maxWidth >= 520
                        ? 2
                        : 1;
                const spacing = 12.0;
                final width = (constraints.maxWidth -
                        spacing * (columns - 1)) /
                    columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    _statCard(
                      'Total Events',
                      eventRepository.totalEvents,
                      Icons.event_note_rounded,
                      AppColors.blue,
                      width,
                    ),
                    _statCard(
                      'Upcoming Events',
                      eventRepository.upcomingEvents,
                      Icons.calendar_month_rounded,
                      AppColors.blue,
                      width,
                    ),
                    _statCard(
                      'Completed Events',
                      eventRepository.completedEvents,
                      Icons.task_alt_rounded,
                      AppColors.green,
                      width,
                    ),
                    _statCard(
                      'Registrations',
                      eventRepository.totalRegistrations,
                      Icons.groups_rounded,
                      const Color(0xFF8B5CF6),
                      width,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText:
                            'Search events, organizations, or locations',
                        prefixIcon: Icon(Icons.search_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: statusFilter,
                      decoration: const InputDecoration(
                        labelText: 'Event Status',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        'All',
                        'Upcoming',
                        'Ongoing',
                        'Completed',
                        'Cancelled',
                      ].map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => statusFilter = value ?? 'All');
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (events.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Text('No matching events found.'),
                  ),
                ),
              )
            else
              ...events.map(_eventCard),
          ],
        ),
      ),
    );
  }

  Widget _statCard(
    String title,
    int value,
    IconData icon,
    Color color,
    double width,
  ) {
    return SizedBox(
      width: width,
      child: Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.10),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 14),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eventCard(CommunityEvent event) {
    final organizationName =
        _organizationName(event.organizationId);
    final color = _statusColor(event.status);

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 10,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$organizationName • ${event.id}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Chip(
                  label: Text(event.status.label),
                  backgroundColor:
                      color.withValues(alpha: 0.12),
                  labelStyle: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              event.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _info(
                  Icons.calendar_today_rounded,
                  _date(event.startsAt),
                ),
                _info(
                  Icons.access_time_rounded,
                  _time(event.startsAt),
                ),
                _info(
                  Icons.location_on_outlined,
                  event.location,
                ),
              ],
            ),
            const Divider(height: 28),
            Wrap(
              spacing: 20,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _info(
                  Icons.how_to_reg_rounded,
                  '${event.registrationCount} registered',
                ),
                _info(
                  Icons.groups_rounded,
                  '${event.attendanceCount} attended',
                ),
                OutlinedButton.icon(
                  onPressed: () => _showEventDetails(event),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 17,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
