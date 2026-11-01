import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/organization/kaisa_organization_access.dart';

/// Limited initial workspace: officers cannot access admin dashboard or invitations.
class KaisaOfficerWorkspacePage extends StatelessWidget {
  const KaisaOfficerWorkspacePage({super.key, required this.organizationId});
  final String organizationId;
  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<List<KaisaManagedOrganization>>(
    future: KaisaOrganizationAccess.instance.managedOrganizations(),
    builder: (context, s) {
      if (!s.hasData)
        return Scaffold(
          body: Center(
            child: s.hasError
                ? Text('Unable to validate access: ${s.error}')
                : const CircularProgressIndicator(),
          ),
        );
      final matches = s.data!
          .where((o) => o.id == organizationId && o.role == 'Officer')
          .toList();
      if (matches.isEmpty)
        return Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => context.go('/resident/home'),
              child: const Text('Officer access unavailable · Return Home'),
            ),
          ),
        );
      final org = matches.first;
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAF8),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  org.name,
                  style: const TextStyle(
                    color: Color(0xFF14532D),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Officer workspace'),
                const SizedBox(height: 20),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Your Officer role is active. Administrative actions such as staff invitations, exports and organization settings require authorized Admin access. Officer permissions can be added after LGU policy approval.',
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/resident/home'),
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Switch to personal profile'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
