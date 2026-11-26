import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Organization navigation only. Authorization remains in KaisaOrgAdminGate
/// and in the server-side operations. This shell does not grant staff access.
class KaisaOrgAdminShell extends StatelessWidget {
  const KaisaOrgAdminShell({super.key, required this.child});
  final Widget child;

  static const _green = Color(0xFF154E2E);
  static const _deep = Color(0xFF103D25);
  static const _gold = Color(0xFFFDBC19);
  static const _muted = Color(0xFFB9D2C2);
  static const _background = Color(0xFFF6F8F6);
  static const _base = '/organization-admin';

  static const _groups = <(String, List<(String, IconData, String)>)>[
    ('OVERVIEW', [
      ('Dashboard & Analytics', Icons.dashboard_outlined, 'dashboard'),
    ]),
    ('PEOPLE MANAGEMENT', [
      ('Members & Requests', Icons.groups_outlined, 'members'),
      ('Staff & Permissions', Icons.manage_accounts_outlined, 'invitations'),
    ]),
    ('COMMUNITY OPERATIONS', [
      ('Events Management', Icons.event_outlined, 'events'),
      ('Attendance Management', Icons.qr_code_scanner, 'attendance'),
      ('E-Certificate Studio', Icons.workspace_premium_outlined, 'ecertificate-studio'),
      ('Feed & Announcements', Icons.campaign_outlined, 'announcements'),
    ]),
    ('INSIGHTS & GOVERNANCE', [
      ('Reports & Exports', Icons.bar_chart_rounded, 'reports'),
      ('Audit Logs', Icons.history_rounded, 'audit-logs'),
    ]),
    ('ORGANIZATION', [
      ('Organization Profile', Icons.storefront_outlined, 'profile'),
      ('Settings', Icons.settings_outlined, 'workspace-settings'),
    ]),
  ];

  String _activePath(String path) {
    if (path == 'settings') return 'profile'; // Legacy profile URL.
    if (path == 'certificates') return 'ecertificate-studio';
    return path;
  }

  String _destination(Uri current, String path) {
    final id = current.queryParameters['organizationId'];
    return Uri(path: '$_base/$path', queryParameters:
        id == null ? null : {'organizationId': id}).toString();
  }

  Widget _navigation(BuildContext context, Uri uri, {required bool drawer}) {
    final active = _activePath(uri.pathSegments.last);
    void go(String target) {
      final router = GoRouter.of(context);
      if (drawer) Navigator.of(context).pop();
      router.go(target);
    }
    return Material(
      color: _green,
      child: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 22, 14, 18),
            child: Row(children: [
              Icon(Icons.groups_rounded, color: _gold, size: 32),
              SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('KAISA', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, decoration: TextDecoration.none)),
                Text('ORGANIZATION ADMIN PORTAL', style: TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.w600, decoration: TextDecoration.none)),
              ])),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFF356347)),
          Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(12, 8, 12, 12), children: [
            for (final group in _groups) ...[
              Padding(padding: const EdgeInsets.fromLTRB(12, 17, 8, 5), child: Text(group.$1, style: const TextStyle(color: _muted, fontSize: 10, letterSpacing: 1.1, fontWeight: FontWeight.w700, decoration: TextDecoration.none))),
              for (final destination in group.$2)
                Padding(padding: const EdgeInsets.only(bottom: 3), child: ListTile(
                  dense: true,
                  minLeadingWidth: 25,
                  horizontalTitleGap: 10,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  selected: active == destination.$3,
                  selectedTileColor: _deep,
                  leading: Icon(destination.$2, size: 21, color: active == destination.$3 ? _gold : _muted),
                  title: Text(destination.$1, style: TextStyle(color: active == destination.$3 ? Colors.white : _muted, fontSize: 13, fontWeight: active == destination.$3 ? FontWeight.w700 : FontWeight.w500, decoration: TextDecoration.none)),
                  trailing: active == destination.$3 ? const Icon(Icons.chevron_right, color: _gold, size: 17) : null,
                  onTap: () => go(_destination(uri, destination.$3)),
                )),
            ],
          ])),
          const Divider(height: 1, color: Color(0xFF356347)),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
            leading: const Icon(Icons.swap_horiz_rounded, color: _gold),
            title: const Text('Resident Portal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, decoration: TextDecoration.none)),
            onTap: () => go('/resident/home'),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uri = GoRouterState.of(context).uri;
    final theme = Theme.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      final desktop = constraints.maxWidth >= 900;
      return Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: _green,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: const Text('KAISA · Organization Administration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          actions: [IconButton(tooltip: 'Organization profile', onPressed: () => context.go(_destination(uri, 'profile')), icon: const Icon(Icons.person_outline)), const SizedBox(width: 8)],
        ),
        drawer: desktop ? null : Drawer(backgroundColor: _green, child: Builder(builder: (drawerContext) => _navigation(drawerContext, uri, drawer: true))),
        body: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (desktop) SizedBox(width: 260, child: _navigation(context, uri, drawer: false)),
          Expanded(child: Material(
            color: _background,
            child: DefaultTextStyle(
              style: (theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14)).copyWith(color: theme.colorScheme.onSurface, decoration: TextDecoration.none),
              child: child,
            ),
          )),
        ]),
      );
    });
  }
}
