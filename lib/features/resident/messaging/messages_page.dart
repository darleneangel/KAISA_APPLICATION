import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/kaisa_resident_design.dart';

/// A list of actual conversations. Names come from a public-safe, authenticated RPC.
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});
  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _conversations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted)
      setState(() {
        _loading = true;
        _error = null;
      });
    try {
      final rows = await Supabase.instance.client.rpc('kaisa_message_inbox');
      if (!mounted) return;
      setState(() {
        _conversations = (rows as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not load conversations: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _conversations.where((item) {
      final term = _search.text.trim().toLowerCase();
      return '${item['display_name'] ?? ''} ${item['last_message'] ?? ''}'
          .toLowerCase()
          .contains(term);
    }).toList();
    return Scaffold(
      backgroundColor: KaisaResidentDesign.paper,
      body: RefreshIndicator(
        onRefresh: _load,
        child: LayoutBuilder(
          builder: (context, size) {
            final pad = KaisaResidentDesign.pagePadding(size.maxWidth);
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: KaisaResidentDesign.desktopWidth,
                ),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(pad, 22, pad, 90),
                  children: [
                    const Text(
                      'STAY CONNECTED',
                      style: TextStyle(
                        color: KaisaResidentDesign.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Messages',
                      style: TextStyle(
                        color: KaisaResidentDesign.ink,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Your private conversations with the KAISA community.',
                      style: TextStyle(
                        color: KaisaResidentDesign.muted,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(23),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            KaisaResidentDesign.forest,
                            Color(0xFF28774B),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.forum_rounded,
                            color: KaisaResidentDesign.yellow,
                            size: 35,
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Conversations that connect.',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Open a resident’s public profile to start a private conversation.',
                                  style: TextStyle(
                                    color: Color(0xFFE2F1E7),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search conversations',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(
                          child: KaisaResidentSectionHeading(
                            title: 'Recent chats',
                            subtitle:
                                'Only conversations you participate in are shown.',
                          ),
                        ),
                        IconButton(
                          onPressed: _load,
                          tooltip: 'Refresh messages',
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    if (_loading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_error != null)
                      KaisaResidentCard(
                        child: Column(
                          children: [
                            Text(_error!, textAlign: TextAlign.center),
                            TextButton(
                              onPressed: _load,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    else if (items.isEmpty)
                      KaisaResidentCard(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.mark_chat_unread_outlined,
                                size: 43,
                                color: KaisaResidentDesign.green,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _conversations.isEmpty
                                    ? 'No conversations yet'
                                    : 'No matching conversations',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 7),
                              const Text(
                                'Visit Community Feed and open a resident profile to message them.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: () => context.go('/resident/feed'),
                                icon: const Icon(Icons.forum_outlined),
                                label: const Text('Explore Community Feed'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...items.map((item) {
                        final id = item['other_user_id']?.toString() ?? '';
                        final name =
                            item['display_name']?.toString() ??
                            'KAISA Resident';
                        final avatar = item['avatar_path']?.toString();
                        final url = avatar == null || avatar.isEmpty
                            ? null
                            : Supabase.instance.client.storage
                                  .from('kaisa-avatars')
                                  .getPublicUrl(avatar);
                        final created = DateTime.tryParse(
                          item['last_at']?.toString() ?? '',
                        )?.toLocal();
                        final time = created == null
                            ? ''
                            : '${created.month}/${created.day} ${TimeOfDay.fromDateTime(created).format(context)}';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              KaisaResidentDesign.cardRadius,
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(
                                KaisaResidentDesign.cardRadius,
                              ),
                              onTap: id.isEmpty
                                  ? null
                                  : () async {
                                      await context.push(
                                        '/resident/messages/$id',
                                      );
                                      if (mounted) _load();
                                    },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration:
                                    KaisaResidentDesign.cardDecoration(),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 25,
                                      backgroundColor: const Color(0xFFE5F2E9),
                                      backgroundImage: url == null
                                          ? null
                                          : NetworkImage(url),
                                      child: url == null
                                          ? Text(
                                              name.isNotEmpty
                                                  ? name[0].toUpperCase()
                                                  : 'R',
                                              style: const TextStyle(
                                                color:
                                                    KaisaResidentDesign.forest,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 13),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: KaisaResidentDesign.ink,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            '${item['from_me'] == true ? 'You: ' : ''}${item['last_message'] ?? ''}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: KaisaResidentDesign.muted,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      time,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: KaisaResidentDesign.muted,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: KaisaResidentDesign.green,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
