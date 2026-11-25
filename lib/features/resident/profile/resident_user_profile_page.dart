import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Read-only resident profile. The data comes from KAISA's existing Supabase
// profile table and feed RPC; it does not change any database records.
class ResidentUserProfilePage extends StatefulWidget {
  const ResidentUserProfilePage({
    super.key,
    required this.userId,
    this.initialName,
    this.initialAvatarPath,
  });

  final String userId;

  // Optional information already visible in the Feed. Useful when profile RLS
  // does not allow the current resident to read someone else's profile row.
  final String? initialName;
  final String? initialAvatarPath;

  @override
  State<ResidentUserProfilePage> createState() =>
      _ResidentUserProfilePageState();
}

class _ResidentUserProfilePageState extends State<ResidentUserProfilePage> {
  static const _forest = Color(0xFF00301B);
  static const _green = Color(0xFF2C6A4A);
  static const _gold = Color(0xFFFDBC19);
  static const _paper = Color(0xFFF9FAF9);
  static const _muted = Color(0xFF66736B);
  static const _line = Color(0xFFE5ECE7);

  final _db = Supabase.instance.client;
  bool _loading = true;
  bool _profileReadable = false;
  String? _profileError;
  String? _postsError;
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _visiblePosts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _name {
    final profile = _profile;
    if (profile != null) {
      final parts = [profile['first_name'], profile['last_name']]
          .where((value) => value != null && '$value'.trim().isNotEmpty)
          .map((value) => value.toString().trim())
          .toList();
      if (parts.isNotEmpty) return parts.join(' ');
    }
    final fromFeed = widget.initialName?.trim() ?? '';
    return fromFeed.isNotEmpty ? fromFeed : 'KAISA Resident';
  }

  String? get _avatarUrl {
    final raw = (_profile?['avatar_path'] ?? widget.initialAvatarPath ?? '')
        .toString()
        .trim();
    if (raw.isEmpty) return null;
    if (raw.startsWith('https://')) return raw;
    return _db.storage.from('kaisa-avatars').getPublicUrl(raw);
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    Map<String, dynamic>? profile;
    String? profileError;
    String? postsError;
    List<Map<String, dynamic>> visiblePosts = [];
    var profileReadable = false;

    try {
      // Only request public-facing fields. Never fetch addresses, birth dates,
      // phone numbers, government IDs, or other private resident data.
      profile = await _db
          .from('resident_profiles')
          .select('first_name,last_name,avatar_path')
          .eq('user_id', widget.userId)
          .maybeSingle();
      profileReadable = profile != null;
      if (profile == null) {
        profileError = 'Public profile information is unavailable.';
      }
    } catch (_) {
      // This is common if resident_profiles RLS allows self-read only.
      // Keep the name/avatar passed from the already-authorized Feed view.
      profileError = 'Additional profile details are not available.';
    }

    try {
      // This is the same visibility-aware RPC already used by the Feed page.
      // Only display posts included in the current viewer's feed response.
      final result = await _db.rpc('kaisa_feed_stream');
      if (result is List) {
        visiblePosts = result
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .where((item) => item['author_id']?.toString() == widget.userId)
            .toList();
        visiblePosts.sort((a, b) {
          final left = DateTime.tryParse('${a['created_at'] ?? ''}');
          final right = DateTime.tryParse('${b['created_at'] ?? ''}');
          return (right ?? DateTime(1970)).compareTo(left ?? DateTime(1970));
        });
      }
    } catch (_) {
      postsError = 'Posts are temporarily unavailable.';
    }

    if (!mounted) return;
    setState(() {
      _profile = profile;
      _profileReadable = profileReadable;
      _profileError = profileError;
      _postsError = postsError;
      _visiblePosts = visiblePosts;
      _loading = false;
    });
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/resident/feed');
    }
  }

  Widget _avatar(double size) {
    final url = _avatarUrl;
    final initial = _name.isEmpty ? 'R' : _name[0].toUpperCase();
    final fallback = Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * .4,
          fontWeight: FontWeight.w800,
          color: _forest,
        ),
      ),
    );
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE3F0E7),
        border: Border.all(color: Colors.white, width: 4),
      ),
      child: url == null
          ? fallback
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            ),
    );
  }

  Widget _postCard(Map<String, dynamic> post) {
    final date = DateTime.tryParse('${post['created_at'] ?? ''}')?.toLocal();
    final category = '${post['category'] ?? 'Community'}';
    final body = '${post['body'] ?? ''}'.trim();
    final images = (post['images'] is List)
        ? (post['images'] as List)
              .map((item) => item.toString())
              .where((path) => path.isNotEmpty)
              .toList()
        : <String>[];
    final imageUrl = images.isEmpty
        ? null
        : _db.storage.from('kaisa-feed').getPublicUrl(images.first);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 17, 18, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F2EB),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: _green,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      date == null
                          ? 'Recently'
                          : '${date.month}/${date.day}/${date.year}',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    body,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF172820),
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  '${post['likes'] ?? 0} likes  ·  ${post['comments'] ?? 0} comments',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (imageUrl != null)
            Image.network(
              imageUrl,
              width: double.infinity,
              height: 185,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSelf = _db.auth.currentUser?.id == widget.userId;
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _paper,
        foregroundColor: _forest,
        title: const Text(
          'Resident profile',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        leading: IconButton(
          tooltip: 'Back to community',
          onPressed: _back,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh profile',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 830),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 72),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: _forest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 78,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_forest, Color(0xFF176141)],
                            ),
                          ),
                          alignment: Alignment.topRight,
                          padding: const EdgeInsets.all(17),
                          child: const Icon(
                            Icons.diversity_3_rounded,
                            color: _gold,
                            size: 28,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(21, 0, 21, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Transform.translate(
                                offset: const Offset(0, -29),
                                child: _avatar(80),
                              ),
                              Transform.translate(
                                offset: const Offset(0, -12),
                                child: Text(
                                  _name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 25,
                                  ),
                                ),
                              ),
                              const Text(
                                'KAISA community member',
                                style: TextStyle(
                                  color: Color(0xFFD4E8DA),
                                  fontSize: 13,
                                ),
                              ),
                              if (isSelf) ...[
                                const SizedBox(height: 18),
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      context.go('/resident/profile'),
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Open my profile'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: Color(0xFF9EC4AA),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_loading &&
                      !_profileReadable &&
                      _profileError != null &&
                      (widget.initialName == null ||
                          widget.initialName!.trim().isEmpty)) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'This resident\'s public profile information is unavailable. '
                      'Profile visibility depends on KAISA access permissions.',
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Community posts',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: _forest,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => context.go('/resident/feed'),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                        iconAlignment: IconAlignment.end,
                        label: const Text('Community Feed'),
                      ),
                    ],
                  ),
                  const Text(
                    'Posts from this resident that are visible to your account.',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                  const SizedBox(height: 15),
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(color: _green),
                      ),
                    )
                  else if (_postsError != null)
                    _notice(_postsError!)
                  else if (_visiblePosts.isEmpty)
                    _notice(
                      'No posts from this resident are visible to you right now.',
                    )
                  else
                    for (final post in _visiblePosts.take(15)) ...[
                      _postCard(post),
                      const SizedBox(height: 12),
                    ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _notice(String message) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        const Icon(Icons.forum_outlined, color: _green, size: 28),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted),
        ),
      ],
    ),
  );
}
