import 'package:flutter/material.dart';
import '../settings/widgets/lgu_role_settings_view.dart';

/// IT Superadmin settings. Keeps the existing route and class name.
class SystemSettingsPage extends StatelessWidget {
  const SystemSettingsPage({super.key});

  @override
  Widget build(BuildContext context) => const LguRoleSettingsView(
    roleName: 'IT',
    roleCode: 'lgu_it_admin',
    subtitle:
        'Personal alert preferences and IT access guidance. Server configuration and account security remain backend-managed.',
    options: [
      LguSettingOption(
        'security',
        'Security event alerts',
        'Local preference for suspicious sign-in and access alerts.',
        Icons.security_outlined,
      ),
      LguSettingOption(
        'health',
        'System health updates',
        'Local preference for service and API-monitoring updates.',
        Icons.monitor_heart_outlined,
      ),
      LguSettingOption(
        'backups',
        'Backup & recovery notices',
        'Local preference for backup and recovery status updates.',
        Icons.backup_outlined,
      ),
    ],
    responsibilities: [
      LguResponsibility(
        'Account management',
        'Account lifecycle, suspension requests and authorized recovery.',
        Icons.manage_accounts_outlined,
      ),
      LguResponsibility(
        'Roles & permissions',
        'Provisioning and access changes through trusted administration.',
        Icons.admin_panel_settings_outlined,
      ),
      LguResponsibility(
        'Security monitoring',
        'Auth failures, audit events and system availability.',
        Icons.shield_outlined,
      ),
      LguResponsibility(
        'Backup & recovery',
        'Scheduled backup checks and approved recovery workflows.',
        Icons.settings_backup_restore_outlined,
      ),
    ],
    safeguards: [
      'Role assignments and permissions require a trusted server and RLS policies.',
      'Security alerts and monitoring figures must be based on real authorized logs.',
      'Backups, secrets, and account actions must never be controlled by local UI toggles.',
    ],
  );
}
