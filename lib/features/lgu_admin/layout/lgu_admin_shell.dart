import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../dashboard/lgu_it_dashboard_page.dart';
import '../../../shared/models/lgu_admin_role.dart';
import '../../../shared/models/lgu_admin_preview.dart';

// KAISA | LGU shared layout. UI only: no changes to authentication,
// backend data, feature pages, route configuration, or inactivity guard.
const _forest = Color(0xFF103F2C);
const _deep = Color(0xFF092D23);
const _green = Color(0xFF24774E);
const _yellow = Color(0xFFFFCC40);
const _paper = Color(0xFFF5F8F4);
const _ink = Color(0xFF183B2B);
const _muted = Color(0xFF778A7C);
const _stroke = Color(0xFFE2EAE3);

class LguAdminShell extends StatelessWidget {
  final Widget child;
  const LguAdminShell({super.key, required this.child});

  static const _operationsItems = <_NavItem>[
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

  static const _itItems = <_NavItem>[
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

  static const _verificationItems = <_NavItem>[
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
      Icons.pageview_rounded,
      '/lgu-admin/verification/history',
    ),
    _NavItem(
      'Verification Reports',
      Icons.bar_chart_rounded,
      '/lgu-admin/verification/reports',
    ),
    _NavItem(
      'Audit Logs',
      Icons.history_rounded,
      '/lgu-admin/verification/audit-logs',
    ),
    _NavItem(
      'Settings',
      Icons.settings_rounded,
      '/lgu-admin/verification/settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LguAdminRole>(
      valueListenable: LguAdminPreview.selectedRole,
      builder: (context, previewRole, _) {
        final user = Supabase.instance.client.auth.currentUser;
        final meta = user?.appMetadata;
        // Only interpret assigned roles if the server-managed flag is set.
        // The router and backend must independently enforce access control.
        String? assignedRole;

        if (meta?['is_super_admin'] == true) {
          assignedRole = meta?['kaisa_lgu_role'] as String?;
        }
        final LguAdminRole? authenticatedRole = switch (assignedRole) {
          'lgu_it_admin' => LguAdminRole.it,
          'lgu_verification_admin' => LguAdminRole.verification,
          'lgu_operations_admin' => LguAdminRole.operations,
          _ => null,
        };
        final role = authenticatedRole ?? previewRole;
        final path = GoRouterState.of(context).uri.path;
        final desktop = MediaQuery.sizeOf(context).width >= 1000;
        final items = switch (role) {
          LguAdminRole.it => _itItems,
          LguAdminRole.verification => _verificationItems,
          LguAdminRole.operations => _operationsItems,
        };
        final matching = items.where((item) => item.path == path);

        String title = 'Overview';

        if (path == '/lgu-admin/profile') {
          title = 'Administrator Profile';
        } else if (path.startsWith('/lgu-admin/verification/review/')) {
          title = 'Identity Review';
        } else if (matching.isNotEmpty) {
          title = matching.first.title;
        }

        // Existing role-specific content behavior, preserved.
        final Widget content;
        if (path == '/lgu-admin/profile') {
          content = child;
        } else if (role == LguAdminRole.operations) {
          content =
              path.startsWith('/lgu-admin/it/') ||
                  path.startsWith('/lgu-admin/verification/')
              ? const _PreviewUnavailable()
              : child;
        } else if (role == LguAdminRole.it) {
          if (path == '/lgu-admin/dashboard') {
            content = const LguItDashboardPage();
          } else if (const <String>{
            '/lgu-admin/it/accounts',
            '/lgu-admin/it/roles',
            '/lgu-admin/it/security-logs',
            '/lgu-admin/it/system-health',
            '/lgu-admin/it/system-settings',
          }.contains(path)) {
            content = child;
          } else {
            content = const _PreviewUnavailable();
          }
        } else {
          content =
              path == '/lgu-admin/verification/dashboard' ||
                  path == '/lgu-admin/verification/applications' ||
                  path == '/lgu-admin/verification/history' ||
                  path == '/lgu-admin/verification/reports' ||
                  path == '/lgu-admin/verification/audit-logs' ||
                  path == '/lgu-admin/verification/settings' ||
                  path.startsWith('/lgu-admin/verification/review/')
              ? child
              : const _PreviewUnavailable();
        }

        return Scaffold(
          backgroundColor: _paper,
          drawer: desktop
              ? null
              : Drawer(
                  width: 292,
                  backgroundColor: _deep,
                  child: _sidebar(
                    context,
                    path,
                    role,
                    items,
                    authenticatedRole: authenticatedRole,
                    mobile: true,
                  ),
                ),
          body: Row(
            children: [
              if (desktop)
                SizedBox(
                  width: 280,
                  child: _sidebar(
                    context,
                    path,
                    role,
                    items,
                    authenticatedRole: authenticatedRole,
                    mobile: false,
                  ),
                ),
              Expanded(
                child: Column(
                  children: [
                    _topBar(title, role, desktop, user?.email),
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

  Widget _sidebar(
    BuildContext context,
    String path,
    LguAdminRole role,
    List<_NavItem> items, {
    required LguAdminRole? authenticatedRole,
    required bool mobile,
  }) {
    final hasAssignedRole = authenticatedRole != null;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_forest, _deep],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(21, 29, 16, 25),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Image.asset(
                      'assets/images/kaisa_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.diversity_3_rounded, color: _forest),
                    ),
                  ),
                  const SizedBox(width: 13),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KAISA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .6,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'LGU ADMINISTRATION',
                          style: TextStyle(
                            color: Color(0xFFA9CFBA),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .075),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .10),
                  ),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          color: _yellow,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            hasAssignedRole
                                ? 'ASSIGNED ADMIN ROLE'
                                : 'PREVIEW ADMIN ROLE',
                            style: const TextStyle(
                              color: Color(0xFFB6D4C1),
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                              letterSpacing: .8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (hasAssignedRole)
                      Text(
                        role.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      )
                    else
                      DropdownButtonFormField<LguAdminRole>(
                        key: ValueKey(role),
                        initialValue: role,
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        style: const TextStyle(
                          color: _forest,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
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
                        onChanged: (value) {
                          if (value == null) return;
                          LguAdminPreview.selectedRole.value = value;
                          context.go(
                            value == LguAdminRole.verification
                                ? '/lgu-admin/verification/dashboard'
                                : '/lgu-admin/dashboard',
                          );
                        },
                      ),
                    const SizedBox(height: 8),
                    Text(
                      hasAssignedRole
                          ? 'Verified account assignment'
                          : 'UI preview only · Not a real permission',
                      style: const TextStyle(
                        color: Color(0xFFA9CFBA),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Padding(
              padding: EdgeInsets.fromLTRB(25, 0, 20, 13),
              child: Text(
                'WORKSPACE',
                style: TextStyle(
                  color: Color(0xFFA9CFBA),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final item in items)
                    _sidebarLink(context, item, path, mobile),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .075),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .08),
                  ),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 19,
                      backgroundColor: _yellow,
                      child: Icon(
                        Icons.shield_outlined,
                        color: _deep,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            role.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hasAssignedRole
                                ? 'LGU Administrator'
                                : 'Development preview',
                            style: const TextStyle(
                              color: Color(0xFFA9CFBA),
                              fontSize: 10,
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
        ),
      ),
    );
  }

  Widget _sidebarLink(
    BuildContext context,
    _NavItem item,
    String path,
    bool mobile,
  ) {
    final selected = item.path == path;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: selected ? _green : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () {
            if (mobile) Navigator.of(context).pop();
            if (path != item.path) context.go(item.path);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: selected ? _yellow : const Color(0xFFC4DCCD),
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
                      color: _yellow,
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

  Widget _topBar(String title, LguAdminRole role, bool desktop, String? email) {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _stroke)),
      ),
      child: Builder(
        builder: (context) => Row(
          children: [
            if (!desktop) ...[
              IconButton(
                tooltip: 'Open navigation',
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu_rounded, color: _forest),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    role.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            
            PopupMenuButton<String>(
              tooltip: 'Administrator account',
              offset: const Offset(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              onSelected: (value) async {
                if (value == 'profile') {
                  context.go('/lgu-admin/profile');
                  return;
                }
                if (value != 'logout') return;
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Log out of KAISA?'),
                    content: const Text(
                      'Are you sure you want to sign out '
                      'of your administrator account?',
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
                if (confirm != true || !context.mounted) return;
                try {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) context.go('/login');
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Unable to log out. Please try again.'),
                    ),
                  );
                }
              },
              itemBuilder: (_) => [
                if (email != null)
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ),
                const PopupMenuDivider(),

                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, color: Color(0xFFB42318)),
                      SizedBox(width: 10),
                      Text(
                        'Log Out',
                        style: TextStyle(color: Color(0xFFB42318)),
                      ),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  border: Border.all(color: _stroke),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFFE7F2E9),
                      child: Icon(Icons.person_outline_rounded, color: _forest),
                    ),
                    SizedBox(width: 5),
                    Icon(Icons.keyboard_arrow_down_rounded, color: _green),
                  ],
                ),
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
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline_rounded, color: _green, size: 42),
          const SizedBox(height: 12),
          const Text(
            'Not part of this administrator workspace',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose Overview to see your available modules.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final role = Supabase
                  .instance
                  .client
                  .auth
                  .currentUser
                  ?.appMetadata['kaisa_lgu_role'];
              context.go(
                role == 'lgu_verification_admin'
                    ? '/lgu-admin/verification/dashboard'
                    : '/lgu-admin/dashboard',
              );
            },
            child: const Text('Go to Overview'),
          ),
        ],
      ),
    ),
  );
}
