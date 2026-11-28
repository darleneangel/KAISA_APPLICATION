import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../events/kaisa_events_repository.dart';
import '../events/event_details_page.dart';
import '../organizations/kaisa_organizations_repository.dart';
import '../widgets/kaisa_resident_design.dart';

import 'feed_event_filters.dart';

TextStyle _feedHeadline(double size) => KaisaTypography.heading(
  TextStyle(
    fontSize: size,
    height: 1.2,
    letterSpacing: -.25,
    color: KaisaResidentDesign.forest,
  ),
);

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _CivicFeedPageState();
}

class _CivicFeedPageState extends State<FeedPage> {
  static const _batchSize = 12;
  final _search = TextEditingController();
  final _focus = FocusNode();
  final _preferences = SharedPreferencesAsync();
  final _ratings = <String, Future<({double average, bool sample})?>>{};
  List<KaisaEvent> _events = [];
  List<KaisaOrganization> _organizations = [];
  Set<String> _following = {};
  Set<String>? _saved;
  final _saving = <String>{};
  bool _savedOnly = false;
  int _savedRevision = 0;
  Map<String, String> _eventOrganizations = {};
  List<Map<String, dynamic>> _followedPosts = [];
  Map<String, DateTime> _creationDates = {};
  List<String> _recent = [];
  Timer? _debounce;
  String? _recentKey;
  String? _category;
  String? _organizer;
  String? _location;
  String _query = '';
  FeedDateFilter _dates = FeedDateFilter.any;
  DateTimeRange? _customDates;
  FeedAvailability _availability = FeedAvailability.any;
  FeedSort _sort = FeedSort.recommended;
  int _limit = _batchSize;
  bool _loading = true;
  bool _failed = false;
  bool _searching = false;
  bool _showAdvanced = false;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_focusChanged);
    KaisaOrganizationsRepository.instance.followsChanged.addListener(
      _followingChanged,
    );
    unawaited(_load());
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _recentKey = 'kaisa.feed.recentSearches.${user.id}';
      unawaited(_loadRecent());
    }
  }

  void _focusChanged() => setState(() {});
  void _followingChanged() => unawaited(_load());

  @override
  void dispose() {
    _debounce?.cancel();
    KaisaOrganizationsRepository.instance.followsChanged.removeListener(
      _followingChanged,
    );
    _focus.removeListener(_focusChanged);
    _focus.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final generation = ++_loadGeneration;
    final savedRevision = _savedRevision;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final repository = KaisaEventsRepository.instance;
      final directory = KaisaOrganizationsRepository.instance;
      final (
        events,
        organizations,
        dates,
        following,
        eventOrganizations,
        posts,
        saved,
      ) = await (
        repository.listEvents(),
        directory.getOrganizations(),
        repository.publishedEventCreationDates(),
        directory.followedOrganizations(),
        directory.eventOrganizations(),
        directory.followedAnnouncements(),
        repository.savedEvents(),
      ).wait;
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _events = events;
        _organizations = organizations;
        _creationDates = dates;
        _following = following ?? {};
        _eventOrganizations = eventOrganizations;
        _followedPosts = posts;
        if (savedRevision == _savedRevision) {
          _saved = saved;
          if (saved == null) _savedOnly = false;
        }
        _ratings.clear();
        final upcoming = _visibleCatalog;
        if (!upcoming.any((event) => event.category == _category)) {
          _category = null;
        }
        if (!upcoming.any((event) => event.organization == _organizer)) {
          _organizer = null;
        }
        if (!upcoming.any((event) => event.location == _location)) {
          _location = null;
        }
      });
    } catch (_) {
      if (mounted && generation == _loadGeneration) {
        setState(() => _failed = true);
      }
    } finally {
      if (mounted && generation == _loadGeneration) {
        setState(() => _loading = false);
      }
    }
  }

  List<KaisaEvent> get _visibleCatalog => _savedOnly
      ? _events.where((event) => _saved?.contains(event.id) == true).toList()
      : _upcoming;

  Future<void> _toggleSave(String id) async {
    final saved = _saved;
    if (saved == null || _saving.contains(id)) return;
    final next = !saved.contains(id);
    setState(() => _saving.add(id));
    try {
      await KaisaEventsRepository.instance.setEventSaved(id, next);
      if (!mounted) return;
      setState(() {
        _savedRevision++;
        final current = _saved ??= <String>{};
        if (next) {
          current.add(id);
        } else {
          current.remove(id);
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update Saved events. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving.remove(id));
    }
  }

  Future<void> _loadRecent() async {
    try {
      final values = await _preferences.getStringList(_recentKey!);
      if (mounted && _recent.isEmpty && values != null) {
        setState(() => _recent = values);
      }
    } catch (_) {
      // Search remains available when device preferences are unavailable.
    }
  }

  Future<void> _saveRecent(List<String> values) async {
    final key = _recentKey;
    if (key == null) return;
    try {
      await _preferences.setStringList(key, values);
    } catch (_) {
      // The current session can still show its recent searches.
    }
  }

  void _searchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      _applyQuery('');
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(
      const Duration(milliseconds: 275),
      () => _applyQuery(value),
    );
  }

  void _applyQuery(String value) => setState(() {
    _query = value.trim();
    _searching = false;
    _limit = _batchSize;
  });

  void _submitQuery(String value) {
    _debounce?.cancel();
    final query = value.trim();
    _search.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    _applyQuery(query);
    _focus.unfocus();
    if (query.isEmpty) return;
    final recent = [
      query,
      ..._recent.where((item) => item.toLowerCase() != query.toLowerCase()),
    ].take(5).toList();
    setState(() => _recent = recent);
    unawaited(_saveRecent(recent));
  }

  List<KaisaEvent> get _upcoming {
    final now = DateTime.now();
    return _events.where((event) => event.endsAt.isAfter(now)).toList();
  }

  bool get _hasFilters =>
      _category != null ||
      _organizer != null ||
      _location != null ||
      _dates != FeedDateFilter.any ||
      _availability != FeedAvailability.any;

  void _updateFilters(VoidCallback update) => setState(() {
    update();
    _limit = _batchSize;
  });

  void _clearFilters() => _updateFilters(() {
    _category = null;
    _organizer = null;
    _location = null;
    _dates = FeedDateFilter.any;
    _customDates = null;
    _availability = FeedAvailability.any;
  });

  List<KaisaEvent> _results(List<KaisaEvent> upcoming) => filterFeedEvents(
    upcoming,
    now: DateTime.now(),
    query: _query,
    category: _category,
    organizer: _organizer,
    location: _location,
    dates: _dates,
    customDates: switch (_customDates) {
      final range? => (range.start, range.end),
      null => null,
    },
    availability: _availability,
    sort: _sort,
    creationDates: _creationDates,
    includeEnded: _savedOnly,
  );
  List<String> _options(Iterable<String> values) =>
      values.where((value) => value.trim().isNotEmpty).toSet().toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  Future<void> _chooseDate(FeedDateFilter? filter) async {
    if (filter == null) return;
    if (filter != FeedDateFilter.custom) {
      _updateFilters(() => _dates = filter);
      return;
    }
    final now = feedManilaTime(DateTime.now());
    final date = DateTime(now.year, now.month, now.day);
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(date.year - 1),
      lastDate: DateTime(date.year + 5, 12, 31),
      currentDate: date,
      initialDateRange: _customDates,
    );
    if (range == null || !mounted) return;
    _updateFilters(() {
      _customDates = range;
      _dates = filter;
    });
  }

  Widget _menu<T>({
    required String label,
    required T value,
    required List<T> values,
    required String Function(T) title,
    required ValueChanged<T> select,
    IconData icon = Icons.expand_more,
  }) => PopupMenuButton<T>(
    tooltip: label,
    initialValue: value,
    onSelected: select,
    itemBuilder: (context) => [
      for (final item in values)
        PopupMenuItem(value: item, child: Text(title(item))),
    ],
    child: Chip(
      label: Text(label, overflow: TextOverflow.ellipsis),
      labelStyle: KaisaTypography.body(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      avatar: Icon(icon, size: 16, color: KaisaResidentDesign.forest),
    ),
  );

  Widget _searchBox(List<KaisaEvent> upcoming) {
    final typed = _search.text.trim().toLowerCase();
    final suggestions = typed.isEmpty
        ? _recent
        : _options([
                ...upcoming.map((event) => event.title),
                ..._organizations.map((organization) => organization.name),
              ])
              .where((name) => name.toLowerCase().contains(typed))
              .take(5)
              .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _search,
          focusNode: _focus,
          textInputAction: TextInputAction.search,
          onChanged: _searchChanged,
          onSubmitted: _submitQuery,
          style: KaisaTypography.body(const TextStyle(fontSize: 14)),
          decoration: InputDecoration(
            labelText: 'Search events and organizations',
            hintText: 'Try an event, organizer or location',
            labelStyle: KaisaTypography.body(const TextStyle(fontSize: 13)),
            hintStyle: KaisaTypography.body(const TextStyle(fontSize: 13)),
            prefixIcon: const Icon(
              Icons.search,
              color: KaisaResidentDesign.forest,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.close),
                    onPressed: () => _submitQuery(''),
                  ),
          ),
        ),
        if (_focus.hasFocus && suggestions.isNotEmpty)
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                ListTile(
                  dense: true,
                  title: Text(
                    typed.isEmpty ? 'Recent searches' : 'Search suggestions',
                  ),
                  trailing: typed.isNotEmpty
                      ? null
                      : TextButton(
                          onPressed: () {
                            setState(() => _recent = []);
                            unawaited(_saveRecent([]));
                          },
                          child: const Text('Clear'),
                        ),
                ),
                for (final suggestion in suggestions)
                  ListTile(
                    dense: true,
                    leading: Icon(typed.isEmpty ? Icons.history : Icons.search),
                    title: Text(suggestion),
                    onTap: () => _submitQuery(suggestion),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _filters(List<KaisaEvent> upcoming, {required bool compact}) {
    final categories = _options(upcoming.map((event) => event.category));
    final dateLabel = _dates == FeedDateFilter.custom
        ? '${_shortDate(_customDates!.start)} – ${_shortDate(_customDates!.end)}'
        : _dates.label;
    final sortMenu = _menu(
      label: _sort.label,
      icon: Icons.sort,
      value: _sort,
      values: FeedSort.values,
      title: (item) => item.label,
      select: (item) => _updateFilters(() => _sort = item),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final category in <String?>[null, ...categories])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category ?? 'All events'),
                    avatar: const Icon(Icons.tag, size: 15),
                    selected: _category == category,
                    onSelected: (_) =>
                        _updateFilters(() => _category = category),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        if (compact)
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
                icon: const Icon(Icons.tune),
                label: Text(_showAdvanced ? 'Hide filters' : 'Filters'),
              ),
              sortMenu,
            ],
          ),
        if (!compact || _showAdvanced)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _menu(
                label: dateLabel,
                icon: Icons.calendar_today_outlined,
                value: _dates,
                values: FeedDateFilter.values,
                title: (item) => item.label,
                select: _chooseDate,
              ),
              _menu(
                label: _organizer ?? 'Organizer',
                icon: Icons.groups_outlined,
                value: _organizer ?? '',
                values: [
                  '',
                  ..._options(upcoming.map((event) => event.organization)),
                ],
                title: (item) => item.isEmpty ? 'All organizers' : item,
                select: (item) => _updateFilters(
                  () => _organizer = item.isEmpty ? null : item,
                ),
              ),
              _menu(
                label: _location ?? 'Location',
                icon: Icons.place_outlined,
                value: _location ?? '',
                values: [
                  '',
                  ..._options(upcoming.map((event) => event.location)),
                ],
                title: (item) => item.isEmpty ? 'All locations' : item,
                select: (item) => _updateFilters(
                  () => _location = item.isEmpty ? null : item,
                ),
              ),
              _menu(
                icon: Icons.event_available_outlined,
                label: _availability == FeedAvailability.any
                    ? 'Registration'
                    : _availability.label,
                value: _availability,
                values: FeedAvailability.values,
                title: (item) => item.label,
                select: (item) => _updateFilters(() => _availability = item),
              ),
              if (!compact) sortMenu,
              if (_hasFilters)
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear all'),
                ),
            ],
          )
        else if (_hasFilters)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (_dates != FeedDateFilter.any) Chip(label: Text(dateLabel)),
              if (_organizer case final organizer?)
                Chip(label: Text(organizer)),
              if (_location case final location?) Chip(label: Text(location)),
              if (_availability != FeedAvailability.any)
                Chip(label: Text(_availability.label)),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear all'),
              ),
            ],
          ),
      ],
    );
  }

  String _shortDate(DateTime date) =>
      MaterialLocalizations.of(context).formatShortDate(date);

  Widget _heading(
    String title, {
    required bool compact,
    bool pageTitle = false,
  }) => Semantics(
    header: true,
    child: Text(
      title,
      style: compact
          ? _feedHeadline(20)
          : pageTitle
          ? _feedHeadline(32)
          : _feedHeadline(24),
    ),
  );

  Widget _cards(
    List<KaisaEvent> events,
    int columns, {
    bool featured = false,
  }) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = 16.0;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final event in events)
            SizedBox(
              width: width,
              height:
                  (columns == 1 ? 142 : 176) +
                  268.0 *
                      math.max(1.0, MediaQuery.textScalerOf(context).scale(1)),
              child: _EventCard(
                event: event,
                saved: _saved?.contains(event.id) == true,
                saving: _saving.contains(event.id),
                onSave: _saved == null ? null : () => _toggleSave(event.id),
                rating: _ratings.putIfAbsent(
                  event.id,
                  () => KaisaEventsRepository.instance.getRatingSummary(event),
                ),
                organizer: _organizerFor(event),
                featured: featured,
                compact: columns == 1,
                onRegistrationChanged: _load,
              ),
            ),
        ],
      );
    },
  );

  KaisaOrganization? _organizerFor(KaisaEvent event) {
    final linked = _eventOrganizations[event.id];
    return _organizations
        .where(
          (organization) => linked != null
              ? organization.id == linked
              : organization.name.trim().toLowerCase() ==
                    event.organization.trim().toLowerCase(),
        )
        .firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _visibleCatalog;
    final results = _results(upcoming);
    final showFollowing =
        !_savedOnly &&
        !_hasFilters &&
        _query.isEmpty &&
        _sort == FeedSort.recommended;
    final (followed: followedEvents, remaining: remainingEvents) = showFollowing
        ? partitionFollowedEvents(
            results,
            (event) => _following.contains(_organizerFor(event)?.id),
          )
        : (followed: <KaisaEvent>[], remaining: results);
    final matchingOrganizations = _savedOnly || _query.isEmpty
        ? <KaisaOrganization>[]
        : _organizations
              .where((organization) {
                final text =
                    '${organization.name} ${organization.description} '
                            '${organization.category} ${organization.location}'
                        .toLowerCase();
                return feedSearchMatches(text, _query);
              })
              .take(6)
              .toList();
    final featured = <KaisaEvent>[];
    if (showFollowing) {
      final categories = <String>{};
      final now = DateTime.now();
      for (final event in remainingEvents) {
        if (feedEventHasSlots(event, now) && categories.add(event.category)) {
          featured.add(event);
          if (featured.length == 3) break;
        }
      }
    }
    final entries = remainingEvents
        .where((event) => !featured.contains(event))
        .toList();
    final baseTheme = Theme.of(context);
    return Theme(
      data: baseTheme.copyWith(
        colorScheme: baseTheme.colorScheme.copyWith(
          primary: KaisaResidentDesign.forest,
          secondary: KaisaResidentDesign.yellow,
        ),
      ),
      child: Scaffold(
        backgroundColor: KaisaResidentDesign.paper,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1040
                  ? 3
                  : constraints.maxWidth >= 680
                  ? 2
                  : 1;
              final compact = columns == 1;
              final padding = compact ? 16.0 : 28.0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 1344 + 2 * padding),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(padding, 20, padding, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _heading(
                                _savedOnly ? 'Saved events' : 'Feed',
                                compact: compact,
                                pageTitle: true,
                              ),
                            ),
                            if (_saved case final bookmarks?)
                              IconButton(
                                tooltip: _savedOnly
                                    ? 'Show all events'
                                    : 'Show saved events',
                                isSelected: _savedOnly,
                                onPressed: () => _updateFilters(() {
                                  _savedOnly = !_savedOnly;
                                  _category = _organizer = _location = null;
                                }),
                                icon: Badge.count(
                                  isLabelVisible: bookmarks.isNotEmpty,
                                  count: bookmarks.length,
                                  child: Icon(
                                    _savedOnly
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                  ),
                                ),
                              ),
                            IconButton(
                              tooltip: 'Refresh events',
                              onPressed: _loading ? null : _load,
                              icon: const Icon(Icons.refresh),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(padding, 4, padding, 40),
                        children: [
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1344),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Discover civic events and opportunities in Cavite City.',
                                  ),
                                  const SizedBox(height: 20),
                                  _searchBox(upcoming),
                                  const SizedBox(height: 12),
                                  if (_loading) ...[
                                    Semantics(
                                      label: 'Loading events',
                                      child: const LinearProgressIndicator(),
                                    ),
                                    const SizedBox(height: 20),
                                    if (showFollowing &&
                                        _followedPosts.isNotEmpty) ...[
                                      _heading(
                                        'Updates from organizations you follow',
                                        compact: compact,
                                      ),
                                      const SizedBox(height: 8),
                                      for (final post in _followedPosts)
                                        Card(
                                          child: ListTile(
                                            leading: const Icon(
                                              Icons.campaign_outlined,
                                            ),
                                            title: Text(
                                              post['title'] as String,
                                            ),
                                            subtitle: Text(
                                              '${post['organization_name']} · ${post['body']}',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            trailing: const Icon(
                                              Icons.chevron_right,
                                            ),
                                            onTap: () {
                                              final organization = _organizations
                                                  .where(
                                                    (item) =>
                                                        item.id ==
                                                        post['organization_id'],
                                                  )
                                                  .firstOrNull;
                                              if (organization != null) {
                                                context.push(
                                                  '/resident/organization-details',
                                                  extra: organization
                                                      .toRouteExtra(),
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                      const SizedBox(height: 20),
                                    ],
                                    if (followedEvents.isNotEmpty) ...[
                                      _heading(
                                        'Events from organizations you follow',
                                        compact: compact,
                                      ),
                                      const SizedBox(height: 8),
                                      _cards(
                                        followedEvents.take(_limit).toList(),
                                        columns,
                                      ),
                                      if (followedEvents.length > _limit)
                                        TextButton(
                                          onPressed: () => setState(
                                            () => _limit += _batchSize,
                                          ),
                                          child: const Text(
                                            'Show more followed events',
                                          ),
                                        ),
                                      const SizedBox(height: 20),
                                    ],
                                    for (var index = 0; index < 2; index++)
                                      Container(
                                        height: 120,
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: KaisaResidentDesign.mint,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                  ] else if (_failed)
                                    Card(
                                      child: ListTile(
                                        title: const Text(
                                          'Could not load the Feed',
                                        ),
                                        subtitle: const Text(
                                          'Check your connection and try again.',
                                        ),
                                        trailing: TextButton(
                                          onPressed: _load,
                                          child: const Text('Retry'),
                                        ),
                                      ),
                                    )
                                  else ...[
                                    _filters(upcoming, compact: compact),
                                    if (_searching)
                                      Semantics(
                                        label: 'Searching',
                                        child: const LinearProgressIndicator(),
                                      ),
                                    const SizedBox(height: 20),
                                    if (featured.isNotEmpty) ...[
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0F3FF),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _heading(
                                              'Recommended for you',
                                              compact: compact,
                                            ),
                                            const Text(
                                              'Upcoming opportunities with slots remaining.',
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _cards(featured, columns, featured: true),
                                      const SizedBox(height: 24),
                                    ],
                                    if (entries.isNotEmpty ||
                                        (featured.isEmpty &&
                                            followedEvents.isEmpty)) ...[
                                      _heading(
                                        _savedOnly
                                            ? 'Your saved events'
                                            : _query.isEmpty
                                            ? 'Upcoming community events'
                                            : 'Event search results',
                                        compact: compact,
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    if (entries.isNotEmpty)
                                      _cards(
                                        entries.take(_limit).toList(),
                                        columns,
                                      )
                                    else if (featured.isEmpty &&
                                        followedEvents.isEmpty)
                                      Card(
                                        child: ListTile(
                                          leading: const Icon(
                                            Icons.event_busy_outlined,
                                          ),
                                          title: Text(
                                            _savedOnly
                                                ? 'No saved events to show'
                                                : _hasFilters ||
                                                      _query.isNotEmpty
                                                ? 'No events match your search'
                                                : 'No upcoming events',
                                          ),
                                          subtitle: Text(
                                            _savedOnly
                                                ? 'Save an event from the Feed or adjust your filters.'
                                                : _hasFilters ||
                                                      _query.isNotEmpty
                                                ? 'Try a different search or clear the filters.'
                                                : 'Check back for new civic opportunities.',
                                          ),
                                        ),
                                      ),
                                    if (entries.length > _limit)
                                      Align(
                                        child: TextButton(
                                          onPressed: () => setState(
                                            () => _limit += _batchSize,
                                          ),
                                          child: const Text('Show more events'),
                                        ),
                                      ),
                                    if (matchingOrganizations.isNotEmpty) ...[
                                      const SizedBox(height: 24),
                                      _heading(
                                        'Matching organizations',
                                        compact: compact,
                                      ),
                                      for (final organization
                                          in matchingOrganizations)
                                        Card(
                                          child: ListTile(
                                            leading: const Icon(
                                              Icons.groups_outlined,
                                            ),
                                            title: Text(organization.name),
                                            subtitle: Text(
                                              organization.category,
                                            ),
                                            trailing: const Icon(
                                              Icons.chevron_right,
                                            ),
                                            onTap: () => context.push(
                                              '/resident/organization-details',
                                              extra: organization
                                                  .toRouteExtra(),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.saved,
    required this.saving,
    required this.onSave,
    required this.rating,
    required this.organizer,
    required this.featured,
    required this.compact,
    required this.onRegistrationChanged,
  });

  final KaisaEvent event;
  final bool saved, saving;
  final VoidCallback? onSave;
  final Future<({double average, bool sample})?> rating;
  final KaisaOrganization? organizer;
  final bool featured;
  final bool compact;
  final VoidCallback onRegistrationChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final start = feedManilaTime(event.startsAt);
    final localizations = MaterialLocalizations.of(context);
    final time = localizations.formatTimeOfDay(TimeOfDay.fromDateTime(start));
    final date = localizations.formatMediumDate(start);
    final status = event.isRegistered
        ? 'Already registered'
        : event.isPast
        ? 'Completed'
        : !event.startsAt.isAfter(DateTime.now())
        ? 'In progress'
        : event.isFull
        ? 'Fully booked'
        : '${event.capacity - event.registeredCount} slots remaining';
    final colors = Theme.of(context).colorScheme;
    final badgeColor = event.isFull && !event.isRegistered
        ? colors.errorContainer
        : KaisaResidentDesign.forest;
    final badgeTextColor = event.isFull && !event.isRegistered
        ? colors.onErrorContainer
        : Colors.white;
    final photo = switch (event.id) {
      'd32111fd-8580-48bc-9ab6-c7f4afb96301' => 'stitch-feed-mangroves.jpg',
      'd32111fd-8580-48bc-9ab6-c7f4afb96302' => 'stitch-feed-health.jpg',
      'd32111fd-8580-48bc-9ab6-c7f4afb96303' => 'stitch-feed-mural.jpg',
      _ => 'unlad_pier.jpg',
    };
    final coverAsset = 'assets/images/cavite/$photo';
    final router = GoRouter.of(context);
    void openOrganizer() {
      final organization = organizer;
      if (organization != null) {
        router.push(
          '/resident/organization-details',
          extra: organization.toRouteExtra(),
        );
      } else {
        router.push(
          Uri(
            path: '/resident/organizations',
            queryParameters: {'q': event.organization},
          ).toString(),
        );
      }
    }

    void openDetails() {
      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final size = MediaQuery.sizeOf(dialogContext);
          return Dialog(
            insetPadding: EdgeInsets.all(size.width < 600 ? 12 : 28),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: 920,
              height: size.height * (size.width < 600 ? .88 : .78),
              child: ScaffoldMessenger(
                child: EventDetailsPage(
                  eventId: event.id,
                  title: event.title,
                  organization: event.organization,
                  category: event.category,
                  description: event.description,
                  date: date,
                  time: time,
                  location: event.location,
                  participants: event.registeredCount,
                  capacity: event.capacity,
                  inDialog: true,
                  openOrganizer: () {
                    Navigator.of(dialogContext).pop();
                    openOrganizer();
                  },
                  coverAsset: photo == 'stitch-feed-mangroves.jpg'
                      ? 'assets/images/cavite/stitch-event-details-mangroves.jpg'
                      : coverAsset,
                  onRegistrationChanged: onRegistrationChanged,
                ),
              ),
            ),
          );
        },
      );
    }

    final statusBadge = DecoratedBox(
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          status,
          style: textTheme.labelSmall?.copyWith(color: badgeTextColor),
        ),
      ),
    );
    final cover = SizedBox(
      height: compact ? 142 : 176,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: KaisaResidentDesign.heroGradient,
            ),
          ),
          Image.asset(
            coverAsset,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(
                Icons.event_available_outlined,
                color: Colors.white,
                size: 44,
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xD900301B)],
                stops: [0.45, 1],
              ),
            ),
          ),
          PositionedDirectional(
            top: 10,
            start: 10,
            end: onSave == null ? 10 : 56,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: statusBadge,
            ),
          ),
          if (onSave != null)
            PositionedDirectional(
              top: 6,
              end: 6,
              child: IconButton.filledTonal(
                tooltip: saved ? 'Remove from Saved events' : 'Save event',
                isSelected: saved,
                onPressed: saving ? null : onSave,
                icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
              ),
            ),
          PositionedDirectional(
            start: 12,
            end: 12,
            bottom: 34,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FutureBuilder(
                future: rating,
                builder: (context, snapshot) {
                  final score = snapshot.data;
                  if (score == null) return const SizedBox.shrink();
                  return Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(
                      Icons.star_rounded,
                      color: Color(0xFF946900),
                      size: 16,
                    ),
                    label: Text(
                      '${score.average.toStringAsFixed(1)} / 5${score.sample ? ' · Sample' : ''}',
                    ),
                  );
                },
              ),
            ),
          ),
          PositionedDirectional(
            start: 12,
            end: 12,
            bottom: 8,
            child: Text(
              '$date · $time PHT',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KaisaTypography.data(
                const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
    final details = Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                event.category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  color: KaisaResidentDesign.green,
                ),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: openOrganizer,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.groups_outlined, size: 17),
            label: Text(
              event.organization,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            event.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: compact && !featured ? _feedHeadline(18) : _feedHeadline(20),
          ),
          if (event.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              event.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F3FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _metadata(
                  context,
                  Icons.place_outlined,
                  event.location.isEmpty
                      ? 'Venue to be announced'
                      : event.location,
                ),
              ],
            ),
          ),
          const Spacer(),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton(
              onPressed: openDetails,
              child: const Text('View details'),
            ),
          ),
        ],
      ),
    );
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      child: InkWell(
        excludeFromSemantics: true,
        onTap: openDetails,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            cover,
            Expanded(child: details),
          ],
        ),
      ),
    );
  }

  Widget _metadata(BuildContext context, IconData icon, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: KaisaResidentDesign.green),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    ],
  );
}
