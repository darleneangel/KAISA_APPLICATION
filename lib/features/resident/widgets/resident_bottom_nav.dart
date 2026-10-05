import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResidentBottomNav extends StatelessWidget {
  final int currentIndex;

  const ResidentBottomNav({
    super.key,
    required this.currentIndex,
  });

  void _navigate(BuildContext context, int index) {
    // Don't navigate again if the user taps
    // the page they are already on.
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        context.go('/resident/home');
        break;

      case 1:
        context.go('/resident/feed');
        break;

      case 2:
        context.go('/resident/organizations');
        break;

      case 3:
        context.go('/resident/events');
        break;

      case 4:
        context.go('/resident/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        _navigate(context, index);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.dynamic_feed_outlined),
          selectedIcon: Icon(Icons.dynamic_feed_rounded),
          label: 'Feed',
        ),
        NavigationDestination(
          icon: Icon(Icons.groups_outlined),
          selectedIcon: Icon(Icons.groups_rounded),
          label: 'Orgs',
        ),
        NavigationDestination(
          icon: Icon(Icons.event_outlined),
          selectedIcon: Icon(Icons.event_rounded),
          label: 'Events',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}