part of '../feed_page.dart';

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
                Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'Residents who liked this post',
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _line),
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
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              color: _forest,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _relativeTime(date),
                              style: GoogleFonts.inter(
                                textStyle: TextStyle(
                                  color: _muted,
                                  fontSize: 12,
                                ),
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
                              style: GoogleFonts.inter(
                                textStyle: TextStyle(
                                  color: _muted,
                                  fontSize: 12,
                                ),
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
                    borderRadius: BorderRadius.circular(20),
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
                          fontSize: 11,
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
          if (_postTags(post).isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 10, 17, 0),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in _readTags(post['interest_tags']))
                    Chip(
                      avatar: const Icon(
                        Icons.interests_outlined,
                        size: 15,
                        color: _forest,
                      ),
                      label: Text(tag),
                      backgroundColor: _soft,
                      labelStyle: GoogleFonts.inter(
                        textStyle: TextStyle(color: _forest, fontSize: 11),
                      ),
                    ),
                  for (final tag in _readTags(post['skill_tags']))
                    Chip(
                      avatar: const Icon(
                        Icons.lightbulb_outline,
                        size: 15,
                        color: _forest,
                      ),
                      label: Text(tag),
                      backgroundColor: const Color(0xFFFFF2D5),
                      labelStyle: GoogleFonts.inter(
                        textStyle: TextStyle(color: _forest, fontSize: 11),
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
                  Padding(
                    padding: EdgeInsets.only(right: 2, top: 4),
                    child: Text(
                      'Relevant to you',
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(color: _muted, fontSize: 10.5),
                      ),
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
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.inter(
                          textStyle: TextStyle(
                            color: _green,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
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
                style: GoogleFonts.plusJakartaSans(
                  textStyle: TextStyle(
                    color: _ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
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
                style: GoogleFonts.inter(
                  textStyle: TextStyle(color: _ink, fontSize: 16, height: 1.55),
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
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _green,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${post['shared_body'] ?? ''}',
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(
                        color: _ink,
                        fontSize: 13.5,
                        height: 1.45,
                      ),
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
                final height = (constraints.maxWidth * (isDouble ? .48 : .68))
                    .clamp(180.0, 420.0)
                    .toDouble();
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
                                child: Column(
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
                                      style: GoogleFonts.inter(
                                        textStyle: TextStyle(
                                          color: _muted,
                                          fontSize: 11,
                                        ),
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
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              color: _ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'likes',
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(color: _muted, fontSize: 11.5),
                          ),
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
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(color: _muted, fontSize: 11.5),
                    ),
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
                      textStyle: GoogleFonts.inter(
                        textStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
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
                      textStyle: GoogleFonts.inter(
                        textStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
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
                      textStyle: GoogleFonts.inter(
                        textStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
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
