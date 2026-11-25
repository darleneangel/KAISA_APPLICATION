import 'package:flutter/material.dart';
import '../settings/widgets/lgu_role_settings_view.dart';

/// Operations Admin: matches the supplied Operations Settings screen.
class LguSettingsPage extends StatelessWidget {
  const LguSettingsPage({super.key});

  @override
  Widget build(BuildContext context) => const LguRoleSettingsView(
    roleName: 'Operations',
    roleCode: 'lgu_operations_admin',
    subtitle:
        'Manage operational notification preferences and review your access scope. Security configuration remains with IT.',
    options: [
      LguSettingOption(
        'general',
        'Administrative updates',
        'Local preference for operational announcements.',
        Icons.notifications_active_outlined,
      ),
      LguSettingOption(
        'events',
        'Event activity',
        'Local preference for event reminders and monitoring updates.',
        Icons.event_available_outlined,
      ),
      LguSettingOption(
        'assignments',
        'Organization assignment changes',
        'Local preference for organization representative updates.',
        Icons.manage_accounts_outlined,
      ),
    ],
    responsibilities: [
      LguResponsibility(
        'Organization operations',
        'Registry and designated organization representatives.',
        Icons.apartment_rounded,
      ),
      LguResponsibility(
        'Events & participation',
        'Event monitoring and authorized operational reviews.',
        Icons.event_note_rounded,
      ),
      LguResponsibility(
        'Reports & audit trail',
        'Scoped operational reporting and activity records.',
        Icons.summarize_outlined,
      ),
      LguResponsibility(
        'Escalation to IT',
        'Account enforcement and technical security issues belong to IT.',
        Icons.support_agent_outlined,
      ),
    ],
    safeguards: [
      'Role and access policy is enforced by the backend, not these switches.',
      'Operations sees authorized operational activity, not private identity evidence.',
      'Account suspensions and security changes must be referred to IT.',
    ],
  );
}
