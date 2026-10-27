import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  String? error;
  @override
  void initState() {
    super.initState();
    _load();
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

  Future<void> _compose() async {
    if (!tier2) {
      context.push('/resident/identity-verification');
      return;
    }
    final posted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CreatePostSheet(),
    );
    if (posted == true) await _load();
  }

  Future<void> _toggleLike(Map<String, dynamic> post) async {
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
      builder: (_) => _CommentsSheet(postId: post['id'] as String),
    );
    await _load();
  }

  Future<void> _share(Map<String, dynamic> post) async {
    // Copyable web URL. The feed route can accept ?post=... for future deep-link emphasis.
    final origin = Uri.base;
    final url = origin.replace(
      path: '/resident/feed',
      queryParameters: {'post': post['id'].toString()},
      fragment: '',
    );
    await Clipboard.setData(ClipboardData(text: url.toString()));
    _snack('Post link copied! Share it with your community.');
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final shown = posts
        .where((p) => filter == 'All' || p['category'] == filter)
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      floatingActionButton: width < 650 && tier2
          ? FloatingActionButton.extended(
              backgroundColor: _forest,
              foregroundColor: Colors.white,
              onPressed: _compose,
              icon: const Icon(Icons.edit_square),
              label: const Text('Create post'),
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 950),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        width < 650 ? 16 : 28,
                        24,
                        width < 650 ? 16 : 28,
                        8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'Community Feed',
                                      style: TextStyle(
                                        color: _ink,
                                        fontSize: 29,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      'Stories, voices and updates from your community.',
                                      style: TextStyle(color: _muted),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Refresh',
                                onPressed: _load,
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  color: _forest,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Notifications',
                                onPressed: () =>
                                    context.push('/resident/notifications'),
                                icon: const Icon(
                                  Icons.notifications_none_rounded,
                                  color: _forest,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_forest, Color(0xFF28774B)],
                              ),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.groups_rounded,
                                  color: _yellow,
                                  size: 36,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tier2
                                            ? 'Your community has a voice'
                                            : 'Your voice matters',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 17,
                                        ),
                                      ),
                                      Text(
                                        tier2
                                            ? 'Share a story or community update today.'
                                            : 'Get Tier 2 verified by the LGU to publish posts.',
                                        style: const TextStyle(
                                          color: Color(0xFFD9EEE0),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (width >= 680)
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _yellow,
                                      foregroundColor: _forest,
                                    ),
                                    onPressed: _compose,
                                    child: Text(
                                      tier2 ? 'Write a post' : 'Get verified',
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (width < 680)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _compose,
                                icon: Icon(
                                  tier2
                                      ? Icons.add_circle_outline
                                      : Icons.verified_user_outlined,
                                ),
                                label: Text(
                                  tier2
                                      ? 'Write a post'
                                      : 'Apply for Tier 2 verification',
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final f in const [
                                  'All',
                                  'Community',
                                  'Announcement',
                                  'Event',
                                  'Organization',
                                ])
                                  Padding(
                                    padding: const EdgeInsets.only(right: 7),
                                    child: ChoiceChip(
                                      label: Text(f),
                                      selected: filter == f,
                                      onSelected: (_) =>
                                          setState(() => filter = f),
                                      selectedColor: const Color(0xFFE3F1E7),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (loading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: _green),
                  ),
                )
              else if (error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(error!, textAlign: TextAlign.center),
                          TextButton(
                            onPressed: _load,
                            child: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (shown.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.forum_outlined, color: _green, size: 50),
                        SizedBox(height: 12),
                        Text(
                          'No posts here yet',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Be part of the conversation.',
                          style: TextStyle(color: _muted),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList.builder(
                  itemCount: shown.length,
                  itemBuilder: (context, i) => Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          width < 650 ? 14 : 26,
                          0,
                          width < 650 ? 14 : 26,
                          16,
                        ),
                        child: _PostCard(
                          post: shown[i],
                          onLike: () => _toggleLike(shown[i]),
                          onComments: () => _comments(shown[i]),
                          onShare: () => _share(shown[i]),
                        ),
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.onLike,
    required this.onComments,
    required this.onShare,
  });
  final Map<String, dynamic> post;
  final VoidCallback onLike, onComments, onShare;
  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse('${post['created_at']}')?.toLocal();
    final names = (post['images'] as List? ?? []).cast<String>();
    final storage = Supabase.instance.client.storage.from('kaisa-feed');
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE3EBE5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
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
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${post['author_name']}',
                        style: const TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${post['category']}  •  ${date == null ? 'Recently' : '${date.day}/${date.month}/${date.year}'}',
                        style: const TextStyle(fontSize: 12, color: _muted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_horiz, color: _muted),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${post['body']}',
              style: const TextStyle(color: _ink, height: 1.5, fontSize: 15),
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
                              height: 190,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(
                                height: 190,
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
            Text(
              '${post['likes']} likes  •  ${post['comments']} comments',
              style: const TextStyle(fontSize: 12, color: _muted),
            ),
            const Divider(height: 23, color: Color(0xFFE3EBE5)),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: onLike,
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
                    onPressed: onShare,
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
    setState(() => busy = true);
    final db = Supabase.instance.client;
    final uid = db.auth.currentUser!.id;
    String? postId;
    try {
      final p = await db
          .from('kaisa_feed_posts')
          .insert({'author_id': uid, 'body': body, 'category': category})
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
            const Text(
              'Create a community post',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: _ink,
              ),
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
              onPressed: busy || images.length >= 2 ? null : _add,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text('Add photos (${images.length}/2, max 200 KB each)'),
            ),
            const SizedBox(height: 12),
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
  const _CommentsSheet({required this.postId});
  final String postId;
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
    if (content.isEmpty || content.length > 500) return;
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
                        title: Text(
                          '${comments[i]['author_name']}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text('${comments[i]['body']}'),
                      ),
                    ),
            ),
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
