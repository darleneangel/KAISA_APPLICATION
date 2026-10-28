import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/kaisa_resident_design.dart';
import 'kaisa_profile_repository.dart';
import 'kaisa_profile_widgets.dart';

class PublicResidentProfilePage extends StatefulWidget {
  const PublicResidentProfilePage({super.key, required this.userId});
  final String userId;
  @override
  State<PublicResidentProfilePage> createState() =>
      _PublicResidentProfilePageState();
}

class _PublicResidentProfilePageState extends State<PublicResidentProfilePage> {
  final repo = KaisaProfileRepository.instance;
  Map<String, dynamic>? profile;
  List<Map<String, dynamic>> posts = [];
  bool busy = true;
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
        repo.publicProfile(widget.userId),
        repo.posts(widget.userId),
      ]);
      if (mounted)
        setState(() {
          profile = results[0] as Map<String, dynamic>?;
          posts = results[1] as List<Map<String, dynamic>>;
        });
    } catch (e) {
      if (mounted)
        setState(() => error = 'Could not load this public profile: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = '${profile?['display_name'] ?? 'KAISA Resident'}';
    final avatar = '${profile?['avatar_path'] ?? ''}';
    return Scaffold(
      backgroundColor: KaisaResidentDesign.paper,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 80),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go('/resident/feed'),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back to Community Feed'),
                ),
                const SizedBox(height: 10),
                if (busy)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(50),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (error != null)
                  KaisaResidentCard(
                    child: Column(
                      children: [
                        Text(error!),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  )
                else if (profile == null)
                  const KaisaResidentCard(
                    child: Text('This profile is not available.'),
                  )
                else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [KaisaResidentDesign.forest, Color(0xFF28774B)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        KaisaProfileAvatar(
                          name: name,
                          url: avatar.isEmpty ? null : repo.avatarUrl(avatar),
                          radius: 43,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (profile!['verified'] == true)
                          const Row(
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                color: KaisaResidentDesign.yellow,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Verified Resident',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: () => context.push(
                            '/resident/messages/${widget.userId}',
                          ),
                          icon: const Icon(Icons.chat_bubble_outline_rounded),
                          label: const Text('Message'),
                          style: FilledButton.styleFrom(
                            backgroundColor: KaisaResidentDesign.yellow,
                            foregroundColor: KaisaResidentDesign.forest,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  KaisaResidentCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const KaisaResidentSectionHeading(title: 'About'),
                        const SizedBox(height: 8),
                        Text(
                          '${profile!['bio'] ?? ''}'.trim().isEmpty
                              ? 'No bio added yet.'
                              : '${profile!['bio']}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 23),
                  KaisaResidentSectionHeading(
                    title: 'Community posts',
                    subtitle: '${posts.length} public post(s)',
                  ),
                  const SizedBox(height: 12),
                  if (posts.isEmpty)
                    const KaisaResidentCard(child: Text('No posts to show.')),
                  for (final post in posts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: KaisaProfilePostCard(
                        post: post,
                        imageUrl: repo.feedImageUrl,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
