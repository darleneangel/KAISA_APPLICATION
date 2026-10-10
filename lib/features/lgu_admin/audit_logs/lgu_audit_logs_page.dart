import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/audit_log_model.dart';
import '../../../shared/repositories/audit_log_repository.dart';

class LguAuditLogsPage extends StatefulWidget {
  const LguAuditLogsPage({super.key});

  @override
  State<LguAuditLogsPage> createState() => _LguAuditLogsPageState();
}

class _LguAuditLogsPageState extends State<LguAuditLogsPage> {
  final AuditLogRepository repository = AuditLogRepository.instance;
  final TextEditingController searchController = TextEditingController();

  String selectedAction = 'All';

  @override
  void initState() {
    super.initState();
    repository.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    repository.removeListener(_refresh);
    searchController.dispose();
    super.dispose();
  }

  List<AuditLog> get filteredLogs {
    final query = searchController.text.trim().toLowerCase();

    return repository.logs.where((log) {
      final matchesAction =
          selectedAction == 'All' || log.action.label == selectedAction;

      final matchesSearch =
          log.actorName.toLowerCase().contains(query) ||
          log.actorRole.toLowerCase().contains(query) ||
          log.module.toLowerCase().contains(query) ||
          log.description.toLowerCase().contains(query) ||
          log.targetId.toLowerCase().contains(query) ||
          log.id.toLowerCase().contains(query);

      return matchesAction && matchesSearch;
    }).toList();
  }

  String _formatDateTime(DateTime date) {
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

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';

    return '$month ${date.day}, ${date.year} • '
        '$hour:$minute $period';
  }

  IconData _actionIcon(AuditActionType action) {
    switch (action) {
      case AuditActionType.create:
        return Icons.add_circle_outline_rounded;
      case AuditActionType.update:
        return Icons.edit_note_rounded;
      case AuditActionType.assign:
        return Icons.person_add_alt_1_rounded;
      case AuditActionType.remove:
        return Icons.person_remove_outlined;
      case AuditActionType.statusChange:
        return Icons.sync_alt_rounded;
      case AuditActionType.login:
        return Icons.lock_outline_rounded;
      case AuditActionType.certificate:
        return Icons.workspace_premium_outlined;
    }
  }

  Color _actionColor(AuditActionType action) {
    switch (action) {
      case AuditActionType.create:
      case AuditActionType.assign:
        return AppColors.green;
      case AuditActionType.update:
      case AuditActionType.statusChange:
        return AppColors.blue;
      case AuditActionType.remove:
        return const Color(0xFFB45309);
      case AuditActionType.login:
        return const Color(0xFF7C3AED);
      case AuditActionType.certificate:
        return const Color(0xFFB7791F);
    }
  }

  void _showDetails(AuditLog log) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Activity Details'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('Log ID', log.id),
                  _detailRow('Date and Time', _formatDateTime(log.timestamp)),
                  _detailRow('Administrator', log.actorName),
                  _detailRow('Role', log.actorRole),
                  _detailRow('Action', log.action.label),
                  _detailRow('Module', log.module),
                  _detailRow('Affected Record', log.targetId),
                  _detailRow('Description', log.description),
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
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logs = filteredLogs;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Audit Logs',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Review administrative activities and system changes '
              'for transparency and accountability.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 950
                    ? 4
                    : constraints.maxWidth >= 540
                    ? 2
                    : 1;
                const spacing = 12.0;
                final cardWidth =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    _summaryCard(
                      'Total Activities',
                      repository.totalLogs,
                      Icons.history_rounded,
                      AppColors.blue,
                      cardWidth,
                    ),
                    _summaryCard(
                      "Today's Activities",
                      repository.todayLogs,
                      Icons.today_rounded,
                      AppColors.green,
                      cardWidth,
                    ),
                    _summaryCard(
                      'Security Activities',
                      repository.securityLogs,
                      Icons.security_rounded,
                      const Color(0xFF7C3AED),
                      cardWidth,
                    ),
                    _summaryCard(
                      'Administrative Changes',
                      repository.administrativeChanges,
                      Icons.manage_accounts_rounded,
                      const Color(0xFFB7791F),
                      cardWidth,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            _panel(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Activity History',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Search administrative events and filter '
                    'by action type.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Search logs, users, modules, or records',
                      prefixIcon: Icon(Icons.search_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedAction,
                    decoration: const InputDecoration(
                      labelText: 'Action Type',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        [
                          'All',
                          ...AuditActionType.values.map(
                            (action) => action.label,
                          ),
                        ].map((action) {
                          return DropdownMenuItem(
                            value: action,
                            child: Text(
                              action == 'All' ? 'All Actions' : action,
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() => selectedAction = value ?? 'All');
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (logs.isEmpty)
              _panel(
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No matching activity logs found.'),
                  ),
                ),
              )
            else
              ...logs.map(_logCard),

            const SizedBox(height: 20),
            const Text(
              'Prototype audit history is stored in memory. '
              'Secure backend logging will be added during '
              'Supabase integration.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(
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
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
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

  Widget _logCard(AuditLog log) {
    final color = _actionColor(log.action);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _panel(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.10),
                  child: Icon(_actionIcon(log.action), color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            log.action.label,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Chip(
                            label: Text(log.module),
                            backgroundColor: AppColors.blueLight,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(log.description),
                      const SizedBox(height: 10),
                      Text(
                        '${log.actorName} • ${log.actorRole}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  _formatDateTime(log.timestamp),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showDetails(log),
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
}
