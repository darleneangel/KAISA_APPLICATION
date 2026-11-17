import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../dashboard/lgu_it_dashboard_page.dart';

import '../../../shared/models/lgu_admin_role.dart';
import '../../../shared/models/lgu_admin_preview.dart';

const _forest = Color(0xFF14532D);
const _green = Color(0xFF237A50);
const _paper = Color(0xFFF8FAF8);
const _ink = Color(0xFF173D2B);
const _muted = Color(0xFF687B70);
const _gold = Color(0xFFFBC02D);
const _stroke = Color(0xFFE2EBE4);

class LguAdminShell extends StatelessWidget {
  final Widget child;

  const LguAdminShell({super.key, required this.child});

  static const _operationsItems = [
    _NavItem('Overview', Icons.dashboard_rounded, '/lgu-admin/dashboard'),
    _NavItem(
      'Organizations',
      Icons.apartment_rounded,
      '/lgu-admin/organizations',
    ),
    _NavItem(
      'Admin Assignments',
      Icons.admin_panel_settings_rounded,
      '/lgu-admin/assignments',
    ),
    _NavItem(
      'Event Monitoring',
      Icons.event_available_rounded,
      '/lgu-admin/events',
    ),
    _NavItem('Reports', Icons.bar_chart_rounded, '/lgu-admin/reports'),
    _NavItem('Audit Logs', Icons.history_rounded, '/lgu-admin/audit-logs'),
    _NavItem('Settings', Icons.settings_rounded, '/lgu-admin/settings'),
  ];

  static const _itItems = [
    _NavItem('Overview', Icons.dashboard_rounded, '/lgu-admin/dashboard'),
    _NavItem(
      'Account Management',
      Icons.manage_accounts_rounded,
      '/lgu-admin/it/accounts',
    ),
    _NavItem(
      'Roles & Permissions',
      Icons.admin_panel_settings_rounded,
      '/lgu-admin/it/roles',
    ),

    _NavItem(
      'Security Logs',
      Icons.security_rounded,
      '/lgu-admin/it/security-logs',
    ),

    _NavItem(
      'Backup & Recovery',
      Icons.backup_outlined,
      '/lgu-admin/it/backup-recovery',
    ),

    _NavItem(
      'System Health',
      Icons.monitor_heart_outlined,
      '/lgu-admin/it/system-health',
    ),

    _NavItem(
      'System Settings',
      Icons.settings_suggest_outlined,
      '/lgu-admin/it/system-settings',
    ),
  ];

  static const _verificationItems = [
    _NavItem(
      'Overview',
      Icons.dashboard_rounded,
      '/lgu-admin/verification/dashboard',
    ),
    _NavItem(
      'Pending Applications',
      Icons.pending_actions_rounded,
      '/lgu-admin/verification/applications',
    ),
    _NavItem(
      'Review History',
      Icons.history_rounded,
      '/lgu-admin/verification/history',
    ),
    _NavItem(
      'Verification Reports',
      Icons.bar_chart_rounded,
      '/lgu-admin/verification/reports',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LguAdminRole>(
      valueListenable: LguAdminPreview.selectedRole,
      builder: (context, previewRole, _) {
        final user = Supabase.instance.client.auth.currentUser;
        final assignedRole = user?.appMetadata['kaisa_lgu_role'];

        final LguAdminRole? authenticatedRole = switch (assignedRole) {
          'lgu_it_admin' => LguAdminRole.it,
          'lgu_verification_admin' => LguAdminRole.verification,
          'lgu_operations_admin' => LguAdminRole.operations,
          _ => null,
        };

        final role = authenticatedRole ?? previewRole;

        final desktop = MediaQuery.sizeOf(context).width >= 1000;

        final path = GoRouterState.of(context).uri.path;

        final items = role == LguAdminRole.operations
            ? _operationsItems
            : role == LguAdminRole.it
            ? _itItems
            : _verificationItems;

        final selected = items.where((item) => item.path == path);

        final title = path.startsWith('/lgu-admin/verification/review/')
            ? 'Identity Review'
            : selected.isNotEmpty
            ? selected.first.title
            : 'Overview';

        // Preview only: IT and Verification currently have

        // Avoid showing Operations content under a different
        // preview role, even if someone opens the URL directly.

        final Widget content;

        if (role == LguAdminRole.operations) {
          content =
              path.startsWith('/lgu-admin/it/') ||
                  path.startsWith('/lgu-admin/verification/')
              ? const _PreviewUnavailable()
              : child;
        } else if (role == LguAdminRole.it) {
          if (path == '/lgu-admin/dashboard') {
            content = const LguItDashboardPage();
          } else if (path == '/lgu-admin/it/accounts' ||
              path == '/lgu-admin/it/roles' ||
              path == '/lgu-admin/it/security-logs' ||
              path == '/lgu-admin/it/system-health' ||
              path == '/lgu-admin/it/backup-recovery' ||
              path == '/lgu-admin/it/system-settings') {
            content = child;
          } else {
            content = const _PreviewUnavailable();
          }
        } else {
          // Verification Administrator
          if (path == '/lgu-admin/verification/dashboard' ||
              path == '/lgu-admin/verification/applications' ||
              path == '/lgu-admin/verification/history' ||
              path == '/lgu-admin/verification/reports' ||
              path.startsWith('/lgu-admin/verification/review/')) {
            content = child;
          } else {
            content = const _PreviewUnavailable();
          }
        }

        return Scaffold(
          backgroundColor: _paper,
          drawer: desktop
              ? null
              : Drawer(
                  backgroundColor: _forest,
                  child: _navigation(
                    context,
                    path,
                    role,
                    items,
                    mobile: true,
                    authenticatedRole: authenticatedRole,
                  ),
                ),
          body: Row(
            children: [
              if (desktop)
                SizedBox(
                  width: 268,
                  child: _navigation(
                    context,
                    path,
                    role,
                    items,
                    mobile: false,
                    authenticatedRole: authenticatedRole,
                  ),
                ),
              Expanded(
                child: Column(
                  children: [
                    _topBar('$title · ${role.label}', desktop),
                    Expanded(child: content),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _navigation(
    BuildContext context,
    String path,
    LguAdminRole role,
    List<_NavItem> items, {
    required bool mobile,
    required LguAdminRole? authenticatedRole,
  }) {
    return ColoredBox(
      color: _forest,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 28, 18, 25),
              child: Row(
                children: [
                  Container(
                    height: 51,
                    width: 51,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Image.asset(
                      'assets/images/kaisa_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.diversity_3_rounded,
                        color: _green,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KAISA',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'LGU ADMINISTRATION',
                          style: TextStyle(
                            color: Color(0xFFC3DDCE),
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Developer-only role selector.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PREVIEW ADMIN ROLE',
                      style: TextStyle(
                        color: Color(0xFFC3DDCE),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<LguAdminRole>(
                      key: ValueKey(role),
                      initialValue: role,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                        color: _forest,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: [
                        for (final option in LguAdminRole.values)
                          DropdownMenuItem(
                            value: option,
                            child: Text(option.label),
                          ),
                      ],

                      onChanged: authenticatedRole != null
                          ? null
                          : (value) {
                              if (value == null) return;

                              LguAdminPreview.selectedRole.value = value;

                              GoRouter.of(context).go(
                                value == LguAdminRole.verification
                                    ? '/lgu-admin/verification/dashboard'
                                    : '/lgu-admin/dashboard',
                              );
                            },
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'UI preview only · Not a real permission',
                      style: TextStyle(color: Color(0xFFC3DDCE), fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(13, 0, 13, 14),
                    child: Text(
                      'WORKSPACE',
                      style: TextStyle(
                        color: Color(0xFFA8D5B9),
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  for (final item in items)
                    _navigationLink(context, item, path, mobile),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(17),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF3D7353))),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: _gold,
                    child: Icon(Icons.shield_outlined, color: _forest),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Development preview',
                          style: TextStyle(
                            color: Color(0xFFC3DDCE),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navigationLink(
    BuildContext context,
    _NavItem item,
    String path,
    bool mobile,
  ) {
    final selected = item.path == path;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected
            ? Colors.white.withValues(alpha: .13)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () {
            if (mobile) {
              Navigator.of(context).pop();
            }
            if (path != item.path) {
              context.go(item.path);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 21,
                  color: selected ? _gold : const Color(0xFFD1E8D9),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: _gold,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(String title, bool desktop) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _stroke)),
      ),
      child: Builder(
        builder: (context) => Row(
          children: [
            if (!desktop) ...[
              IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu_rounded, color: _forest),
              ),
              const SizedBox(width: 6),
            ],

            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),

            const Icon(Icons.shield_outlined, color: _green, size: 18),
            const SizedBox(width: 8),
            const Text(
              'LGU Portal',
              style: TextStyle(
                color: _muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(width: 16),

            // Profile dropdown: View Profile / Log Out
            PopupMenuButton<String>(
              tooltip: 'Administrator Account',
              offset: const Offset(0, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: (value) async {
                if (value == 'profile') {
                  context.go('/lgu-admin/profile');
                  return;
                }

                if (value == 'logout') {
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Log out of KAISA?'),
                      content: const Text(
                        'Are you sure you want to '
                        'sign out of your Superadmin account?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Log Out'),
                        ),
                      ],
                    ),
                  );

                  if (shouldLogout != true || !context.mounted) {
                    return;
                  }

                  try {
                    await Supabase.instance.client.auth.signOut();

                    if (context.mounted) {
                      context.go('/login');
                    }
                  } catch (error) {
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Unable to log out. '
                          'Please try again.',
                        ),
                      ),
                    );
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline_rounded, color: _forest),
                      SizedBox(width: 12),
                      Text('View Profile'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, color: Color(0xFFB42318)),
                      SizedBox(width: 12),
                      Text(
                        'Log Out',
                        style: TextStyle(color: Color(0xFFB42318)),
                      ),
                    ],
                  ),
                ),
              ],
              child: const CircleAvatar(
                radius: 19,
                backgroundColor: Color(0xFFE6F2EA),
                child: Icon(Icons.person_outline_rounded, color: _forest),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final String title;
  final IconData icon;
  final String path;

  const _NavItem(this.title, this.icon, this.path);
}

class _PreviewUnavailable extends StatelessWidget {
  const _PreviewUnavailable();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline_rounded, color: _green, size: 42),
            const SizedBox(height: 12),
            const Text(
              'Not part of this role preview',
              style: TextStyle(
                color: _ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose Overview to see the modules '
              'planned for this administrator.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/lgu-admin/dashboard'),
              child: const Text('Go to Overview'),
            ),
          ],
        ),
      ),
    );
  }
}
