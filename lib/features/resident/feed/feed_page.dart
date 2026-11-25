import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import '../widgets/kaisa_account_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/kaisa_resident_design.dart';

// Civic Dignity: Stitch is a visual reference, not a source of new features.
const _forest = Color(0xFF00301B);
const _green = Color(0xFF2C6A4A);
const _yellow = Color(0xFFFDBC19);
const _ink = Color(0xFF151C27);
const _muted = Color(0xFF66736B);
const _canvas = Color(0xFFF9FAF9);
const _soft = Color(0xFFF0F5F1);
const _line = Color(0xFFE5ECE7);
const _sage = Color(0xFF95D4AD);

String _relativeTime(DateTime? date) {
  if (date == null) return 'Recently';
  final elapsed = DateTime.now().difference(date);
  if (elapsed.isNegative || elapsed.inMinutes < 1) return 'Just now';
  if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m ago';
  if (elapsed.inHours < 24) return '${elapsed.inHours}h ago';
  if (elapsed.inDays < 7) return '${elapsed.inDays}d ago';
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
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

Color _categoryTint(String category) {
  switch (category.toLowerCase()) {
    case 'announcement':
      return const Color(0xFFFFF2D5);
    case 'event':
      return const Color(0xFFE8F0FF);
    case 'organization':
      return const Color(0xFFF0EAFE);
    default:
      return const Color(0xFFE9F4EC);
  }
}

Color _categoryInk(String category) {
  switch (category.toLowerCase()) {
    case 'announcement':
      return const Color(0xFF856000);
    case 'event':
      return const Color(0xFF2D567E);
    case 'organization':
      return const Color(0xFF65528E);
    default:
      return _forest;
  }
}

IconData _categoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'announcement':
      return Icons.campaign_outlined;
    case 'event':
      return Icons.event_available_outlined;
    case 'organization':
      return Icons.groups_2_outlined;
    default:
      return Icons.forum_outlined;
  }
}

// Interest/skill names mirror the KAISA Profile Setup screen. They are
// preferences, NOT authorization claims and not extra public profile fields.
const _kaisaInterests = <String>[
  'Environment',
  'Education',
  'Health',
  'Youth',
  'Sports',
  'Arts & Culture',
  'Technology',
  'Community Service',
  'Disaster Preparedness',
  'Livelihood',
];
const _kaisaSkills = <String>[
  'Communication',
  'Leadership',
  'Graphic Design',
  'Photography',
  'Video Editing',
  'Programming',
  'Writing',
  'Public Speaking',
  'Event Management',
  'First Aid',
];

// Common terms help connect a resident's selection with ordinary post text.
// This is explainable on-device ranking, not an ML prediction or a new RPC.
const _interestKeywords = <String, List<String>>{
  'Environment': [
    'environment',
    'ecology',
    'sustainability',
    'clean up',
    'recycling',
    'tree planting',
    'green',
    'coastal',
  ],
  'Education': [
    'education',
    'learning',
    'school',
    'tutoring',
    'student',
    'workshop',
    'seminar',
  ],
  'Health': [
    'health',
    'wellness',
    'clinic',
    'medical',
    'nutrition',
    'mental health',
    'first aid',
  ],
  'Youth': ['youth', 'students', 'young people', 'leadership', 'teen'],
  'Sports': [
    'sports',
    'basketball',
    'volleyball',
    'athletics',
    'fitness',
    'tournament',
  ],
  'Arts & Culture': [
    'art',
    'arts',
    'culture',
    'music',
    'dance',
    'painting',
    'heritage',
  ],
  'Technology': [
    'technology',
    'digital',
    'coding',
    'programming',
    'computer',
    'software',
    'it workshop',
  ],
  'Community Service': [
    'community service',
    'volunteer',
    'outreach',
    'donation',
    'charity',
    'bayanihan',
  ],
  'Disaster Preparedness': [
    'disaster',
    'preparedness',
    'emergency',
    'rescue',
    'evacuation',
    'flood',
    'safety',
  ],
  'Livelihood': [
    'livelihood',
    'employment',
    'job',
    'business',
    'entrepreneur',
    'training',
    'income',
  ],
};
const _skillKeywords = <String, List<String>>{
  'Communication': [
    'communication',
    'public relations',
    'discussion',
    'advocacy',
  ],
  'Leadership': [
    'leadership',
    'organizing',
    'facilitation',
    'community leader',
  ],
  'Graphic Design': ['graphic design', 'poster', 'design', 'layout'],
  'Photography': ['photography', 'photographer', 'photos', 'photo walk'],
  'Video Editing': ['video editing', 'film', 'videography', 'video'],
  'Programming': [
    'programming',
    'coding',
    'python',
    'software',
    'app development',
  ],
  'Writing': ['writing', 'creative writing', 'journalism', 'copywriting'],
  'Public Speaking': [
    'public speaking',
    'speech',
    'seminar',
    'host',
    'presentation',
  ],
  'Event Management': [
    'event management',
    'event planning',
    'organizer',
    'logistics',
    'coordination',
  ],
  'First Aid': ['first aid', 'cpr', 'emergency response', 'rescue'],
};

String _normalized(String text) =>
    text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

// Only a small typo tolerance. This never performs a broad user-directory query.
bool _withinOneEdit(String a, String b) {
  if ((a.length - b.length).abs() > 1) return false;
  if (a == b) return true;
  var i = 0, j = 0, edits = 0;
  while (i < a.length && j < b.length) {
    if (a[i] == b[j]) {
      i++;
      j++;
      continue;
    }
    if (++edits > 1) return false;
    if (a.length > b.length) {
      i++;
    } else if (b.length > a.length) {
      j++;
    } else {
      i++;
      j++;
    }
  }
  return edits + (a.length - i) + (b.length - j) <= 1;
}

bool _termMatch(String text, String term) {
  final needle = _normalized(term);
  final haystack = _normalized(text);
  if (needle.isEmpty || haystack.isEmpty) return false;
  if (' $haystack '.contains(' $needle ')) return true;
  final tokens = haystack.split(' ');
  if (needle.contains(' ')) return false;
  return tokens.any(
    (word) =>
        word.startsWith(needle) ||
        (needle.length >= 5 &&
            word.length >= 5 &&
            _withinOneEdit(needle, word)),
  );
}

List<String> _readTags(dynamic value) {
  if (value is List) {
    return value
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }
  if (value is String) {
    final input = value.trim();
    if (input.startsWith('[')) {
      try {
        return _readTags(jsonDecode(input));
      } catch (_) {
        /* legacy CSV */
      }
    }
    return input
        .split(RegExp(r'[,;]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }
  return <String>[];
}

String _postCorpus(Map<String, dynamic> post) => [
  post['title'],
  post['body'],
  post['category'],
  post['shared_body'],
  post['shared_author_name'],
].map((value) => '${value ?? ''}').join(' ');

// All search/ranking is applied only to rows already returned by the existing
// kaisa_feed_stream RPC. Supabase visibility and RLS stay authoritative.
double _postSearchScore(Map<String, dynamic> post, String query) {
  final tokens = _normalized(query).split(' ').where((e) => e.isNotEmpty);
  if (tokens.isEmpty) return 1;
  final fields = <(String, double)>[
    ('${post['author_name'] ?? ''}', 8),
    ('${post['title'] ?? ''}', 7),
    ('${post['category'] ?? ''}', 6),
    ('${post['body'] ?? ''}', 3),
    ('${post['shared_body'] ?? ''}', 2),
    ('${post['shared_author_name'] ?? ''}', 3),
  ];
  var score = 0.0;
  for (final token in tokens) {
    var weight = 0.0;
    for (final field in fields) {
      if (_termMatch(field.$1, token)) weight = math.max(weight, field.$2);
    }
    if (weight == 0) return 0; // Every word must match somewhere.
    score += weight;
  }
  final phrase = _normalized(query);
  if (phrase.isNotEmpty && _normalized(_postCorpus(post)).contains(phrase)) {
    score += 5;
  }
  return score;
}

List<String> _matchingPreferences(
  Map<String, dynamic> post,
  List<String> interests,
  List<String> skills,
) {
  final corpus = _postCorpus(post);
  return [
    for (final tag in interests)
      if ((_interestKeywords[tag] ?? [tag]).any(
        (term) => _termMatch(corpus, term),
      ))
        tag,
    for (final tag in skills)
      if ((_skillKeywords[tag] ?? [tag]).any(
        (term) => _termMatch(corpus, term),
      ))
        tag,
  ];
}

double _recommendationScore(
  Map<String, dynamic> post,
  List<String> interests,
  List<String> skills,
) {
  final published = DateTime.tryParse('${post['created_at'] ?? ''}')?.toLocal();
  final daysOld = published == null
      ? 90.0
      : math.max(0.0, DateTime.now().difference(published).inHours / 24.0);
  // Recency matters; popularity has a capped influence so newcomers are seen.
  final freshness = 24.0 / (1 + daysOld / 3.0);
  final likes = (num.tryParse('${post['likes'] ?? 0}') ?? 0).toDouble();
  final comments = (num.tryParse('${post['comments'] ?? 0}') ?? 0).toDouble();
  final engagement = math.min(
    12.0,
    2 * math.log(1 + math.max(0, likes) + 2 * math.max(0, comments)),
  );
  final relevant = _matchingPreferences(post, interests, skills);
  final interestHits = relevant.where(interests.contains).length;
  final skillHits = relevant.where(skills.contains).length;
  return freshness +
      engagement +
      math.min(32.0, interestHits * 16.0) +
      math.min(18.0, skillHits * 9.0);
}

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});
  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final db = Supabase.instance.client;
  List<Map<String, dynamic>> posts = [];
  String filter = 'All';
  final TextEditingController _searchController = TextEditingController();
  List<String> _feedInterests = [];
  List<String> _feedSkills = [];
  bool _personalized = true;
  bool _savingPreferences = false;
  bool _showCategoryFilters = true;
  Map<String, String> _storyUrls = {};
  bool loading = true;
  bool tier2 = false;
  List<Map<String, dynamic>> stories = [];
  Timer? _storyTicker;
  String? error;
  String displayName = 'Resident';
  String avatarPath = '';
  late final VoidCallback _profileChangeListener;

  @override
  void initState() {
    super.initState();
    _profileChangeListener = () => _loadProfile();
    kaisaAccountRefresh.addListener(_profileChangeListener);
    _loadProfile();
    _load();
    _loadStories();
    _storyTicker = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _loadStories(),
    );
  }

  @override
  void dispose() {
    _storyTicker?.cancel();
    _searchController.dispose();
    kaisaAccountRefresh.removeListener(_profileChangeListener);
    super.dispose();
  }

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
      if (!mounted) return;
      setState(() {
        posts = (results[0] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        tier2 = results[1] == true;
      });
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

  Future<void> _loadStories() async {
    try {
      // Keep the existing active-stories RPC and signed storage URLs.
      final result = await db.rpc('kaisa_active_stories');
      final fetched = (result as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final thumbnails = <String, String>{};
      // Load thumbnails only for stories actually visible in the strip.
      await Future.wait(
        fetched.take(25).map((story) async {
          final path = (story['image_path'] ?? '').toString().trim();
          if (path.isEmpty) return;
          try {
            thumbnails[path] = await db.storage
                .from('kaisa-stories')
                .createSignedUrl(path, 10 * 60);
          } catch (_) {
            // Missing/unauthorized media uses a consistent icon fallback.
          }
        }),
      );
      if (mounted) {
        setState(() {
          stories = fetched;
          _storyUrls = thumbnails;
        });
      }
    } catch (e) {
      if (mounted) _snack('Stories could not load: $e');
    }
  }

  Future<void> _createStory() async {
    if (!tier2) {
      context.push('/resident/identity-verification');
      return;
    }
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 540),
          child: _CreateStoryDialog(),
        ),
      ),
    );
    if (result == true) await _loadStories();
  }

  Future<void> _viewStory(Map<String, dynamic> story) async {
    final path = '${story['image_path'] ?? ''}';
    String? url;
    if (path.isNotEmpty) {
      try {
        url = await db.storage.from('kaisa-stories').createSignedUrl(path, 120);
      } catch (e) {
        _snack('Story image unavailable: $e');
      }
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        backgroundColor: _forest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SizedBox(
            height: MediaQuery.sizeOf(dialogContext).height * .75,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_stories_outlined,
                        color: _yellow,
                        size: 22,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          '${story['author_name'] ?? 'Resident'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close story',
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24),
                  Expanded(
                    child: Center(
                      child: url == null
                          ? const Icon(
                              Icons.auto_stories_rounded,
                              color: _sage,
                              size: 70,
                            )
                          : Image.network(
                              url,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.broken_image_outlined,
                                size: 58,
                                color: Colors.white70,
                              ),
                            ),
                    ),
                  ),
                  if ('${story['caption'] ?? ''}'.trim().isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 125),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 13),
                          child: Text(
                            '${story['caption']}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              height: 1.5,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _storiesStrip() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: _line),
    ),
    padding: const EdgeInsets.fromLTRB(16, 17, 12, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_stories_outlined, size: 19, color: _forest),
            const SizedBox(width: 9),
            const Expanded(
              child: Text(
                'Community stories',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
            ),
            Text(
              '${stories.length} active · 24h',
              style: const TextStyle(fontSize: 11, color: _muted),
            ),
          ],
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 105,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              SizedBox(
                width: 83,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _createStory,
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 65,
                            height: 65,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: _yellow, width: 2),
                              color: _soft,
                            ),
                            alignment: Alignment.center,
                            child: _avatar(radius: 28),
                          ),
                          Positioned(
                            right: -1,
                            bottom: -2,
                            child: Container(
                              width: 25,
                              height: 25,
                              decoration: BoxDecoration(
                                color: _forest,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                tier2 ? Icons.add : Icons.lock_outline,
                                size: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tier2 ? 'Your story' : 'Verify first',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ...stories.map((story) {
                final imagePath = '${story['image_path'] ?? ''}';
                final thumb = _storyUrls[imagePath];
                final author = '${story['author_name'] ?? 'Resident'}';
                return SizedBox(
                  width: 89,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _viewStory(story),
                    child: Column(
                      children: [
                        Container(
                          width: 66,
                          height: 66,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _green, width: 2),
                          ),
                          child: CircleAvatar(
                            backgroundColor: _soft,
                            backgroundImage: thumb == null
                                ? null
                                : NetworkImage(thumb),
                            child: thumb == null
                                ? const Icon(
                                    Icons.auto_stories_rounded,
                                    size: 26,
                                    color: _forest,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          author,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: _ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    ),
  );

  Future<void> _compose() async {
    if (!tier2) {
      context.push('/resident/identity-verification');
      return;
    }
    final wide = MediaQuery.sizeOf(context).width >= 700;
    final posted = wide
        ? await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (_) => Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: const _CreatePostSheet(),
              ),
            ),
          )
        : await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            showDragHandle: true,
            builder: (_) => const _CreatePostSheet(),
          );
    if (posted == true) await _load();
  }

  Future<void> _toggleLike(Map<String, dynamic> post) async {
    if (!tier2) {
      _snack('Tier 2 verification required to like posts.');
      return;
    }
    final uid = db.auth.currentUser?.id;
    if (uid == null) return;
    try {
      if (post['liked'] == true) {
        await db
            .from('kaisa_feed_likes')
            .delete()
            .eq('post_id', post['id'])
            .eq('user_id', uid);
      } else {
        await db.from('kaisa_feed_likes').insert({
          'post_id': post['id'],
          'user_id': uid,
        });
      }
      await _load();
    } catch (e) {
      _snack('Like could not be updated: $e');
    }
  }

  Future<void> _comments(Map<String, dynamic> post) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: _CommentsSheet(
            postId: post['id'] as String,
            canComment: tier2,
          ),
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _share(Map<String, dynamic> post) async {
    if (!tier2) {
      _snack('Tier 2 verification required to share posts.');
      return;
    }
    if (post['visibility'] == 'private' || post['shared_post_id'] != null) {
      _snack('This post cannot be shared to another feed.');
      return;
    }
    final note = TextEditingController();
    var audience = post['visibility'] == 'friends' ? 'friends' : 'public';
    try {
      final publish = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: const Text('Share to your feed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Share ${post['author_name']}’s post with your community.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: note,
                  maxLength: 500,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Add a message (optional)',
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: audience,
                  decoration: const InputDecoration(
                    labelText: 'Who can see your share?',
                  ),
                  items: ['public', 'friends']
                      .where(
                        (v) => post['visibility'] == 'public' || v == 'friends',
                      )
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(v == 'public' ? 'Public' : 'Friends'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setLocal(() => audience = v ?? audience),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Share post'),
              ),
            ],
          ),
        ),
      );
      if (publish != true) return;
      await db.rpc(
        'kaisa_share_to_feed',
        params: {
          'p_post_id': post['id'],
          'p_message': note.text.trim(),
          'p_visibility': audience,
        },
      );
      await _load();
      _snack('Shared to your feed!');
    } catch (e) {
      _snack('Sharing failed: $e');
    } finally {
      note.dispose();
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _avatar({double radius = 22}) {
    final fallback = displayName.trim().isEmpty
        ? 'R'
        : displayName.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE3F1E7),
      backgroundImage: avatarPath.isEmpty
          ? null
          : NetworkImage(
              db.storage.from('kaisa-avatars').getPublicUrl(avatarPath),
            ),
      child: avatarPath.isEmpty
          ? Text(
              fallback,
              style: const TextStyle(
                color: _forest,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }

  Widget _quickLink(IconData icon, String text, String route) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    leading: Icon(icon, color: _forest, size: 23),
    title: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: _ink,
        fontSize: 13,
      ),
    ),
    onTap: () => context.push(route),
  );

  Widget _sidebar(bool right) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: right
        ? [
            _sidePanel(
              title: 'Explore KAISA',
              subtitle: 'Stay involved in your community',
              children: [
                _quickLink(
                  Icons.event_available_outlined,
                  'Upcoming events',
                  '/resident/events',
                ),
                _quickLink(
                  Icons.groups_outlined,
                  'Organizations',
                  '/resident/organizations',
                ),
                _quickLink(
                  Icons.search_rounded,
                  'Community Feed',
                  '/resident/feed',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _sidePanel(
              title: 'Your activity',
              children: [
                _quickLink(
                  Icons.event_note_outlined,
                  'My events',
                  '/resident/my-events',
                ),
                _quickLink(
                  Icons.group_work_outlined,
                  'My organizations',
                  '/resident/my-organizations',
                ),
                _quickLink(
                  Icons.notifications_none_rounded,
                  'Notifications',
                  '/resident/notifications',
                ),
              ],
            ),
          ]
        : [
            _sidePanel(
              title: 'Your community',
              children: [
                _quickLink(
                  Icons.person_outline_rounded,
                  'My profile',
                  '/resident/profile',
                ),
                _quickLink(
                  Icons.forum_outlined,
                  'Community Feed',
                  '/resident/feed',
                ),
                _quickLink(
                  Icons.chat_bubble_outline_rounded,
                  'My organizations',
                  '/resident/my-organizations',
                ),
                _quickLink(
                  Icons.groups_2_outlined,
                  'Organizations',
                  '/resident/organizations',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: _forest,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.volunteer_activism_rounded,
                    color: _yellow,
                    size: 28,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Stronger communities start with you.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Discover activities, find your people, and make a difference.',
                    style: TextStyle(color: Color(0xFFDCECDF), fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => context.push('/resident/events'),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Browse events'),
                    style: TextButton.styleFrom(foregroundColor: _yellow),
                  ),
                ],
              ),
            ),
          ],
  );

  Widget _sidePanel({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: KaisaResidentDesign.border),
      borderRadius: BorderRadius.circular(13),
    ),
    padding: const EdgeInsets.fromLTRB(10, 16, 10, 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
            child: Text(
              subtitle,
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
          ),
        const SizedBox(height: 5),
        ...children,
      ],
    ),
  );

  Widget _composer() => Container(
    padding: const EdgeInsets.fromLTRB(17, 17, 17, 11),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(15),
      boxShadow: const [
        BoxShadow(
          color: Color(0x06000000),
          blurRadius: 12,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          children: [
            _avatar(radius: 23),
            const SizedBox(width: 12),
            Expanded(
              child: Material(
                color: _soft,
                borderRadius: BorderRadius.circular(11),
                child: InkWell(
                  borderRadius: BorderRadius.circular(11),
                  onTap: _compose,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 15,
                    ),
                    child: Text(
                      tier2
                          ? 'Share something with your community…'
                          : 'Verify your account to join the conversation',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: _muted),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: _line),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: _compose,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 21),
                label: const Text('Photo'),
                style: TextButton.styleFrom(foregroundColor: _green),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: _compose,
                icon: Icon(
                  tier2
                      ? Icons.edit_note_rounded
                      : Icons.verified_user_outlined,
                  size: 21,
                ),
                label: Text(tier2 ? 'Write a post' : 'Get verified'),
                style: TextButton.styleFrom(foregroundColor: _forest),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _bulletin(Map<String, dynamic> announcement) {
    final author = (announcement['author_name'] ?? 'Community member')
        .toString();
    final body = (announcement['body'] ?? '').toString().trim();
    if (body.isEmpty) return const SizedBox.shrink();
    final excerpt = body.length > 220 ? '${body.substring(0, 220)}…' : body;
    return Material(
      color: const Color(0xFFFFF4DB),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: () => setState(() => filter = 'Announcement'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFFF1DFA9)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _yellow,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: _forest,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FROM YOUR COMMUNITY',
                      style: TextStyle(
                        color: Color(0xFF7B5900),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _forest,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      excerpt,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        height: 1.4,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'See announcements',
                          style: TextStyle(
                            color: _forest,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: _forest,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : _forest,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                  const Row(
                    children: [
                      Icon(Icons.circle, size: 7, color: _green),
                      SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'CAVITE CITY  /  COMMUNITY CONNECTIONS',
                          style: TextStyle(
                            color: _green,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 1.15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Community Feed',
                    style: TextStyle(
                      fontSize: 31,
                      color: _forest,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'A place for updates, conversations, and community stories.',
                    style: TextStyle(color: _muted, fontSize: 13, height: 1.45),
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
                      style: const TextStyle(
                        fontSize: 10,
                        color: _forest,
                        fontWeight: FontWeight.w800,
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
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _openSmartSearch,
                  child: Container(
                    height: 49,
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    decoration: BoxDecoration(
                      border: Border.all(color: _line),
                      borderRadius: BorderRadius.circular(12),
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
                            style: TextStyle(
                              fontSize: 13,
                              color: _searchController.text.isEmpty
                                  ? _muted
                                  : _ink,
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
              borderRadius: BorderRadius.circular(12),
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
                            style: TextStyle(
                              color: selected ? Colors.white : _ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (!loading && posts.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              '${f == 'All' ? posts.length : posts.where((p) => p['category'] == f).length}',
                              style: TextStyle(
                                fontSize: 11,
                                color: selected ? _sage : _muted,
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
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
                  const Expanded(
                    child: Text(
                      'Discover what matters to you',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _forest,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _savingPreferences ? null : _editFeedPreferences,
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: const Text('Interests & skills'),
                    style: TextButton.styleFrom(foregroundColor: _green),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              if (_feedInterests.isEmpty && _feedSkills.isEmpty)
                const Text(
                  'Choose interests and skills to personalize your feed.',
                  style: TextStyle(fontSize: 12, color: _muted),
                )
              else
                Text(
                  'Based on ${[..._feedInterests, ..._feedSkills].take(3).join(', ')}'
                  '${_feedInterests.length + _feedSkills.length > 3 ? ' and more' : ''}',
                  style: const TextStyle(color: _muted, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _feedSortChip(
                    'For you',
                    Icons.favorite_outline_rounded,
                    true,
                  ),
                  const SizedBox(width: 8),
                  _feedSortChip('Most recent', Icons.schedule_rounded, false),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 17),
        _storiesStrip(),
        const SizedBox(height: 14),
        _composer(),
        if (latestAnnouncement != null &&
            filter == 'All' &&
            _searchController.text.trim().isEmpty) ...[
          const SizedBox(height: 16),
          _bulletin(latestAnnouncement),
        ],
        const SizedBox(height: 25),
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COMMUNITY CONVERSATIONS',
                    style: TextStyle(
                      color: _green,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'From your community',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (!loading && error == null)
              Text(
                '${shown.length} ${shown.length == 1 ? 'post' : 'posts'}',
                style: const TextStyle(color: _muted, fontSize: 12),
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
      borderRadius: BorderRadius.circular(14),
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
          style: const TextStyle(color: _ink, fontSize: 14, height: 1.5),
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
    final wide = size.width >= 1060;
    return Scaffold(
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
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: _feedMain(shown)),
                    if (wide) ...[
                      const SizedBox(width: 25),
                      Expanded(flex: 3, child: _sidebar(true)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.tier2,
    required this.matches,
    required this.onLike,
    required this.onComments,
    required this.onShare,
  });
  final Map<String, dynamic> post;
  final bool tier2;
  final List<String> matches;
  final VoidCallback onLike, onComments, onShare;
  Future<void> _showLikers(BuildContext context) async {
    try {
      final result = await Supabase.instance.client.rpc(
        'kaisa_post_likers',
        params: {'p_post_id': post['id']},
      );
      if (!context.mounted) return;
      final likers = (result as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * .55,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'Residents who liked this post',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ),
                Expanded(
                  child: likers.isEmpty
                      ? const Center(child: Text('No likes yet.'))
                      : ListView.builder(
                          itemCount: likers.length,
                          itemBuilder: (c, i) {
                            final item = likers[i];
                            final name =
                                '${item['display_name'] ?? 'Resident'}';
                            final avatar = '${item['avatar_path'] ?? ''}';
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: avatar.isEmpty
                                    ? null
                                    : NetworkImage(
                                        Supabase.instance.client.storage
                                            .from('kaisa-avatars')
                                            .getPublicUrl(avatar),
                                      ),
                                child: avatar.isEmpty
                                    ? Text(name.substring(0, 1))
                                    : null,
                              ),
                              title: Text(name),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () {
                                Navigator.pop(sheetContext);
                                context.push(
                                  '/resident/user/${item['user_id']}',
                                  extra: {'name': name, 'avatar_path': avatar},
                                );
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
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not load likes: $e')));
      }
    }
  }

  void _openPostImage(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(13),
        backgroundColor: const Color(0xFF111C17),
        child: Stack(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(dialogContext).width * .95,
                maxHeight: MediaQuery.sizeOf(dialogContext).height * .84,
              ),
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 5,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox(
                    height: 200,
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 5,
              right: 5,
              child: IconButton.filledTonal(
                tooltip: 'Close image',
                onPressed: () => Navigator.of(dialogContext).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse('${post['created_at']}')?.toLocal();
    final names = (post['images'] as List? ?? [])
        .map((e) => '$e')
        .where((path) => path.isNotEmpty)
        .toList();
    final storage = Supabase.instance.client.storage.from('kaisa-feed');
    final author = (post['author_name'] ?? 'KAISA Resident').toString().trim();
    final safeAuthor = author.isEmpty ? 'KAISA Resident' : author;
    final authorId = '${post['author_id'] ?? ''}';
    final category = '${post['category'] ?? 'Community'}';
    final postText = '${post['body'] ?? ''}'.trim();
    final postTitle = '${post['title'] ?? ''}'.trim();
    final liked = post['liked'] == true;
    final likes = post['likes'] ?? 0;
    final comments = post['comments'] ?? 0;
    final visibility = '${post['visibility'] ?? 'public'}';
    final rawAvatar =
        '${post['author_avatar_path'] ?? post['avatar_path'] ?? ''}';
    final avatarUrl = rawAvatar.isEmpty
        ? null
        : rawAvatar.startsWith('http')
        ? rawAvatar
        : Supabase.instance.client.storage
              .from('kaisa-avatars')
              .getPublicUrl(rawAvatar);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 17, 17, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: authorId.isEmpty
                      ? null
                      : () => context.push(
                          '/resident/user/$authorId',
                          extra: {'name': safeAuthor, 'avatar_path': rawAvatar},
                        ),
                  borderRadius: BorderRadius.circular(40),
                  child: CircleAvatar(
                    radius: 23,
                    backgroundColor: _categoryTint(category),
                    backgroundImage: avatarUrl == null
                        ? null
                        : NetworkImage(avatarUrl),
                    child: avatarUrl == null
                        ? Text(
                            safeAuthor.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: _categoryInk(category),
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: authorId.isEmpty
                            ? null
                            : () => context.push(
                                '/resident/user/$authorId',
                                extra: {
                                  'name': safeAuthor,
                                  'avatar_path': rawAvatar,
                                },
                              ),
                        child: Text(
                          safeAuthor,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _forest,
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _relativeTime(date),
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child: Icon(Icons.circle, color: _muted, size: 3),
                          ),
                          Icon(
                            visibility == 'private'
                                ? Icons.lock_outline_rounded
                                : visibility == 'friends'
                                ? Icons.people_outline_rounded
                                : Icons.public_rounded,
                            size: 14,
                            color: _muted,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              visibility == 'private'
                                  ? 'Only me'
                                  : visibility == 'friends'
                                  ? 'Friends'
                                  : 'Public',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Post options',
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_horiz_rounded, color: _muted),
                  onSelected: (choice) async {
                    if (choice == 'copy') {
                      await Clipboard.setData(ClipboardData(text: postText));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Post text copied')),
                        );
                      }
                    } else if (choice == 'author' && authorId.isNotEmpty) {
                      if (context.mounted) {
                        context.push(
                          '/resident/user/$authorId',
                          extra: {'name': safeAuthor, 'avatar_path': rawAvatar},
                        );
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'copy',
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.copy_rounded),
                        title: Text('Copy post text'),
                      ),
                    ),
                    if (authorId.isNotEmpty)
                      const PopupMenuItem(
                        value: 'author',
                        child: ListTile(
                          dense: true,
                          leading: Icon(Icons.account_circle_outlined),
                          title: Text('View author'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 14, 17, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _categoryTint(category),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _categoryIcon(category),
                        size: 13,
                        color: _categoryInk(category),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        category.toUpperCase(),
                        style: TextStyle(
                          color: _categoryInk(category),
                          fontSize: 9.5,
                          letterSpacing: .5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (matches.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 10, 17, 0),
              child: Wrap(
                spacing: 6,
                runSpacing: 5,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 2, top: 4),
                    child: Text(
                      'Relevant to you',
                      style: TextStyle(color: _muted, fontSize: 10.5),
                    ),
                  ),
                  for (final tag in matches.take(2))
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _soft,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: _green,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (postTitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 12, 17, 0),
              child: Text(
                postTitle,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
            ),
          if (postText.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(
                17,
                postTitle.isNotEmpty ? 7 : 13,
                17,
                0,
              ),
              child: SelectableText(
                postText,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 14.5,
                  height: 1.55,
                ),
              ),
            ),
          if (post['shared_post_id'] != null)
            Container(
              margin: const EdgeInsets.fromLTRB(17, 13, 17, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _soft,
                borderRadius: BorderRadius.circular(9),
                border: const Border(left: BorderSide(color: _green, width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.repeat_rounded, size: 16, color: _green),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'Shared from ${post['shared_author_name'] ?? 'Resident'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _green,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${post['shared_body'] ?? ''}',
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          if (names.isNotEmpty) ...[
            const SizedBox(height: 15),
            LayoutBuilder(
              builder: (context, constraints) {
                final isDouble = names.length > 1;
                final height = isDouble ? 205.0 : 290.0;
                return SizedBox(
                  height: height,
                  width: double.infinity,
                  child: Row(
                    children: [
                      for (var i = 0; i < names.length; i++) ...[
                        if (i > 0) const SizedBox(width: 4),
                        Expanded(
                          child: InkWell(
                            onTap: () => _openPostImage(
                              context,
                              storage.getPublicUrl(names[i]),
                            ),
                            child: Image.network(
                              storage.getPublicUrl(names[i]),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: height,
                              errorBuilder: (_, _, _) => Container(
                                color: _soft,
                                alignment: Alignment.center,
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.broken_image_outlined,
                                      color: _muted,
                                      size: 28,
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Image unavailable',
                                      style: TextStyle(
                                        color: _muted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 14, 17, 10),
            child: Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _showLikers(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          size: 15,
                          color: liked ? const Color(0xFFB64959) : _green,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$likes',
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'likes',
                          style: TextStyle(color: _muted, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: onComments,
                  child: Text(
                    '$comments comments',
                    style: const TextStyle(color: _muted, fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _line),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: tier2 ? onLike : null,
                    icon: Icon(
                      liked ? Icons.favorite_rounded : Icons.favorite_border,
                      size: 19,
                      color: tier2
                          ? (liked ? const Color(0xFFB64959) : _forest)
                          : Colors.grey,
                    ),
                    label: Text(liked ? 'Liked' : 'Like'),
                    style: TextButton.styleFrom(
                      foregroundColor: liked
                          ? const Color(0xFFB64959)
                          : _forest,
                      textStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: onComments,
                    icon: const Icon(Icons.mode_comment_outlined, size: 19),
                    label: const Text('Comment'),
                    style: TextButton.styleFrom(
                      foregroundColor: _forest,
                      textStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed:
                        tier2 &&
                            post['shared_post_id'] == null &&
                            post['visibility'] != 'private'
                        ? onShare
                        : null,
                    icon: const Icon(Icons.share_outlined, size: 19),
                    label: const Text('Share'),
                    style: TextButton.styleFrom(
                      foregroundColor: _forest,
                      textStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet();
  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  String visibility = 'public';
  final text = TextEditingController();
  String category = 'Community';
  final images = <({Uint8List bytes, String name, String mime})>[];
  bool busy = false;
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (images.length >= 2) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose image'),
              onTap: () => Navigator.pop(c, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo (supported devices)'),
              onTap: () => Navigator.pop(c, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 65,
        maxWidth: 1280,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final mime = picked.mimeType ?? 'image/jpeg';
      if (!['image/jpeg', 'image/png', 'image/webp'].contains(mime)) {
        throw Exception('Please use JPG, PNG or WEBP.');
      }
      if (bytes.lengthInBytes > 204800) {
        throw Exception('Image is over 200 KB. Reduce its size and retry.');
      }
      if (mounted) {
        setState(
          () => images.add((bytes: bytes, name: picked.name, mime: mime)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _submit() async {
    final body = text.text.trim();
    if (body.isEmpty || body.length > 2000) return;
    if (visibility != 'public' && images.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photos are currently supported on Public posts only.'),
        ),
      );
      return;
    }
    setState(() => busy = true);
    final db = Supabase.instance.client;
    final uid = db.auth.currentUser!.id;
    String? postId;
    try {
      final p = await db
          .from('kaisa_feed_posts')
          .insert({
            'author_id': uid,
            'body': body,
            'category': category,
            'visibility': visibility,
          })
          .select('id')
          .single();
      postId = p['id'] as String;
      for (var i = 0; i < images.length; i++) {
        final image = images[i];
        final ext = image.mime == 'image/png'
            ? 'png'
            : image.mime == 'image/webp'
            ? 'webp'
            : 'jpg';
        final path = '$uid/${postId}_${i + 1}.$ext';
        await db.storage
            .from('kaisa-feed')
            .uploadBinary(
              path,
              image.bytes,
              fileOptions: FileOptions(contentType: image.mime, upsert: false),
            );
        await db.from('kaisa_feed_images').insert({
          'post_id': postId,
          'owner_id': uid,
          'storage_path': path,
          'position': i + 1,
        });
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      // A partial post is removed on error, but uploaded orphan media may require scheduled cleanup.
      if (postId != null) {
        try {
          await db.from('kaisa_feed_posts').delete().eq('id', postId);
        } catch (_) {}
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not publish: $e')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 22,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _soft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    size: 24,
                    color: _forest,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NEW COMMUNITY POST',
                        style: TextStyle(
                          color: _green,
                          fontSize: 10,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Share an update',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: _forest,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close without posting',
                  onPressed: busy ? null : () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close_rounded, color: _ink),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Keep your neighbors informed, connected, and inspired.',
              style: TextStyle(color: _muted, fontSize: 13),
            ),
            const SizedBox(height: 22),
            const Text(
              'CATEGORY',
              style: TextStyle(
                color: _forest,
                letterSpacing: 1,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 7),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: InputDecoration(
                prefixIcon: Icon(_categoryIcon(category), color: _green),
                labelText: 'Post category',
                filled: true,
                fillColor: _soft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _line),
                ),
              ),
              items:
                  const ['Community', 'Announcement', 'Event', 'Organization']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
              onChanged: busy
                  ? null
                  : (value) => setState(() => category = value ?? category),
            ),
            const SizedBox(height: 15),
            const Text(
              'WHO CAN SEE THIS?',
              style: TextStyle(
                color: _forest,
                letterSpacing: 1,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 7),
            DropdownButtonFormField<String>(
              initialValue: visibility,
              decoration: InputDecoration(
                prefixIcon: Icon(
                  visibility == 'private'
                      ? Icons.lock_outline_rounded
                      : visibility == 'friends'
                      ? Icons.people_outline_rounded
                      : Icons.public_rounded,
                  color: _green,
                ),
                labelText: 'Audience',
                filled: true,
                fillColor: _soft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _line),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'public',
                  child: Text('Public · Everyone'),
                ),
                DropdownMenuItem(value: 'friends', child: Text('Friends only')),
                DropdownMenuItem(value: 'private', child: Text('Only me')),
              ],
              onChanged: busy
                  ? null
                  : (value) => setState(() {
                      visibility = value ?? 'public';
                      if (visibility != 'public') images.clear();
                    }),
            ),
            if (visibility != 'public')
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 9),
                child: Text(
                  'Photos are currently available for public posts only.',
                  style: TextStyle(fontSize: 12, color: _muted),
                ),
              ),
            const SizedBox(height: 17),
            const Text(
              'YOUR MESSAGE',
              style: TextStyle(
                color: _forest,
                letterSpacing: 1,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 7),
            TextField(
              controller: text,
              onChanged: (_) => setState(() {}),
              minLines: 4,
              maxLines: 8,
              maxLength: 2000,
              decoration: InputDecoration(
                hintText: 'What would you like to share with your community?',
                hintStyle: const TextStyle(color: _muted, fontSize: 14),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _green, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                for (final img in images)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          img.bytes,
                          width: 112,
                          height: 108,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 3,
                        right: 3,
                        child: IconButton.filledTonal(
                          iconSize: 18,
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Remove photo',
                          onPressed: busy
                              ? null
                              : () => setState(() => images.remove(img)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: busy || images.length >= 2 || visibility != 'public'
                  ? null
                  : _add,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text('Add photo (${images.length}/2 · 200 KB each)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _forest,
                side: const BorderSide(color: _line),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy
                        ? null
                        : () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      foregroundColor: _forest,
                      side: const BorderSide(color: _line),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: busy || text.text.trim().isEmpty
                        ? null
                        : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: _forest,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    icon: Icon(
                      busy ? Icons.hourglass_empty_rounded : Icons.send_rounded,
                      size: 18,
                    ),
                    label: Text(busy ? 'Publishing…' : 'Publish post'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({required this.postId, required this.canComment});
  final String postId;
  final bool canComment;
  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final message = TextEditingController();
  List<Map<String, dynamic>> comments = [];
  bool busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    message.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await Supabase.instance.client.rpc(
        'kaisa_feed_comments_for',
        params: {'p_post_id': widget.postId},
      );
      if (mounted) {
        setState(
          () => comments = (data as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to load comments: $e')));
      }
    }
  }

  Future<void> _send() async {
    final content = message.text.trim();
    if (!widget.canComment || content.isEmpty || content.length > 500) return;
    setState(() => busy = true);
    try {
      final db = Supabase.instance.client;
      await db.from('kaisa_feed_comments').insert({
        'post_id': widget.postId,
        'author_id': db.auth.currentUser!.id,
        'body': content,
      });
      message.clear();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not comment: $e')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableHeight =
        (MediaQuery.sizeOf(context).height -
                MediaQuery.viewInsetsOf(context).bottom -
                65)
            .clamp(220.0, 700.0)
            .toDouble();
    return SizedBox(
      height: availableHeight,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(19, 11, 11, 10),
            child: Row(
              children: [
                Container(
                  width: 37,
                  height: 37,
                  decoration: BoxDecoration(
                    color: _soft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.mode_comment_outlined,
                    color: _green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Text(
                    'Comments',
                    style: TextStyle(
                      color: _forest,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close comments',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _line),
          Expanded(
            child: comments.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            color: _sage,
                            size: 42,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No comments yet',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: _ink,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Start the conversation with your community.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    itemCount: comments.length,
                    itemBuilder: (ctx, i) {
                      final item = comments[i];
                      final author = '${item['author_name'] ?? 'Resident'}';
                      final id = '${item['author_id'] ?? ''}';
                      final when = DateTime.tryParse(
                        '${item['created_at'] ?? ''}',
                      )?.toLocal();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: id.isEmpty
                                  ? null
                                  : () {
                                      final router = GoRouter.of(context);
                                      Navigator.pop(context);
                                      router.push(
                                        '/resident/user/$id',
                                        extra: {'name': author},
                                      );
                                    },
                              child: CircleAvatar(
                                radius: 19,
                                backgroundColor: const Color(0xFFE3EEE7),
                                child: Text(
                                  author.isEmpty
                                      ? 'R'
                                      : author[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: _forest,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  InkWell(
                                    onTap: id.isEmpty
                                        ? null
                                        : () {
                                            final router = GoRouter.of(context);
                                            Navigator.pop(context);
                                            router.push(
                                              '/resident/user/$id',
                                              extra: {'name': author},
                                            );
                                          },
                                    child: Text(
                                      author,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: _forest,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${item['body'] ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      color: _ink,
                                      height: 1.45,
                                    ),
                                  ),
                                  if (when != null) ...[
                                    const SizedBox(height: 5),
                                    Text(
                                      _relativeTime(when),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: _muted,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1, color: _line),
          if (!widget.canComment)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: TextButton.icon(
                onPressed: () {
                  final router = GoRouter.of(context);
                  Navigator.pop(context);
                  router.push('/resident/identity-verification');
                },
                icon: const Icon(Icons.verified_user_outlined),
                label: const Text('Verify your account to comment'),
                style: TextButton.styleFrom(foregroundColor: _forest),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 11, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: message,
                      maxLength: 500,
                      minLines: 1,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) {
                        if (!busy) _send();
                      },
                      decoration: InputDecoration(
                        hintText: 'Write a comment…',
                        counterText: '',
                        isDense: true,
                        filled: true,
                        fillColor: _soft,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    tooltip: 'Post comment',
                    style: IconButton.styleFrom(backgroundColor: _forest),
                    onPressed: busy ? null : _send,
                    icon: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Edit existing profile-style choices without requiring database migrations.
class _FeedPreferencesDialog extends StatefulWidget {
  const _FeedPreferencesDialog({required this.interests, required this.skills});
  final List<String> interests;
  final List<String> skills;

  @override
  State<_FeedPreferencesDialog> createState() => _FeedPreferencesDialogState();
}

class _FeedPreferencesDialogState extends State<_FeedPreferencesDialog> {
  late final Set<String> selectedInterests = {...widget.interests};
  late final Set<String> selectedSkills = {...widget.skills};

  Widget _choices(List<String> choices, Set<String> selected) => Wrap(
    spacing: 8,
    runSpacing: 6,
    children: [
      for (final value in choices)
        FilterChip(
          selected: selected.contains(value),
          label: Text(value, style: const TextStyle(fontSize: 12)),
          selectedColor: const Color(0xFFDDEFE3),
          checkmarkColor: _forest,
          side: BorderSide(color: selected.contains(value) ? _green : _line),
          onSelected: (checked) => setState(() {
            if (checked) {
              selected.add(value);
            } else {
              selected.remove(value);
            }
          }),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 18),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 570),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.interests_rounded, color: _forest),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    'Personalize your feed',
                    style: TextStyle(
                      color: _forest,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const Text(
              'Choose the same interests and skills used in KAISA Profile Setup. '
              'These help order posts that you already have permission to view.',
              style: TextStyle(fontSize: 12.5, color: _muted, height: 1.45),
            ),
            const SizedBox(height: 13),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'COMMUNITY INTERESTS',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: _green,
                        letterSpacing: 1,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _choices(_kaisaInterests, selectedInterests),
                    const SizedBox(height: 18),
                    const Text(
                      'YOUR SKILLS',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: _green,
                        letterSpacing: 1,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _choices(_kaisaSkills, selectedSkills),
                  ],
                ),
              ),
            ),
            const Divider(height: 23),
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() {
                    selectedInterests.clear();
                    selectedSkills.clear();
                  }),
                  child: const Text('Clear all'),
                ),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _forest),
                  onPressed: () => Navigator.pop(context, (
                    interests: selectedInterests.toList(),
                    skills: selectedSkills.toList(),
                  )),
                  child: const Text('Save preferences'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Facebook-like discovery modal, intentionally limited to posts and authors
/// returned by kaisa_feed_stream. No public user directory is queried.
class _FeedSmartSearchDialog extends StatefulWidget {
  const _FeedSmartSearchDialog({
    required this.posts,
    required this.initialQuery,
  });
  final List<Map<String, dynamic>> posts;
  final String initialQuery;
  @override
  State<_FeedSmartSearchDialog> createState() => _FeedSmartSearchDialogState();
}

class _FeedSmartSearchDialogState extends State<_FeedSmartSearchDialog> {
  late final TextEditingController controller = TextEditingController(
    text: widget.initialQuery,
  );
  String tab = 'All';
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = controller.text.trim();
    final foundPosts =
        widget.posts.where((post) => _postSearchScore(post, query) > 0).toList()
          ..sort(
            (a, b) => _postSearchScore(
              b,
              query,
            ).compareTo(_postSearchScore(a, query)),
          );
    final people = <String, Map<String, String>>{};
    for (final post in widget.posts) {
      final id = '${post['author_id'] ?? ''}';
      final name = '${post['author_name'] ?? ''}'.trim();
      if (id.isEmpty || name.isEmpty) continue;
      if (query.isEmpty ||
          _termMatch(name, query) ||
          _normalized(query).split(' ').every((t) => _termMatch(name, t))) {
        people[id] = {
          'name': name,
          'id': id,
          'avatar_path':
              '${post['author_avatar_path'] ?? post['avatar_path'] ?? ''}',
        };
      }
    }
    final categories = <String>{};
    for (final post in widget.posts) {
      final category = '${post['category'] ?? ''}';
      if (category.isNotEmpty &&
          (query.isEmpty || _termMatch(category, query))) {
        categories.add(category);
      }
    }
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: SizedBox(
          height:
              (MediaQuery.sizeOf(context).height -
                      MediaQuery.viewInsetsOf(context).bottom -
                      50)
                  .clamp(210.0, 680.0)
                  .toDouble(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 12, 7, 11),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: _forest, size: 23),
                    const SizedBox(width: 9),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (value) =>
                            Navigator.pop(context, value.trim()),
                        decoration: const InputDecoration(
                          hintText: 'Search people, posts, or topics',
                          hintStyle: TextStyle(color: _muted, fontSize: 14),
                          border: InputBorder.none,
                          filled: false,
                        ),
                      ),
                    ),
                    if (query.isNotEmpty)
                      IconButton(
                        onPressed: () => setState(() => controller.clear()),
                        icon: const Icon(Icons.close, color: _muted),
                        tooltip: 'Clear',
                      ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Close search',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: _line),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    for (final name in const ['All', 'Posts', 'People'])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(name),
                          selected: tab == name,
                          onSelected: (_) => setState(() => tab = name),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 2, 14, 12),
                  children: [
                    if (tab != 'Posts' && people.isNotEmpty) ...[
                      const _SearchGroupTitle('PEOPLE IN YOUR COMMUNITY FEED'),
                      for (final person in people.values.take(
                        query.isEmpty ? 4 : 8,
                      ))
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 5,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: _soft,
                            child: Text(
                              person['name']![0].toUpperCase(),
                              style: const TextStyle(
                                color: _forest,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          title: Text(
                            person['name']!,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: const Text(
                            'View resident profile',
                            style: TextStyle(fontSize: 11.5, color: _muted),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            final router = GoRouter.of(context);
                            Navigator.pop(context);
                            router.push(
                              '/resident/user/${person['id']}',
                              extra: {
                                'name': person['name'],
                                'avatar_path': person['avatar_path'],
                              },
                            );
                          },
                        ),
                    ],
                    if (tab == 'All' && categories.isNotEmpty) ...[
                      const _SearchGroupTitle('TOPICS'),
                      Wrap(
                        spacing: 7,
                        runSpacing: 5,
                        children: [
                          for (final topic in categories)
                            ActionChip(
                              avatar: Icon(
                                _categoryIcon(topic),
                                size: 16,
                                color: _forest,
                              ),
                              label: Text(topic),
                              onPressed: () => Navigator.pop(context, topic),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (tab != 'People') ...[
                      const _SearchGroupTitle('MATCHING POSTS'),
                      if (foundPosts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(18),
                          child: Text(
                            'No matching posts in your current feed.',
                            style: TextStyle(color: _muted),
                          ),
                        )
                      else
                        for (final post in foundPosts.take(12))
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 5,
                            ),
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: _categoryTint(
                                  '${post['category'] ?? 'Community'}',
                                ),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Icon(
                                _categoryIcon('${post['category'] ?? ''}'),
                                color: _forest,
                                size: 21,
                              ),
                            ),
                            title: Text(
                              '${post['author_name'] ?? 'Resident'} · '
                              '${post['category'] ?? 'Community'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${post['body'] ?? ''}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                            onTap: () => Navigator.pop(
                              context,
                              query.isEmpty
                                  ? '${post['author_name'] ?? ''}'
                                  : query,
                            ),
                          ),
                    ],
                    if (tab == 'People' && people.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(18),
                        child: Text(
                          'No matching residents in loaded posts.',
                          style: TextStyle(color: _muted),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1, color: _line),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 9, 16, 13),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Searches posts already visible to your account.',
                        style: TextStyle(fontSize: 11, color: _muted),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => Navigator.pop(context, query),
                      icon: const Icon(Icons.search_rounded, size: 17),
                      label: const Text('Search'),
                      style: FilledButton.styleFrom(backgroundColor: _forest),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchGroupTitle extends StatelessWidget {
  const _SearchGroupTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(5, 12, 5, 7),
    child: Text(
      title,
      style: const TextStyle(
        color: _green,
        fontSize: 10,
        letterSpacing: .9,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _CreateStoryDialog extends StatefulWidget {
  const _CreateStoryDialog();
  @override
  State<_CreateStoryDialog> createState() => _CreateStoryDialogState();
}

class _CreateStoryDialogState extends State<_CreateStoryDialog> {
  final caption = TextEditingController();
  XFile? photo;
  Uint8List? bytes;
  String visibility = 'public';
  bool saving = false;
  @override
  void dispose() {
    caption.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1400,
      );
      if (file == null) return; // Camera/gallery dismissed.
      final value = await file.readAsBytes();
      if (value.lengthInBytes > 2097152) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Story image must be under 2 MB')),
          );
        }
        return;
      }
      if (mounted) {
        setState(() {
          photo = file;
          bytes = value;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to open camera or photos: $e')),
        );
      }
    }
  }

  Future<void> _captureCamera() async {
    try {
      final captured = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(builder: (_) => const _StoryCameraScreen()),
      );
      if (captured == null || !mounted) return;
      if (captured.lengthInBytes > 2097152) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Story image must be under 2 MB')),
        );
        return;
      }
      setState(() {
        bytes = captured;
        photo = null; // Camera's takePicture() returns JPEG bytes.
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to capture photo: $e')));
      }
    }
  }

  Future<void> _save() async {
    if (caption.text.trim().isEmpty && bytes == null) return;
    setState(() => saving = true);
    final db = Supabase.instance.client;
    final uid = db.auth.currentUser!.id;
    String? path;
    try {
      if (bytes != null) {
        final mime = (photo?.mimeType?.toLowerCase() == 'image/png')
            ? 'image/png'
            : (photo?.mimeType?.toLowerCase() == 'image/webp')
            ? 'image/webp'
            : 'image/jpeg';
        if (!['image/jpeg', 'image/png', 'image/webp'].contains(mime)) {
          throw Exception('Use JPG, PNG or WEBP');
        }
        final ext = mime == 'image/png'
            ? 'png'
            : mime == 'image/webp'
            ? 'webp'
            : 'jpg';
        path = '$uid/${DateTime.now().microsecondsSinceEpoch}.$ext';
        await db.storage
            .from('kaisa-stories')
            .uploadBinary(
              path,
              bytes!,
              fileOptions: FileOptions(contentType: mime, upsert: false),
            );
      }
      await db.from('kaisa_stories').insert({
        'author_id': uid,
        'caption': caption.text.trim(),
        'visibility': visibility,
        'image_path': path,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (path != null) {
        try {
          await db.storage.from('kaisa-stories').remove([path]);
        } catch (_) {}
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not publish story: $e')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Create a story',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: saving ? null : () => Navigator.pop(context, false),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Text('Visible for 24 hours', style: TextStyle(color: _muted)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: visibility,
            decoration: const InputDecoration(labelText: 'Audience'),
            items: const [
              DropdownMenuItem(value: 'public', child: Text('Public')),
              DropdownMenuItem(value: 'friends', child: Text('Friends')),
              DropdownMenuItem(value: 'private', child: Text('Only me')),
            ],
            onChanged: saving
                ? null
                : (v) => setState(() => visibility = v ?? 'public'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: caption,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Write a story...'),
          ),
          if (bytes != null)
            Image.memory(bytes!, height: 180, fit: BoxFit.contain),
          OutlinedButton.icon(
            onPressed: saving ? null : _captureCamera,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Take a photo with camera'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: saving ? null : () => _pick(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Choose from gallery'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: saving ? null : () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: saving ? null : _save,
            child: Text(saving ? 'Publishing...' : 'Share story'),
          ),
        ],
      ),
    ),
  );
}

/// Uses the same `camera` plugin as KAISA ID verification, on Android and web.
class _StoryCameraScreen extends StatefulWidget {
  const _StoryCameraScreen();
  @override
  State<_StoryCameraScreen> createState() => _StoryCameraScreenState();
}

class _StoryCameraScreenState extends State<_StoryCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _capturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize([int? selectedIndex]) async {
    final old = _controller;
    _controller = null;
    if (mounted) setState(() => _error = null);
    await old?.dispose();
    try {
      final devices = await availableCameras();
      if (devices.isEmpty) {
        throw StateError('No camera was detected on this device.');
      }
      _cameras = devices;
      _cameraIndex =
          selectedIndex ??
          devices.indexWhere(
            (d) => d.lensDirection == CameraLensDirection.front,
          );
      if (_cameraIndex < 0 || _cameraIndex >= devices.length) _cameraIndex = 0;
      final next = CameraController(
        devices[_cameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await next.initialize();
      if (!mounted) {
        await next.dispose();
        return;
      }
      setState(() => _controller = next);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error =
              'Camera unavailable: $e\n\nCheck browser/device camera permissions and close other apps using the camera.',
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      final previous = _controller;
      _controller = null;
      previous?.dispose();
    } else if (state == AppLifecycleState.resumed && mounted) {
      _initialize(_cameraIndex);
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (_capturing || controller == null || !controller.value.isInitialized) {
      return;
    }
    setState(() => _capturing = true);
    try {
      final picture = await controller.takePicture();
      final data = await picture.readAsBytes();
      if (mounted) Navigator.of(context).pop(data);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not take photo: $e');
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: const Color(0xFF101C15),
      appBar: AppBar(
        title: const Text('Take a Story Photo'),
        backgroundColor: const Color(0xFF101C15),
        foregroundColor: Colors.white,
        leading: IconButton(
          tooltip: 'Close camera',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                      )
                    : controller == null || !controller.value.isInitialized
                    ? const CircularProgressIndicator()
                    : AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: CameraPreview(controller),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_cameras.length > 1)
                    IconButton(
                      tooltip: 'Switch camera',
                      onPressed: _capturing
                          ? null
                          : () => _initialize(
                              (_cameraIndex + 1) % _cameras.length,
                            ),
                      icon: const Icon(
                        Icons.cameraswitch_outlined,
                        color: Colors.white,
                      ),
                    ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: controller == null || _capturing
                        ? null
                        : _capture,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(_capturing ? 'Capturing...' : 'Capture photo'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
