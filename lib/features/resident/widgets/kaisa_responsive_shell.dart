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
    return Theme(
      data: KaisaTypography.theme(context),
      child: LayoutBuilder(
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
      ),
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
  String? _avatarUrl;
  String? _avatarUserId;
  int _profileRequest = 0;

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

  Future<void> _reload() async {
    final request = ++_profileRequest;
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (!mounted) return;
    if (user == null) {
      setState(() {
        _firstName = null;
        _avatarUrl = null;
        _avatarUserId = null;
      });
      return;
    }
    final meta = user.userMetadata ?? {};
    final fallback = (meta['first_name'] ?? meta['firstName'] ?? '')
        .toString()
        .trim();
    if (_avatarUserId != user.id) {
      setState(() {
        _avatarUserId = user.id;
        _firstName = fallback;
        _avatarUrl = null;
      });
    }
    try {
      final row = await client
          .from('resident_profiles')
          .select('first_name, avatar_path')
          .eq('user_id', user.id)
          .maybeSingle();
      if (!mounted ||
          request != _profileRequest ||
          client.auth.currentUser?.id != user.id)
        return;
      final name = (row?['first_name'] ?? '').toString().trim();
      final path = (row?['avatar_path'] ?? '').toString().trim();
      final url = path.isEmpty
          ? null
          : client.storage.from('kaisa-avatars').getPublicUrl(path);
      setState(() {
        _firstName = name.isEmpty ? fallback : name;
        _avatarUrl = url == null
            ? null
            : Uri.parse(url)
                  .replace(
                    queryParameters: {
                      'v': DateTime.now().millisecondsSinceEpoch.toString(),
                    },
                  )
                  .toString();
      });
    } catch (error) {
      debugPrint('KAISA header profile lookup unavailable: $error');
    }
  }

  String get _initial {
    final name = (_firstName ?? '').trim();
    return name.isEmpty ? 'R' : name.substring(0, 1).toUpperCase();
  }

  Widget _avatarFallback() => Center(
    child: Text(
      _initial,
      style: KaisaTypography.body(
        const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    ),
  );

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Sign out of KAISA?'),
        content: Text('You can sign back in with your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Sign out'),
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

  void _explore() {
    final router = GoRouter.of(context);
    var query = '';
    final destinations = <(String, IconData, String)>[
      for (final item in KaisaResidentNavigation.destinations)
        (item.label, item.icon, item.path),
      ('My Events', Icons.event_available_outlined, '/resident/my-events'),
      (
        'My Organizations',
        Icons.group_work_outlined,
        '/resident/my-organizations',
      ),
      (
        'Notifications',
        Icons.notifications_none_rounded,
        '/resident/notifications',
      ),
      (
        'Identity Verification',
        Icons.verified_user_outlined,
        '/resident/identity-verification',
      ),
    ];
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Theme(
        data: KaisaTypography.theme(context),
        child: StatefulBuilder(
          builder: (context, update) {
            final results = destinations
                .where(
                  (item) => item.$1.toLowerCase().contains(
                    query.trim().toLowerCase(),
                  ),
                )
                .toList();
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 540,
                  maxHeight: MediaQuery.sizeOf(context).height * .72,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Smart Search',
                              style: KaisaTypography.heading(
                                const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close search',
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Find a KAISA page or service.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        autofocus: true,
                        onChanged: (value) => update(() => query = value),
                        decoration: const InputDecoration(
                          hintText: 'Search KAISA features...',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: results.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text('No matching pages.'),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: results.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final item = results[index];
                                  return ListTile(
                                    leading: Icon(
                                      item.$2,
                                      color: KaisaResidentDesign.forest,
                                    ),
                                    title: Text(item.$1),
                                    trailing: const Icon(
                                      Icons.chevron_right_rounded,
                                    ),
                                    onTap: () {
                                      Navigator.pop(dialogContext);
                                      router.go(item.$3);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final tiny = width < 390;
    return Material(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 66,
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
                        borderRadius: BorderRadius.circular(8),
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
                        Text(
                          'KAISA',
                          style: KaisaTypography.heading(
                            TextStyle(
                              color: KaisaResidentDesign.forest,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                            ),
                          ),
                        ),
                        if (!tiny)
                          Text(
                            'CAVITE CITY',
                            style: KaisaTypography.body(
                              TextStyle(
                                color: KaisaResidentDesign.muted,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
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
                    label: Text(
                      'Search KAISA',
                      style: KaisaTypography.body(
                        const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: KaisaResidentDesign.border),
                      foregroundColor: KaisaResidentDesign.muted,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: KaisaResidentDesign.forest,
                    child: ClipOval(
                      child: SizedBox.square(
                        dimension: 34,
                        child: _avatarUrl == null
                            ? _avatarFallback()
                            : Image.network(
                                _avatarUrl!,
                                key: ValueKey(_avatarUrl),
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => _avatarFallback(),
                                loadingBuilder: (context, child, progress) =>
                                    progress == null
                                    ? child
                                    : _avatarFallback(),
                              ),
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
