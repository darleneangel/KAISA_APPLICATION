import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Organization Admin profile editor. Server RPCs enforce Admin membership.
class KaisaOrgProfilePage extends StatefulWidget {
  const KaisaOrgProfilePage({super.key});

  @override
  State<KaisaOrgProfilePage> createState() => _KaisaOrgProfilePageState();
}

class _KaisaOrgProfilePageState extends State<KaisaOrgProfilePage> {
  static const forest = Color(0xFF14532D);
  final description = TextEditingController();
  final mission = TextEditingController();
  final location = TextEditingController();
  final email = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String? lastId;
  String name = '';
  String category = '';
  String status = '';
  String? error;
  bool loading = false;
  bool saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = GoRouterState.of(context).uri.queryParameters['organizationId'];
    if (id != lastId) {
      lastId = id;
      if (id != null && id.isNotEmpty) {
        Future.microtask(() => load(id));
      }
    }
  }

  @override
  void dispose() {
    description.dispose();
    mission.dispose();
    location.dispose();
    email.dispose();
    super.dispose();
  }

  void fill(Map<String, dynamic> data) {
    name = '${data['name'] ?? ''}';
    category = '${data['category'] ?? ''}';
    status = '${data['status'] ?? ''}';
    description.text = '${data['description'] ?? ''}';
    mission.text = '${data['mission'] ?? ''}';
    location.text = '${data['location'] ?? ''}';
    email.text = '${data['contact_email'] ?? ''}';
  }

  Future<void> load(String id) async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await Supabase.instance.client.rpc(
        'kaisa_org_admin_profile_get',
        params: {'p_organization_id': id},
      );
      if (!mounted || lastId != id) return;
      setState(() => fill(Map<String, dynamic>.from(result as Map)));
    } catch (e) {
      if (mounted)
        setState(() => error = 'Could not load organization profile: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> save() async {
    final id = lastId;
    if (id == null || saving || !formKey.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final result = await Supabase.instance.client.rpc(
        'kaisa_org_admin_profile_update',
        params: {
          'p_organization_id': id,
          'p_description': description.text.trim(),
          'p_mission': mission.text.trim(),
          'p_location': location.text.trim(),
          'p_contact_email': email.text.trim(),
        },
      );
      if (!mounted || lastId != id) return;
      setState(() => fill(Map<String, dynamic>.from(result as Map)));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organization profile updated.')),
      );
    } catch (e) {
      if (mounted) setState(() => error = 'Could not save profile: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (lastId == null || lastId!.isEmpty) {
      return const Center(child: Text('Choose an organization first.'));
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(colors: [forest, Color(0xFF237A50)]),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: Color(0xFFFBC02D),
                child: Icon(Icons.groups_rounded, color: forest, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ORGANIZATION PROFILE',
                      style: TextStyle(
                        color: Color(0xFFFBC02D),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      name.isEmpty ? 'Loading organization...' : name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '$category  ·  $status',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (loading) const LinearProgressIndicator(),
        if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(error!, style: const TextStyle(color: Colors.red)),
          ),
        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit organization information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: forest,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Official name, approval status and Admin roles are managed separately by the LGU.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: description,
                    maxLines: 3,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                      labelText: 'About the organization',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: mission,
                    maxLines: 3,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                      labelText: 'Mission',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: location,
                    maxLength: 250,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: email,
                    maxLength: 254,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.isNotEmpty &&
                          !RegExp(
                            r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                          ).hasMatch(value)) {
                        return 'Enter a valid contact email';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Contact email',
                      prefixIcon: Icon(Icons.mail_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: saving || loading ? null : save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(saving ? 'Saving...' : 'Save changes'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
