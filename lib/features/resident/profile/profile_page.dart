import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/kaisa_resident_design.dart';
import 'kaisa_profile_repository.dart';
import 'kaisa_profile_widgets.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final repo = KaisaProfileRepository.instance;
  Map<String, dynamic>? data, privateData;
  List<Map<String, dynamic>> posts = [], attendance = [], certificates = [];
  bool loading = true, saving = false, verified = false;
  String? error;
  String get uid => Supabase.instance.client.auth.currentUser!.id;
  String get name => '${data?['display_name'] ?? 'KAISA Resident'}';
  String get photoPath => '${data?['avatar_path'] ?? ''}';
  String? get photoUrl => photoPath.isEmpty ? null : repo.avatarUrl(photoPath);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await Future.wait<dynamic>([
        repo.publicProfile(uid),
        repo.privateProfile(),
        repo.posts(uid),
        repo.isTier2(),
        repo.attendance(),
        repo.certificates(),
      ]);
      if (!mounted) return;
      setState(() {
        data = result[0] as Map<String, dynamic>?;
        privateData = result[1] as Map<String, dynamic>?;
        posts = result[2] as List<Map<String, dynamic>>;
        verified = result[3] == true;
        attendance = result[4] as List<Map<String, dynamic>>;
        certificates = result[5] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      if (mounted)
        setState(
          () => error =
              'Unable to load profile. Check the SQL migration and your connection. ($e)',
        );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _toast(String message) {
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editProfile() async {
    final controller = TextEditingController(text: '${data?['bio'] ?? ''}');
    String? newPath = photoPath.isEmpty ? null : photoPath;
    bool photoBusy = false;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Edit public profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Your photo, name and bio can be seen by other KAISA residents. Your address and account details stay private.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  maxLength: 300,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    hintText: 'Tell your community a little about yourself',
                    border: OutlineInputBorder(),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: photoBusy
                      ? null
                      : () async {
                          try {
                            final file = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 75,
                              maxWidth: 1200,
                            );
                            if (file == null) return;
                            setDialogState(() => photoBusy = true);
                            final bytes = await file.readAsBytes();
                            final path = await repo.uploadAvatar(
                              bytes,
                              file.mimeType ?? 'image/jpeg',
                            );
                            if (dialogContext.mounted)
                              setDialogState(() => newPath = path);
                          } catch (e) {
                            _toast('Could not upload photo: $e');
                          } finally {
                            if (dialogContext.mounted)
                              setDialogState(() => photoBusy = false);
                          }
                        },
                  icon: photoBusy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_a_photo_outlined),
                  label: Text(
                    newPath == photoPath
                        ? 'Choose profile photo'
                        : 'New photo selected',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: photoBusy
                  ? null
                  : () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: photoBusy
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              child: const Text('Save profile'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      setState(() => saving = true);
      try {
        await repo.saveProfile(
          bio: controller.text.trim(),
          avatarPath: newPath,
        );
        await _load();
        _toast('Profile updated successfully.');
      } catch (e) {
        _toast('Could not save profile: $e');
      } finally {
        if (mounted) setState(() => saving = false);
      }
    }
    controller.dispose();
  }

  Future<void> _logout() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out of KAISA?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) context.go('/welcome');
    } catch (e) {
      _toast('Unable to sign out: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: KaisaResidentDesign.paper,
    body: RefreshIndicator(
      onRefresh: _load,
      child: LayoutBuilder(
        builder: (context, c) {
          final compact = c.maxWidth < 600;
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 28,
              20,
              compact ? 16 : 28,
              80,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR COMMUNITY IDENTITY',
                      style: TextStyle(
                        color: KaisaResidentDesign.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'My Profile',
                      style: TextStyle(
                        color: KaisaResidentDesign.ink,
                        fontSize: 29,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Your story, activities and community journey.',
                      style: TextStyle(
                        color: KaisaResidentDesign.muted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (loading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
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
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(compact ? 21 : 30),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              KaisaResidentDesign.forest,
                              Color(0xFF267A50),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Wrap(
                          spacing: 20,
                          runSpacing: 14,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            KaisaProfileAvatar(
                              name: name,
                              url: photoUrl,
                              radius: 48,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 23,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  Supabase
                                          .instance
                                          .client
                                          .auth
                                          .currentUser
                                          ?.email ??
                                      '',
                                  style: const TextStyle(
                                    color: Color(0xFFE1F1E6),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 9),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      verified
                                          ? Icons.verified_rounded
                                          : Icons.shield_outlined,
                                      color: KaisaResidentDesign.yellow,
                                      size: 19,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      verified
                                          ? 'Tier 2 · Verified resident'
                                          : 'Tier 1 · Basic account',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            FilledButton.icon(
                              onPressed: saving ? null : _editProfile,
                              style: FilledButton.styleFrom(
                                backgroundColor: KaisaResidentDesign.yellow,
                                foregroundColor: KaisaResidentDesign.forest,
                              ),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit photo & bio'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!verified)
                        KaisaResidentCard(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.verified_user_outlined,
                                color: KaisaResidentDesign.green,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Unlock Tier 2 by completing LGU identity verification.',
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.push(
                                  '/resident/identity-verification',
                                ),
                                child: const Text('Verify'),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      KaisaResidentCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const KaisaResidentSectionHeading(
                              title: 'About me',
                            ),
                            const SizedBox(height: 9),
                            Text(
                              '${data?['bio'] ?? ''}'.trim().isEmpty
                                  ? 'No bio yet. Add a short introduction to your community.'
                                  : '${data?['bio']}',
                              style: const TextStyle(
                                color: KaisaResidentDesign.ink,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _nav(
                            'My Events',
                            Icons.event_available_outlined,
                            '/resident/my-events',
                          ),
                          _nav(
                            'My Organizations',
                            Icons.groups_2_outlined,
                            '/resident/my-organizations',
                          ),
                          _nav(
                            'Identity Status',
                            Icons.shield_outlined,
                            '/resident/verification-status',
                          ),
                          _nav(
                            'Notifications',
                            Icons.notifications_none_outlined,
                            '/resident/notifications',
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      KaisaResidentSectionHeading(
                        title: 'My posts',
                        subtitle:
                            'Your public Community Feed contributions · ${posts.length} post(s)',
                      ),
                      const SizedBox(height: 12),
                      if (posts.isEmpty)
                        const KaisaResidentCard(
                          child: Text(
                            'No posts yet. Approved Tier 2 residents can publish in Community Feed.',
                          ),
                        ),
                      for (final post in posts)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: KaisaProfilePostCard(
                            post: post,
                            imageUrl: repo.feedImageUrl,
                          ),
                        ),
                      const SizedBox(height: 25),
                      const KaisaResidentSectionHeading(
                        title: 'Events attended',
                        subtitle: 'Private participation history',
                      ),
                      const SizedBox(height: 12),
                      if (attendance.isEmpty)
                        const KaisaResidentCard(
                          child: Text(
                            'No attended events recorded yet. Events appear here after an authorized attendance check-in.',
                          ),
                        ),
                      for (final reg in attendance)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: KaisaResidentCard(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.event_available_rounded,
                                color: KaisaResidentDesign.green,
                              ),
                              title: Text(
                                '${(reg['event'] as Map?)?['title'] ?? 'Community event'}',
                              ),
                              subtitle: const Text('Attendance confirmed'),
                            ),
                          ),
                        ),
                      const SizedBox(height: 25),
                      const KaisaResidentSectionHeading(
                        title: 'My e-certificates',
                        subtitle:
                            'Certificates issued by authorized organizers',
                      ),
                      const SizedBox(height: 12),
                      if (certificates.isEmpty)
                        const KaisaResidentCard(
                          child: Text(
                            'No e-certificates issued yet. Only official certificates will appear here.',
                          ),
                        ),
                      for (final cert in certificates)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: KaisaResidentCard(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.workspace_premium_outlined,
                                color: KaisaResidentDesign.green,
                              ),
                              title: Text('${cert['title']}'),
                              subtitle: const Text(
                                'Issued certificate · Download support to follow',
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 26),
                      OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Sign out'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );

  Widget _nav(String text, IconData icon, String path) => OutlinedButton.icon(
    onPressed: () => context.push(path),
    icon: Icon(icon, size: 19),
    label: Text(text),
    style: OutlinedButton.styleFrom(
      foregroundColor: KaisaResidentDesign.forest,
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
    ),
  );
}
