import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/repositories/lgu_settings_repository.dart';

// KAISA LGU Operations visual system.
const _forest = Color(0xFF00492C);
const _green = Color(0xFF287D55);
const _paper = Color(0xFFF6F8F5);
const _ink = Color(0xFF173D2B);
const _muted = Color(0xFF687B70);
const _gold = Color(0xFFFBBA16);
const _stroke = Color(0xFFE2EBE4);
const _mint = Color(0xFFEAF5EE);

class LguSettingsPage extends StatefulWidget {
  const LguSettingsPage({super.key});

  @override
  State<LguSettingsPage> createState() => _LguSettingsPageState();
}

class _LguSettingsPageState extends State<LguSettingsPage> {
  final LguSettingsRepository settings = LguSettingsRepository.instance;

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
    final user = Supabase.instance.client.auth.currentUser;
    final role = user?.appMetadata['kaisa_lgu_role']?.toString();
    final isOperationsAdmin =
        user?.appMetadata['is_super_admin'] == true &&
        role == 'lgu_operations_admin';

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 650;
        return ColoredBox(
          color: _paper,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 28,
              24,
              compact ? 16 : 28,
              48,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1260),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(compact),
                      const SizedBox(height: 22),
                      _sectionHeading(
                        'Your Operations workspace',
                        'View your current signed-in role and operational access scope.',
                      ),
                      const SizedBox(height: 12),
                      _identityCard(
                        email: user?.email,
                        role: role,
                        isOperationsAdmin: isOperationsAdmin,
                        compact: compact,
                      ),
                      const SizedBox(height: 22),
                      _sectionHeading(
                        'Notification preferences',
                        'Customize local prototype preferences for this app session.',
                      ),
                      const SizedBox(height: 12),
                      _preferencesPanel(),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: _confirmReset,
                          icon: const Icon(Icons.restart_alt_rounded),
                          label: const Text('Restore defaults'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _forest,
                            side: const BorderSide(color: _stroke),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _sectionHeading(
                        'Responsibilities & safeguards',
                        'Reference guidance for least-privilege Operations access.',
                      ),
                      const SizedBox(height: 12),
                      _responsibilityGrid(),
                      const SizedBox(height: 20),
                      _securityPanel(),
                      const SizedBox(height: 20),
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 17,
                            color: _muted,
                          ),
                          SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'Prototype settings: these notification switches update '
                              'the in-memory LguSettingsRepository only. They do not '
                              'change Supabase Auth, database permissions, push delivery, '
                              'or system-wide configuration. They may reset when the app '
                              'restarts. Real access is enforced by your backend and RLS.',
                              style: TextStyle(
                                fontSize: 11,
                                color: _muted,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _header(bool compact) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(compact ? 23 : 30),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        colors: [Color(0xFF0B3024), Color(0xFF15543A), Color(0xFF288258)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 20,
      runSpacing: 16,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 660),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'KAISA  /  LGU OPERATIONS  /  SETTINGS',
                style: TextStyle(
                  color: _gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 13),
              Text(
                'Operations Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 27 : 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'A focused workspace for notification preferences and '
                'read-only access guidance. System security settings '
                'remain with the IT Superadmin.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFFE2F0E6),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white30),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_outlined, color: _gold, size: 19),
              SizedBox(width: 8),
              Text(
                'OPERATIONS ADMIN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _sectionHeading(String title, String description) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: _ink,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 4),
      Text(description, style: const TextStyle(color: _muted, fontSize: 12)),
    ],
  );

  Widget _identityCard({
    required String? email,
    required String? role,
    required bool isOperationsAdmin,
    required bool compact,
  }) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(compact ? 18 : 23),
    decoration: _surface(),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 14,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 530),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _mint,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_outlined,
                  color: _forest,
                  size: 26,
                ),
              ),
              const SizedBox(width: 13),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Signed-in administrator',
                      style: TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email ?? 'No authenticated user',
                      softWrap: true,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'KAISA role: ${role ?? 'Not available'}',
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isOperationsAdmin ? _mint : const Color(0xFFFFF3D8),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            isOperationsAdmin
                ? 'Operations role detected'
                : 'Role not confirmed',
            style: TextStyle(
              color: isOperationsAdmin ? _forest : const Color(0xFF94670A),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _preferencesPanel() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
    decoration: _surface(),
    child: Column(
      children: [
        _preference(
          icon: Icons.notifications_active_outlined,
          title: 'Administrative updates',
          subtitle: 'Local preference for general Operations notifications.',
          value: settings.administrativeNotifications,
          onChanged: settings.setAdministrativeNotifications,
        ),
        const Divider(height: 1, color: _stroke),
        _preference(
          icon: Icons.event_available_outlined,
          title: 'Event activity',
          subtitle: 'Local preference for event-related reminders and updates.',
          value: settings.eventNotifications,
          onChanged: settings.setEventNotifications,
        ),
        const Divider(height: 1, color: _stroke),
        _preference(
          icon: Icons.manage_accounts_outlined,
          title: 'Organization assignment changes',
          subtitle: 'Local preference for representative-assignment notices.',
          value: settings.assignmentNotifications,
          onChanged: settings.setAssignmentNotifications,
        ),
      ],
    ),
  );

  Widget _preference({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => SwitchListTile.adaptive(
    contentPadding: const EdgeInsets.symmetric(vertical: 5),
    secondary: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: _mint,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, color: _forest, size: 21),
    ),
    activeTrackColor: _green,
    activeThumbColor: Colors.white,
    title: Text(
      title,
      style: const TextStyle(
        color: _ink,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    ),
    subtitle: Text(
      subtitle,
      style: const TextStyle(color: _muted, fontSize: 12),
    ),
    value: value,
    onChanged: onChanged,
  );

  Widget _responsibilityGrid() {
    final items = <({IconData icon, String title, String body})>[
      (
        icon: Icons.apartment_rounded,
        title: 'Organization operations',
        body: 'Registry records and designated organization representatives.',
      ),
      (
        icon: Icons.event_note_rounded,
        title: 'Events & participation',
        body: 'Event monitoring and authorized operational reviews.',
      ),
      (
        icon: Icons.summarize_outlined,
        title: 'Reports & audit trail',
        body: 'Scoped reporting and read-only operational activity history.',
      ),
      (
        icon: Icons.support_agent_rounded,
        title: 'Escalation to IT',
        body:
            'Account enforcement and technical security changes belong to IT.',
      ),
    ];
    return LayoutBuilder(
      builder: (context, bounds) {
        final columns = bounds.maxWidth >= 740 ? 2 : 1;
        const gap = 12.0;
        final width = (bounds.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: Container(
                  padding: const EdgeInsets.all(19),
                  decoration: _surface(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _mint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.icon, color: _forest, size: 21),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                color: _ink,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              item.body,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 12,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _securityPanel() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: _surface(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.verified_user_outlined, color: _forest, size: 23),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Security & access boundaries',
                style: TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _securityLine(
          'Role permissions',
          'Read-only here. IT manages technical provisioning and access policy.',
        ),
        const Divider(height: 24, color: _stroke),
        _securityLine(
          'Audit history',
          'Operations can inspect authorized operational actions, not private IT security records.',
        ),
        const Divider(height: 24, color: _stroke),
        _securityLine(
          'Inactivity protection',
          'Your existing five-minute administrator inactivity guard is handled outside this page.',
        ),
      ],
    ),
  );

  Widget _securityLine(String title, String detail) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(Icons.check_circle_outline_rounded, size: 19, color: _green),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: _ink,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              detail,
              style: const TextStyle(color: _muted, fontSize: 12, height: 1.45),
            ),
          ],
        ),
      ),
    ],
  );

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Restore notification defaults?',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Reset the three local Operations notification preferences to '
          'their default values? No account roles or Supabase settings will change.',
          style: TextStyle(color: _muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _forest),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restore defaults'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    settings.resetDefaults();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Prototype notification defaults restored.'),
        ),
      );
  }

  BoxDecoration _surface() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: _stroke),
  );
}
