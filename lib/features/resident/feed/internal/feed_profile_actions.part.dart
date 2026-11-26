part of '../feed_page.dart';

// Account display, preferences persistence, and smart-search dialog.
mixin _FeedProfileActions on _FeedStateCore {
  @override
  Future<void> _loadProfile() async {
    final uid = db.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final value = await db
          .from('resident_profiles')
          .select('first_name,last_name,avatar_path')
          .eq('user_id', uid)
          .maybeSingle();
      // The saved onboarding fields may live in profile columns or Auth
      // metadata, depending on the current KAISA schema. Never require either.
      final meta = db.auth.currentUser?.userMetadata ?? <String, dynamic>{};
      var interests = _readTags(
        meta['kaisa_feed_interests'] ??
            meta['interests'] ??
            meta['community_interests'],
      );
      var skills = _readTags(meta['kaisa_feed_skills'] ?? meta['skills']);
      if (!meta.containsKey('kaisa_feed_interests') ||
          !meta.containsKey('kaisa_feed_skills')) {
        try {
          final extra = await db
              .from('resident_profiles')
              .select('interests,skills')
              .eq('user_id', uid)
              .maybeSingle();
          if (!meta.containsKey('kaisa_feed_interests') &&
              _readTags(extra?['interests']).isNotEmpty) {
            interests = _readTags(extra?['interests']);
          }
          if (!meta.containsKey('kaisa_feed_skills') &&
              _readTags(extra?['skills']).isNotEmpty) {
            skills = _readTags(extra?['skills']);
          }
        } catch (_) {
          // Optional columns are absent on some KAISA deployments.
        }
      }
      if (!mounted) return;
      setState(() {
        displayName = [
          value?['first_name'],
          value?['last_name'],
        ].where((v) => v != null && '$v'.trim().isNotEmpty).join(' ');
        if (displayName.isEmpty) displayName = 'KAISA Resident';
        avatarPath = '${value?['avatar_path'] ?? ''}';
        _feedInterests = interests;
        _feedSkills = skills;
      });
    } catch (_) {
      // Keep a safe avatar fallback without hiding the Feed on profile errors.
    }
  }

  @override
  Future<void> _editFeedPreferences() async {
    final selection =
        await showDialog<({List<String> interests, List<String> skills})>(
          context: context,
          builder: (dialogContext) => _FeedPreferencesDialog(
            interests: _feedInterests,
            skills: _feedSkills,
          ),
        );
    if (selection == null || !mounted || _savingPreferences) return;
    setState(() => _savingPreferences = true);
    try {
      final meta = Map<String, dynamic>.from(
        db.auth.currentUser?.userMetadata ?? <String, dynamic>{},
      );
      // Update only namespaced user metadata; no new database table or migration.
      meta['kaisa_feed_interests'] = selection.interests;
      meta['kaisa_feed_skills'] = selection.skills;
      await db.auth.updateUser(UserAttributes(data: meta));
      if (!mounted) return;
      setState(() {
        _feedInterests = selection.interests;
        _feedSkills = selection.skills;
      });
      _snack('Feed preferences saved. Recommendations updated.');
    } catch (e) {
      _snack('Could not save feed preferences: $e');
    } finally {
      if (mounted) setState(() => _savingPreferences = false);
    }
  }

  @override
  Future<void> _openSmartSearch() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (_) => _FeedSmartSearchDialog(
        posts: posts,
        initialQuery: _searchController.text,
      ),
    );
    if (selected == null || !mounted) return;
    _searchController.text = selected;
    setState(() {
      filter = 'All';
    });
  }
}
