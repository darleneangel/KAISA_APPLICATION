import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/kaisa_account_refresh.dart';
import '../widgets/kaisa_resident_design.dart';
import '../widgets/kaisa_responsive_shell.dart';
import '../widgets/kaisa_notification_card.dart';
import '../notifications/kaisa_notification_repository.dart';

/// KAISA Resident Home — minimalist Civic Dignity design.
///
/// Keeps the existing KAISA shell, routing, font setup, account refresh,
/// profile progress, and feature finder. New dashboard sections read the real
/// KAISA Supabase tables with the signed-in user's RLS-protected session.
/// Nothing on this page simulates verification, participation or notifications.
const _forest = Color(0xFF00492C);
const _deep = Color(0xFF00301B);
const _gold = Color(0xFFFBBA16);
const _ink = Color(0xFF1F2937);
const _muted = Color(0xFF6B7280);
const _paper = Color(0xFFF8F9FA);
const _line = Color(0xFFE5E7EB);
const _mint = Color(0xFFE7F2EC);
const _goldWash = Color(0xFFFFF8E5);

// Civic Dignity typography: Outfit for headings, Plus Jakarta Sans for
// resident-facing UI, and Inter for analytical numbers and chart labels.
// Only font-family strings cross the Google Fonts boundary. All theme and
// style objects are native Flutter objects (avoids the TextTheme conflict).
String? _outfitFamily(FontWeight weight) =>
    GoogleFonts.outfit(fontWeight: weight).fontFamily;
String? _jakartaFamily(FontWeight weight) =>
    GoogleFonts.plusJakartaSans(fontWeight: weight).fontFamily;
String? _interFamily(FontWeight weight) =>
    GoogleFonts.inter(fontWeight: weight).fontFamily;

TextStyle _display(
  double size, {
  Color color = _ink,
  FontWeight weight = FontWeight.w600,
  double height = 1.2,
}) => TextStyle(
  fontFamily: _outfitFamily(weight),
  fontSize: size,
  fontWeight: weight,
  letterSpacing: -.25,
  height: height,
  color: color,
);

TextStyle _metric(double size, {Color color = _deep}) => TextStyle(
  fontFamily: _interFamily(FontWeight.w700),
  fontSize: size,
  fontWeight: FontWeight.w700,
  height: 1.2,
  color: color,
  fontFeatures: const [FontFeature.tabularFigures()],
);

TextStyle _dataStyle(
  double size, {
  Color color = _muted,
  FontWeight weight = FontWeight.w400,
}) => TextStyle(
  fontFamily: _interFamily(weight),
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: 1.4,
  fontFeatures: const [FontFeature.tabularFigures()],
);

String _field(Map<String, dynamic>? data, String key, [String fallback = '']) {
  final value = data?[key];
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

DateTime? _date(Object? raw) =>
    raw == null ? null : DateTime.tryParse(raw.toString())?.toLocal();

String _friendlyDate(Object? raw, {bool withTime = true}) {
  final date = _date(raw);
  if (date == null) return 'Date to be announced';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final day = '${months[date.month - 1]} ${date.day}, ${date.year}';
  if (!withTime) return day;
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minutes = date.minute.toString().padLeft(2, '0');
  final meridiem = date.hour < 12 ? 'AM' : 'PM';
  return '$day  •  $hour:$minutes $meridiem';
}

String _relativeDate(Object? raw) {
  final value = _date(raw);
  if (value == null) return 'Recently';
  final diff = DateTime.now().difference(value);
  if (diff.isNegative || diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return _friendlyDate(raw, withTime: false);
}

class ResidentHomePage extends StatefulWidget {
  const ResidentHomePage({super.key});

  @override
  State<ResidentHomePage> createState() => _ResidentHomePageState();
}

class _ResidentHomePageState extends State<ResidentHomePage> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _entitlement;
  Map<String, dynamic>? _identityRequest;
  List<Map<String, dynamic>> _events = const [];
  List<Map<String, dynamic>> _posts = const [];
  List<Map<String, dynamic>> _notifications = const [];

  List<int> _monthlyRegistrations = List.filled(6, 0);
  List<int> _monthlyAttendance = List.filled(6, 0);
  List<int> _monthlyPosts = List.filled(6, 0);
  List<String> _months = const [];
  Map<String, int> _eventCategories = const {};
  Map<String, int> _registrationStatuses = const {};
  int _readNotifications = 0;
  int _registeredEvents = 0;
  int _attendedEvents = 0;
  int _unreadNotifications = 0;
  int _membershipCount = 0;
  int _certificateCount = 0;

  bool _loading = true;
  bool _refreshing = false;
  bool _signedOut = false;
  Set<String> _errors = const {};
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    kaisaAccountRefresh.addListener(_onAccountChanged);
    _loadDashboard();
  }

  @override
  void dispose() {
    _requestId++;
    kaisaAccountRefresh.removeListener(_onAccountChanged);
    super.dispose();
  }

  void _onAccountChanged() => _loadDashboard();

  String get _firstName {
    final metadata =
        Supabase.instance.client.auth.currentUser?.userMetadata ?? {};
    final raw =
        (_profile?['first_name'] ??
                metadata['first_name'] ??
                metadata['firstName'] ??
                _profile?['full_name'] ??
                metadata['full_name'] ??
                '')
            .toString()
            .trim();
    return raw.isEmpty ? 'Resident' : raw.split(RegExp(r'\s+')).first;
  }

  String get _location {
    final fields = [
      _field(_profile, 'barangay'),
      _field(_profile, 'city_municipality'),
      _field(_profile, 'province'),
    ].where((entry) => entry.isNotEmpty);
    return fields.isEmpty ? 'Set your community location' : fields.join(', ');
  }

  int get _profileProgress {
    final profile = _profile;
    if (profile == null) return 0;
    const keys = [
      'first_name',
      'last_name',
      'birth_date',
      'mobile_number',
      'province',
      'city_municipality',
      'barangay',
      'street_address',
    ];
    final filled = keys.where((key) => _field(profile, key).isNotEmpty).length;
    return (filled * 100 / keys.length).round();
  }

  int? get _residentTier {
    final value = _entitlement?['tier'];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  String get _verificationLabel {
    if (_errors.contains('entitlement')) return 'Status unavailable';
    if (_loading) return 'Checking account…';
    if ((_residentTier ?? 0) >= 2) return 'Tier 2 • Verified';
    final status = _field(_identityRequest, 'status').toLowerCase();
    if (status == 'pending' || status == 'submitted' || status == 'in_review') {
      return 'Verification in review';
    }
    if (status == 'rejected') return 'Verification needs attention';
    if (_residentTier == 1) return 'Tier 1 • Basic account';
    return 'Verification status unavailable';
  }

  Future<void> _attempt(
    String label,
    Set<String> errors,
    Future<void> Function() fetch,
  ) async {
    try {
      await fetch();
    } catch (error) {
      errors.add(label);
      debugPrint('KAISA home [$label] failed: $error');
    }
  }

  /// Loads only verified KAISA tables and columns. Individual section errors
  /// are isolated, so an unavailable feed never blocks profile or events.
  Future<void> _loadDashboard() async {
    final requestId = ++_requestId;
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _signedOut = true;
        _loading = false;
        _refreshing = false;
        _profile = null;
        _entitlement = null;
        _events = const [];
        _posts = const [];
        _notifications = const [];
        _errors = const {};
      });
      return;
    }

    if (mounted) {
      setState(() {
        _signedOut = false;
        _loading = true;
      });
    }

    final errors = <String>{};
    Map<String, dynamic>? profile;
    Map<String, dynamic>? entitlement;
    Map<String, dynamic>? identityRequest;
    List<Map<String, dynamic>> events = [];
    List<Map<String, dynamic>> posts = [];
    List<Map<String, dynamic>> notifications = [];
    int registrations = 0;
    int attendance = 0;
    int unread = 0;
    int memberships = 0;
    int certificates = 0;
    final uid = user.id;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 5);
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final months = List.generate(
      6,
      (i) => monthNames[DateTime(start.year, start.month + i).month - 1],
    );
    final monthlyRegistrations = List<int>.filled(6, 0);
    final monthlyAttendance = List<int>.filled(6, 0);
    final monthlyPosts = List<int>.filled(6, 0);
    final eventCategories = <String, int>{};
    final registrationStatuses = <String, int>{};
    var readNotifications = 0;
    // Count each month on the server so API row limits cannot truncate trends.
    Future<void> monthly(
      String table,
      String dateColumn,
      String ownerColumn,
      String owner,
      List<int> values,
    ) async {
      await Future.wait<void>(
        List.generate(6, (i) async {
          final a = DateTime(start.year, start.month + i);
          final b = DateTime(start.year, start.month + i + 1);
          final result = await client
              .from(table)
              .select('id')
              .eq(ownerColumn, owner)
              .gte(dateColumn, a.toUtc().toIso8601String())
              .lt(dateColumn, b.toUtc().toIso8601String())
              .count(CountOption.exact);
          values[i] = result.count;
        }),
      );
    }

    await Future.wait<void>([
      _attempt(
        'registrationTrend',
        errors,
        () => monthly(
          'kaisa_event_registrations',
          'registered_at',
          'user_id',
          uid,
          monthlyRegistrations,
        ),
      ),
      _attempt(
        'attendanceTrend',
        errors,
        () => monthly(
          'kaisa_event_attendance',
          'checked_in_at',
          'user_id',
          uid,
          monthlyAttendance,
        ),
      ),
      _attempt(
        'postTrend',
        errors,
        () => monthly(
          'kaisa_feed_posts',
          'created_at',
          'visibility',
          'public',
          monthlyPosts,
        ),
      ),
      _attempt('eventCategories', errors, () async {
        final rows = await client
            .from('kaisa_events')
            .select('category')
            .eq('status', 'published')
            .gte('starts_at', now.toUtc().toIso8601String())
            .order('starts_at')
            .limit(100);
        for (final row in rows) {
          final name = _field(row, 'category', 'Uncategorized');
          eventCategories[name] = (eventCategories[name] ?? 0) + 1;
        }
      }),
      _attempt('registrationStatuses', errors, () async {
        final total = await client
            .from('kaisa_event_registrations')
            .select('id')
            .eq('user_id', uid)
            .count(CountOption.exact);
        for (final status in [
          'registered',
          'confirmed',
          'attended',
          'cancelled',
        ]) {
          final result = await client
              .from('kaisa_event_registrations')
              .select('id')
              .eq('user_id', uid)
              .eq('status', status)
              .count(CountOption.exact);
          if (result.count > 0) registrationStatuses[status] = result.count;
        }
        final other =
            total.count -
            registrationStatuses.values.fold<int>(0, (a, b) => a + b);
        if (other > 0) registrationStatuses['Other'] = other;
      }),
      _attempt('readNotifications', errors, () async {
        final result = await client
            .from('kaisa_notifications')
            .select('id')
            .eq('recipient_id', uid)
            .eq('is_read', true)
            .count(CountOption.exact);
        readNotifications = result.count;
      }),
      _attempt('profile', errors, () async {
        profile = await client
            .from('resident_profiles')
            .select(
              'first_name,last_name,middle_name,full_name,birth_date,'
              'mobile_number,province,city_municipality,barangay,street_address',
            )
            .eq('user_id', uid)
            .maybeSingle();
      }),
      _attempt('entitlement', errors, () async {
        entitlement = await client
            .from('kaisa_entitlements')
            .select('tier')
            .eq('user_id', uid)
            .maybeSingle();
      }),
      _attempt('identity', errors, () async {
        identityRequest = await client
            .from('kaisa_identity_requests')
            .select('status,submitted_at')
            .eq('user_id', uid)
            .order('submitted_at', ascending: false)
            .limit(1)
            .maybeSingle();
      }),
      _attempt('events', errors, () async {
        final result = await client
            .from('kaisa_events')
            .select('id,title,organization_name,category,location,starts_at')
            .eq('status', 'published')
            .gte('starts_at', DateTime.now().toUtc().toIso8601String())
            .order('starts_at', ascending: true)
            .limit(3);
        events = List<Map<String, dynamic>>.from(result);
      }),
      _attempt('feed', errors, () async {
        final result = await client
            .from('kaisa_feed_posts')
            .select('id,body,category,created_at')
            .eq('visibility', 'public')
            .order('created_at', ascending: false)
            .limit(2);
        posts = List<Map<String, dynamic>>.from(result);
      }),
      _attempt('notifications', errors, () async {
        final result = await client
            .from('kaisa_notifications')
            .select('id,kind,title,body,target_path,is_read,created_at')
            .eq('recipient_id', uid)
            .order('created_at', ascending: false)
            .limit(3);
        notifications = List<Map<String, dynamic>>.from(result);
        final countResult = await client
            .from('kaisa_notifications')
            .select('id')
            .eq('recipient_id', uid)
            .eq('is_read', false)
            .count(CountOption.exact);
        unread = countResult.count;
      }),
      _attempt('registrations', errors, () async {
        final result = await client
            .from('kaisa_event_registrations')
            .select('id,status')
            .eq('user_id', uid);
        registrations = result.where((entry) {
          final status = _field(entry, 'status').toLowerCase();
          return status == 'registered' || status == 'confirmed';
        }).length;
      }),
      _attempt('attendance', errors, () async {
        final result = await client
            .from('kaisa_event_attendance')
            .select('id')
            .eq('user_id', uid);
        attendance = result.length;
      }),
      _attempt('memberships', errors, () async {
        final result = await client
            .from('kaisa_organization_memberships')
            .select('id,status')
            .eq('user_id', uid);
        memberships = result.where((entry) {
          final status = _field(entry, 'status').toLowerCase();
          return status == 'approved' ||
              status == 'active' ||
              status == 'member';
        }).length;
      }),
      _attempt('certificates', errors, () async {
        final result = await client
            .from('kaisa_resident_certificates')
            .select('id')
            .eq('resident_id', uid);
        certificates = result.length;
      }),
    ]);

    if (!mounted || requestId != _requestId) return;
    setState(() {
      _monthlyRegistrations = monthlyRegistrations;
      _monthlyAttendance = monthlyAttendance;
      _monthlyPosts = monthlyPosts;
      _months = months;
      _eventCategories = eventCategories;
      _registrationStatuses = registrationStatuses;
      _readNotifications = readNotifications;
      _profile = profile;
      _entitlement = entitlement;
      _identityRequest = identityRequest;
      _events = events;
      _posts = posts;
      _notifications = notifications;
      _registeredEvents = registrations;
      _attendedEvents = attendance;
      _unreadNotifications = unread;
      _membershipCount = memberships;
      _certificateCount = certificates;
      _errors = errors;
      _loading = false;
      _refreshing = false;
    });
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    await _loadDashboard();
  }

  void _go(String path) => context.go(path);

  /// Preserved original feature finder: searches *routes*, not private data.
  void _openQuickNavigation() {
    const destinations = <(String, IconData, String)>[
      ('Feed', Icons.dynamic_feed_outlined, '/resident/feed'),
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
    final typographyTheme = KaisaTypography.homeTheme(context);
    showDialog<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => Theme(
        data: typographyTheme,
        child: StatefulBuilder(
          builder: (sheetContext, updateSheet) {
            final found = destinations
                .where(
                  (item) => item.$1.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
            return Dialog(
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 540,
                    maxHeight:
                        (MediaQuery.sizeOf(sheetContext).height -
                                MediaQuery.viewInsetsOf(sheetContext).bottom -
                                120)
                            .clamp(100.0, 520.0)
                            .toDouble(),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Smart Search',
                              style: _display(26, weight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close search',
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Search resident pages and tools.',
                        style: TextStyle(color: _muted, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        autofocus: false,
                        onChanged: (value) => updateSheet(() => query = value),
                        decoration: InputDecoration(
                          hintText: 'Search features…',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: _paper,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: const BorderSide(color: _line),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: const BorderSide(color: _line),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Flexible(
                        child: found.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(
                                  child: Text('No matching feature.'),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: found.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1, color: _line),
                                itemBuilder: (_, index) {
                                  final item = found[index];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(item.$2, color: _forest),
                                    title: Text(item.$1),
                                    trailing: const Icon(Icons.chevron_right),
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
      ),
    );
  }

  Widget _buildDashboard(double width) {
    final compact = width < 600;
    final pagePadding = KaisaResidentDesign.pagePadding(width);
    return RefreshIndicator(
      color: _forest,
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          pagePadding,
          compact ? 20 : 34,
          pagePadding,
          compact ? 46 : 64,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopGreeting(
                  name: _firstName,
                  location: _location,
                  compact: compact,
                  onProfile: () => _go('/resident/profile'),
                ),
                if (_signedOut) ...[
                  const SizedBox(height: 18),
                  _StateNotice(
                    icon: Icons.lock_outline,
                    message: 'Sign in to see your resident dashboard.',
                    actionLabel: 'Log in',
                    onAction: () => _go('/login'),
                  ),
                ] else ...[
                  const SizedBox(height: 22),
                  _SearchLauncher(onTap: _openQuickNavigation),
                  if (_errors.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _StateNotice(
                      icon: Icons.info_outline_rounded,
                      message:
                          'Some live KAISA sections could not be loaded. '
                          'Your available sections are still shown.',
                      actionLabel: 'Retry',
                      onAction: _refresh,
                    ),
                  ],
                  const SizedBox(height: 22),
                  _WelcomePanel(
                    compact: compact,
                    nextEvent: _events.isEmpty ? null : _events.first,
                    busy: _loading,
                    eventsUnavailable: _errors.contains('events'),
                    onEvents: () => _go('/resident/events'),
                  ),
                  const SizedBox(height: 18),
                  _AccountSummary(
                    compact: compact,
                    busy: _loading,
                    progress: _profileProgress,
                    profileUnavailable: _errors.contains('profile'),
                    verification: _verificationLabel,
                    tier: _residentTier,
                    onProfile: () => _go('/resident/profile'),
                    onVerification: () =>
                        _go('/resident/identity-verification'),
                  ),
                  const SizedBox(height: 32),
                  _SectionHeading(
                    title: 'What would you like to do?',
                    subtitle:
                        'Everything you need for community participation.',
                    action: 'All features',
                    onAction: _openQuickNavigation,
                  ),
                  const SizedBox(height: 13),
                  _QuickActions(
                    onOrganizations: () => _go('/resident/organizations'),
                    onFeed: () => _go('/resident/feed'),
                    onEvents: () => _go('/resident/events'),
                    onMyEvents: () => _go('/resident/my-events'),
                  ),
                  const SizedBox(height: 34),
                  _SectionHeading(
                    title: 'Upcoming in your community',
                    subtitle: 'Published events, updated from KAISA.',
                    action: 'All events',
                    onAction: () => _go('/resident/events'),
                  ),
                  const SizedBox(height: 12),
                  _UpcomingEvents(
                    events: _events,
                    loading: _loading,
                    failed: _errors.contains('events'),
                    onOpenEvents: () => _go('/resident/events'),
                  ),
                  const SizedBox(height: 34),
                  _SectionHeading(
                    title: 'Your community at a glance',
                    subtitle: 'Activity connected to your own KAISA account.',
                  ),
                  const SizedBox(height: 12),
                  _ActivitySummary(
                    registered: _registeredEvents,
                    attended: _attendedEvents,
                    memberships: _membershipCount,
                    certificates: _certificateCount,
                    loading: _loading,
                    errors: _errors,
                    onEvents: () => _go('/resident/my-events'),
                    onOrganizations: () => _go('/resident/my-organizations'),
                    onCertificates: () => _go('/resident/profile'),
                  ),
                  const SizedBox(height: 34),
                  _SectionHeading(
                    title: 'Participation analytics',
                    subtitle:
                        'Live activity across the last six calendar months.',
                  ),
                  const SizedBox(height: 12),
                  _AnalyticsGrid(
                    loading: _loading,
                    errors: _errors,
                    months: _months,
                    registrations: _monthlyRegistrations,
                    attendance: _monthlyAttendance,
                    posts: _monthlyPosts,
                    categories: _eventCategories,
                    statuses: _registrationStatuses,
                    read: _readNotifications,
                    unread: _unreadNotifications,
                  ),
                  const SizedBox(height: 34),
                  _LiveSections(
                    posts: _posts,
                    notifications: _notifications,
                    unread: _unreadNotifications,
                    loading: _loading,
                    feedFailed: _errors.contains('feed'),
                    notificationsFailed: _errors.contains('notifications'),
                    onFeed: () => _go('/resident/feed'),
                    onNotifications: () => _go('/resident/notifications'),
                  ),
                  const SizedBox(height: 28),
                  _MoreLinks(
                    onMyOrganizations: () => _go('/resident/my-organizations'),
                    onVerification: () =>
                        _go('/resident/identity-verification'),
                    onProfile: () => _go('/resident/profile'),
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
  Widget build(BuildContext context) {
    final page = Scaffold(
      backgroundColor: _paper,
      body: LayoutBuilder(
        builder: (context, constraints) =>
            _buildDashboard(constraints.maxWidth),
      ),
    );
    // Preserve the existing mobile/desktop shell and its navigation.
    final insideShell =
        context.findAncestorWidgetOfExactType<KaisaResponsiveShell>() != null;
    return Theme(
      data: KaisaTypography.homeTheme(context),
      child: insideShell ? page : KaisaResponsiveShell(child: page),
    );
  }
}

class _TopGreeting extends StatelessWidget {
  const _TopGreeting({
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
              'KAISA  /  CAVITE CITY',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.7,
                fontWeight: FontWeight.w800,
                color: _forest,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Magandang araw, $name.',
              style: _display(
                compact ? 32 : 44,
                color: _deep,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: _muted),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    location,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      _HeaderIcon(
        icon: Icons.person_outline_rounded,
        tooltip: 'My profile',
        onTap: onProfile,
      ),
    ],
  );
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(7),
      side: const BorderSide(color: _line),
    ),
    child: IconButton(
      tooltip: tooltip,
      icon: Icon(icon, color: _forest, size: 23),
      onPressed: onTap,
    ),
  );
}

class _SearchLauncher extends StatelessWidget {
  const _SearchLauncher({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(7),
      side: const BorderSide(color: _line),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Icon(Icons.search_rounded, size: 21, color: _forest),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Search KAISA pages and features',
                style: TextStyle(color: _muted, fontSize: 13),
              ),
            ),
            Icon(Icons.arrow_forward_rounded, size: 18, color: _muted),
          ],
        ),
      ),
    ),
  );
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel({
    required this.compact,
    required this.nextEvent,
    required this.busy,
    required this.eventsUnavailable,
    required this.onEvents,
  });
  final bool compact;
  final Map<String, dynamic>? nextEvent;
  final bool busy;
  final bool eventsUnavailable;
  final VoidCallback onEvents;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(compact ? 21 : 29),
    decoration: BoxDecoration(
      color: _deep,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 19, color: _gold),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'BELONG. PARTICIPATE. MAKE AN IMPACT.',
                style: TextStyle(
                  color: _gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .9,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          'Your community, within reach.',
          style: _display(
            compact ? 30 : 40,
            color: Colors.white,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 9),
        const Text(
          'Explore local events, stay informed and take part in meaningful initiatives around Cavite City.',
          style: TextStyle(
            color: Color(0xFFDAE9E0),
            height: 1.55,
            fontSize: 14,
          ),
        ),
        if (!busy && !eventsUnavailable && nextEvent != null) ...[
          const SizedBox(height: 17),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF165138),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_outlined, color: _gold, size: 19),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Next: ${_field(nextEvent, 'title', 'Community event')}  ·  '
                    '${_friendlyDate(nextEvent?['starts_at'])}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 19),
        OutlinedButton.icon(
          onPressed: onEvents,
          icon: const Icon(Icons.arrow_forward_rounded, size: 17),
          label: const Text('Explore community events'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _deep,
            backgroundColor: _gold,
            side: BorderSide.none,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 17),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            textStyle: TextStyle(
              fontFamily: _jakartaFamily(FontWeight.w700),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    ),
  );
}

class _AccountSummary extends StatelessWidget {
  const _AccountSummary({
    required this.compact,
    required this.busy,
    required this.progress,
    required this.profileUnavailable,
    required this.verification,
    required this.tier,
    required this.onProfile,
    required this.onVerification,
  });
  final bool compact;
  final bool busy;
  final int progress;
  final bool profileUnavailable;
  final String verification;
  final int? tier;
  final VoidCallback onProfile;
  final VoidCallback onVerification;

  @override
  Widget build(BuildContext context) {
    final card1 = _OutlinePanel(
      child: InkWell(
        onTap: onProfile,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _MicroLabel('YOUR RESIDENT PROFILE'),
              const SizedBox(height: 11),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      profileUnavailable
                          ? 'Unavailable'
                          : busy
                          ? 'Loading…'
                          : '$progress% complete',
                      style: _metric(26, color: _deep),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, color: _forest),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: busy || profileUnavailable ? null : progress / 100,
                  minHeight: 5,
                  backgroundColor: _line,
                  color: _forest,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Review or complete your basic information.',
                style: TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
    final card2 = _OutlinePanel(
      child: InkWell(
        onTap: onVerification,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _MicroLabel('ACCOUNT ACCESS'),
              const SizedBox(height: 11),
              Row(
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    size: 21,
                    color: _forest,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      verification,
                      style: _display(14, color: _deep),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: _muted),
                ],
              ),
              const SizedBox(height: 11),
              Text(
                tier != null && tier! >= 2
                    ? 'Your verified resident access is active.'
                    : 'Check your verification status or submit a request.',
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
    if (compact) {
      return Column(children: [card1, const SizedBox(height: 10), card2]);
    }
    return Row(
      children: [
        Expanded(child: card1),
        const SizedBox(width: 14),
        Expanded(child: card2),
      ],
    );
  }
}

class _MicroLabel extends StatelessWidget {
  const _MicroLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: _forest,
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.1,
    ),
  );
}

class _OutlinePanel extends StatelessWidget {
  const _OutlinePanel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: _line),
    ),
    child: child,
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    this.action,
    this.onAction,
  });
  final String title;
  final String subtitle;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: _display(23)),
            const SizedBox(height: 5),
            Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
          ],
        ),
      ),
      if (action != null && onAction != null) ...[
        const SizedBox(width: 4),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: _forest,
            padding: const EdgeInsets.symmetric(horizontal: 5),
          ),
          child: Text(action!, style: const TextStyle(fontSize: 12)),
        ),
      ],
    ],
  );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
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
    builder: (_, constraints) {
      final cols = constraints.maxWidth >= 860
          ? 4
          : constraints.maxWidth >= 330
          ? 2
          : 1;
      const gap = 12.0;
      final cell = (constraints.maxWidth - gap * (cols - 1)) / cols;
      final entries = [
        (
          Icons.groups_2_outlined,
          'Organizations',
          'Explore local groups',
          onOrganizations,
        ),
        (
          Icons.forum_outlined,
          'Community feed',
          'News and announcements',
          onFeed,
        ),
        (Icons.event_outlined, 'Events', 'Find local opportunities', onEvents),
        (
          Icons.event_available_outlined,
          'My events',
          'Your registrations',
          onMyEvents,
        ),
      ];
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final item in entries)
            SizedBox(
              width: cell,
              child: _OutlinePanel(
                child: InkWell(
                  onTap: item.$4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              height: 37,
                              width: 37,
                              decoration: BoxDecoration(
                                color: _mint,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(item.$1, color: _forest, size: 20),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.north_east_rounded,
                              size: 16,
                              color: _muted,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          item.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _display(14, weight: FontWeight.w700),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item.$3,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: _muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _UpcomingEvents extends StatelessWidget {
  const _UpcomingEvents({
    required this.events,
    required this.loading,
    required this.failed,
    required this.onOpenEvents,
  });
  final List<Map<String, dynamic>> events;
  final bool loading;
  final bool failed;
  final VoidCallback onOpenEvents;

  @override
  Widget build(BuildContext context) {
    if (loading) return const _LoadingPanel();
    if (failed) {
      return const _EmptyPanel(
        icon: Icons.wifi_off_outlined,
        message: 'Upcoming events could not be loaded.',
      );
    }
    if (events.isEmpty) {
      return const _EmptyPanel(
        icon: Icons.event_busy_outlined,
        message: 'No upcoming published events are available yet.',
      );
    }
    return LayoutBuilder(
      builder: (_, constraints) {
        final columns = constraints.maxWidth >= 800 ? 3 : 1;
        const gap = 12.0;
        final cell = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final event in events)
              SizedBox(
                width: cell,
                child: _OutlinePanel(
                  child: InkWell(
                    onTap: onOpenEvents,
                    child: Padding(
                      padding: const EdgeInsets.all(17),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: _mint,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _field(event, 'category', 'Community'),
                                  style: const TextStyle(
                                    color: _forest,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.arrow_outward_rounded,
                                color: _forest,
                                size: 17,
                              ),
                            ],
                          ),
                          const SizedBox(height: 13),
                          Text(
                            _field(event, 'title', 'Community event'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: _display(15, height: 1.3),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _field(
                              event,
                              'organization_name',
                              'Community organizer',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _muted, fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          _SmallMetadata(
                            Icons.calendar_today_outlined,
                            _friendlyDate(event['starts_at']),
                          ),
                          const SizedBox(height: 8),
                          _SmallMetadata(
                            Icons.place_outlined,
                            _field(
                              event,
                              'location',
                              'Location to be announced',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SmallMetadata extends StatelessWidget {
  const _SmallMetadata(this.icon, this.content);
  final IconData icon;
  final String content;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 15, color: _forest),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: _muted),
        ),
      ),
    ],
  );
}

class _ActivitySummary extends StatelessWidget {
  const _ActivitySummary({
    required this.registered,
    required this.attended,
    required this.memberships,
    required this.certificates,
    required this.loading,
    required this.errors,
    required this.onEvents,
    required this.onOrganizations,
    required this.onCertificates,
  });
  final int registered;
  final int attended;
  final int memberships;
  final int certificates;
  final bool loading;
  final Set<String> errors;
  final VoidCallback onEvents;
  final VoidCallback onOrganizations;
  final VoidCallback onCertificates;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) {
      final columns = constraints.maxWidth >= 850 ? 4 : 2;
      const gap = 11.0;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      final values = [
        (
          'Registered events',
          registered,
          'registrations',
          Icons.event_available_outlined,
          onEvents,
        ),
        (
          'Events attended',
          attended,
          'attendance',
          Icons.volunteer_activism_outlined,
          onEvents,
        ),
        (
          'Memberships',
          memberships,
          'memberships',
          Icons.groups_outlined,
          onOrganizations,
        ),
        (
          'Certificates',
          certificates,
          'certificates',
          Icons.workspace_premium_outlined,
          onCertificates,
        ),
      ];
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final item in values)
            SizedBox(
              width: width,
              child: _OutlinePanel(
                child: InkWell(
                  onTap: item.$5,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(item.$4, color: _forest, size: 20),
                        const SizedBox(height: 14),
                        Text(
                          loading
                              ? '…'
                              : errors.contains(item.$3)
                              ? '—'
                              : '${item.$2}',
                          style: _metric(30, color: _deep),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.$1,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _LiveSections extends StatelessWidget {
  const _LiveSections({
    required this.posts,
    required this.notifications,
    required this.unread,
    required this.loading,
    required this.feedFailed,
    required this.notificationsFailed,
    required this.onFeed,
    required this.onNotifications,
  });
  final List<Map<String, dynamic>> posts;
  final List<Map<String, dynamic>> notifications;
  final int unread;
  final bool loading;
  final bool feedFailed;
  final bool notificationsFailed;
  final VoidCallback onFeed;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) {
      final feed = _LiveFeedPanel(
        posts: posts,
        loading: loading,
        failed: feedFailed,
        onFeed: onFeed,
      );
      final alerts = _NotificationsPanel(
        notifications: notifications,
        unread: unread,
        loading: loading,
        failed: notificationsFailed,
        onOpen: onNotifications,
      );
      if (constraints.maxWidth < 780) {
        return Column(children: [feed, const SizedBox(height: 18), alerts]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 6, child: feed),
          const SizedBox(width: 17),
          Expanded(flex: 4, child: alerts),
        ],
      );
    },
  );
}

class _LiveFeedPanel extends StatelessWidget {
  const _LiveFeedPanel({
    required this.posts,
    required this.loading,
    required this.failed,
    required this.onFeed,
  });
  final List<Map<String, dynamic>> posts;
  final bool loading;
  final bool failed;
  final VoidCallback onFeed;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _SectionHeading(
        title: 'From the community',
        subtitle: 'Recent posts in your feed.',
        action: 'See all',
        onAction: onFeed,
      ),
      const SizedBox(height: 12),
      _OutlinePanel(
        child: loading
            ? const _LoadingPanel(bordered: false)
            : failed
            ? const _EmptyPanel(
                icon: Icons.wifi_off_outlined,
                message: 'The community feed is currently unavailable.',
              )
            : posts.isEmpty
            ? const _EmptyPanel(
                icon: Icons.forum_outlined,
                message: 'No community posts are visible right now.',
              )
            : Column(
                children: [
                  for (var i = 0; i < posts.length; i++) ...[
                    InkWell(
                      onTap: onFeed,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(17, 15, 17, 17),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.forum_outlined,
                                  color: _forest,
                                  size: 17,
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    _field(
                                      posts[i],
                                      'category',
                                      'Community post',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _forest,
                                    ),
                                  ),
                                ),
                                Text(
                                  _relativeDate(posts[i]['created_at']),
                                  style: const TextStyle(
                                    color: _muted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 9),
                            Text(
                              _field(posts[i], 'body', 'Post unavailable'),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 12,
                                height: 1.55,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (i < posts.length - 1)
                      const Divider(height: 1, color: _line),
                  ],
                ],
              ),
      ),
    ],
  );
}

class _NotificationsPanel extends StatefulWidget {
  const _NotificationsPanel({
    required this.notifications,
    required this.unread,
    required this.loading,
    required this.failed,
    required this.onOpen,
  });
  final List<Map<String, dynamic>> notifications;
  final int unread;
  final bool loading, failed;
  final VoidCallback onOpen;
  @override
  State<_NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends State<_NotificationsPanel> {
  String? _expanded;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _SectionHeading(
        title: 'Notifications',
        subtitle: widget.loading || widget.failed
            ? 'Updates for your account.'
            : widget.unread == 0
            ? 'You’re all caught up.'
            : '${widget.unread} unread updates.',
        action: 'View all',
        onAction: widget.onOpen,
      ),
      const SizedBox(height: 12),
      if (widget.loading)
        const _OutlinePanel(child: _LoadingPanel(bordered: false))
      else if (widget.failed)
        const _OutlinePanel(
          child: _EmptyPanel(
            icon: Icons.wifi_off_outlined,
            message: 'Notifications are currently unavailable.',
          ),
        )
      else if (widget.notifications.isEmpty)
        const _OutlinePanel(
          child: _EmptyPanel(
            icon: Icons.notifications_none_outlined,
            message: 'You have no notifications yet.',
          ),
        )
      else
        for (final row in widget.notifications)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: KaisaNotificationCard(
              key: ValueKey(row['id']),
              notification: KaisaNotification.fromMap(row),
              expanded: _expanded == row['id'].toString(),
              busy: false,
              onExpand: () => setState(
                () => _expanded = _expanded == row['id'].toString()
                    ? null
                    : row['id'].toString(),
              ),
              onOpen: widget.onOpen,
              openLabel: 'View notifications',
            ),
          ),
    ],
  );
}

class _MoreLinks extends StatelessWidget {
  const _MoreLinks({
    required this.onMyOrganizations,
    required this.onVerification,
    required this.onProfile,
  });
  final VoidCallback onMyOrganizations;
  final VoidCallback onVerification;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final links = [
      (Icons.groups_outlined, 'My organizations', onMyOrganizations),
      (Icons.verified_user_outlined, 'Identity verification', onVerification),
      (Icons.person_outline_rounded, 'My resident profile', onProfile),
    ];
    return _OutlinePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 17, 16, 12),
            child: _MicroLabel('MORE ACCOUNT OPTIONS'),
          ),
          for (var i = 0; i < links.length; i++) ...[
            const Divider(height: 1, color: _line),
            InkWell(
              onTap: links[i].$3,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                child: Row(
                  children: [
                    Icon(links[i].$1, color: _forest, size: 20),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        links[i].$2,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: _muted,
                      size: 19,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.icon, required this.message});
  final IconData icon;
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 27),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _forest, size: 25),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel({this.bordered = true});
  final bool bordered;
  @override
  Widget build(BuildContext context) {
    final content = const SizedBox(
      height: 88,
      child: Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: _forest),
      ),
    );
    return bordered ? _OutlinePanel(child: content) : content;
  }
}

class _StateNotice extends StatelessWidget {
  const _StateNotice({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _goldWash,
      border: const Border(left: BorderSide(color: _gold, width: 4)),
    ),
    child: Row(
      children: [
        Icon(icon, color: _deep, size: 20),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: _ink, fontSize: 12),
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(foregroundColor: _forest),
          child: Text(actionLabel),
        ),
      ],
    ),
  );
}

/// Native Flutter charts: no extra chart dependency or font override.
class _AnalyticsGrid extends StatelessWidget {
  const _AnalyticsGrid({
    required this.loading,
    required this.errors,
    required this.months,
    required this.registrations,
    required this.attendance,
    required this.posts,
    required this.categories,
    required this.statuses,
    required this.read,
    required this.unread,
  });
  final bool loading;
  final Set<String> errors;
  final List<String> months;
  final List<int> registrations, attendance, posts;
  final Map<String, int> categories, statuses;
  final int read, unread;

  Widget panel(
    String title,
    String subtitle,
    List<String> keys,
    Widget content,
  ) => _OutlinePanel(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _display(20)),
          const SizedBox(height: 5),
          Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 18),
          if (loading)
            const LinearProgressIndicator(color: _forest)
          else if (keys.any(errors.contains))
            const Text(
              'Data unavailable. Refresh to retry.',
              style: TextStyle(color: _muted),
            )
          else
            content,
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth >= 760
          ? (constraints.maxWidth - 14) / 2
          : constraints.maxWidth;
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          SizedBox(
            width: width,
            child: panel(
              'My participation',
              'Registration records and event check-ins',
              ['registrationTrend', 'attendanceTrend'],
              _MonthlyBars(
                months: months,
                first: registrations,
                second: attendance,
                firstLabel: 'Registrations',
                secondLabel: 'Check-ins',
              ),
            ),
          ),
          SizedBox(
            width: width,
            child: panel(
              'Community activity',
              'Public feed posts visible to your account',
              ['postTrend'],
              _MonthlyBars(
                months: months,
                first: posts,
                firstLabel: 'Public posts',
              ),
            ),
          ),
          SizedBox(
            width: width,
            child: panel(
              'Upcoming event categories',
              'Breakdown of the next 100 published events',
              ['eventCategories'],
              _Breakdown(values: categories),
            ),
          ),
          SizedBox(
            width: width,
            child: panel(
              'My registration status',
              'All your event registration records',
              ['registrationStatuses'],
              _Breakdown(values: statuses),
            ),
          ),
          SizedBox(
            width: width,
            child: panel(
              'Notification overview',
              'Your read and unread notifications',
              ['notifications', 'readNotifications'],
              _Breakdown(values: {'Read': read, 'Unread': unread}),
            ),
          ),
        ],
      );
    },
  );
}

class _MonthlyBars extends StatelessWidget {
  const _MonthlyBars({
    required this.months,
    required this.first,
    required this.firstLabel,
    this.second,
    this.secondLabel,
  });
  final List<String> months;
  final List<int> first;
  final List<int>? second;
  final String firstLabel;
  final String? secondLabel;
  @override
  Widget build(BuildContext context) {
    final peak = [...first, ...?second].fold<int>(1, (a, b) => a > b ? a : b);
    Widget bar(int value, Color color) => Expanded(
      child: Tooltip(
        message: '$value',
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '$value',
              style: _dataStyle(11, color: _ink, weight: FontWeight.w500),
            ),
            const SizedBox(height: 3),
            Container(
              height: 82 * value / peak + (value == 0 ? 1 : 0),
              width: double.infinity,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            _ChartKey(label: firstLabel, color: _forest),
            if (secondLabel != null)
              _ChartKey(label: secondLabel!, color: _gold),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 136,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < months.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              bar(first[i], _forest),
                              if (second != null) ...[
                                const SizedBox(width: 3),
                                bar(second![i], _gold),
                              ],
                            ],
                          ),
                        ),
                        const Divider(height: 7, color: _line),
                        Text(months[i], style: _dataStyle(11)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (first.every((v) => v == 0) &&
            (second?.every((v) => v == 0) ?? true))
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'No activity during this period.',
              style: TextStyle(color: _muted, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _ChartKey extends StatelessWidget {
  const _ChartKey({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: _dataStyle(11),
        ),
      ),
    ],
  );
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.values});
  final Map<String, int> values;
  @override
  Widget build(BuildContext context) {
    final total = values.values.fold<int>(0, (a, b) => a + b);
    if (total == 0)
      return const Text(
        'No records yet.',
        style: TextStyle(color: _muted, fontSize: 13),
      );
    final entries = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$total', style: _metric(30, color: _deep)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                for (var i = 0; i < entries.length; i++)
                  if (entries[i].value > 0)
                    Expanded(
                      flex: entries[i].value,
                      child: ColoredBox(
                        color: [
                          _forest,
                          _gold,
                          const Color(0xFF719B85),
                          const Color(0xFF8B9CB0),
                        ][i % 4],
                      ),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < entries.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: _ChartKey(
                    label: entries[i].key,
                    color: [
                      _forest,
                      _gold,
                      const Color(0xFF719B85),
                      const Color(0xFF8B9CB0),
                    ][i % 4],
                  ),
                ),
                Text(
                  '${entries[i].value}  ·  ${(entries[i].value * 100 / total).round()}%',
                  style: _dataStyle(12, color: _ink, weight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
