import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'kaisa_theme_switch.dart';

class KaisaResidentNavbar extends StatelessWidget {
  const KaisaResidentNavbar({
    super.key,
    required this.currentPath,
    required this.compact,
    required this.onToggle,
  });
  final String currentPath;
  final bool compact;
  final VoidCallback onToggle;
  static const destinations = <({String label, String path, IconData icon})>[
    (label: 'Home', path: '/resident/home', icon: Icons.home_rounded),
    (
      label: 'Community Feed',
      path: '/resident/feed',
      icon: Icons.dynamic_feed_rounded,
    ),
    (
      label: 'Organizations',
      path: '/resident/organizations',
      icon: Icons.groups_rounded,
    ),
    (label: 'Events', path: '/resident/events', icon: Icons.event_rounded),
    (label: 'Profile', path: '/resident/profile', icon: Icons.person_rounded),
  ];
  Widget link(
    BuildContext context,
    ({String label, String path, IconData icon}) item,
  ) {
    final active = currentPath == item.path;
    return Tooltip(
      message: item.label,
      child: Material(
        color: active ? const Color(0xFF217B57) : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () => context.go(item.path),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 15,
              vertical: 14,
            ),
            child: Row(
              mainAxisAlignment: compact
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(
                  item.icon,
                  color: active ? AppColors.yellow : Colors.white70,
                  size: 23,
                ),
                if (!compact) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 230),
    width: compact ? 76 : 250,
    color: AppColors.deepForest,
    padding: const EdgeInsets.fromLTRB(12, 18, 12, 16),
    child: Column(
      children: [
        Row(
          children: [
            if (!compact) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/kaisa_logo.png',
                  width: 35,
                  height: 35,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.diversity_3, color: Colors.white),
                ),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'KAISA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
            IconButton(
              onPressed: onToggle,
              tooltip: compact ? 'Expand navigation' : 'Collapse navigation',
              icon: Icon(
                compact ? Icons.menu_open_rounded : Icons.menu_rounded,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 35),
        if (!compact)
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 12, bottom: 9),
              child: Text(
                'COMMUNITY',
                style: TextStyle(
                  color: AppColors.lime,
                  letterSpacing: 1.8,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ...destinations.map(
          (d) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: link(context, d),
          ),
        ),
        const Spacer(),
        Theme(
          data: Theme.of(context).copyWith(
            iconTheme: const IconThemeData(color: Colors.white),
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(onSurface: Colors.white),
          ),
          child: const KaisaThemeSwitch(),
        ),
        const Divider(color: Colors.white24),
        link(context, (
          label: 'About KAISA',
          path: '/resident/about',
          icon: Icons.info_outline_rounded,
        )),
        if (!compact)
          const Padding(
            padding: EdgeInsets.only(top: 15),
            child: Text(
              'CONNECT • PARTICIPATE • IMPACT',
              style: TextStyle(color: Colors.white60, fontSize: 9),
            ),
          ),
      ],
    ),
  );
}

class KaisaMobileNavbar extends StatelessWidget {
  const KaisaMobileNavbar({super.key, required this.currentPath});
  final String currentPath;
  @override
  Widget build(BuildContext context) {
    final index = KaisaResidentNavbar.destinations.indexWhere(
      (d) => d.path == currentPath,
    );
    return NavigationBar(
      height: 72,
      selectedIndex: index < 0 ? 0 : index,
      onDestinationSelected: (i) =>
          context.go(KaisaResidentNavbar.destinations[i].path),
      destinations: KaisaResidentNavbar.destinations
          .map(
            (d) => NavigationDestination(
              icon: Icon(d.icon),
              label: d.label == 'Community Feed'
                  ? 'Feed'
                  : d.label == 'Organizations'
                  ? 'Orgs'
                  : d.label,
            ),
          )
          .toList(),
    );
  }
}
