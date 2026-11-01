import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'kaisa_organization_access.dart';

class KaisaMyStaffInvitationsPage extends StatefulWidget {
  const KaisaMyStaffInvitationsPage({super.key});
  @override
  State<KaisaMyStaffInvitationsPage> createState() =>
      _KaisaMyStaffInvitationsPageState();
}

class _KaisaMyStaffInvitationsPageState
    extends State<KaisaMyStaffInvitationsPage> {
  late Future<List<Map<String, dynamic>>> future;
  bool working = false;
  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() => setState(() {
    future = KaisaOrganizationAccess.instance.pendingInvitations();
  });
  Future<void> respond(String id, bool accept) async {
    setState(() => working = true);
    try {
      final result = await KaisaOrganizationAccess.instance.respond(
        id,
        accept: accept,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result == 'pending_superadmin'
                ? 'Accepted; awaiting Super Admin approval.'
                : result == 'approved'
                ? 'Invitation accepted. Organization management enabled.'
                : 'Invitation declined.',
          ),
        ),
      );
      refresh();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not respond: $e')));
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8FAF8),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850),
        child: RefreshIndicator(
          onRefresh: () async {
            refresh();
            await future;
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextButton.icon(
                onPressed: () => context.go('/resident/profile'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('My Profile'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Organization invitations',
                style: TextStyle(
                  color: Color(0xFF14532D),
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Invitations are tied to your personal resident account.',
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: future,
                builder: (context, snapshot) {
                  if (!snapshot.hasData && !snapshot.hasError)
                    return const Center(child: CircularProgressIndicator());
                  if (snapshot.hasError)
                    return Text(
                      'Unable to load invitations: ${snapshot.error}',
                    );
                  final invitations = snapshot.data!;
                  if (invitations.isEmpty)
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No invitations right now.'),
                      ),
                    );
                  return Column(
                    children: [
                      for (final i in invitations)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${i['organization_name']}',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('Role: ${i['role']} · ${i['status']}'),
                                if ('${i['note']}'.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Text('${i['note']}'),
                                  ),
                                if (i['status'] == 'pending')
                                  Row(
                                    children: [
                                      OutlinedButton(
                                        onPressed: working
                                            ? null
                                            : () =>
                                                  respond('${i['id']}', false),
                                        child: const Text('Decline'),
                                      ),
                                      const SizedBox(width: 10),
                                      FilledButton(
                                        onPressed: working
                                            ? null
                                            : () => respond('${i['id']}', true),
                                        child: const Text('Accept'),
                                      ),
                                    ],
                                  )
                                else
                                  const Text('Awaiting Super Admin decision.'),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
