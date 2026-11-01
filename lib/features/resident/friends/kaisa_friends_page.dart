import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/kaisa_resident_design.dart';

class KaisaFriendsPage extends StatefulWidget {
  const KaisaFriendsPage({super.key});
  @override
  State<KaisaFriendsPage> createState() => _KaisaFriendsPageState();
}

class _KaisaFriendsPageState extends State<KaisaFriendsPage> {
  final db = Supabase.instance.client;
  List<Map<String, dynamic>> items = [];
  bool busy = true;
  bool tier2 = false;
  String? error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        db.rpc('kaisa_my_friendships'),
        db.rpc('kaisa_is_tier2'),
      ]);
      if (mounted)
        setState(() {
          items = (results[0] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          tier2 = results[1] == true;
        });
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _act(String uid, String action) async {
    try {
      await db.rpc(
        'kaisa_friend_action',
        params: {'p_user_id': uid, 'p_action': action},
      );
      await _load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: KaisaResidentDesign.paper,
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 90),
        children: [
          const Text(
            'FRIEND CONNECTIONS',
            style: TextStyle(
              color: KaisaResidentDesign.green,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Friends & Requests',
            style: TextStyle(
              fontSize: 27,
              color: KaisaResidentDesign.forest,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Friendships require both residents to have Tier 2 verification.',
          ),
          const SizedBox(height: 18),
          if (!tier2)
            const KaisaResidentCard(
              child: Text(
                'Verify your identity to send or accept friend requests.',
              ),
            ),
          if (busy)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(50),
                child: CircularProgressIndicator(),
              ),
            )
          else if (error != null)
            KaisaResidentCard(child: Text('Could not load friends: $error'))
          else if (items.isEmpty)
            const KaisaResidentCard(
              child: Text(
                'No friends or requests yet. Visit a resident’s public profile to add them.',
              ),
            )
          else
            for (final item in items)
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          child: Icon(Icons.person_outline),
                        ),
                        title: Text('${item['name']}'),
                        subtitle: Text(
                          item['status'] == 'accepted'
                              ? 'Friends'
                              : item['incoming'] == true
                              ? 'Incoming request'
                              : 'Request sent',
                        ),
                        onTap: () =>
                            context.push('/resident/user/${item['other_id']}'),
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (tier2 &&
                              item['status'] == 'pending' &&
                              item['incoming'] == true)
                            FilledButton(
                              onPressed: () =>
                                  _act('${item['other_id']}', 'accept'),
                              child: const Text('Accept'),
                            ),
                          if (tier2)
                            Outliner(
                              item: item,
                              onPressed: () =>
                                  _act('${item['other_id']}', 'remove'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    ),
  );
}

class Outliner extends StatelessWidget {
  const Outliner({super.key, required this.item, required this.onPressed});
  final Map<String, dynamic> item;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    child: Text(
      item['status'] == 'accepted'
          ? 'Unfriend'
          : item['incoming'] == true
          ? 'Decline'
          : 'Cancel request',
    ),
  );
}
