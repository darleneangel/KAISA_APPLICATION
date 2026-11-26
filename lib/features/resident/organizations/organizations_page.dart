import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/kaisa_resident_design.dart';
import 'kaisa_organization_widgets.dart';
import 'kaisa_organizations_repository.dart';
import 'organization_details_page.dart';
import 'organization_profile_widgets.dart';

enum _DirectorySort { name, members }

class OrganizationsPage extends StatefulWidget {
  const OrganizationsPage({super.key, this.initialSearch = ''});
  final String initialSearch;

  @override
  State<OrganizationsPage> createState() => _OrganizationsPageState();
}

class _OrganizationsPageState extends State<OrganizationsPage> {
  static const _pageSize = 6;
  final _directory = KaisaOrganizationsRepository.instance;
  late final _search = TextEditingController(text: widget.initialSearch);
  final _focus = FocusNode();
  final _ratings = <String, Future<Map<String, dynamic>?>>{};
  List<KaisaOrganization> _organizations = [];
  Map<String, Map<String, dynamic>> _profiles = {};
  Set<String>? _following;
  String? _sector, _location;
  int? _sdg;
  bool _followingOnly = false;
  _DirectorySort _sort = _DirectorySort.name;
  int _page = 0;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_focusChanged);
    _directory.followsChanged.addListener(_reloadFollows);
    _load();
  }

  void _focusChanged() => setState(() {});

  @override
  void dispose() {
    _directory.followsChanged.removeListener(_reloadFollows);
    _focus.removeListener(_focusChanged);
    _focus.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final (organizations, profiles, following) = await (
        _directory.getOrganizations(),
        _directory.profiles(),
        _directory.followedOrganizations(),
      ).wait;
      if (!mounted) return;
      setState(() {
        _organizations = organizations;
        _profiles = profiles;
        _following = following;
        _ratings.clear();
        _page = 0;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reloadFollows() async {
    try {
      final follows = await _directory.followedOrganizations();
      if (mounted)
        setState(() {
          _following = follows;
          if (_followingOnly) _page = 0;
        });
    } catch (_) {
      // A failed background read leaves the current directory visible.
    }
  }

  List<int> _goals(KaisaOrganization organization) =>
      (_profiles[organization.id]?['sdg_goals'] as List? ?? const [])
          .whereType<int>()
          .toList();

  void _filter(VoidCallback update) => setState(() {
    update();
    _page = 0;
  });

  Future<void> _openOrganization(KaisaOrganization organization) async {
    if (MediaQuery.sizeOf(context).width < 850) {
      await context.push(
        '/resident/organization-details',
        extra: organization.toRouteExtra(),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 1080,
          height: MediaQuery.sizeOf(context).height * .88,
          child: ScaffoldMessenger(
            child: OrganizationDetailsPage(
              organizationId: organization.id,
              name: organization.name,
              category: organization.category,
              description: organization.description,
              members: organization.memberCount,
              inDialog: true,
            ),
          ),
        ),
      ),
    );
  }

  Widget _heading(BuildContext context, String label) => Text(
    label,
    style: Theme.of(
      context,
    ).textTheme.headlineMedium?.copyWith(color: KaisaResidentDesign.forest),
  );

  Widget _searchAndFilters(BuildContext context, List<String> sectors) {
    final query = _search.text.trim().toLowerCase();
    final suggestions = _focus.hasFocus && query.isNotEmpty
        ? _organizations
              .where(
                (organization) =>
                    organization.name.toLowerCase().contains(query),
              )
              .take(4)
        : const <KaisaOrganization>[];
    final locations =
        _organizations
            .map((organization) => organization.location)
            .where((location) => location.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final goals = _organizations.expand(_goals).toSet().toList()..sort();
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            TextField(
              controller: _search,
              focusNode: _focus,
              onChanged: (_) => _filter(() {}),
              onSubmitted: (_) => _focus.unfocus(),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'Search organizations',
                hintText: 'Name, cause or location',
                prefixIcon: const Icon(
                  Icons.search,
                  color: KaisaResidentDesign.forest,
                ),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () => _filter(_search.clear),
                        icon: const Icon(Icons.close),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            if (suggestions.isNotEmpty)
              Column(
                children: [
                  for (final organization in suggestions)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.manage_search),
                      title: Text(organization.name),
                      onTap: () {
                        _filter(() => _search.text = organization.name);
                        _focus.unfocus();
                      },
                    ),
                ],
              ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All organizations'),
                    selected: _sector == null,
                    onSelected: (_) => _filter(() => _sector = null),
                  ),
                  for (final category in sectors)
                    ChoiceChip(
                      avatar: Icon(kaisaOrganizationIcon(category), size: 16),
                      label: Text(category),
                      selected: _sector == category,
                      onSelected: (_) => _filter(() => _sector = category),
                    ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PopupMenuButton<String>(
                  tooltip: 'Filter by location',
                  onSelected: (value) =>
                      _filter(() => _location = value.isEmpty ? null : value),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: '',
                      child: Text('All locations'),
                    ),
                    for (final location in locations)
                      PopupMenuItem(value: location, child: Text(location)),
                  ],
                  child: Chip(
                    avatar: const Icon(Icons.place_outlined, size: 16),
                    label: Text(_location ?? 'Location'),
                  ),
                ),
                PopupMenuButton<int>(
                  tooltip: 'Filter by SDG',
                  onSelected: (value) =>
                      _filter(() => _sdg = value == 0 ? null : value),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 0, child: Text('All SDGs')),
                    for (final goal in goals)
                      PopupMenuItem(value: goal, child: Text('SDG $goal')),
                  ],
                  child: Chip(
                    avatar: const Icon(Icons.track_changes, size: 16),
                    label: Text(_sdg == null ? 'SDG alignment' : 'SDG $_sdg'),
                  ),
                ),
                if (_following != null)
                  FilterChip(
                    label: const Text('Following'),
                    selected: _followingOnly,
                    onSelected: (value) =>
                        _filter(() => _followingOnly = value),
                  ),
                PopupMenuButton<_DirectorySort>(
                  tooltip: 'Sort organizations',
                  onSelected: (value) => _filter(() => _sort = value),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: _DirectorySort.name,
                      child: Text('Name A–Z'),
                    ),
                    PopupMenuItem(
                      value: _DirectorySort.members,
                      child: Text('Most members'),
                    ),
                  ],
                  child: Chip(
                    avatar: const Icon(Icons.sort, size: 16),
                    label: Text(
                      _sort == _DirectorySort.name
                          ? 'Name A–Z'
                          : 'Most members',
                    ),
                  ),
                ),
                if (query.isNotEmpty ||
                    _sector != null ||
                    _location != null ||
                    _sdg != null ||
                    _followingOnly)
                  TextButton(
                    onPressed: () => _filter(() {
                      _search.clear();
                      _sector = _location = null;
                      _sdg = null;
                      _followingOnly = false;
                    }),
                    child: const Text('Clear all'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _grid(List<KaisaOrganization> organizations) => LayoutBuilder(
    builder: (context, bounds) {
      final columns = bounds.maxWidth >= 850
          ? 3
          : bounds.maxWidth >= 590
          ? 2
          : 1;
      final width = (bounds.maxWidth - 14 * (columns - 1)) / columns;
      final textScale = MediaQuery.textScalerOf(
        context,
      ).scale(1).clamp(1.0, double.infinity);
      final height = 144 + (width < 290 ? 356 : 322) * textScale;
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          for (final organization in organizations)
            SizedBox(
              width: width,
              height: height,
              child: _card(context, organization),
            ),
        ],
      );
    },
  );

  Widget _card(BuildContext context, KaisaOrganization organization) {
    final text = Theme.of(context).textTheme;
    final image = OrganizationImage(
      reference: _profiles[organization.id]?['cover_image'] as String?,
      icon: kaisaOrganizationIcon(organization.category),
    );
    final rating = FutureBuilder<Map<String, dynamic>?>(
      future: _ratings.putIfAbsent(
        organization.id,
        () => _directory.feedback(organization.id),
      ),
      builder: (context, snapshot) {
        final score = snapshot.data?['rating'] as num?;
        if (score == null) return const SizedBox.shrink();
        return Chip(
          visualDensity: VisualDensity.compact,
          avatar: const Icon(
            Icons.star_rounded,
            size: 16,
            color: Color(0xFF946900),
          ),
          label: Text(
            '${score.toStringAsFixed(1)} (${snapshot.data?['count']})',
          ),
          backgroundColor: Colors.white,
        );
      },
    );
    return Card(
      color: Colors.white,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openOrganization(organization),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 144,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  image,
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xA000301B)],
                        stops: [.45, 1],
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    start: 10,
                    end: 10,
                    top: 8,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Chip(
                        avatar: Icon(
                          kaisaOrganizationIcon(organization.category),
                          size: 16,
                          color: KaisaResidentDesign.forest,
                        ),
                        label: Text(
                          organization.category,
                          overflow: TextOverflow.ellipsis,
                        ),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                  PositionedDirectional(end: 10, bottom: 8, child: rating),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    Text(
                      organization.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleLarge?.copyWith(
                        color: KaisaResidentDesign.forest,
                      ),
                    ),
                    if (organization.location.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 15,
                            color: KaisaResidentDesign.forest,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              organization.location,
                              style: text.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    Text(
                      organization.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall,
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 16,
                          color: KaisaResidentDesign.forest,
                        ),
                        Text(
                          '${organization.memberCount} members',
                          style: text.labelMedium,
                        ),
                        for (final goal in _goals(organization).take(3))
                          Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text('SDG $goal'),
                          ),
                      ],
                    ),
                    const Spacer(),
                    const Divider(height: 1),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FilledButton(
                          onPressed: () => _openOrganization(organization),
                          child: const Text('View profile'),
                        ),
                        if (_following case final followed?)
                          OrganizationFollowButton(
                            key: ValueKey(organization.id),
                            organizationId: organization.id,
                            following: followed.contains(organization.id),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final sectors =
        _organizations
            .map((organization) => organization.category)
            .toSet()
            .toList()
          ..sort();
    final results =
        _organizations
            .where(
              (organization) =>
                  (_sector == null || organization.category == _sector) &&
                  (_location == null || organization.location == _location) &&
                  (_sdg == null || _goals(organization).contains(_sdg)) &&
                  (!_followingOnly ||
                      _following?.contains(organization.id) == true) &&
                  '${organization.name} ${organization.description} ${organization.category} ${organization.location}'
                      .toLowerCase()
                      .contains(query),
            )
            .toList()
          ..sort((a, b) {
            final order = _sort == _DirectorySort.members
                ? b.memberCount.compareTo(a.memberCount)
                : 0;
            return order == 0
                ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
                : order;
          });
    final showFeatured =
        query.isEmpty &&
        _sector == null &&
        _sdg == null &&
        _location == null &&
        !_followingOnly &&
        _sort == _DirectorySort.name;
    final featured = showFeatured
        ? (results
              .where(
                (organization) =>
                    _profiles[organization.id]?['cover_image'] != null,
              )
              .toList()
            ..sort((a, b) {
              final aGallery =
                  (_profiles[a.id]?['gallery_images'] as List?)?.length ?? 0;
              final bGallery =
                  (_profiles[b.id]?['gallery_images'] as List?)?.length ?? 0;
              final byGallery = bGallery.compareTo(aGallery);
              return byGallery == 0 ? a.name.compareTo(b.name) : byGallery;
            }))
        : <KaisaOrganization>[];
    final spotlight = featured
        .take(MediaQuery.sizeOf(context).width < 768 ? 1 : 3)
        .toList();
    final spotlightIds = spotlight
        .map((organization) => organization.id)
        .toSet();
    final roster = results
        .where((organization) => !spotlightIds.contains(organization.id))
        .toList();
    final pages = (roster.length / _pageSize).ceil();
    final visiblePage = pages == 0 ? 0 : _page.clamp(0, pages - 1);

    return Theme(
      data: KaisaTypography.homeTheme(context),
      child: KaisaOrganizationPageFrame(
        child: Builder(
          builder: (context) => RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  children: [
                    _heading(
                      context,
                      MediaQuery.sizeOf(context).width < 768
                          ? 'Organizations'
                          : 'Explore Organizations',
                    ),

                    if (_following case final followed?)
                      OutlinedButton.icon(
                        onPressed: () =>
                            _filter(() => _followingOnly = !_followingOnly),
                        icon: Icon(
                          _followingOnly
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                        ),
                        label: Text('Following (${followed.length})'),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Discover civic groups, explore their work, and follow the causes you care about.',
                ),
                const SizedBox(height: 16),
                _searchAndFilters(context, sectors),
                const SizedBox(height: 20),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else if (_failed)
                  KaisaOrganizationEmpty(
                    title: 'Could not load organizations',
                    message: 'Check your connection and try again.',
                    action: TextButton(
                      onPressed: _load,
                      child: const Text('Retry'),
                    ),
                  )
                else ...[
                  if (_following == null)
                    const Text('Following is currently unavailable.'),
                  if (spotlight.isNotEmpty) ...[
                    _heading(context, 'Featured organizations'),
                    const SizedBox(height: 10),
                    _grid(spotlight),
                    const SizedBox(height: 24),
                  ],
                  _heading(context, 'Civic Directory'),
                  const SizedBox(height: 4),
                  Text('${results.length} published organizations'),
                  const SizedBox(height: 12),
                  if (results.isEmpty)
                    const KaisaOrganizationEmpty(
                      title: 'No organizations found',
                      message: 'Try changing your search or filters.',
                    )
                  else if (roster.isNotEmpty)
                    _grid(
                      roster
                          .skip(visiblePage * _pageSize)
                          .take(_pageSize)
                          .toList(),
                    ),
                  if (pages > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          tooltip: 'Previous page',
                          onPressed: visiblePage == 0
                              ? null
                              : () => setState(() => _page = visiblePage - 1),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text('Page ${visiblePage + 1} of $pages'),
                        IconButton(
                          tooltip: 'Next page',
                          onPressed: visiblePage + 1 >= pages
                              ? null
                              : () => setState(() => _page = visiblePage + 1),
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                ],
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
