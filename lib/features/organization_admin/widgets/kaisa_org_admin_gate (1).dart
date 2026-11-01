import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Client-side navigation guard. SQL RPCs provide the actual authorization.
class KaisaOrgAdminGate extends StatefulWidget {
  const KaisaOrgAdminGate({super.key, required this.child});
  final Widget child;
  @override
  State<KaisaOrgAdminGate> createState() => _KaisaOrgAdminGateState();
}

class _KaisaOrgAdminGateState extends State<KaisaOrgAdminGate> {
  late Future<bool> allowed;
  @override
  void initState() {
    super.initState();
    allowed = _check();
  }

  Future<bool> _check() async {
    if (Supabase.instance.client.auth.currentUser == null) return false;
    final data = await Supabase.instance.client.rpc(
      'kaisa_admin_my_organizations',
    );
    return data is List && data.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: allowed,
    builder: (context, s) {
      if (s.connectionState != ConnectionState.done)
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      if (s.hasError)
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Unable to validate admin access: ${s.error}',
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: () => setState(() => allowed = _check()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        );
      if (s.data != true)
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Organization Admin access required.'),
                TextButton(
                  onPressed: () => context.go('/resident/home'),
                  child: const Text('Back to Resident Portal'),
                ),
              ],
            ),
          ),
        );
      return widget.child;
    },
  );
}
