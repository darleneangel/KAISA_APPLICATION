part of '../feed_page.dart';

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
                Expanded(
                  child: Text(
                    'Comments',
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(
                        color: _forest,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
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
                ? Center(
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
                            style: GoogleFonts.inter(
                              textStyle: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: _ink,
                              ),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Start the conversation with your community.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              textStyle: TextStyle(color: _muted, fontSize: 12),
                            ),
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
                                  style: GoogleFonts.inter(
                                    textStyle: TextStyle(
                                      color: _forest,
                                      fontWeight: FontWeight.w900,
                                    ),
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
                                      style: GoogleFonts.inter(
                                        textStyle: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: _forest,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${item['body'] ?? ''}',
                                    style: GoogleFonts.inter(
                                      textStyle: TextStyle(
                                        fontSize: 13.5,
                                        color: _ink,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                  if (when != null) ...[
                                    const SizedBox(height: 5),
                                    Text(
                                      _relativeTime(when),
                                      style: GoogleFonts.inter(
                                        textStyle: TextStyle(
                                          fontSize: 11,
                                          color: _muted,
                                        ),
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
