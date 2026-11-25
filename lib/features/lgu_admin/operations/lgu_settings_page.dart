import 'package:flutter/material.dart';
<<<<<<< HEAD
import '../settings/widgets/lgu_role_settings_view.dart';
=======
import '../layout/lgu_role_settings_view.dart';
>>>>>>> beff271c77b5546304dfe3296c31bd8c33d1f3a2

class LguSettingsPage extends StatelessWidget {
  const LguSettingsPage({super.key});

  @override
  Widget build(BuildContext context) => const LguRoleSettingsView(
    roleName: 'Operations',
    roleCode: 'lgu_operations_admin',
    subtitle: 'Your administrator profile, operational preferences, and access responsibilities.',
    options: [
      LguSettingOption('general', 'Administrative updates',
          'Local preference for operational announcements.', Icons.notifications_active_outlined),
      LguSettingOption('events', 'Event activity',
          'Local preference for event reminders and monitoring updates.', Icons.event_available_outlined),
      LguSettingOption('assignments', 'Organization assignment changes',
          'Local preference for representative updates.', Icons.manage_accounts_outlined),
    ],
    responsibilities: [
      LguResponsibility('Organization operations',
          'Registry records and designated representatives.', Icons.apartment_rounded),
      LguResponsibility('Events & participation',
          'Event monitoring and recorded community participation.', Icons.event_note_rounded),
      LguResponsibility('Reports & audit trail',
          'Operational PDF reports and related activity records.', Icons.summarize_outlined),
      LguResponsibility('Escalation to IT',
          'Security incidents and account enforcement go to IT.', Icons.support_agent_outlined),
    ],
    safeguards: [
      'Role and permissions are assigned by trusted backend controls, not this page.',
      'Operations manages authorized operational data, not private verification evidence.',
      'Account suspension and system security decisions belong to IT.',
    ],
  );
}
