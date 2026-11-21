import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'kaisa_resident_navbar.dart';
import 'kaisa_responsive_shell.dart';

/// Backward-compatible widget used by legacy pages.
/// Uses the same five KAISA feature destinations as KaisaResponsiveShell.
/// It hides itself when a page is already wrapped in the shared shell.
class ResidentBottomNav extends StatelessWidget {
  const ResidentBottomNav({super.key, required this.currentIndex});
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    if (KaisaShellScope.isInside(context)) return const SizedBox.shrink();
    final location = GoRouterState.of(context).uri.path;
    return KaisaMobileNavbar(currentPath: location);
  }
}
