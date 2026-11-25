import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import '../widgets/kaisa_account_refresh.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/kaisa_resident_design.dart';

// Internal parts share the Feed library. Existing data and action contracts remain unchanged.
part 'internal/feed_presentation.part.dart';
part 'internal/feed_relevance.part.dart';
part 'internal/feed_state_core.part.dart';
part 'internal/feed_profile_actions.part.dart';
part 'internal/feed_loading.part.dart';
part 'internal/feed_stories.part.dart';
part 'internal/feed_post_actions.part.dart';
part 'internal/feed_navigation_ui.part.dart';
part 'internal/feed_composer_ui.part.dart';
part 'internal/feed_timeline_ui.part.dart';
part 'widgets/feed_post_card.part.dart';
part 'widgets/feed_create_post.part.dart';
part 'widgets/feed_comments.part.dart';
part 'widgets/feed_preferences.part.dart';
part 'widgets/feed_smart_search.part.dart';
part 'widgets/feed_create_story.part.dart';
part 'widgets/feed_story_camera.part.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});
  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage>
    with
        _FeedStateCore,
        _FeedProfileActions,
        _FeedLoading,
        _FeedStories,
        _FeedPostActions,
        _FeedNavigationUi,
        _FeedComposerUi,
        _FeedTimelineUi {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final query = _searchController.text.trim();
    final shown = posts
        .where(
          (p) =>
              (filter == 'All' || p['category'] == filter) &&
              _postSearchScore(p, query) > 0,
        )
        .toList();
    // Search ranks by text relevance. Otherwise use interest/skill matches
    // plus freshness or plain reverse chronological order.
    shown.sort((a, b) {
      if (query.isNotEmpty) {
        final byQuery = _postSearchScore(
          b,
          query,
        ).compareTo(_postSearchScore(a, query));
        if (byQuery != 0) return byQuery;
      } else if (_personalized &&
          (_feedInterests.isNotEmpty || _feedSkills.isNotEmpty)) {
        final byInterest = _recommendationScore(
          b,
          _feedInterests,
          _feedSkills,
        ).compareTo(_recommendationScore(a, _feedInterests, _feedSkills));
        if (byInterest != 0) return byInterest;
      }
      final aTime =
          DateTime.tryParse('${a['created_at'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bTime =
          DateTime.tryParse('${b['created_at'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    final wide = size.width >= 1024;
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        textTheme: Theme.of(
          context,
        ).textTheme.apply(fontFamily: GoogleFonts.inter().fontFamily),
        colorScheme: theme.colorScheme.copyWith(
          primary: _forest,
          secondary: _yellow,
        ),
      ),
      child: Scaffold(
        backgroundColor: _canvas,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await Future.wait<void>([_load(), _loadStories()]);
            },
            color: _green,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                size.width < 560 ? 16 : 26,
                25,
                size.width < 560 ? 16 : 26,
                96,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 680),
                            child: _feedMain(shown),
                          ),
                        ),
                      ),
                      if (wide) ...[
                        const SizedBox(width: 25),
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              _communitySnapshot(),
                              const SizedBox(height: 16),
                              _sidebar(true),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _communitySnapshot() {
    return _sidePanel(
      title: 'Community at a glance',
      subtitle: 'Updates visible to your account',
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: loading
              ? const LinearProgressIndicator(color: _green)
              : error != null
              ? const Text('Community totals unavailable')
              : Row(
                  children: [
                    Expanded(child: _feedMetric('${posts.length}', 'Posts')),
                    Expanded(
                      child: _feedMetric('${stories.length}', 'Stories'),
                    ),
                  ],
                ),
        ),
        if (!loading && error == null)
          for (final category in ['Announcement', 'Event', 'Organization'])
            ListTile(
              dense: true,
              leading: Icon(_categoryIcon(category), color: _green),
              title: Text(category),
              trailing: Text(
                '${posts.where((p) => p['category'] == category).length}',
              ),
              onTap: () => setState(() {
                filter = category;
                _showCategoryFilters = true;
                _searchController.clear();
              }),
            ),
      ],
    );
  }

  Widget _feedMetric(String value, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: GoogleFonts.plusJakartaSans(
          textStyle: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: _forest,
          ),
        ),
      ),
      Text(
        label,
        style: GoogleFonts.inter(
          textStyle: TextStyle(fontSize: 12, color: _muted),
        ),
      ),
    ],
  );
}
