import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'kaisa_resident_design.dart';

/// Responsive navigation for existing resident routes.
/// Phone: one shared bottom navigation bar for every resident route.
/// Tablet: compact icon rail. Desktop: expanded KAISA sidebar.
/// No changes to authentication or router definitions are required.
class KaisaResponsiveShell extends StatelessWidget {
  const KaisaResponsiveShell({super.key, required this.child, this.location});
  final Widget child;
  final String? location;

  static const _forest = Color(0xFF14532D);
  static const _gold = Color(0xFFFBC02D);
  static const _paths = [
    '/resident/home',
    '/resident/feed',
    '/resident/organizations',
    '/resident/events',
    '/resident/messages',
    '/resident/profile',
  ];
  static const _names = [
    'Home',
    'Community Feed',
    'Organizations',
    'Events',
    'Messages',
    'My Profile',
  ];
  static const _icons = [
    Icons.home_outlined,
    Icons.forum_outlined,
    Icons.groups_2_outlined,
    Icons.event_outlined,
    Icons.chat_bubble_outline_rounded,
    Icons.person_outline_rounded,
  ];

  int _selected(String route) {
    if (route.contains('/event')) return 3;
    if (route.contains('/organization')) return 2;
    if (route.contains('/profile') ||
        route.contains('/verification') ||
        route.contains('/user/'))
      return 5;
    if (route.contains('/messages')) return 4;
    if (route.contains('/feed')) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final route = location ?? GoRouterState.of(context).uri.path;
    final index = _selected(route);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width < 600) {
          return Scaffold(
            backgroundColor: KaisaResidentDesign.paper,
            body: Column(
              children: [
                const KaisaResidentTopBar(),
                Expanded(child: child),
              ],
            ),
            bottomNavigationBar: SafeArea(
              top: false,
              child: NavigationBar(
                height: 70,
                elevation: 0,
                backgroundColor: Colors.white,
                indicatorColor: const Color(0xFFE5F2E9),
                selectedIndex: index,
                labelBehavior:
                    NavigationDestinationLabelBehavior.onlyShowSelected,
                onDestinationSelected: (next) {
                  if (next != index) context.go(_paths[next]);
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.forum_outlined),
                    selectedIcon: Icon(Icons.forum_rounded),
                    label: 'Feed',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.groups_2_outlined),
                    selectedIcon: Icon(Icons.groups_2_rounded),
                    label: 'Groups',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.event_outlined),
                    selectedIcon: Icon(Icons.event_rounded),
                    label: 'Events',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.chat_bubble_outline_rounded),
                    selectedIcon: Icon(Icons.chat_bubble_rounded),
                    label: 'Messages',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline_rounded),
                    selectedIcon: Icon(Icons.person_rounded),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          );
        }
        final desktop = width >= 1024;
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAF8),
          body: SafeArea(
            child: Row(
              children: [
                Container(
                  width: desktop ? 254 : 86,
                  decoration: const BoxDecoration(color: _forest),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          desktop ? 22 : 10,
                          28,
                          10,
                          34,
                        ),
                        child: Row(
                          mainAxisAlignment: desktop
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(
                                Icons.diversity_3_rounded,
                                color: _gold,
                                size: 25,
                              ),
                            ),
                            if (desktop)
                              const Padding(
                                padding: EdgeInsets.only(left: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'KAISA',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    Text(
                                      'RESIDENT PORTAL',
                                      style: TextStyle(
                                        color: Color(0xFFC4E2CE),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (desktop)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(23, 0, 0, 14),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'MENU',
                              style: TextStyle(
                                color: Color(0xFFBDD7C6),
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                      for (var i = 0; i < _paths.length; i++)
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            desktop ? 12 : 9,
                            0,
                            desktop ? 12 : 9,
                            8,
                          ),
                          child: Tooltip(
                            message: _names[i],
                            child: Material(
                              color: index == i
                                  ? Colors.white.withValues(alpha: .13)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(13),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(13),
                                onTap: () => context.go(_paths[i]),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: desktop ? 14 : 8,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: desktop
                                        ? MainAxisAlignment.start
                                        : MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _icons[i],
                                        size: 23,
                                        color: index == i
                                            ? _gold
                                            : const Color(0xFFD9EDE0),
                                      ),
                                      if (desktop) ...[
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Text(
                                            _names[i],
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: index == i
                                                  ? Colors.white
                                                  : const Color(0xFFD9EDE0),
                                              fontWeight: index == i
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(15, 12, 15, 24),
                        child: desktop
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .09),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.favorite_rounded,
                                      color: _gold,
                                      size: 23,
                                    ),
                                    SizedBox(height: 9),
                                    Text(
                                      'Stronger together.',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'Connect • Participate • Impact',
                                      style: TextStyle(
                                        color: Color(0xFFCEDECF),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const Icon(
                                Icons.favorite_outline_rounded,
                                color: _gold,
                              ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const KaisaResidentTopBar(),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: KaisaResidentDesign.desktopWidth,
                            ),
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
        );
      },
    );
  }
}

/// Shared, single top header for resident screens. Put it in the ShellRoute
/// wrapper rather than adding a separate AppBar to every screen.
class KaisaResidentTopBar extends StatelessWidget {
  const KaisaResidentTopBar({super.key});

  static const _options = <(String, IconData, String)>[
    ('Community Feed', Icons.forum_outlined, '/resident/feed'),
    ('Organizations', Icons.groups_2_outlined, '/resident/organizations'),
    ('Events', Icons.event_available_outlined, '/resident/events'),
    ('My Events', Icons.bookmark_added_outlined, '/resident/my-events'),
    ('Messages', Icons.chat_bubble_outline_rounded, '/resident/messages'),
  ];

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out of KAISA?'),
        content: const Text('You will return to the welcome screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) context.go('/welcome');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text('Could not sign out. Please try again.'),
          ),
        );
      }
    }
  }

  void _search(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const KaisaResidentSectionHeading(
              title: 'Explore KAISA',
              subtitle: 'Find what matters to your community.',
            ),
            const SizedBox(height: 12),
            for (final option in _options)
              ListTile(
                leading: Icon(option.$2, color: KaisaResidentDesign.green),
                title: Text(option.$1),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go(option.$3);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 420;
    final rawName =
        Supabase.instance.client.auth.currentUser?.userMetadata?['first_name']
            ?.toString() ??
        '';
    final initial = rawName.trim().isEmpty
        ? 'R'
        : rawName.trim()[0].toUpperCase();
    return Material(
      color: KaisaResidentDesign.paper,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 66,
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 24),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: KaisaResidentDesign.border),
            ),
          ),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context.go('/resident/home'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: KaisaResidentDesign.forest,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.diversity_3_rounded,
                        color: KaisaResidentDesign.yellow,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 9),
                    const Text(
                      'KAISA',
                      style: TextStyle(
                        color: KaisaResidentDesign.forest,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Explore KAISA',
                iconSize: KaisaResidentDesign.iconSize,
                onPressed: () => _search(context),
                icon: const Icon(
                  Icons.search_rounded,
                  color: KaisaResidentDesign.ink,
                ),
              ),
              IconButton(
                tooltip: 'Messages',
                iconSize: KaisaResidentDesign.iconSize,
                onPressed: () => context.go('/resident/messages'),
                icon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: KaisaResidentDesign.ink,
                ),
              ),
              IconButton(
                tooltip: 'Notifications',
                iconSize: KaisaResidentDesign.iconSize,
                onPressed: () => context.go('/resident/notifications'),
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: KaisaResidentDesign.ink,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Account',
                onSelected: (value) {
                  if (value == 'logout') {
                    _logout(context);
                  } else {
                    context.go(value);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: '/resident/profile',
                    child: Text('My profile'),
                  ),
                  PopupMenuItem(
                    value: '/resident/identity-verification',
                    child: Text('Identity verification'),
                  ),
                  PopupMenuItem(value: 'logout', child: Text('Sign out')),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: const Color(0xFFE5F2E9),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: KaisaResidentDesign.forest,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
