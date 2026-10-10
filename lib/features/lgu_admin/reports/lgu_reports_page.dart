import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/community_event_model.dart';
import '../../../shared/repositories/community_event_repository.dart';
import '../../../shared/repositories/organization_repository.dart';

class LguReportsPage extends StatefulWidget {
  const LguReportsPage({super.key});

  @override
  State<LguReportsPage> createState() => _LguReportsPageState();
}

class _LguReportsPageState extends State<LguReportsPage> {
  final OrganizationRepository organizationRepository =
      OrganizationRepository.instance;

  final CommunityEventRepository eventRepository =
      CommunityEventRepository.instance;

  @override
  void initState() {
    super.initState();
    organizationRepository.addListener(_refresh);
    eventRepository.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    organizationRepository.removeListener(_refresh);
    eventRepository.removeListener(_refresh);
    super.dispose();
  }

  String _organizationName(String id) {
    for (final org in organizationRepository.organizations) {
      if (org.id == id) return org.name;
    }
    return 'Unknown Organization';
  }

  Map<String, int> get organizationCategories {
    final counts = <String, int>{};

    for (final org in organizationRepository.organizations) {
      counts.update(org.category, (count) => count + 1, ifAbsent: () => 1);
    }

    return Map.fromEntries(
      counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  int get cancelledEvents => eventRepository.events
      .where((event) => event.status == CommunityEventStatus.cancelled)
      .length;

  double get attendanceRate {
    final registered = eventRepository.events
        .where((event) => event.status == CommunityEventStatus.completed)
        .fold<int>(0, (total, event) => total + event.registrationCount);

    final attended = eventRepository.events
        .where((event) => event.status == CommunityEventStatus.completed)
        .fold<int>(0, (total, event) => total + event.attendanceCount);

    if (registered == 0) return 0;
    return attended / registered * 100;
  }

  String _formatDate(DateTime date) {
    final month = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][date.month - 1];

    return '$month ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final totalOrganizations = organizationRepository.totalOrganizations;

    final activeOrganizations = organizationRepository.activeOrganizations;

    final totalEvents = eventRepository.totalEvents;
    final totalRegistrations = eventRepository.totalRegistrations;
    final totalAttendance = eventRepository.totalAttendance;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Reports & Analytics',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Review organizational activity, community '
              'participation, and event performance.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // OVERVIEW STATISTICS
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 950
                    ? 4
                    : constraints.maxWidth >= 540
                    ? 2
                    : 1;

                const spacing = 14.0;

                final cardWidth =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    _statCard(
                      'Organizations',
                      totalOrganizations,
                      Icons.apartment_rounded,
                      AppColors.blue,
                      cardWidth,
                    ),
                    _statCard(
                      'Active Organizations',
                      activeOrganizations,
                      Icons.verified_rounded,
                      AppColors.green,
                      cardWidth,
                    ),
                    _statCard(
                      'Total Events',
                      totalEvents,
                      Icons.event_note_rounded,
                      AppColors.blueDark,
                      cardWidth,
                    ),
                    _statCard(
                      'Registrations',
                      totalRegistrations,
                      Icons.groups_rounded,
                      const Color(0xFF8B5CF6),
                      cardWidth,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 26),

            // ORGANIZATION BREAKDOWN
            _sectionTitle('Organization Analytics'),
            const SizedBox(height: 12),

            _panel(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Organization Status',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  _progressRow(
                    'Active',
                    activeOrganizations,
                    totalOrganizations,
                    AppColors.green,
                  ),
                  const SizedBox(height: 16),
                  _progressRow(
                    'Inactive',
                    organizationRepository.inactiveOrganizations,
                    totalOrganizations,
                    const Color(0xFFB7791F),
                  ),
                  const Divider(height: 32),
                  const Text(
                    'Organizations by Category',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  if (organizationCategories.isEmpty)
                    const Text('No organizations registered.')
                  else
                    ...organizationCategories.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _progressRow(
                          entry.key,
                          entry.value,
                          totalOrganizations,
                          AppColors.blue,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            // EVENT ANALYTICS
            _sectionTitle('Event Analytics'),
            const SizedBox(height: 12),

            _panel(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Events by Status',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  _progressRow(
                    'Upcoming',
                    eventRepository.upcomingEvents,
                    totalEvents,
                    AppColors.blue,
                  ),
                  const SizedBox(height: 16),
                  _progressRow(
                    'Ongoing',
                    eventRepository.ongoingEvents,
                    totalEvents,
                    AppColors.green,
                  ),
                  const SizedBox(height: 16),
                  _progressRow(
                    'Completed',
                    eventRepository.completedEvents,
                    totalEvents,
                    const Color(0xFF64748B),
                  ),
                  const SizedBox(height: 16),
                  _progressRow(
                    'Cancelled',
                    cancelledEvents,
                    totalEvents,
                    const Color(0xFFB45309),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            // PARTICIPATION ANALYTICS
            _sectionTitle('Community Participation'),
            const SizedBox(height: 12),

            _panel(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 40,
                    runSpacing: 20,
                    children: [
                      _metric(
                        'Total Registrations',
                        '$totalRegistrations',
                        Icons.how_to_reg_rounded,
                      ),
                      _metric(
                        'Recorded Attendance',
                        '$totalAttendance',
                        Icons.fact_check_rounded,
                      ),
                      _metric(
                        'Completed-Event Attendance Rate',
                        '${attendanceRate.toStringAsFixed(1)}%',
                        Icons.percent_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Attendance rate is calculated using '
                    'registrations and recorded attendance '
                    'from completed events only.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            // EVENT SUMMARY
            _sectionTitle('Event Summary'),
            const SizedBox(height: 12),

            _panel(
              eventRepository.events.isEmpty
                  ? const Text('No events available.')
                  : Column(
                      children: eventRepository.events.map((event) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _organizationName(event.organizationId),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 14,
                                runSpacing: 8,
                                children: [
                                  _smallInfo(
                                    Icons.calendar_today_rounded,
                                    _formatDate(event.startsAt),
                                  ),
                                  _smallInfo(
                                    Icons.event_available_rounded,
                                    event.status.label,
                                  ),
                                  _smallInfo(
                                    Icons.people_outline_rounded,
                                    '${event.registrationCount} registered',
                                  ),
                                  _smallInfo(
                                    Icons.check_circle_outline_rounded,
                                    '${event.attendanceCount} attended',
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _panel(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
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
      child: _panel(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.10),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              '$value',
              style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressRow(String label, int value, int total, Color color) {
    final fraction = total == 0 ? 0.0 : (value / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Text('$value', style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 9),
        LinearProgressIndicator(
          value: fraction,
          minHeight: 9,
          borderRadius: BorderRadius.circular(12),
          backgroundColor: color.withValues(alpha: 0.10),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _metric(String title, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.blue, size: 28),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _smallInfo(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
