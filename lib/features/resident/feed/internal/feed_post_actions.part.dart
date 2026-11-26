part of '../feed_page.dart';

// Compose, likes, comments, share RPC, and feedback toasts.
mixin _FeedPostActions on _FeedStateCore {
  @override
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

  @override
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

  @override
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

  @override
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

  @override
  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
