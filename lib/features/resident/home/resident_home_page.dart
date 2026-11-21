import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/kaisa_account_refresh.dart';
import '../widgets/kaisa_resident_design.dart';
import '../widgets/kaisa_responsive_shell.dart';

/// KAISA Resident Home — Civic Dignity / Stitch-inspired presentation.
///
/// The uploaded Stitch files are a VISUAL reference only. All links below
/// target existing KAISA resident modules. No fictional user metrics, IDs,
/// verification statuses, events, or Supabase tables are introduced.
///
/// The responsive shell owns the header, mobile/desktop navigation, portal
/// switcher and sign-out. This page deliberately does not duplicate them.
const Color _forest = Color(0xFF00492C);
const Color _deep = Color(0xFF00301B);
const Color _gold = Color(0xFFFBBA16);
const Color _ink = Color(0xFF1F2937);
const Color _muted = Color(0xFF6B7280);
const Color _paper = Color(0xFFF8F9FA);
const Color _line = Color(0xFFE5E7EB);
const Color _mint = Color(0xFFE7F2EC);
const Color _blueIce = Color(0xFFE7EDFC);
const Color _goldWash = Color(0xFFFFF0CF);

TextStyle _display(double size, {Color color = _ink}) => TextStyle(
  fontFamily: 'serif',
  fontSize: size,
  fontWeight: FontWeight.w700,
  letterSpacing: -.45,
  height: 1.12,
  color: color,
);

class ResidentHomePage extends StatefulWidget {
  const ResidentHomePage({super.key});

  @override
  State<ResidentHomePage> createState() => _ResidentHomePageState();
}

class _ResidentHomePageState extends State<ResidentHomePage> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _refreshing = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    kaisaAccountRefresh.addListener(_onAccountChanged);
    _loadProfile();
  }

  @override
  void dispose() {
    kaisaAccountRefresh.removeListener(_onAccountChanged);
    super.dispose();
  }

  void _onAccountChanged() => _loadProfile();

  String get _firstName {
    final metadata =
        Supabase.instance.client.auth.currentUser?.userMetadata ?? {};
    final raw =
        (_profile?['first_name'] ??
                metadata['first_name'] ??
                metadata['firstName'] ??
                metadata['full_name'] ??
                '')
            .toString()
            .trim();
    return raw.isEmpty ? 'Resident' : raw.split(RegExp(r'\s+')).first;
  }

  String get _location {
    final barangay = (_profile?['barangay'] ?? '').toString().trim();
    final city = (_profile?['city_municipality'] ?? '').toString().trim();
    final province = (_profile?['province'] ?? '').toString().trim();
    final pieces = [barangay, city, province].where((e) => e.isNotEmpty);
    return pieces.isEmpty ? 'Add your community location' : pieces.join(', ');
  }

  int get _profileProgress {
    final p = _profile;
    if (p == null) return 0;
    const fields = [
      'first_name',
      'last_name',
      'birth_date',
      'mobile_number',
      'province',
      'city_municipality',
      'barangay',
      'street_address',
    ];
    final filled = fields.where((field) {
      final value = p[field];
      return value != null && value.toString().trim().isNotEmpty;
    }).length;
    return (filled * 100 / fields.length).round();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _profile = null;
        _loading = false;
        _loadError = 'Please sign in again.';
      });
      return;
    }

    try {
      // Preserved: original resident_profiles table, selected fields and filter.
      final row = await Supabase.instance.client
          .from('resident_profiles')
          .select(
            'first_name,last_name,middle_name,birth_date,mobile_number,province,city_municipality,barangay,street_address',
          )
          .eq('user_id', user.id)
          .maybeSingle();
      if (!mounted) return;
      setState(() {
        _profile = row;
        _loadError = null;
        _loading = false;
      });
    } catch (error) {
      debugPrint('KAISA home profile read failed: $error');
      if (!mounted) return;
      setState(() {
        _loadError =
            'Profile could not be loaded. Check your connection or profile access permissions.';
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    await _loadProfile();
    if (mounted) setState(() => _refreshing = false);
  }

  void _go(String path) => context.go(path);

  /// Search local module names, not database content (no search RPC invented).
  void _openQuickNavigation() {
    const destinations = <(String, IconData, String)>[
      ('Community Feed', Icons.forum_outlined, '/resident/feed'),
      ('Organizations', Icons.groups_2_outlined, '/resident/organizations'),
      ('Events', Icons.event_outlined, '/resident/events'),
      ('My Events', Icons.event_available_outlined, '/resident/my-events'),
      ('My Organizations', Icons.people_outline, '/resident/my-organizations'),
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
      ('My Profile', Icons.person_outline_rounded, '/resident/profile'),
    ];

    var query = '';
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, updateSheet) {
          final results = destinations
              .where(
                (item) => item.$1.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              4,
              20,
              MediaQuery.viewInsetsOf(sheetContext).bottom + 22,
            ),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 540,
                  maxHeight: MediaQuery.sizeOf(sheetContext).height * .72,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Find a KAISA feature', style: _display(26)),
                    const SizedBox(height: 6),
                    const Text(
                      'Search resident pages and tools.',
                      style: TextStyle(color: _muted, fontSize: 13),
                    ),
                    const SizedBox(height: 17),
                    TextField(
                      autofocus: false,
                      onChanged: (value) => updateSheet(() => query = value),
                      decoration: InputDecoration(
                        hintText: 'Search features...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: _paper,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: _line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: _line),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: results.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 30),
                              child: Center(
                                child: Text('No matching KAISA feature.'),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: results.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1, color: _line),
                              itemBuilder: (context, index) {
                                final item = results[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(item.$2, color: _forest),
                                  title: Text(item.$1),
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                  ),
                                  onTap: () {
                                    Navigator.pop(sheetContext);
                                    _go(item.$3);
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = Scaffold(
      backgroundColor: _paper,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final compact = width < 600;
          final pagePadding = KaisaResidentDesign.pagePadding(width);

          return RefreshIndicator(
            color: _forest,
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                pagePadding,
                compact ? 23 : 36,
                pagePadding,
                compact ? 48 : 64,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1130),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Greeting(
                        name: _firstName,
                        location: _location,
                        compact: compact,
                        onProfile: () => _go('/resident/profile'),
                      ),
                      const SizedBox(height: 18),
                      _ProfileStrip(
                        loading: _loading,
                        available: _profile != null,
                        hasError: _loadError != null,
                        progress: _profileProgress,
                        onTap: () => _go('/resident/profile'),
                      ),
                      if (_loadError != null) ...[
                        const SizedBox(height: 12),
                        _ProfileError(message: _loadError!, onRetry: _refresh),
                      ],
                      const SizedBox(height: 22),
                      _SearchLaunch(onTap: _openQuickNavigation),
                      const SizedBox(height: 24),
                      _JourneyHero(
                        loading: _loading,
                        available: _profile != null,
                        hasError: _loadError != null,
                        progress: _profileProgress,
                        onProfile: () => _go('/resident/profile'),
                      ),
                      const SizedBox(height: 34),
                      _SectionHeader(
                        title: 'Pangunahing Aksyon',
                        caption: 'Connect, participate, and stay informed.',
                        actionLabel: 'All features',
                        onAction: _openQuickNavigation,
                      ),
                      const SizedBox(height: 15),
                      _ActionGrid(
                        onOrganizations: () => _go('/resident/organizations'),
                        onFeed: () => _go('/resident/feed'),
                        onEvents: () => _go('/resident/events'),
                        onMyEvents: () => _go('/resident/my-events'),
                      ),
                      const SizedBox(height: 36),
                      _SectionHeader(
                        title: 'Stay connected',
                        caption: 'A home for your KAISA activity.',
                      ),
                      const SizedBox(height: 14),
                      _LowerPanels(
                        onFeed: () => _go('/resident/feed'),
                        onOrganizations: () =>
                            _go('/resident/my-organizations'),
                        onNotifications: () => _go('/resident/notifications'),
                        onVerification: () =>
                            _go('/resident/identity-verification'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    // Reuse the existing shell. If an app_router ShellRoute already wraps this
    // page, the child does not produce a second top bar or bottom navigation.
    final insideShell =
        context.findAncestorWidgetOfExactType<KaisaResponsiveShell>() != null;
    return insideShell ? page : KaisaResponsiveShell(child: page);
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.name,
    required this.location,
    required this.compact,
    required this.onProfile,
  });

  final String name;
  final String location;
  final bool compact;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'KAISA  /  RESIDENT SPACE',
              style: TextStyle(
                color: _forest,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.7,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Magandang araw, $name! 👋',
              style: _display(compact ? 30 : 39, color: _deep),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                const Icon(Icons.place_outlined, color: _forest, size: 17),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    location,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _muted,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(width: 13),
      Material(
        color: _blueIce,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onProfile,
          borderRadius: BorderRadius.circular(12),
          child: const SizedBox(
            height: 58,
            width: 58,
            child: Icon(Icons.person_outline_rounded, color: _forest, size: 30),
          ),
        ),
      ),
    ],
  );
}

class _ProfileStrip extends StatelessWidget {
  const _ProfileStrip({
    required this.loading,
    required this.available,
    required this.hasError,
    required this.progress,
    required this.onTap,
  });
  final bool loading;
  final bool available;
  final bool hasError;
  final int progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          border: Border.all(color: _line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                color: _mint,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.badge_outlined, color: _forest, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasError
                        ? 'Profile status unavailable'
                        : loading
                        ? 'Loading your profile'
                        : available
                        ? 'Resident profile'
                        : 'Set up your resident profile',
                    style: const TextStyle(
                      color: _deep,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasError
                        ? 'Tap to review your account'
                        : loading
                        ? 'Checking your information'
                        : '$progress% of basic details completed',
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (loading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _forest,
                ),
              )
            else
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: _forest,
                size: 15,
              ),
          ],
        ),
      ),
    ),
  );
}

class _SearchLaunch extends StatelessWidget {
  const _SearchLaunch({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(11),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: _line),
          borderRadius: BorderRadius.circular(11),
          boxShadow: const [
            BoxShadow(
              color: Color(0x07000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.search_rounded, color: _muted, size: 23),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Search KAISA pages and features...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: _muted, fontSize: 13),
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.tune_rounded, color: _forest, size: 22),
          ],
        ),
      ),
    ),
  );
}

class _JourneyHero extends StatelessWidget {
  const _JourneyHero({
    required this.loading,
    required this.available,
    required this.hasError,
    required this.progress,
    required this.onProfile,
  });

  final bool loading;
  final bool available;
  final bool hasError;
  final int progress;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: _deep,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Stack(
      children: [
        Positioned(
          top: -100,
          right: -75,
          child: Container(
            height: 245,
            width: 245,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                width: 30,
                color: const Color(0xFF1A6748).withValues(alpha: .55),
              ),
            ),
          ),
        ),
        Positioned(
          right: 8,
          bottom: -48,
          child: Transform.rotate(
            angle: -.25,
            child: Container(
              width: 185,
              height: 85,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _gold.withValues(alpha: .22),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 23),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.volunteer_activism_outlined,
                    size: 20,
                    color: _gold,
                  ),
                  SizedBox(width: 9),
                  Flexible(
                    child: Text(
                      'BAYANIHAN  •  YOUR KAISA JOURNEY',
                      style: TextStyle(
                        color: _gold,
                        letterSpacing: 1.1,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 440;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your place. Your people. Your impact.',
                              style: _display(
                                narrow ? 25 : 33,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 9),
                            const Text(
                              'A stronger community starts with the connections you make.',
                              style: TextStyle(
                                color: Color(0xFFCDE4D7),
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: narrow ? 76 : 104,
                        padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF24573E),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .12),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              hasError
                                  ? '—'
                                  : loading
                                  ? '…'
                                  : '$progress%',
                              style: _display(
                                narrow ? 24 : 30,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'PROFILE',
                              style: TextStyle(
                                color: Color(0xFFE9C76F),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .7,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: hasError || loading ? null : progress / 100,
                  minHeight: 7,
                  color: _gold,
                  backgroundColor: const Color(0xFF426C57),
                ),
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      hasError
                          ? 'Your profile details could not be loaded.'
                          : loading
                          ? 'Checking your profile information…'
                          : !available
                          ? 'Add your details to get started.'
                          : progress == 100
                          ? 'Your basic details are complete.'
                          : 'Complete your details to personalize KAISA.',
                      style: const TextStyle(
                        color: Color(0xFFCDE4D7),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onProfile,
                    style: TextButton.styleFrom(
                      foregroundColor: _gold,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                    ),
                    iconAlignment: IconAlignment.end,
                    label: Text(progress == 100 ? 'My profile' : 'Review'),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.caption,
    this.actionLabel,
    this.onAction,
  });
  final String title;
  final String caption;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: _display(25)),
            const SizedBox(height: 5),
            Text(caption, style: const TextStyle(color: _muted, fontSize: 12)),
          ],
        ),
      ),
      if (actionLabel != null && onAction != null) ...[
        const SizedBox(width: 8),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(foregroundColor: _forest),
          child: Text(actionLabel!),
        ),
      ],
    ],
  );
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({
    required this.onOrganizations,
    required this.onFeed,
    required this.onEvents,
    required this.onMyEvents,
  });
  final VoidCallback onOrganizations;
  final VoidCallback onFeed;
  final VoidCallback onEvents;
  final VoidCallback onMyEvents;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final columns = width >= 900
          ? 4
          : width >= 344
          ? 2
          : 1;
      const gap = 12.0;
      final cellWidth = (width - gap * (columns - 1)) / columns;
      final entries = [
        (
          icon: Icons.groups_2_outlined,
          label: 'Organizations',
          caption: 'Find community groups',
          category: 'CONNECT',
          accent: _blueIce,
          onTap: onOrganizations,
        ),
        (
          icon: Icons.campaign_outlined,
          label: 'Community Feed',
          caption: 'Read community updates',
          category: 'STAY INFORMED',
          accent: _goldWash,
          onTap: onFeed,
        ),
        (
          icon: Icons.event_available_outlined,
          label: 'Events',
          caption: 'Discover local activities',
          category: 'PARTICIPATE',
          accent: _mint,
          onTap: onEvents,
        ),
        (
          icon: Icons.confirmation_number_outlined,
          label: 'My Events',
          caption: 'Review your registrations',
          category: 'YOUR ACTIVITY',
          accent: const Color(0xFFE7E9F3),
          onTap: onMyEvents,
        ),
      ];
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final item in entries)
            SizedBox(
              width: cellWidth,
              child: _ActionCard(
                icon: item.icon,
                title: item.label,
                caption: item.caption,
                category: item.category,
                accent: item.accent,
                onTap: item.onTap,
              ),
            ),
        ],
      );
    },
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.caption,
    required this.category,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String caption;
  final String category;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(11),
      side: const BorderSide(color: _line),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Container(
        height: 203,
        padding: const EdgeInsets.fromLTRB(17, 17, 15, 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 26, color: _forest),
                ),
                const Icon(Icons.north_east_rounded, color: _muted, size: 17),
              ],
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _display(19),
            ),
            const SizedBox(height: 5),
            Text(
              caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: _muted, height: 1.3),
            ),
            const SizedBox(height: 11),
            Text(
              category,
              style: const TextStyle(
                fontSize: 9,
                color: _forest,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _LowerPanels extends StatelessWidget {
  const _LowerPanels({
    required this.onFeed,
    required this.onOrganizations,
    required this.onNotifications,
    required this.onVerification,
  });

  final VoidCallback onFeed;
  final VoidCallback onOrganizations;
  final VoidCallback onNotifications;
  final VoidCallback onVerification;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final notice = _Noticeboard(onTap: onFeed);
      final account = _AccountMenu(
        onOrganizations: onOrganizations,
        onNotifications: onNotifications,
        onVerification: onVerification,
      );
      if (constraints.maxWidth < 760) {
        return Column(children: [notice, const SizedBox(height: 14), account]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 6, child: notice),
          const SizedBox(width: 16),
          Expanded(flex: 4, child: account),
        ],
      );
    },
  );
}

class _Noticeboard extends StatelessWidget {
  const _Noticeboard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(11),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: const Border(
            left: BorderSide(color: _gold, width: 5),
            top: BorderSide(color: _line),
            right: BorderSide(color: _line),
            bottom: BorderSide(color: _line),
          ),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(19, 19, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F1E7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'COMMUNITY NOTICEBOARD',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF80600C),
                    fontWeight: FontWeight.w800,
                    letterSpacing: .8,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Keep up with your community.', style: _display(22)),
              const SizedBox(height: 7),
              const Text(
                'Find announcements and posts from organizations in your community feed.',
                style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 12),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Open community feed',
                    style: TextStyle(
                      color: _forest,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, color: _forest, size: 17),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _AccountMenu extends StatelessWidget {
  const _AccountMenu({
    required this.onOrganizations,
    required this.onNotifications,
    required this.onVerification,
  });
  final VoidCallback onOrganizations;
  final VoidCallback onNotifications;
  final VoidCallback onVerification;

  @override
  Widget build(BuildContext context) {
    final links = [
      (Icons.groups_outlined, 'My Organizations', onOrganizations),
      (Icons.notifications_none_rounded, 'Notifications', onNotifications),
      (Icons.verified_user_outlined, 'Identity Verification', onVerification),
    ];
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
        side: const BorderSide(color: _line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              'YOUR KAISA ACCOUNT',
              style: TextStyle(
                color: _forest,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ),
          const Divider(height: 1, color: _line),
          for (final link in links) ...[
            InkWell(
              onTap: link.$3,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    Icon(link.$1, color: _forest, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        link.$2,
                        style: const TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: _muted,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            if (link != links.last) const Divider(height: 1, color: _line),
          ],
        ],
      ),
    );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF5DF),
      border: Border.all(color: const Color(0xFFECCB8E)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline_rounded, color: _deep, size: 22),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: const TextStyle(fontSize: 12))),
        TextButton(
          onPressed: onRetry,
          style: TextButton.styleFrom(foregroundColor: _forest),
          child: const Text('Retry'),
        ),
      ],
    ),
  );
}
