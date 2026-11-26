part of '../feed_page.dart';

// Active-story RPC, signed media thumbnails, 24h strip and viewer.
mixin _FeedStories on _FeedStateCore {
  @override
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

  @override
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

  @override
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
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
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
                            style: GoogleFonts.inter(
                              textStyle: TextStyle(
                                color: Colors.white,
                                height: 1.5,
                                fontSize: 14,
                              ),
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

  @override
  Widget _storiesStrip() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
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
            Expanded(
              child: Text(
                'Community stories',
                style: GoogleFonts.plusJakartaSans(
                  textStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ),
            ),
            Text(
              '${stories.length} active · 24h',
              style: GoogleFonts.inter(
                textStyle: TextStyle(fontSize: 12, color: _muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 116,
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
                        style: GoogleFonts.inter(
                          textStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
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
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _ink,
                            ),
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
}
