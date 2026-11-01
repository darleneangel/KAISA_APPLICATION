import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'kaisa_organization_access.dart';

/// Drop into both resident and organization-admin top bars.
/// No second authentication session: these are navigation contexts only.
class KaisaAccountSwitcher extends StatelessWidget {
  const KaisaAccountSwitcher({super.key, this.compact = false});
  final bool compact;
  static const forest = Color(0xFF14532D);

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Switch profile',
    icon: const Icon(Icons.swap_horiz_rounded, color: forest),
    onPressed: () => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFF8FAF8),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Switch KAISA profile',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: forest,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Text(
                  'Use the same login to manage your authorized organizations.',
                  style: TextStyle(color: Color(0xFF687B70)),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_outline),
                    ),
                    title: const Text('Personal resident profile'),
                    subtitle: const Text('Home, Feed, Events and Friends'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      context.go('/resident/home');
                    },
                  ),
                ),
                FutureBuilder<List<KaisaManagedOrganization>>(
                  future: KaisaOrganizationAccess.instance
                      .managedOrganizations(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.all(18),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError)
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'Could not load organizations: ${snapshot.error}',
                        ),
                      );
                    final orgs = snapshot.data ?? [];
                    if (orgs.isEmpty)
                      return const Padding(
                        padding: EdgeInsets.all(18),
                        child: Text(
                          'No organization management access assigned yet.',
                        ),
                      );
                    return Flexible(
                      fit: FlexFit.loose,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: orgs.length,
                        itemBuilder: (context, index) {
                          final org = orgs[index];
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFE5F2E9),
                                child: Icon(
                                  Icons.groups_rounded,
                                  color: forest,
                                ),
                              ),
                              title: Text(org.name),
                              subtitle: Text(org.role),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.pop(sheetContext);
                                // The role-aware gate validates this id again server-side.
                                context.go(
                                  org.role == 'Admin'
                                      ? '/organization-admin/dashboard?organizationId=${Uri.encodeComponent(org.id)}'
                                      : '/organization-admin/officer?organizationId=${Uri.encodeComponent(org.id)}',
                                );
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
