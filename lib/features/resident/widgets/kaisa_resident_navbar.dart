import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'kaisa_resident_design.dart';
import 'kaisa_theme_switch.dart';

/// The single navigation schema for sidebar, tablet rail and bottom bar.
/// KAISA feature labels use existing resident routes; Stitch informs visuals only.
class KaisaNavDestination {
  const KaisaNavDestination(
    this.label,
    this.path,
    this.icon,
    this.selectedIcon,
  );
  final String label;
  final String path;
  final IconData icon;
  final IconData selectedIcon;
}

abstract final class KaisaResidentNavigation {
  static const destinations = <KaisaNavDestination>[
    KaisaNavDestination(
      'Home',
      '/resident/home',
      Icons.home_outlined,
      Icons.home_rounded,
    ),
    KaisaNavDestination(
      'Community Feed',
      '/resident/feed',
      Icons.forum_outlined,
      Icons.forum_rounded,
    ),
    KaisaNavDestination(
      'Organizations',
      '/resident/organizations',
      Icons.groups_2_outlined,
      Icons.groups_2_rounded,
    ),
    KaisaNavDestination(
      'Events',
      '/resident/events',
      Icons.event_outlined,
      Icons.event_rounded,
    ),
    KaisaNavDestination(
      'Profile',
      '/resident/profile',
      Icons.person_outline_rounded,
      Icons.person_rounded,
    ),
  ];

  static int selectedIndex(String route) {
    if (route == '/resident/home') return 0;
    if (route == '/resident/feed') return 1;
    if (route.startsWith('/resident/organization') ||
        route.startsWith('/resident/my-organizations') ||
        route.startsWith('/resident/request-organization'))
      return 2;
    if (route == '/resident/events' ||
        route.startsWith('/resident/event-details') ||
        route.startsWith('/resident/my-events'))
      return 3;
    if (route.startsWith('/resident/profile') || route.contains('verification'))
      return 4;
    return -1; // Notifications and other utilities have no primary selection.
  }
}

class KaisaResidentNavbar extends StatelessWidget {
  const KaisaResidentNavbar({
    super.key,
    required this.currentPath,
    required this.compact,
    required this.onToggle,
    this.canToggle = true,
  });
  final String currentPath;
  final bool compact;
  final VoidCallback onToggle;
  final bool canToggle;

  // Compatibility with code that previously referenced this property.
  static const destinations = KaisaResidentNavigation.destinations;

  Widget _link(
    BuildContext context,
    String label,
    String path,
    IconData icon,
    bool active,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Tooltip(
      message: label,
      child: Material(
        color: active ? const Color(0xFF176044) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            if (GoRouterState.of(context).uri.path != path) context.go(path);
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 14,
              vertical: 13,
            ),
            child: Row(
              mainAxisAlignment: compact
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: active
                      ? KaisaResidentDesign.yellow
                      : const Color(0xFFD6E4DD),
                  size: 22,
                ),
                if (!compact) ...[
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      label,
                      style: KaisaTypography.heading(
                        TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  if (active)
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: KaisaResidentDesign.yellow,
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final selected = KaisaResidentNavigation.selectedIndex(currentPath);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: compact ? 78 : 246,
      color: KaisaResidentDesign.forest,
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 10 : 18,
                22,
                compact ? 10 : 15,
                25,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!compact) ...[
                    _BrandMark(size: 38),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KAISA',
                            style: KaisaTypography.heading(
                              TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .4,
                              ),
                            ),
                          ),
                          Text(
                            'CIVIC PORTAL',
                            style: KaisaTypography.body(
                              TextStyle(
                                color: Color(0xFFB6D0C0),
                                fontSize: 9,
                                letterSpacing: 1.1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (canToggle)
                    IconButton(
                      tooltip: compact ? 'Expand sidebar' : 'Collapse sidebar',
                      onPressed: onToggle,
                      icon: Icon(
                        compact ? Icons.menu_open_rounded : Icons.menu_rounded,
                        color: Colors.white,
                        size: 23,
                      ),
                    ),
                  if (!canToggle) const _BrandMark(size: 34),
                ],
              ),
            ),
            if (!compact)
              Padding(
                padding: EdgeInsets.fromLTRB(29, 0, 0, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'RESIDENT SERVICES',
                    style: KaisaTypography.body(
                      TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: Color(0xFFACC9B7),
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (var i = 0; i < destinations.length; i++)
                    _link(
                      context,
                      destinations[i].label,
                      destinations[i].path,
                      selected == i
                          ? destinations[i].selectedIcon
                          : destinations[i].icon,
                      selected == i &&
                          currentPath != '/resident/my-events' &&
                          currentPath != '/resident/my-organizations',
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(color: Color(0xFF32654A), height: 1),
                  ),
                  if (!compact)
                    Padding(
                      padding: EdgeInsets.only(left: 17, bottom: 10),
                      child: Text(
                        'MORE',
                        style: KaisaTypography.body(
                          TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: Color(0xFFACC9B7),
                          ),
                        ),
                      ),
                    ),
                  _link(
                    context,
                    'My Events',
                    '/resident/my-events',
                    Icons.event_available_outlined,
                    currentPath == '/resident/my-events',
                  ),
                  _link(
                    context,
                    'My Organizations',
                    '/resident/my-organizations',
                    Icons.groups_2_outlined,
                    currentPath == '/resident/my-organizations',
                  ),
                  _link(
                    context,
                    'Notifications',
                    '/resident/notifications',
                    Icons.notifications_none_rounded,
                    currentPath == '/resident/notifications',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 8, 11, 16),
              child: Column(
                children: [
                  const Divider(color: Color(0xFF32654A)),
                  Row(
                    mainAxisAlignment: compact
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [
                      const KaisaThemeSwitch(compact: true),
                      if (!compact)
                        Text(
                          'Appearance',
                          style: KaisaTypography.body(
                            TextStyle(color: Color(0xFFD6E4DD), fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  if (!compact)
                    Padding(
                      padding: EdgeInsets.only(top: 10, left: 7),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'CONNECT • PARTICIPATE • IMPACT',
                          style: KaisaTypography.body(
                            TextStyle(
                              color: Color(0xFFACC9B7),
                              fontSize: 9,
                              letterSpacing: .3,
                            ),
                          ),
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
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Image.asset(
      'assets/images/kaisa_logo.png',
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Icon(
        Icons.account_balance_rounded,
        color: KaisaResidentDesign.forest,
      ),
    ),
  );
}

class KaisaMobileNavbar extends StatelessWidget {
  const KaisaMobileNavbar({super.key, required this.currentPath});
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final selected = KaisaResidentNavigation.selectedIndex(currentPath);
    return Material(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Container(
          height: 66,
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: KaisaResidentDesign.border)),
          ),
          child: Row(
            children: [
              for (
                var i = 0;
                i < KaisaResidentNavigation.destinations.length;
                i++
              )
                Expanded(
                  child: _MobileNavItem(
                    item: KaisaResidentNavigation.destinations[i],
                    active: selected == i,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileNavItem extends StatelessWidget {
  const _MobileNavItem({required this.item, required this.active});
  final KaisaNavDestination item;
  final bool active;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: active,
    label: item.label,
    child: InkWell(
      onTap: () {
        if (GoRouterState.of(context).uri.path != item.path)
          context.go(item.path);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 46,
            height: 30,
            decoration: BoxDecoration(
              color: active ? KaisaResidentDesign.mint : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              active ? item.selectedIcon : item.icon,
              color: active
                  ? KaisaResidentDesign.forest
                  : KaisaResidentDesign.muted,
              size: 22,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.label == 'Community Feed'
                ? 'Feed'
                : item.label == 'Organizations'
                ? 'Orgs'
                : item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KaisaTypography.body(
              TextStyle(
                color: active
                    ? KaisaResidentDesign.forest
                    : KaisaResidentDesign.muted,
                fontSize: 10,
                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
