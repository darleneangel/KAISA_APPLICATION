import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/organization/kaisa_organization_access.dart';

/// Organization-scoped staff invitation page. Requires the orgId from the active admin context.
class KaisaInviteStaffPage extends StatefulWidget {
  const KaisaInviteStaffPage({super.key, required this.organizationId});
  final String organizationId;
  @override
  State<KaisaInviteStaffPage> createState() => _KaisaInviteStaffPageState();
}

class _KaisaInviteStaffPageState extends State<KaisaInviteStaffPage> {
  static const forest = Color(0xFF14532D);
  final search = TextEditingController();
  final note = TextEditingController();
  Timer? debounce;
  List<Map<String, dynamic>> matches = [];
  Map<String, dynamic>? selected;
  String role = 'Officer';
  bool searching = false, sending = false;
  String? error;
  int generation = 0;

  @override
  void dispose() {
    debounce?.cancel();
    search.dispose();
    note.dispose();
    super.dispose();
  }

  void onSearch(String value) {
    debounce?.cancel();
    final id = ++generation;
    setState(() {
      selected = null;
      matches = [];
      error = null;
      searching = value.trim().length >= 3;
    });
    if (value.trim().length < 3) return;
    debounce = Timer(const Duration(milliseconds: 320), () async {
      try {
        final results = await KaisaOrganizationAccess.instance.searchResidents(
          widget.organizationId,
          value,
        );
        if (mounted && id == generation)
          setState(() {
            matches = results;
            searching = false;
          });
      } catch (e) {
        if (mounted && id == generation)
          setState(() {
            error = '$e';
            searching = false;
          });
      }
    });
  }

  Future<void> submit() async {
    final person = selected;
    if (person == null || sending) return;
    setState(() {
      sending = true;
      error = null;
    });
    try {
      await KaisaOrganizationAccess.instance.invite(
        organizationId: widget.organizationId,
        residentId: '${person['user_id']}',
        role: role,
        note: note.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation sent for resident approval.')),
      );
      search.clear();
      note.clear();
      setState(() {
        selected = null;
        matches = [];
      });
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8FAF8),
    body: SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () => context.go(
                    '/organization-admin/dashboard?organizationId=${Uri.encodeComponent(widget.organizationId)}',
                  ),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Dashboard'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Invite organization staff',
                  style: TextStyle(
                    fontSize: 25,
                    color: forest,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Search a verified Tier 2 resident by name or exact email. Email addresses are never shown in suggestions.',
                ),
                const SizedBox(height: 22),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: search,
                          onChanged: onSearch,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            labelText: 'Find resident',
                            hintText: 'Type at least 3 characters',
                          ),
                        ),
                        if (searching) const LinearProgressIndicator(),
                        if (search.text.isNotEmpty &&
                            !searching &&
                            matches.isEmpty &&
                            selected == null)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text('No matching eligible residents.'),
                          ),
                        for (final person in matches)
                          ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person_outline),
                            ),
                            title: Text('${person['full_name'] ?? 'Resident'}'),
                            subtitle: const Text('Tier 2 · Verified'),
                            trailing: selected?['user_id'] == person['user_id']
                                ? const Icon(Icons.check_circle, color: forest)
                                : const Icon(Icons.add_circle_outline),
                            onTap: () => setState(() => selected = person),
                          ),
                        if (selected != null) ...[
                          const SizedBox(height: 20),
                          Text(
                            'Invite ${selected!['full_name']}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: role,
                            decoration: const InputDecoration(
                              labelText: 'Proposed role',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Officer',
                                child: Text('Officer'),
                              ),
                              DropdownMenuItem(
                                value: 'Admin',
                                child: Text(
                                  'Administrator · Super Admin approval required',
                                ),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => role = v ?? 'Officer'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: note,
                            maxLength: 500,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Invitation message (optional)',
                            ),
                          ),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: sending ? null : submit,
                            icon: const Icon(Icons.send_outlined),
                            label: Text(
                              sending ? 'Sending...' : 'Send invitation',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'An invitation never grants instant Admin access. The invitee must accept, and Admin elevation requires Super Admin review.',
                  style: TextStyle(color: Color(0xFF687B70)),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
