part of '../feed_page.dart';

// Existing kaisa_feed_stream and kaisa_is_tier2 RPC requests.
mixin _FeedLoading on _FeedStateCore {
  @override
  Future<void> _load() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }
    try {
      final results = await Future.wait<dynamic>([
        db.rpc('kaisa_feed_stream'),
        db.rpc('kaisa_is_tier2'),
      ]);
      final loaded = (results[0] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      // Enrich only posts already returned by the visibility-aware RPC.
      // Existing table RLS remains in force; never broaden the feed.
      final ids = loaded
          .map((p) => p['id'])
          .whereType<String>()
          .toSet()
          .toList();
      final tags = <String, Map<String, dynamic>>{};
      String? tagError;
      try {
        for (var offset = 0; offset < ids.length; offset += 100) {
          final rows = await db
              .from('kaisa_feed_posts')
              .select('id,interest_tags,skill_tags')
              .inFilter('id', ids.skip(offset).take(100).toList());
          for (final row in rows) {
            tags[row['id'].toString()] = row;
          }
        }
        for (final post in loaded) {
          final row = tags[post['id']];
          if (row != null) {
            post['interest_tags'] = row['interest_tags'];
            post['skill_tags'] = row['skill_tags'];
          }
        }
        if (ids.any((id) => !tags.containsKey(id))) {
          tagError =
              'Some post tags are unavailable under the current access rules.';
        }
      } catch (e) {
        tagError =
            'Post tags could not be loaded. Check the tag migration and access rules.';
        debugPrint('KAISA post tags: $e');
      }
      if (!mounted) return;
      setState(() {
        posts = loaded;
        tier2 = results[1] == true;
      });
      if (tagError != null) _snack(tagError);
    } catch (e) {
      if (mounted) {
        setState(
          () => error =
              'Unable to load community posts. Check your connection or migration. ($e)',
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}
