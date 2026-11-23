import 'package:flutter/material.dart';
import '../layout/lgu_role_settings_view.dart';

class SystemSettingsPage extends StatelessWidget {
  const SystemSettingsPage({super.key});

  @override
  Widget build(BuildContext context) => const LguRoleSettingsView(
    roleName: 'IT',
    roleCode: 'lgu_it_admin',
    subtitle: 'Your administrator profile, security preferences, and IT responsibilities.',
    options: [
      LguSettingOption('security', 'Security event alerts',
          'Local preference for unusual sign-in and access events.', Icons.shield_outlined),
      LguSettingOption('health', 'System health updates',
          'Local preference for service and availability updates.', Icons.monitor_heart_outlined),
      LguSettingOption('backup', 'Backup and recovery notices',
          'Local preference for backup and restore information.', Icons.backup_outlined),
    ],
    responsibilities: [
      LguResponsibility('Account management',
          'Account administration and authorized account recovery.', Icons.manage_accounts_outlined),
      LguResponsibility('Roles & permissions',
          'Trusted provisioning and role-based access enforcement.', Icons.admin_panel_settings_outlined),
      LguResponsibility('Security monitoring',
          'Sign-in failures, access events and system health.', Icons.security_outlined),
      LguResponsibility('Backup & recovery',
          'Review and operate authorized backup workflows.', Icons.settings_backup_restore_outlined),
    ],
    safeguards: [
      'Protected account role changes must be completed by trusted backend code.',
      'Production telemetry must come from authorized sources, not sample charts.',
      'Service keys, passwords, and recovery secrets must not be stored in this UI.',
    ],
  );
}
