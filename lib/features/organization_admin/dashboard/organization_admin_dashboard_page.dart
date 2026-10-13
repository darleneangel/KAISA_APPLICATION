import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/community_event_model.dart';
import '../../../shared/models/organization_model.dart';
import '../../../shared/repositories/community_event_repository.dart';
import '../../../shared/repositories/organization_repository.dart';

class OrganizationAdminDashboardPage extends StatefulWidget {
  final String organizationId;

  const OrganizationAdminDashboardPage({
    super.key,
    required this.organizationId,
  });

  @override
  State<OrganizationAdminDashboardPage> createState() =>
      _OrganizationAdminDashboardPageState();
}

class _OrganizationAdminDashboardPageState
    extends State<OrganizationAdminDashboardPage> {
  final organizationRepository = OrganizationRepository.instance;
  final eventRepository = CommunityEventRepository.instance;

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

  RegistryOrganization? get organization {
    for (final item in organizationRepository.organizations) {
      if (item.id == widget.organizationId) return item;
    }
    return null;
  }

  List<CommunityEvent> get organizationEvents {
    return eventRepository.events
        .where((event) => event.organizationId == widget.organizationId)
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  }

  String formatDate(DateTime date) {
    const months = [
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
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final org = organization;

    if (org == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Organization record not found.'),
        ),
      );
    }

    final events = organizationEvents;
    final upcoming = events
        .where((e) => e.status == CommunityEventStatus.upcoming)
        .length;
    final completed = events
        .where((e) => e.status == CommunityEventStatus.completed)
        .length;
    final registrations = events.fold<int>(
      0,
      (sum, event) => sum + event.registrationCount,
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Organization Dashboard',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Welcome to ${org.name}',
              style: const TextStyle(
                fontSize: 17,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            _panel(
              Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.blueLight,
                    child: Icon(
                      Icons.groups_rounded,
                      color: AppColors.blue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          org.name,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${org.id} • ${org.category} • ${org.status}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          org.adminEmail.isEmpty
                              ? 'No administrator assigned'
                              : 'Administrator: ${org.adminEmail}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 950
                    ? 4
                    : constraints.maxWidth >= 540
                    ? 2
                    : 1;
                const gap = 12.0;
                final cardWidth =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;

                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    _statCard(
                      'Total Events',
                      events.length,
                      Icons.event_note_rounded,
                      AppColors.blue,
                      cardWidth,
                    ),
                    _statCard(
                      'Upcoming Events',
                      upcoming,
                      Icons.calendar_month_rounded,
                      AppColors.blueDark,
                      cardWidth,
                    ),
                    _statCard(
                      'Completed Events',
                      completed,
                      Icons.task_alt_rounded,
                      AppColors.green,
                      cardWidth,
                    ),
                    _statCard(
                      'Event Registrations',
                      registrations,
                      Icons.how_to_reg_rounded,
                      const Color(0xFF8B5CF6),
                      cardWidth,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 28),
            const Text(
              'Organization Events',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            if (events.isEmpty)
              _panel(
                const Text(
                  'No events have been recorded for this organization.',
                ),
              )
            else
              ...events.map(
                (event) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _panel(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                event.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Chip(label: Text(event.status.label)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${formatDate(event.startsAt)} • '
                          '${event.location}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${event.registrationCount} registered • '
                          '${event.attendanceCount} attended',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),
            const Text(
              'Management Modules',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _moduleCard(
                  context,
                  'Members',
                  'Membership approvals and member records',
                  Icons.people_outline_rounded,
                  '/organization-admin/members',
                ),
                _moduleCard(
                  context,
                  'Events',
                  'Create and manage community activities',
                  Icons.event_available_outlined,
                  '/organization-admin/events',
                ),
                _moduleCard(
                  context,
                  'Attendance',
                  'Verify actual event participation',
                  Icons.fact_check_outlined,
                  '/organization-admin/attendance',
                ),
                _moduleCard(
                  context,
                  'Certificate Studio',
                  'Design and issue e-certificates',
                  Icons.workspace_premium_outlined,
                  '/organization-admin/certificates',
                ),
              ],
            ),
          ],
        ),
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

  Widget _moduleCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    String route,
  ) {
    return SizedBox(
      width: 270,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go(route),
        child: _panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.blue, size: 30),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Text('Open module'),
                  SizedBox(width: 5),
                  Icon(Icons.arrow_forward_rounded, size: 17),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
