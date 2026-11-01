import 'dart:typed_data';
import 'dart:async';
import '../widgets/kaisa_account_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/kaisa_resident_design.dart';

const _forest = Color(0xFF14532D);
const _green = Color(0xFF237A50);
const _yellow = Color(0xFFFBC02D);
const _ink = Color(0xFF173D2B);
const _muted = Color(0xFF69786F);

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});
  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final db = Supabase.instance.client;
  List<Map<String, dynamic>> posts = [];
  String filter = 'All';
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
      if (!mounted) return;
      setState(() {
        displayName = [
          value?['first_name'],
          value?['last_name'],
        ].where((v) => v != null && '$v'.trim().isNotEmpty).join(' ');
        if (displayName.isEmpty) displayName = 'KAISA Resident';
        avatarPath = '${value?['avatar_path'] ?? ''}';
      });
    } catch (_) {
      // Keep a safe avatar fallback without hiding the Feed on profile errors.
    }
  }

  Future<void> _load() async {
    if (mounted)
      setState(() {
        loading = true;
        error = null;
      });
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
      if (mounted)
        setState(
          () => error =
              'Unable to load community posts. Check your connection or migration. ($e)',
        );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loadStories() async {
    try {
      final result = await db.rpc('kaisa_active_stories');
      if (mounted)
        setState(
          () => stories = (result as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
        );
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
        backgroundColor: _forest,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${story['author_name']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
                if (url != null)
                  Image.network(url, height: 320, fit: BoxFit.contain),
                const SizedBox(height: 12),
                Text(
                  '${story['caption'] ?? ''}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _storiesStrip() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Text(
          'Stories · 24 hours',
          style: TextStyle(
            color: _ink,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
      SizedBox(
        height: 112,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            SizedBox(
              width: 94,
              child: InkWell(
                onTap: _createStory,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 31,
                      backgroundColor: const Color(0xFFE2F1E6),
                      child: Icon(
                        tier2 ? Icons.add_rounded : Icons.lock_outline,
                        color: _forest,
                        size: 27,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      tier2 ? 'Your story' : 'Verify',
                      style: const TextStyle(fontSize: 12, color: _ink),
                    ),
                  ],
                ),
              ),
            ),
            for (final story in stories)
              SizedBox(
                width: 96,
                child: InkWell(
                  onTap: () => _viewStory(story),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 31,
                        backgroundColor: Color(0xFFE2F1E6),
                        child: Icon(Icons.auto_stories, color: _forest),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '${story['author_name']}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, color: _ink),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 12),
    ],
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
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          _CommentsSheet(postId: post['id'] as String, canComment: tier2),
    );
    await _load();
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
                  'Discover more',
                  '/resident/search',
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
                  'Messages',
                  '/resident/messages',
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
      borderRadius: BorderRadius.circular(18),
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
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: KaisaResidentDesign.border),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        Row(
          children: [
            _avatar(radius: 21),
            const SizedBox(width: 11),
            Expanded(
              child: Material(
                color: const Color(0xFFF2F5F2),
                borderRadius: BorderRadius.circular(30),
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: _compose,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 18,
                    ),
                    child: Text(
                      tier2
                          ? "What's on your mind, $displayName?"
                          : 'Get verified to share a post',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: _muted),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        const Divider(height: 1, color: Color(0xFFEBEFEB)),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: _compose,
                icon: const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: _green,
                ),
                label: const Text('Photo', style: TextStyle(color: _ink)),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: _compose,
                icon: const Icon(Icons.edit_note_outlined, color: _green),
                label: Text(
                  tier2 ? 'Write a post' : 'Verify',
                  style: const TextStyle(color: _ink),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _feedMain(List<Map<String, dynamic>> shown) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COMMUNITY CONNECTIONS',
                  style: TextStyle(
                    color: _green,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Community Feed',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh posts',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, color: _forest),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _storiesStrip(),
      _composer(),
      const SizedBox(height: 18),
      SizedBox(
        height: 46,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final f in const [
              'All',
              'Community',
              'Announcement',
              'Event',
              'Organization',
            ])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f),
                  selected: filter == f,
                  selectedColor: const Color(0xFFE2F1E6),
                  onSelected: (_) => setState(() => filter = f),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      if (loading)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 50),
          child: Center(child: CircularProgressIndicator(color: _green)),
        )
      else if (error != null)
        _feedNotice(error!, action: 'Try again', onTap: _load)
      else if (shown.isEmpty)
        _feedNotice(
          'No community posts found yet.',
          action: tier2 ? 'Create the first post' : 'Get verified',
          onTap: _compose,
        )
      else
        for (final post in shown) ...[
          _PostCard(
            post: post,
            tier2: tier2,
            onLike: () => _toggleLike(post),
            onComments: () => _comments(post),
            onShare: () => _share(post),
          ),
          const SizedBox(height: 14),
        ],
    ],
  );

  Widget _feedNotice(
    String message, {
    required String action,
    required VoidCallback onTap,
  }) => Container(
    padding: const EdgeInsets.all(28),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: KaisaResidentDesign.border),
    ),
    child: Column(
      children: [
        const Icon(Icons.forum_outlined, color: _green, size: 37),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        TextButton(onPressed: onTap, child: Text(action)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final shown = posts
        .where((p) => filter == 'All' || p['category'] == filter)
        .toList();
    final wide = size.width >= 1200;
    final medium = size.width >= 850 && !wide;
    return Scaffold(
      backgroundColor: KaisaResidentDesign.paper,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              size.width < 560 ? 12 : 22,
              20,
              size.width < 560 ? 12 : 22,
              100,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (wide) ...[
                      Expanded(flex: 3, child: _sidebar(false)),
                      const SizedBox(width: 20),
                    ],
                    Expanded(
                      flex: wide
                          ? 7
                          : medium
                          ? 7
                          : 1,
                      child: _feedMain(shown),
                    ),
                    if (wide || medium) ...[
                      const SizedBox(width: 20),
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
    required this.onLike,
    required this.onComments,
    required this.onShare,
  });
  final Map<String, dynamic> post;
  final bool tier2;
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
      if (context.mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not load likes: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse('${post['created_at']}')?.toLocal();
    final names = (post['images'] as List? ?? []).cast<String>();
    final storage = Supabase.instance.client.storage.from('kaisa-feed');
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KaisaResidentDesign.cardRadius),
        side: const BorderSide(color: KaisaResidentDesign.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(KaisaResidentDesign.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () =>
                      context.push('/resident/user/${post['author_id']}'),
                  borderRadius: BorderRadius.circular(40),
                  child: CircleAvatar(
                    backgroundColor: const Color(0xFFE5F3E9),
                    child: Text(
                      (post['author_name'] as String? ?? 'R')
                          .substring(0, 1)
                          .toUpperCase(),
                      style: const TextStyle(
                        color: _forest,
                        fontWeight: FontWeight.bold,
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
                        onTap: () =>
                            context.push('/resident/user/${post['author_id']}'),
                        child: Text(
                          '${post['author_name']}',
                          style: const TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '${post['category']}  •  ${date == null ? 'Recently' : '${date.day}/${date.month}/${date.year}'}',
                        style: const TextStyle(fontSize: 12, color: _muted),
                      ),
                    ],
                  ),
                ),
                Icon(
                  post['visibility'] == 'private'
                      ? Icons.lock_outline
                      : post['visibility'] == 'friends'
                      ? Icons.people_outline
                      : Icons.public_rounded,
                  color: _muted,
                  size: 17,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${post['body']}',
              style: const TextStyle(color: _ink, height: 1.5, fontSize: 15),
            ),
            if (post['shared_post_id'] != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F7F3),
                  border: Border.all(color: KaisaResidentDesign.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shared from ${post['shared_author_name'] ?? 'Resident'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('${post['shared_body'] ?? ''}'),
                  ],
                ),
              ),
            if (names.isNotEmpty) ...[
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, c) => Row(
                  children: [
                    for (var i = 0; i < names.length; i++)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: i == 0 && names.length > 1 ? 8 : 0,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              storage.getPublicUrl(names[i]),
                              height: 260,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(
                                height: 260,
                                child: Center(
                                  child: Icon(Icons.broken_image_outlined),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _showLikers(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${post['likes']} likes  •  ${post['comments']} comments',
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
              ),
            ),
            const Divider(height: 23, color: Color(0xFFE3EBE5)),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: tier2 ? onLike : null,
                    icon: Icon(
                      post['liked'] == true
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: post['liked'] == true ? Colors.redAccent : _green,
                    ),
                    label: const Text('Like'),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: onComments,
                    icon: const Icon(Icons.chat_bubble_outline, color: _green),
                    label: const Text('Comment'),
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
                    icon: const Icon(Icons.share_outlined, color: _green),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
          ],
        ),
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
      if (!['image/jpeg', 'image/png', 'image/webp'].contains(mime))
        throw Exception('Please use JPG, PNG or WEBP.');
      if (bytes.lengthInBytes > 204800)
        throw Exception('Image is over 200 KB. Reduce its size and retry.');
      if (mounted)
        setState(
          () => images.add((bytes: bytes, name: picked.name, mime: mime)),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
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
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not publish: $e')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Create a community post',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      color: _ink,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close without posting',
                  onPressed: busy ? null : () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Share news, activities, and stories with your neighbors.',
              style: TextStyle(color: _muted),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(labelText: 'Post category'),
              items: const [
                'Community',
                'Announcement',
                'Event',
                'Organization',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => category = v ?? category),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: visibility,
              decoration: const InputDecoration(labelText: 'Audience'),
              items: const [
                DropdownMenuItem(
                  value: 'public',
                  child: Text('Public · Everyone'),
                ),
                DropdownMenuItem(
                  value: 'friends',
                  child: Text('Friends · Accepted friends only'),
                ),
                DropdownMenuItem(value: 'private', child: Text('Only me')),
              ],
              onChanged: busy
                  ? null
                  : (v) => setState(() {
                      visibility = v ?? 'public';
                      if (visibility != 'public') images.clear();
                    }),
            ),
            if (visibility != 'public')
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Private/Friends photos will be available after secure media migration.',
                  style: TextStyle(fontSize: 12, color: _muted),
                ),
              ),
            const SizedBox(height: 10),
            TextField(
              controller: text,
              onChanged: (_) => setState(() {}),
              minLines: 3,
              maxLines: 7,
              maxLength: 2000,
              decoration: const InputDecoration(
                hintText: 'What would you like to share?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final img in images)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          img.bytes,
                          width: 110,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton.filledTonal(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: busy
                              ? null
                              : () => setState(() => images.remove(img)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            TextButton.icon(
              onPressed: busy || images.length >= 2 || visibility != 'public'
                  ? null
                  : _add,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text('Add photos (${images.length}/2, max 200 KB each)'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: busy ? null : () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _forest),
                onPressed: busy || text.text.trim().isEmpty ? null : _submit,
                child: Text(busy ? 'Publishing...' : 'Publish post'),
              ),
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
      if (mounted)
        setState(
          () => comments = (data as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to load comments: $e')));
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
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not comment: $e')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .55,
        child: Column(
          children: [
            const Text(
              'Community comments',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: comments.isEmpty
                  ? const Center(
                      child: Text('No comments yet. Start the conversation!'),
                    )
                  : ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (c, i) => ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person_outline),
                        ),
                        onTap: () {
                          final author = comments[i]['author_id']?.toString();
                          if (author != null && author.isNotEmpty) {
                            Navigator.pop(context);
                            context.push('/resident/user/$author');
                          }
                        },
                        title: Text(
                          '${comments[i]['author_name']}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text('${comments[i]['body']}'),
                      ),
                    ),
            ),
            if (!widget.canComment)
              const Padding(
                padding: EdgeInsets.all(10),
                child: Text('Tier 2 verification required to comment.'),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: message,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        hintText: 'Write a comment…',
                        counterText: '',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: busy ? null : _send,
                    icon: const Icon(Icons.send_rounded, color: _green),
                  ),
                ],
              ),
          ],
        ),
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
      if (mounted)
        setState(() {
          photo = file;
          bytes = value;
        });
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
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to capture photo: $e')));
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
        if (!['image/jpeg', 'image/png', 'image/webp'].contains(mime))
          throw Exception('Use JPG, PNG or WEBP');
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
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not publish story: $e')));
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
      if (devices.isEmpty)
        throw StateError('No camera was detected on this device.');
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
      if (mounted)
        setState(
          () => _error =
              'Camera unavailable: $e\n\nCheck browser/device camera permissions and close other apps using the camera.',
        );
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
    if (_capturing || controller == null || !controller.value.isInitialized)
      return;
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
