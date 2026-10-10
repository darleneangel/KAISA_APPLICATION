
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/repositories/lgu_settings_repository.dart';

class LguSettingsPage extends StatefulWidget {
  const LguSettingsPage({super.key});

  @override
  State<LguSettingsPage> createState() => _LguSettingsPageState();
}

class _LguSettingsPageState extends State<LguSettingsPage> {
  final LguSettingsRepository settings =
      LguSettingsRepository.instance;

  @override
  void initState() {
    super.initState();
    settings.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    settings.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Settings & Access Management',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Review administrative access and configure '
              'KAISA management preferences.',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            _sectionTitle('Super Administrator Accounts'),
            const SizedBox(height: 12),
            _panel(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Three designated Super Admin positions',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'These are planned administrative slots. '
                    'Actual account identities and credentials '
                    'will be configured through authentication.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (int i = 1; i <= 3; i++) ...[
                    if (i > 1) const Divider(height: 24),
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: AppColors.blueLight,
                          child: Icon(
                            Icons.admin_panel_settings_rounded,
                            color: AppColors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Super Administrator $i',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Text(
                                'Not configured',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Chip(
                          label: Text('Pending Setup'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 28),
            _sectionTitle('Role-Based Access Overview'),
            const SizedBox(height: 12),
            _panel(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Proposed KAISA Permission Structure',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Reference only. These permissions '
                    'are not enforced by this prototype page.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _roleCard(
                    icon: Icons.security_rounded,
                    title: 'Super Admin',
                    subtitle: 'System-wide administration',
                    permissions: const [
                      'Manage administrative accounts',
                      'Configure role assignments',
                      'Access system-wide reports and audit logs',
                      'Oversee organizations and certificates',
                    ],
                  ),
                  const Divider(height: 32),
                  _roleCard(
                    icon: Icons.account_balance_rounded,
                    title: 'LGU Admin / Authorized Staff',
                    subtitle: 'Permission-scoped LGU management',
                    permissions: const [
                      'View permitted organization records',
                      'Manage organization registrations if authorized',
                      'Assign administrators if authorized',
                      'Monitor events, reports, and certificates',
                    ],
                  ),
                  const Divider(height: 32),
                  _roleCard(
                    icon: Icons.groups_rounded,
                    title: 'Organization Admin',
                    subtitle: 'Own-organization management',
                    permissions: const [
                      'Manage authorized organization records',
                      'Manage members and activities',
                      'Record event attendance',
                      'Issue authorized organization certificates',
                    ],
                  ),
                  const Divider(height: 32),
                  _roleCard(
                    icon: Icons.person_outline_rounded,
                    title: 'Resident',
                    subtitle: 'Community participation',
                    permissions: const [
                      'Explore and join organizations',
                      'Register for community events',
                      'Track personal participation',
                      'Access certificates issued to their account',
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            _sectionTitle('Administrative Preferences'),
            const SizedBox(height: 12),
            _panel(
              Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(
                      Icons.notifications_active_outlined,
                      color: AppColors.blue,
                    ),
                    title: const Text(
                      'Administrative Notifications',
                    ),
                    subtitle: const Text(
                      'Preference for general administrative alerts.',
                    ),
                    value: settings.administrativeNotifications,
                    onChanged:
                        settings.setAdministrativeNotifications,
                  ),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(
                      Icons.event_available_outlined,
                      color: AppColors.blue,
                    ),
                    title: const Text('Event Notifications'),
                    subtitle: const Text(
                      'Preference for event-related alerts.',
                    ),
                    value: settings.eventNotifications,
                    onChanged: settings.setEventNotifications,
                  ),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(
                      Icons.assignment_ind_outlined,
                      color: AppColors.blue,
                    ),
                    title: const Text(
                      'Administrator Assignment Alerts',
                    ),
                    subtitle: const Text(
                      'Preference for changes in '
                      'organization administrator assignments.',
                    ),
                    value: settings.assignmentNotifications,
                    onChanged:
                        settings.setAssignmentNotifications,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _confirmReset,
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Restore Default Preferences'),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'Prototype settings are stored in memory '
              'and reset when the application restarts.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore Defaults?'),
        content: const Text(
          'Reset all administrative notification '
          'preferences to their default values?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    settings.resetDefaults();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Default preferences restored.'),
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

  Widget _roleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<String> permissions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.blueLight,
              child: Icon(icon, color: AppColors.blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...permissions.map(
          (permission) => Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 18,
                  color: AppColors.green,
                ),
                const SizedBox(width: 9),
                Expanded(child: Text(permission)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
