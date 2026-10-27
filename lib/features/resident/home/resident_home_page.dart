import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/resident_bottom_nav.dart';

const _forest = Color(0xFF14532D);
const _green = Color(0xFF237A50);
const _paper = Color(0xFFF8FAF8);
const _ink = Color(0xFF173D2B);
const _subtle = Color(0xFF687B70);
const _gold = Color(0xFFFBC02D);

class ResidentHomePage extends StatefulWidget {
  const ResidentHomePage({super.key});

  @override
  State<ResidentHomePage> createState() => _ResidentHomePageState();
}

class _ResidentHomePageState extends State<ResidentHomePage> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _loadError;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  String get _firstName {
    final meta = Supabase.instance.client.auth.currentUser?.userMetadata ?? {};
    final raw =
        (_profile?['first_name'] ??
                meta['first_name'] ??
                meta['firstName'] ??
                meta['full_name'] ??
                '')
            .toString()
            .trim();
    return raw.isEmpty ? 'Resident' : raw.split(RegExp(r'\s+')).first;
  }

  String get _location {
    final city = (_profile?['city_municipality'] ?? '').toString().trim();
    final province = (_profile?['province'] ?? '').toString().trim();
    if (city.isEmpty && province.isEmpty) return 'Add your community location';
    return [city, province].where((part) => part.isNotEmpty).join(', ');
  }

  int get _profileProgress {
    final p = _profile;
    if (p == null) return 0;
    const requiredFields = [
      'first_name',
      'last_name',
      'birth_date',
      'mobile_number',
      'province',
      'city_municipality',
      'barangay',
      'street_address',
    ];
    final present = requiredFields.where((key) {
      final value = p[key];
      return value != null && value.toString().trim().isNotEmpty;
    }).length;
    return (present * 100 / requiredFields.length).round();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted)
        setState(() {
          _loading = false;
          _loadError = 'Please sign in again.';
        });
      return;
    }
    try {
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

  void _search() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Explore KAISA',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _ink,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Choose what you would like to discover.',
              style: TextStyle(color: _subtle),
            ),
            const SizedBox(height: 14),
            for (final item in const [
              (
                'Organizations',
                Icons.groups_2_outlined,
                '/resident/organizations',
              ),
              (
                'Community events',
                Icons.event_available_outlined,
                '/resident/events',
              ),
              ('Community feed', Icons.forum_outlined, '/resident/feed'),
              (
                'My events',
                Icons.bookmark_added_outlined,
                '/resident/my-events',
              ),
            ])
              ListTile(
                leading: Icon(item.$2, color: _green),
                title: Text(item.$1),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 15),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go(item.$3);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out of KAISA?'),
        content: const Text('You can sign in again using your account.'),
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
    if (confirmed != true || !context.mounted) return;
    try {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) context.go('/welcome');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to sign out. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 800;
        final compact = constraints.maxWidth < 540;
        final pad = compact ? 18.0 : 32.0;
        return Scaffold(
          backgroundColor: _paper,
          appBar: AppBar(
            backgroundColor: _paper,
            surfaceTintColor: Colors.transparent,
            titleSpacing: pad,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _forest,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.diversity_3_rounded,
                    color: _gold,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'KAISA',
                  style: TextStyle(
                    color: _forest,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Explore',
                onPressed: _search,
                icon: const Icon(Icons.search_rounded, color: _ink),
              ),
              IconButton(
                tooltip: 'Refresh dashboard',
                onPressed: _refreshing ? null : _refresh,
                icon: const Icon(Icons.refresh_rounded, color: _ink),
              ),
              IconButton(
                tooltip: 'Notifications',
                onPressed: () => context.go('/resident/notifications'),
                icon: const Icon(Icons.notifications_none_rounded, color: _ink),
              ),
              PopupMenuButton<String>(
                tooltip: 'Account',
                icon: const CircleAvatar(
                  radius: 17,
                  backgroundColor: Color(0xFFE5F2E9),
                  child: Icon(Icons.person_rounded, color: _forest, size: 19),
                ),
                onSelected: (value) => value == 'logout'
                    ? _logout(context)
                    : context.go('/resident/profile'),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'profile', child: Text('My profile')),
                  PopupMenuItem(value: 'logout', child: Text('Sign out')),
                ],
              ),
              SizedBox(width: compact ? 9 : 24),
            ],
          ),
          body: SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      pad,
                      compact ? 12 : 28,
                      pad,
                      56,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR COMMUNITY SPACE',
                          style: TextStyle(
                            color: _green,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          'Hello, $_firstName 👋',
                          style: TextStyle(
                            color: _ink,
                            fontSize: compact ? 29 : 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          'Discover opportunities, connect with organizations, and make an impact.',
                          style: TextStyle(
                            color: _subtle,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              size: 16,
                              color: _green,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _location,
                                style: const TextStyle(
                                  color: _subtle,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_loadError != null) ...[
                          const SizedBox(height: 12),
                          _Notice(message: _loadError!, onRetry: _refresh),
                        ],
                        const SizedBox(height: 25),
                        _HeroBanner(
                          compact: compact,
                          onVerify: () =>
                              context.go('/resident/identity-verification'),
                        ),
                        const SizedBox(height: 21),
                        if (_loading)
                          const LinearProgressIndicator(color: _green)
                        else
                          _ProgressCard(
                            percent: _profileProgress,
                            hasProfile: _profile != null,
                            onOpen: () => context.go('/resident/profile'),
                          ),
                        const SizedBox(height: 29),
                        _Header(
                          title: 'Your shortcuts',
                          caption: 'Pick up right where you left off.',
                        ),
                        const SizedBox(height: 13),
                        _Shortcuts(onOpen: (path) => context.go(path)),
                        const SizedBox(height: 28),
                        _Header(
                          title: 'Explore KAISA',
                          caption: 'Everything you need, in one place.',
                        ),
                        const SizedBox(height: 15),
                        LayoutBuilder(
                          builder: (context, box) {
                            final count = box.maxWidth >= 830
                                ? 4
                                : box.maxWidth >= 480
                                ? 2
                                : 2;
                            final spacing = 12.0;
                            final width =
                                (box.maxWidth - spacing * (count - 1)) / count;
                            return Wrap(
                              spacing: spacing,
                              runSpacing: spacing,
                              children: [
                                _ActionTile(
                                  width: width,
                                  icon: Icons.groups_2_outlined,
                                  title: 'Organizations',
                                  detail: 'Find your community',
                                  color: _green,
                                  onTap: () =>
                                      context.go('/resident/organizations'),
                                ),
                                _ActionTile(
                                  width: width,
                                  icon: Icons.event_available_outlined,
                                  title: 'Events',
                                  detail: 'Join local activities',
                                  color: const Color(0xFFB78510),
                                  onTap: () => context.go('/resident/events'),
                                ),
                                _ActionTile(
                                  width: width,
                                  icon: Icons.forum_outlined,
                                  title: 'Community Feed',
                                  detail: 'See the latest posts',
                                  color: const Color(0xFF2B6A89),
                                  onTap: () => context.go('/resident/feed'),
                                ),
                                _ActionTile(
                                  width: width,
                                  icon: Icons.verified_user_outlined,
                                  title: 'Verification',
                                  detail: 'Manage your status',
                                  color: _forest,
                                  onTap: () => context.go(
                                    '/resident/identity-verification',
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 31),
                        if (wide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _DiscoverPanel(
                                  onOpen: () =>
                                      context.go('/resident/organizations'),
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: _UpdatesPanel(
                                  onEvents: () =>
                                      context.go('/resident/events'),
                                  onFeed: () => context.go('/resident/feed'),
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _DiscoverPanel(
                            onOpen: () => context.go('/resident/organizations'),
                          ),
                          const SizedBox(height: 18),
                          _UpdatesPanel(
                            onEvents: () => context.go('/resident/events'),
                            onFeed: () => context.go('/resident/feed'),
                          ),
                        ],
                        const SizedBox(height: 22),
                        const Text(
                          'Organization and event suggestions link to existing KAISA pages. They are prototype examples until connected to published Supabase records.',
                          style: TextStyle(fontSize: 11, color: _subtle),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: constraints.maxWidth < 600
              ? const ResidentBottomNav(currentIndex: 0)
              : null,
        );
      },
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.compact, required this.onVerify});
  final bool compact;
  final VoidCallback onVerify;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(compact ? 23 : 34),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [_forest, Color(0xFF267A50)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(25),
      boxShadow: [
        BoxShadow(
          color: _forest.withValues(alpha: .12),
          blurRadius: 22,
          offset: const Offset(0, 9),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          right: -24,
          top: -27,
          child: Icon(
            Icons.diversity_3_rounded,
            size: compact ? 145 : 205,
            color: Colors.white.withValues(alpha: .08),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                '✦  YOUR KAISA JOURNEY',
                style: TextStyle(
                  color: _gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7,
                ),
              ),
            ),
            const SizedBox(height: 19),
            Text(
              'Stronger communities\nstart with you.',
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 25 : 34,
                fontWeight: FontWeight.w900,
                height: 1.16,
              ),
            ),
            const SizedBox(height: 13),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 530),
              child: const Text(
                'Complete identity verification to access more ways to participate in your community.',
                style: TextStyle(
                  color: Color(0xFFE0F0E6),
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
            ),
            const SizedBox(height: 23),
            FilledButton.icon(
              onPressed: onVerify,
              icon: const Icon(Icons.shield_outlined, size: 19),
              label: const Text('Get verified'),
              style: FilledButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: _forest,
                minimumSize: const Size(0, 46),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.caption});
  final String title, caption;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 21,
          color: _ink,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 5),
      Text(caption, style: const TextStyle(color: _subtle, fontSize: 13)),
    ],
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.width,
    required this.icon,
    required this.title,
    required this.detail,
    required this.color,
    required this.onTap,
  });
  final double width;
  final IconData icon;
  final String title, detail;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE4ECE5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 47,
                height: 47,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _subtle, fontSize: 11),
              ),
              const SizedBox(height: 10),
              Icon(Icons.arrow_forward_rounded, color: color, size: 18),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DiscoverPanel extends StatelessWidget {
  const _DiscoverPanel({required this.onOpen});
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => _Panel(
    title: 'Explore organizations · Preview',
    action: 'View all',
    onTap: onOpen,
    children: [
      _PreviewRow(
        icon: Icons.volunteer_activism_outlined,
        title: 'KAISA Youth Volunteers · Sample',
        caption: 'Youth • Volunteerism',
        color: _green,
        onTap: onOpen,
      ),
      Divider(height: 24, color: Color(0xFFF0F3F0)),
      _PreviewRow(
        icon: Icons.eco_outlined,
        title: 'Community Environment Network · Sample',
        caption: 'Environment • Sustainability',
        color: const Color(0xFFB78510),
        onTap: onOpen,
      ),
    ],
  );
}

class _UpdatesPanel extends StatelessWidget {
  const _UpdatesPanel({required this.onEvents, required this.onFeed});
  final VoidCallback onEvents, onFeed;
  @override
  Widget build(BuildContext context) => _Panel(
    title: 'Explore more · Preview',
    action: 'View events',
    onTap: onEvents,
    children: [
      _PreviewRow(
        icon: Icons.calendar_month_outlined,
        title: 'Upcoming community events',
        caption: 'Find opportunities to participate',
        color: _green,
        onTap: onEvents,
      ),
      const Divider(height: 24, color: Color(0xFFF0F3F0)),
      _PreviewRow(
        icon: Icons.campaign_outlined,
        title: 'Community announcements',
        caption: 'Catch up with the latest updates',
        color: const Color(0xFF2B6A89),
        onTap: onFeed,
      ),
    ],
  );
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.action,
    required this.onTap,
    required this.children,
  });
  final String title, action;
  final VoidCallback onTap;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(21),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE4ECE5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
            TextButton(
              onPressed: onTap,
              child: Text(
                action,
                style: const TextStyle(
                  color: _green,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        ...children,
      ],
    ),
  );
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.icon,
    required this.title,
    required this.caption,
    required this.color,
    this.onTap,
  });
  final IconData icon;
  final String title, caption;
  final Color color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _subtle, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 18, color: _subtle),
        ],
      ),
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7E0),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline_rounded, color: Color(0xFF9D6B0C)),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(fontSize: 12, color: _ink),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.percent,
    required this.hasProfile,
    required this.onOpen,
  });
  final int percent;
  final bool hasProfile;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE2EBE4)),
    ),
    child: LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 450;
        final heading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              percent == 100
                  ? 'Your basic profile is complete'
                  : 'Complete your resident profile',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: _ink,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              !hasProfile
                  ? 'Set up your profile to personalize your KAISA experience.'
                  : percent == 100
                  ? 'Your profile details are ready. Keep them up to date.'
                  : 'Add your missing details to help organizations know you better.',
              style: const TextStyle(color: _subtle, fontSize: 12, height: 1.4),
            ),
          ],
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (narrow)
              heading
            else
              Row(
                children: [
                  Expanded(child: heading),
                  Text(
                    '$percent%',
                    style: const TextStyle(
                      color: _green,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 15),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percent / 100,
                minHeight: 9,
                backgroundColor: const Color(0xFFE8F1EA),
                color: _green,
              ),
            ),
            if (narrow) ...[
              const SizedBox(height: 8),
              Text(
                '$percent% complete',
                style: const TextStyle(
                  color: _green,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 9),
            TextButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.arrow_forward_rounded, size: 17),
              label: const Text('View my profile'),
              style: TextButton.styleFrom(foregroundColor: _green),
            ),
          ],
        );
      },
    ),
  );
}

class _Shortcuts extends StatelessWidget {
  const _Shortcuts({required this.onOpen});
  final ValueChanged<String> onOpen;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final cols = c.maxWidth >= 730
          ? 3
          : c.maxWidth >= 430
          ? 3
          : 2;
      final w = (c.maxWidth - (cols - 1) * 10) / cols;
      const items = [
        (Icons.event_note_outlined, 'My events', '/resident/my-events'),
        (
          Icons.groups_outlined,
          'My organizations',
          '/resident/my-organizations',
        ),
        (Icons.person_outline_rounded, 'My profile', '/resident/profile'),
        (
          Icons.notifications_none_rounded,
          'Notifications',
          '/resident/notifications',
        ),
        (
          Icons.verified_user_outlined,
          'Verification',
          '/resident/identity-verification',
        ),
        (Icons.info_outline_rounded, 'About KAISA', '/resident/about'),
      ];
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final item in items)
            SizedBox(
              width: w,
              child: OutlinedButton(
                onPressed: () => onOpen(item.$3),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _forest,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE1E9E2)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(item.$1, size: 23),
                    const SizedBox(height: 8),
                    Text(
                      item.$2,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}
