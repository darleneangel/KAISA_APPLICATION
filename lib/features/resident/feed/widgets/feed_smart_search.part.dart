part of '../feed_page.dart';

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
                        decoration: InputDecoration(
                          hintText: 'Search people, posts, or topics',
                          hintStyle: GoogleFonts.inter(
                            textStyle: TextStyle(color: _muted, fontSize: 14),
                          ),
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
                              style: GoogleFonts.inter(
                                textStyle: TextStyle(
                                  color: _forest,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            person['name']!,
                            style: GoogleFonts.inter(
                              textStyle: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          subtitle: Text(
                            'View resident profile',
                            style: GoogleFonts.inter(
                              textStyle: TextStyle(
                                fontSize: 11.5,
                                color: _muted,
                              ),
                            ),
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
                        Padding(
                          padding: EdgeInsets.all(18),
                          child: Text(
                            'No matching posts in your current feed.',
                            style: GoogleFonts.inter(
                              textStyle: TextStyle(color: _muted),
                            ),
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
                              style: GoogleFonts.inter(
                                textStyle: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            subtitle: Text(
                              '${post['body'] ?? ''}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                textStyle: TextStyle(fontSize: 12),
                              ),
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
                      Padding(
                        padding: EdgeInsets.all(18),
                        child: Text(
                          'No matching residents in loaded posts.',
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(color: _muted),
                          ),
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
                    Expanded(
                      child: Text(
                        'Searches posts already visible to your account.',
                        style: GoogleFonts.inter(
                          textStyle: TextStyle(fontSize: 11, color: _muted),
                        ),
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
      style: GoogleFonts.inter(
        textStyle: TextStyle(
          color: _green,
          fontSize: 10,
          letterSpacing: .9,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}
