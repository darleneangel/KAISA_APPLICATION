import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Responsive role-aware profile switcher. Does NOT create a second login.
/// Organization access is fetched from the authenticated Supabase RPC.
class KaisaPortalSwitcher extends StatelessWidget {
  const KaisaPortalSwitcher({super.key});

  Future<List<Map<String, dynamic>>> _managedOrganizations() async {
    final result = await Supabase.instance.client.rpc(
      'kaisa_my_managed_organizations',
    );
    if (result is! List) return [];
    return result
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  void _open(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          10,
          16,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * .7,
            maxWidth: 550,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Switch KAISA portal',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                subtitle: Text(
                  'Use your existing account to access your authorized organizations.',
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF14532D),
                ),
                title: const Text('Resident Portal'),
                subtitle: const Text('Your personal profile'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go('/resident/home');
                },
              ),
              Flexible(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _managedOrganizations(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Could not load managed organizations. Check that the role-switching RPC is installed.',
                        ),
                      );
                    }
                    final orgs = snapshot.data ?? [];
                    if (orgs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No organization Admin or Officer access assigned to this account.',
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: orgs.length,
                      itemBuilder: (context, index) {
                        final org = orgs[index];
                        final role = (org['role'] ?? '').toString();
                        final orgId = (org['id'] ?? '').toString();
                        return ListTile(
                          leading: const Icon(
                            Icons.groups_rounded,
                            color: Color(0xFF14532D),
                          ),
                          title: Text(
                            (org['name'] ?? 'Organization').toString(),
                          ),
                          subtitle: Text(role),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: orgId.isEmpty
                              ? null
                              : () {
                                  Navigator.pop(sheetContext);
                                  final route = role == 'Admin'
                                      ? '/organization-admin/dashboard'
                                      : '/organization-admin/officer';
                                  // Existing route guards MUST verify organization-specific RBAC.
                                  context.go(
                                    '$route?organizationId=${Uri.encodeComponent(orgId)}',
                                  );
                                },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Switch Resident / Organization portal',
    onPressed: () => _open(context),
    icon: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF14532D)),
  );
}
