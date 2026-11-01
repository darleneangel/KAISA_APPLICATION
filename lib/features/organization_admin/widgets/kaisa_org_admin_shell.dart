import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Independent organization-admin navigation; shares KAISA visual language.
class KaisaOrgAdminShell extends StatelessWidget {
  const KaisaOrgAdminShell({super.key, required this.child});
  final Widget child;
  static const forest = Color(0xFF14532D), yellow = Color(0xFFFBC02D);
  static const routes = [
    '/organization-admin/dashboard',
    '/organization-admin/attendance',
  ];
  static const labels = ['Dashboard', 'Attendance Scanner'];
  static const icons = [
    Icons.dashboard_outlined,
    Icons.qr_code_scanner_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final route = GoRouterState.of(context).uri.path;
    final selected = route.contains('attendance') ? 1 : 0;
    return LayoutBuilder(
      builder: (context, size) {
        final desktop = size.maxWidth >= 880;
        final sidebar = desktop
            ? Container(
                width: size.maxWidth >= 1150 ? 250 : 86,
                color: forest,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 30, 15, 32),
                      child: Row(
                        mainAxisAlignment: size.maxWidth >= 1150
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.diversity_3_rounded,
                            color: yellow,
                            size: 29,
                          ),
                          if (size.maxWidth >= 1150)
                            const Padding(
                              padding: EdgeInsets.only(left: 14),
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
                                    'ORG ADMIN PORTAL',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    for (var i = 0; i < routes.length; i++)
                      ListTile(
                        selected: i == selected,
                        selectedTileColor: Colors.white12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        leading: Icon(
                          icons[i],
                          color: i == selected ? yellow : Colors.white70,
                        ),
                        title: size.maxWidth >= 1150
                            ? Text(
                                labels[i],
                                style: const TextStyle(color: Colors.white),
                              )
                            : null,
                        onTap: () => context.go(routes[i]),
                      ),
                    const Spacer(),
                    ListTile(
                      leading: const Icon(
                        Icons.swap_horiz_rounded,
                        color: yellow,
                      ),
                      title: size.maxWidth >= 1150
                          ? const Text(
                              'Resident Portal',
                              style: TextStyle(color: Colors.white),
                            )
                          : null,
                      onTap: () => context.go('/resident/home'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              )
            : null;
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAF8),
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
                                'KAISA  ·  Organization Administration',
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
                    selectedIndex: selected,
                    onDestinationSelected: (i) => context.go(routes[i]),
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.dashboard_outlined),
                        label: 'Dashboard',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.qr_code_scanner_rounded),
                        label: 'Scanner',
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
