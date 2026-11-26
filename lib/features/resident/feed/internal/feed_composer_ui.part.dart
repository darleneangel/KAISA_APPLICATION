part of '../feed_page.dart';

// The existing composer and announcement highlight.
mixin _FeedComposerUi on _FeedStateCore {
  @override
  Widget _composer() => Container(
    padding: const EdgeInsets.fromLTRB(17, 17, 17, 11),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(8),
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
                borderRadius: BorderRadius.circular(28),
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: _compose,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 15,
                    ),
                    child: Text(
                      tier2
                          ? 'What’s happening in your community?'
                          : 'Verify your account to join the conversation',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(fontSize: 14, color: _muted),
                      ),
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
                label: Text(tier2 ? 'Create post' : 'Get verified'),
                style: TextButton.styleFrom(foregroundColor: _forest),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  @override
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
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          color: _forest,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      excerpt,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                          color: _ink,
                          height: 1.4,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'See announcements',
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              color: _forest,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
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
}
