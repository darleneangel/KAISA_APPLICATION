import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Responsive navigation for existing resident routes.
/// Phone: existing page-level bottom navigation is preserved.
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
    '/resident/profile',
  ];
  static const _names = [
    'Home',
    'Community Feed',
    'Organizations',
    'Events',
    'My Profile',
  ];
  static const _icons = [
    Icons.home_outlined,
    Icons.forum_outlined,
    Icons.groups_2_outlined,
    Icons.event_outlined,
    Icons.person_outline_rounded,
  ];

  int _selected(String route) {
    if (route.contains('/event')) return 3;
    if (route.contains('/organization')) return 2;
    if (route.contains('/profile') || route.contains('/verification')) return 4;
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
        if (width < 600) return child;
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
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1440),
                      child: child,
                    ),
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
