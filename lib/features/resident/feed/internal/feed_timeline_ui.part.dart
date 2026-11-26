part of '../feed_page.dart';

// Existing timeline, category and sort controls, and empty states.
mixin _FeedTimelineUi on _FeedStateCore {
  @override
  Widget _feedSortChip(String title, IconData icon, bool personalized) {
    final selected = _personalized == personalized;
    return Material(
      color: selected ? _forest : _soft,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _personalized = personalized),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: selected ? _yellow : _forest),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.inter(
                  textStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : _forest,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget _feedMain(List<Map<String, dynamic>> shown) {
    final announcements = posts
        .where(
          (p) =>
              p['category'] == 'Announcement' &&
              '${p['body'] ?? ''}'.trim().isNotEmpty,
        )
        .toList();
    final latestAnnouncement = announcements.isEmpty
        ? null
        : announcements.first;
    const categories = <String>[
      'All',
      'Community',
      'Announcement',
      'Event',
      'Organization',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.circle, size: 7, color: _green),
                      SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'CAVITE CITY  /  COMMUNITY CONNECTIONS',
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              color: _green,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                              letterSpacing: 1.15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Community Feed',
                    style: GoogleFonts.plusJakartaSans(
                      textStyle: TextStyle(
                        fontSize: 32,
                        color: _forest,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Stay connected with the people and organizations of Cavite City.',
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(
                        color: _muted,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: tier2
                  ? 'Identity verified (Tier 2)'
                  : 'Basic account (Tier 1)',
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: tier2
                      ? const Color(0xFFE5EFE9)
                      : const Color(0xFFF1F3F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Icon(
                      tier2
                          ? Icons.verified_user_rounded
                          : Icons.person_outline,
                      size: 18,
                      color: _forest,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tier2 ? 'Tier 2' : 'Tier 1',
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          fontSize: 10,
                          color: _forest,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 19),
        Row(
          children: [
            Expanded(
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _openSmartSearch,
                  child: Container(
                    height: 49,
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    decoration: BoxDecoration(
                      border: Border.all(color: _line),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: _forest,
                          size: 21,
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            _searchController.text.trim().isEmpty
                                ? 'Search posts, residents, and topics…'
                                : _searchController.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              textStyle: TextStyle(
                                fontSize: 13,
                                color: _searchController.text.isEmpty
                                    ? _muted
                                    : _ink,
                              ),
                            ),
                          ),
                        ),
                        if (_searchController.text.trim().isNotEmpty)
                          IconButton(
                            tooltip: 'Clear search',
                            onPressed: () =>
                                setState(() => _searchController.clear()),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: _forest,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Material(
              color: _soft,
              borderRadius: BorderRadius.circular(8),
              child: IconButton(
                tooltip: _showCategoryFilters ? 'Hide filters' : 'Show filters',
                icon: Icon(
                  _showCategoryFilters
                      ? Icons.tune_rounded
                      : Icons.filter_list_rounded,
                  color: _forest,
                ),
                onPressed: () => setState(
                  () => _showCategoryFilters = !_showCategoryFilters,
                ),
              ),
            ),
            const SizedBox(width: 2),
            IconButton(
              tooltip: 'Refresh posts and stories',
              onPressed: () {
                _load();
                _loadStories();
              },
              icon: const Icon(Icons.refresh_rounded, color: _forest),
            ),
          ],
        ),
        if (_showCategoryFilters) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 39,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final f = categories[i];
                final selected = filter == f;
                return Material(
                  color: selected ? _forest : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => setState(() => filter = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: selected ? _forest : _line),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (f != 'All') ...[
                            Icon(
                              _categoryIcon(f),
                              size: 15,
                              color: selected ? _yellow : _categoryInk(f),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            f == 'All' ? 'All updates' : f,
                            style: GoogleFonts.inter(
                              textStyle: TextStyle(
                                color: selected ? Colors.white : _ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (!loading && posts.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              '${f == 'All' ? posts.length : posts.where((p) => p['category'] == f).length}',
                              style: GoogleFonts.inter(
                                textStyle: TextStyle(
                                  fontSize: 11,
                                  color: selected ? _sage : _muted,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 16),
        _storiesStrip(),
        const SizedBox(height: 12),
        _composer(),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_outlined,
                    color: _forest,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your feed',
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _forest,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _savingPreferences ? null : _editFeedPreferences,
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: const Text('Preferences'),
                    style: TextButton.styleFrom(foregroundColor: _green),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              if (_feedInterests.isEmpty && _feedSkills.isEmpty)
                Text(
                  'Choose interests and skills to personalize your feed.',
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(fontSize: 12, color: _muted),
                  ),
                )
              else
                Text(
                  'Based on ${[..._feedInterests, ..._feedSkills].take(3).join(', ')}'
                  '${_feedInterests.length + _feedSkills.length > 3 ? ' and more' : ''}',
                  style: GoogleFonts.inter(
                    textStyle: TextStyle(color: _muted, fontSize: 12),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _feedSortChip(
                    'For you',
                    Icons.favorite_outline_rounded,
                    true,
                  ),
                  _feedSortChip('Most recent', Icons.schedule_rounded, false),
                ],
              ),
            ],
          ),
        ),
        if (latestAnnouncement != null &&
            filter == 'All' &&
            _searchController.text.trim().isEmpty) ...[
          const SizedBox(height: 16),
          _bulletin(latestAnnouncement),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LATEST CONVERSATIONS',
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(
                        color: _green,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                      ),
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Community updates',
                    style: GoogleFonts.plusJakartaSans(
                      textStyle: TextStyle(
                        color: _ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!loading && error == null)
              Text(
                '${shown.length} ${shown.length == 1 ? 'post' : 'posts'}',
                style: GoogleFonts.inter(
                  textStyle: TextStyle(color: _muted, fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 13),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(child: CircularProgressIndicator(color: _green)),
          )
        else if (error != null)
          _feedNotice(
            error!,
            action: 'Try again',
            onTap: _load,
            icon: Icons.wifi_off_rounded,
          )
        else if (shown.isEmpty)
          _feedNotice(
            _searchController.text.trim().isNotEmpty
                ? 'No posts match your search. Try another word or clear the search.'
                : filter != 'All'
                ? 'There are no ${filter.toLowerCase()} posts yet.'
                : 'No community posts yet. Be the first to start a conversation!',
            action: _searchController.text.trim().isNotEmpty || filter != 'All'
                ? 'Show all posts'
                : tier2
                ? 'Create a post'
                : 'Get verified',
            onTap: () {
              if (_searchController.text.trim().isNotEmpty || filter != 'All') {
                _searchController.clear();
                setState(() => filter = 'All');
              } else {
                _compose();
              }
            },
          )
        else
          for (final post in shown) ...[
            _PostCard(
              post: post,
              tier2: tier2,
              matches: _personalized && _searchController.text.trim().isEmpty
                  ? _matchingPreferences(post, _feedInterests, _feedSkills)
                  : const [],
              onLike: () => _toggleLike(post),
              onComments: () => _comments(post),
              onShare: () => _share(post),
            ),
            const SizedBox(height: 15),
          ],
      ],
    );
  }

  @override
  Widget _feedNotice(
    String message, {
    required String action,
    required VoidCallback onTap,
    IconData icon = Icons.forum_outlined,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _line),
    ),
    child: Column(
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: _soft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, size: 30, color: _green),
        ),
        const SizedBox(height: 15),
        Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            textStyle: TextStyle(color: _ink, fontSize: 14, height: 1.5),
          ),
        ),
        const SizedBox(height: 13),
        FilledButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.arrow_forward_rounded, size: 17),
          label: Text(action),
          style: FilledButton.styleFrom(
            backgroundColor: _forest,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    ),
  );
}
