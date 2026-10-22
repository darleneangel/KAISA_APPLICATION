import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'kaisa_resident_navbar.dart';

class KaisaResponsiveShell extends StatefulWidget {
  const KaisaResponsiveShell({super.key, required this.child});
  final Widget child;
  @override
  State<KaisaResponsiveShell> createState() => _KaisaResponsiveShellState();
}

class _KaisaResponsiveShellState extends State<KaisaResponsiveShell> {
  bool collapsed = false;
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final mobile = width < 700;
    final tablet = width >= 700 && width < 1100;
    final path = GoRouterState.of(context).uri.path;
    final content = Theme(data: Theme.of(context), child: widget.child);
    if (mobile)
      return Scaffold(
        body: content,
        bottomNavigationBar: KaisaMobileNavbar(currentPath: path),
      );
    return Scaffold(
      body: Row(
        children: [
          KaisaResidentNavbar(
            currentPath: path,
            compact: tablet || collapsed,
            onToggle: () => setState(() => collapsed = !collapsed),
          ),
          Expanded(child: content),
        ],
      ),
    );
  }
}
