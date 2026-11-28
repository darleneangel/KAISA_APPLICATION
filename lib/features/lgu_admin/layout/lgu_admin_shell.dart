import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../dashboard/lgu_it_dashboard_page.dart';
import '../verification/resident_directory_page.dart';
import '../../../shared/models/lgu_admin_role.dart';

// KAISA | LGU shared layout. Planned modules are explicitly non-operational.
// Existing live permissions remain in their original domains until migration.
const _forest = Color(0xFF154E2E);
const _deep = Color(0xFF103D25);
const _green = Color(0xFF24774E);
const _yellow = Color(0xFFFDBC19);
const _paper = Color(0xFFF5F8F4);
const _ink = Color(0xFF183B2B);
const _muted = Color(0xFF778A7C);
const _stroke = Color(0xFFE2EAE3);

class LguAdminShell extends StatelessWidget {
  final Widget child;
  const LguAdminShell({super.key, required this.child});

  static const _operationsItems = <_NavItem>[
    _NavItem('Dashboard', Icons.dashboard_rounded, '/lgu-admin/dashboard', 'OVERVIEW'),
    _NavItem('Organization Monitoring', Icons.apartment_rounded, '/lgu-admin/operations/organization-monitoring', 'COMMUNITY OPERATIONS'),
    _NavItem('Event Monitoring', Icons.event_available_rounded, '/lgu-admin/events', 'COMMUNITY OPERATIONS'),
    _NavItem('Event Moderation', Icons.gavel_rounded, '/lgu-admin/operations/moderation', 'COMMUNITY OPERATIONS'),
    _NavItem('Participation Monitoring', Icons.groups_rounded, '/lgu-admin/operations/participation', 'COMMUNITY OPERATIONS'),
    _NavItem('Official Announcements', Icons.campaign_rounded, '/lgu-admin/operations/announcements', 'COMMUNITY OPERATIONS'),
    _NavItem('Reports & Analytics', Icons.bar_chart_rounded, '/lgu-admin/reports', 'GOVERNANCE'),
    _NavItem('Audit Logs', Icons.history_rounded, '/lgu-admin/audit-logs', 'GOVERNANCE'),
    _NavItem('Settings', Icons.settings_rounded, '/lgu-admin/settings', 'GOVERNANCE'),
    _NavItem('Organization Registry (legacy)', Icons.apartment_rounded, '/lgu-admin/organizations', 'LEGACY ACCESS · TRANSITION'),
    _NavItem('Admin Assignments (legacy)', Icons.admin_panel_settings_rounded, '/lgu-admin/assignments', 'LEGACY ACCESS · TRANSITION'),
  ];

  static const _itItems = <_NavItem>[
    _NavItem('Dashboard', Icons.dashboard_rounded, '/lgu-admin/dashboard', 'OVERVIEW'),
    _NavItem('Account Management', Icons.manage_accounts_rounded, '/lgu-admin/it/accounts', 'ACCESS MANAGEMENT'),
    _NavItem('Roles & Permissions', Icons.admin_panel_settings_rounded, '/lgu-admin/it/roles', 'ACCESS MANAGEMENT'),
    _NavItem('System Health', Icons.monitor_heart_outlined, '/lgu-admin/it/system-health', 'SYSTEM ADMINISTRATION'),
    _NavItem('Security Management', Icons.security_rounded, '/lgu-admin/it/security', 'SYSTEM ADMINISTRATION'),
    _NavItem('Security & Audit Logs', Icons.history_rounded, '/lgu-admin/it/security-logs', 'GOVERNANCE'),
    _NavItem('Settings', Icons.settings_rounded, '/lgu-admin/it/system-settings', 'GOVERNANCE'),
  ];

  static const _verificationItems = <_NavItem>[
    _NavItem('Dashboard', Icons.dashboard_rounded, '/lgu-admin/verification/dashboard', 'OVERVIEW'),
    _NavItem('Resident Directory', Icons.groups_rounded, '/lgu-admin/verification/residents', 'RESIDENT MANAGEMENT'),
    _NavItem('Identity Verification', Icons.pending_actions_rounded, '/lgu-admin/verification/applications', 'RESIDENT MANAGEMENT'),
    _NavItem('Verification History', Icons.pageview_rounded, '/lgu-admin/verification/history', 'RESIDENT MANAGEMENT'),
    _NavItem('Organization Registry', Icons.apartment_rounded, '/lgu-admin/verification/organizations', 'ORGANIZATION MANAGEMENT'),
    _NavItem('Admin Assignments', Icons.admin_panel_settings_rounded, '/lgu-admin/verification/assignments', 'ORGANIZATION MANAGEMENT'),
    _NavItem('Reports & Analytics', Icons.bar_chart_rounded, '/lgu-admin/verification/reports', 'GOVERNANCE'),
    _NavItem('Audit Logs', Icons.history_rounded, '/lgu-admin/verification/audit-logs', 'GOVERNANCE'),
    _NavItem('Settings', Icons.settings_rounded, '/lgu-admin/verification/settings', 'GOVERNANCE'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final meta = user?.appMetadata;
    String? assignedRole;
    if (meta != null && meta['is_super_admin'] == true) {
      final value = meta['kaisa_lgu_role'];
      if (value is String) assignedRole = value;
    }
    final LguAdminRole? authenticatedRole = switch (assignedRole) {
      'lgu_it_admin' => LguAdminRole.it,
      'lgu_verification_admin' => LguAdminRole.verification,
      'lgu_operations_admin' => LguAdminRole.operations,
      _ => null,
    };
    if (authenticatedRole == null) {
      return Scaffold(body: Center(child: TextButton(
        onPressed: () => context.go('/resident/home'),
        child: const Text('LGU administrator access required. Return home.'),
      )));
    }
    final role = authenticatedRole;
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

        final allowed = matching.isNotEmpty ||
            (role == LguAdminRole.verification &&
             path.startsWith('/lgu-admin/verification/review/'));
        final Widget content = !allowed
            ? const _PreviewUnavailable()
            : role == LguAdminRole.it && path == '/lgu-admin/dashboard'
                ? const LguItDashboardPage() : child;

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
                    Expanded(child: Material(
                      color: _paper,
                      child: DefaultTextStyle(
                        style: (Theme.of(context).textTheme.bodyMedium ??
                            const TextStyle(fontSize: 14)).copyWith(
                              decoration: TextDecoration.none, color: _ink),
                        child: content,
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
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
              padding: const EdgeInsets.fromLTRB(18, 18, 16, 16),
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
                    Text(
                      _roleLabel(role),
                      style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w800, fontSize: 14),
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
            const SizedBox(height: 12),
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
                  for (var i = 0; i < items.length; i++) ...[
                    if (i == 0 || items[i].group != items[i - 1].group)
                      _sectionHeading(items[i].group),
                    _sidebarLink(context, items[i], path, mobile),
                  ],
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
                            _roleLabel(role),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
      height: 64,
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
                    _roleLabel(role),
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
                if (value == 'preview' && lguPreviewEnabled) {
                  context.go('/lgu-admin-preview');
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
                if (lguPreviewEnabled)
                  const PopupMenuItem<String>(value: 'preview',
                    child: Text('Developer preview')),
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
  final String group;
  const _NavItem(this.title, this.icon, this.path, this.group);
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


const bool lguPreviewEnabled = kDebugMode &&
    bool.fromEnvironment('USE_MOCK_DATA', defaultValue: false);

String _roleLabel(LguAdminRole role) => switch (role) {
  LguAdminRole.it => 'Systems Administrator',
  LguAdminRole.verification => 'Community Affairs Administrator',
  LguAdminRole.operations => 'Operations Administrator',
};

Widget _sectionHeading(String label) => Padding(
  padding: const EdgeInsets.fromLTRB(12, 12, 8, 6),
  child: Text(label, style: const TextStyle(color: Color(0xFFA9CFBA),
    fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: .5)),
);

/// Navigation-only placeholder, deliberately contains no live data or mutations.
class LguPlannedModulePage extends StatelessWidget {
  const LguPlannedModulePage({super.key, required this.title,
    this.description = 'This module will be implemented in the next development stage.'});
  final String title;
  final String description;
  @override
  Widget build(BuildContext context) => Center(child: SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.construction_rounded, color: _green, size: 42),
      const SizedBox(height: 12),
      Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text(description, textAlign: TextAlign.center),
      const SizedBox(height: 8),
      const Text('Planned module · No live administrative actions',
        style: TextStyle(color: _muted)),
    ]),
  ));
}

/// Isolated debug navigation preview. No existing administrative page is mounted.
class LguDeveloperPreviewPage extends StatefulWidget {
  const LguDeveloperPreviewPage({super.key});
  @override
  State<LguDeveloperPreviewPage> createState() => _LguDeveloperPreviewPageState();
}

class _LguDeveloperPreviewPageState extends State<LguDeveloperPreviewPage> {
  LguAdminRole _role = LguAdminRole.verification;
  String? _selected;
  List<_NavItem> get _items => (switch (_role) {
    LguAdminRole.it => LguAdminShell._itItems,
    LguAdminRole.verification => LguAdminShell._verificationItems,
    LguAdminRole.operations => LguAdminShell._operationsItems,
  }).where((item) => !item.group.startsWith('LEGACY')).toList();

  @override
  Widget build(BuildContext context) {
    if (!lguPreviewEnabled) return const SizedBox.shrink();
    final selected = _items.firstWhere((item) => item.path == _selected,
      orElse: () => _items.first);
    final desktop = MediaQuery.sizeOf(context).width >= 1000;
    Widget navigation(bool mobile, BuildContext navContext) => Material(color: _forest, child: SafeArea(
      child: ListView(padding: const EdgeInsets.all(12), children: [
        const Text('KAISA', style: TextStyle(color: Colors.white,
          fontSize: 26, fontWeight: FontWeight.bold)),
        const Text('LGU DEVELOPER PREVIEW', style: TextStyle(color: _yellow, fontSize: 12)),
        const SizedBox(height: 12),
        DropdownButtonFormField<LguAdminRole>(
          initialValue: _role, isExpanded: true, dropdownColor: Colors.white,
          decoration: const InputDecoration(filled: true, fillColor: Colors.white),
          items: [for (final role in LguAdminRole.values)
            DropdownMenuItem(value: role, child: Text(_roleLabel(role),
              style: const TextStyle(color: _ink, fontSize: 13)))],
          onChanged: (role) {
            if (role == null) return;
            setState(() { _role = role; _selected = null; });
          },
        ),
        for (var i = 0; i < _items.length; i++) ...[
          if (i == 0 || _items[i].group != _items[i-1].group)
            _sectionHeading(_items[i].group),
          ListTile(dense: true, selected: selected.path == _items[i].path,
            selectedTileColor: _deep, selectedColor: _yellow,
            textColor: Colors.white, iconColor: const Color(0xFFBCD8C5),
            leading: Icon(_items[i].icon), title: Text(_items[i].title),
            onTap: () {
              setState(() => _selected = _items[i].path);
              if (mobile) Navigator.of(navContext).pop();
            }),
        ],
      ]),
    ));
    return Scaffold(backgroundColor: _paper,
      appBar: AppBar(title: const Text('LGU developer preview'), actions: [
        TextButton(onPressed: () => context.go('/resident/home'),
          child: const Text('Exit preview')),
      ]),
      drawer: desktop ? null : Drawer(child: Builder(builder: (drawerContext) =>
        // The route is not changed by selecting preview modules.
        navigation(true, drawerContext))),
      body: Row(children: [
        if (desktop) SizedBox(width: 280, child: navigation(false, context)),
        Expanded(child: selected.path == '/lgu-admin/verification/residents'
          ? const ResidentDirectoryPage(previewOnly: true)
          : ListView(padding: const EdgeInsets.all(24), children: [
          const Card(child: Padding(padding: EdgeInsets.all(16), child: Text(
            'MOCK NAVIGATION ONLY — No live data or administrative permissions.'))),
          const SizedBox(height: 16),
          Text(_roleLabel(_role), style: Theme.of(context).textTheme.titleMedium),
          Text(selected.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          const Text('This preview validates the navigation structure. Feature-level mock data will be added when each module is developed.'),
        ])),
      ]),
    );
  }
}
