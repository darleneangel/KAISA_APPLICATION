import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Organization Admin navigation. This widget provides navigation, not permission.
/// Every organization-admin route and backend RPC must independently enforce access.
class KaisaOrgAdminShell extends StatelessWidget {
  const KaisaOrgAdminShell({super.key, required this.child});

  final Widget child;

  static const forest = Color(0xFF14532D);
  static const yellow = Color(0xFFFBC02D);
  static const selectedGreen = Color(0xFF31704F);
  static const _background = Color(0xFFF8FAF8);

  // `enabled` means a route is intended to be registered in app_router.dart.
  // Turn on other routes only after their pages and protected routes exist.
  static const _entries = <_AdminMenuEntry>[
    _AdminMenuEntry(
      'Dashboard & Analytics',
      Icons.dashboard_outlined,
      '/organization-admin/dashboard',
      true,
    ),
    _AdminMenuEntry(
      'Members & Requests',
      Icons.groups_outlined,
      '/organization-admin/members',
      false,
    ),
    _AdminMenuEntry(
      'Staff Invitations',
      Icons.person_add_alt_outlined,
      '/organization-admin/invitations',
      true,
    ),
    _AdminMenuEntry(
      'Events Management',
      Icons.event_note_outlined,
      '/organization-admin/events',
      false,
    ),
    _AdminMenuEntry(
      'Attendance Scanner',
      Icons.qr_code_scanner_rounded,
      '/organization-admin/attendance',
      true,
    ),
    _AdminMenuEntry(
      'E-Certificate Studio',
      Icons.workspace_premium_outlined,
      '/organization-admin/certificates',
      true,
    ),
    _AdminMenuEntry(
      'Community Feed & Announcements',
      Icons.dynamic_feed_outlined,
      '/organization-admin/announcements',
      true,
    ),
    _AdminMenuEntry(
      'Reports & Exports',
      Icons.assessment_outlined,
      '/organization-admin/reports',
      true,
    ),
    _AdminMenuEntry(
      'Organization Profile',
      Icons.storefront_outlined,
      '/organization-admin/settings',
      true,
    ),
  ];

  // Keep mobile destinations focused; the More tab gives access to every item.
  static const _mobileIndices = [0, 3, 4, 5];

  void _openMenuEntry(
    BuildContext context,
    _AdminMenuEntry entry,
    String? organizationId,
  ) {
    if (!entry.enabled) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(entry.label),
          content: const Text(
            'This section is not built yet. It is not an account-permission lock. '
            'Its page and protected route have not been integrated yet.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    if (organizationId == null || organizationId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please choose an organization from the account switcher.',
          ),
        ),
      );
      return;
    }
    context.go(
      Uri(
        path: entry.path,
        queryParameters: {'organizationId': organizationId},
      ).toString(),
    );
  }

  void _showMobileMenu(BuildContext context, String? organizationId) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text(
                'Organization management',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            for (final entry in _entries)
              ListTile(
                leading: Icon(entry.icon, color: forest),
                selected: entry.path == GoRouterState.of(context).uri.path,
                selectedTileColor: const Color(0xFFE1F2E7),
                title: Text(entry.label),
                trailing: entry.enabled
                    ? const Icon(Icons.chevron_right)
                    : const Icon(Icons.lock_clock_outlined, size: 18),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openMenuEntry(context, entry, organizationId);
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: forest),
              title: const Text('Resident Portal'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.go('/resident/home');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uri = GoRouterState.of(context).uri;
    final currentPath = uri.path;
    final organizationId = uri.queryParameters['organizationId'];
    final activeIndex = _entries.indexWhere(
      (entry) => entry.path == currentPath,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 880;
        final expanded = constraints.maxWidth >= 1150;
        final sidebar = desktop
            ? Container(
                width: expanded ? 250 : 86,
                color: forest,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 28, 14, 24),
                      child: Row(
                        mainAxisAlignment: expanded
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.diversity_3_rounded,
                            color: yellow,
                            size: 29,
                          ),
                          if (expanded)
                            const Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(left: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'KAISA',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 23,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      'ORGANIZATION ADMIN PORTAL',
                                      maxLines: 2,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        children: [
                          for (var i = 0; i < _entries.length; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Tooltip(
                                message: _entries[i].label,
                                child: ListTile(
                                  selected: i == activeIndex,
                                  selectedTileColor: selectedGreen,
                                  tileColor: Colors.transparent,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  leading: Icon(
                                    _entries[i].icon,
                                    color: i == activeIndex
                                        ? yellow
                                        : Colors.white70,
                                  ),
                                  title: expanded
                                      ? Text(
                                          _entries[i].label,
                                          style: TextStyle(
                                            color: i == activeIndex
                                                ? Colors.white
                                                : Colors.white70,
                                            fontSize: 12,
                                            fontWeight: i == activeIndex
                                                ? FontWeight.w700
                                                : FontWeight.w400,
                                          ),
                                        )
                                      : null,
                                  trailing: expanded && !_entries[i].enabled
                                      ? const Icon(
                                          Icons.lock_clock_outlined,
                                          color: Colors.white54,
                                          size: 16,
                                        )
                                      : expanded && i == activeIndex
                                      ? const Icon(
                                          Icons.chevron_right_rounded,
                                          color: yellow,
                                          size: 18,
                                        )
                                      : null,
                                  onTap: () => _openMenuEntry(
                                    context,
                                    _entries[i],
                                    organizationId,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white24),
                    Tooltip(
                      message: 'Resident Portal',
                      child: ListTile(
                        leading: const Icon(
                          Icons.swap_horiz_rounded,
                          color: yellow,
                        ),
                        title: expanded
                            ? const Text(
                                'Resident Portal',
                                style: TextStyle(color: Colors.white),
                              )
                            : null,
                        onTap: () => context.go('/resident/home'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              )
            : null;

        final mobileIndex = _mobileIndices.indexOf(activeIndex);
        return Scaffold(
          backgroundColor: _background,
          body: SafeArea(
            child: Row(
              children: [
                if (sidebar != null) sidebar,
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 64,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFE2EBE4)),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.diversity_3_rounded,
                              color: forest,
                            ),
                            const SizedBox(width: 9),
                            const Expanded(
                              child: Text(
                                'KAISA · Organization Administration',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: forest,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Resident Portal',
                              onPressed: () => context.go('/resident/home'),
                              icon: const Icon(
                                Icons.person_outline_rounded,
                                color: forest,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1180),
                            child: child,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: desktop
              ? null
              : SafeArea(
                  top: false,
                  child: NavigationBar(
                    indicatorColor: const Color(0xFFD5EBDD),
                    selectedIndex: mobileIndex < 0 ? 4 : mobileIndex,
                    onDestinationSelected: (index) {
                      if (index == 4) {
                        _showMobileMenu(context, organizationId);
                      } else {
                        _openMenuEntry(
                          context,
                          _entries[_mobileIndices[index]],
                          organizationId,
                        );
                      }
                    },
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.dashboard_outlined),
                        label: 'Dashboard',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.event_note_outlined),
                        label: 'Events',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.qr_code_scanner_rounded),
                        label: 'Attendance',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.workspace_premium_outlined),
                        label: 'Certificates',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.menu_rounded),
                        label: 'More',
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _AdminMenuEntry {
  const _AdminMenuEntry(this.label, this.icon, this.path, this.enabled);
  final String label;
  final IconData icon;
  final String path;
  final bool enabled;
}
