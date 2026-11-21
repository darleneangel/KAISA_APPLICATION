import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'kaisa_account_refresh.dart';
import 'kaisa_portal_switcher.dart';
import 'kaisa_resident_design.dart';
import 'kaisa_resident_navbar.dart';
import 'notification_bell.dart';

/// Parent marker: the legacy ResidentBottomNav hides itself inside this shell.
/// Prevents two bottom bars while pages are migrated to shared navigation.
class KaisaShellScope extends InheritedWidget {
  const KaisaShellScope({super.key, required super.child});
  static bool isInside(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KaisaShellScope>() != null;
  @override
  bool updateShouldNotify(KaisaShellScope oldWidget) => false;
}

/// Shared navigation chrome only. Supabase and page data stay in their pages.
/// Phone: 5 KAISA feature tabs. Tablet: icon rail. Desktop: sidebar.
class KaisaResponsiveShell extends StatefulWidget {
  const KaisaResponsiveShell({super.key, required this.child, this.location});
  final Widget child;
  final String? location;
  @override
  State<KaisaResponsiveShell> createState() => _KaisaResponsiveShellState();
}

class _KaisaResponsiveShellState extends State<KaisaResponsiveShell> {
  bool _sidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final current = widget.location ?? GoRouterState.of(context).uri.path;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final mobile = width < 768;
        final tablet = width >= 768 && width < 1024;
        final sidebarCollapsed = tablet || _sidebarCollapsed;

        return Scaffold(
          backgroundColor: KaisaResidentDesign.paper,
          body: KaisaShellScope(
            child: mobile
                ? Column(
                    children: [
                      const KaisaResidentTopBar(),
                      Expanded(child: widget.child),
                    ],
                  )
                : Row(
                    children: [
                      KaisaResidentNavbar(
                        currentPath: current,
                        compact: sidebarCollapsed,
                        onToggle: () => setState(
                          () => _sidebarCollapsed = !_sidebarCollapsed,
                        ),
                        canToggle: !tablet,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const KaisaResidentTopBar(),
                            Expanded(
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 1440,
                                  ),
                                  child: widget.child,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          bottomNavigationBar: mobile
              ? KaisaMobileNavbar(currentPath: current)
              : null,
        );
      },
    );
  }
}

/// The shared KAISA header with Stitch-inspired presentation only.
/// Account data is loaded from the existing Supabase resident profile.
class KaisaResidentTopBar extends StatefulWidget {
  const KaisaResidentTopBar({super.key});
  @override
  State<KaisaResidentTopBar> createState() => _KaisaResidentTopBarState();
}

class _KaisaResidentTopBarState extends State<KaisaResidentTopBar> {
  String? _firstName;

  @override
  void initState() {
    super.initState();
    kaisaAccountRefresh.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    kaisaAccountRefresh.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final meta = user.userMetadata ?? {};
    final fallback = (meta['first_name'] ?? meta['firstName'] ?? '')
        .toString()
        .trim();
    if (mounted) setState(() => _firstName = fallback);
    Supabase.instance.client
        .from('resident_profiles')
        .select('first_name')
        .eq('user_id', user.id)
        .maybeSingle()
        .then((row) {
          if (!mounted) return;
          final value = (row?['first_name'] ?? '').toString().trim();
          if (value.isNotEmpty) setState(() => _firstName = value);
        })
        .catchError((Object error) {
          debugPrint('KAISA header profile lookup unavailable: $error');
        });
  }

  String get _initial {
    final name = (_firstName ?? '').trim();
    return name.isEmpty ? 'R' : name.substring(0, 1).toUpperCase();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out of KAISA?'),
        content: const Text('You can sign back in with your account.'),
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
    if (confirmed != true || !mounted) return;
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) context.go('/welcome');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text('Unable to sign out. Please try again.'),
          ),
        );
      }
    }
  }

  void _explore() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Find KAISA features',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: KaisaResidentDesign.ink,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Go directly to a KAISA service.',
              style: TextStyle(fontSize: 14, color: KaisaResidentDesign.muted),
            ),
            const SizedBox(height: 17),
            for (final entry in const <(String, IconData, String)>[
              ('Community Feed', Icons.forum_outlined, '/resident/feed'),
              (
                'Organizations',
                Icons.groups_2_outlined,
                '/resident/organizations',
              ),
              ('Events', Icons.event_outlined, '/resident/events'),
              (
                'My Events',
                Icons.event_available_outlined,
                '/resident/my-events',
              ),
              (
                'My Organizations',
                Icons.group_work_outlined,
                '/resident/my-organizations',
              ),
            ])
              ListTile(
                leading: Icon(entry.$2, color: KaisaResidentDesign.forest),
                title: Text(entry.$1),
                trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go(entry.$3);
                },
              ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final tiny = width < 390;
    return Material(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64,
          padding: EdgeInsets.symmetric(
            horizontal: tiny ? 12 : (width < 768 ? 17 : 28),
          ),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: KaisaResidentDesign.border),
            ),
          ),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(7),
                onTap: () => context.go('/resident/home'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: KaisaResidentDesign.border),
                      ),
                      child: Image.asset(
                        'assets/images/kaisa_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.account_balance_rounded,
                          color: KaisaResidentDesign.forest,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'KAISA',
                          style: TextStyle(
                            color: KaisaResidentDesign.forest,
                            fontFamily: 'Outfit',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                          ),
                        ),
                        if (!tiny)
                          const Text(
                            'CAVITE CITY',
                            style: TextStyle(
                              color: KaisaResidentDesign.muted,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (width >= 1024)
                SizedBox(
                  width: 210,
                  height: 37,
                  child: OutlinedButton.icon(
                    onPressed: _explore,
                    icon: const Icon(Icons.search_rounded, size: 18),
                    label: const Text('Search KAISA'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: KaisaResidentDesign.border),
                      foregroundColor: KaisaResidentDesign.muted,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                    ),
                  ),
                )
              else
                IconButton(
                  tooltip: 'Explore KAISA',
                  icon: const Icon(Icons.search_rounded),
                  onPressed: _explore,
                  color: KaisaResidentDesign.ink,
                ),
              const SizedBox(width: 1),
              const NotificationBell(),
              const KaisaPortalSwitcher(),
              PopupMenuButton<String>(
                tooltip: 'Account',
                onSelected: (value) {
                  if (value == 'logout') {
                    _logout();
                    return;
                  }
                  if (value == 'switch') {
                    return;
                  } // switching is owned by KaisaPortalSwitcher
                  context.go(value);
                },
                itemBuilder: (_) => [
                  if (_firstName != null && _firstName!.isNotEmpty)
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Text('Signed in as $_firstName'),
                    ),
                  const PopupMenuItem(
                    value: '/resident/profile',
                    child: Text('My profile'),
                  ),
                  const PopupMenuItem(
                    value: '/resident/identity-verification',
                    child: Text('Identity verification'),
                  ),
                  const PopupMenuItem(value: 'logout', child: Text('Sign out')),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: KaisaResidentDesign.forest,
                    child: Text(
                      _initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
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
