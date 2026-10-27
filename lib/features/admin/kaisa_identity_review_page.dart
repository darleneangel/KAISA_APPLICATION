import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Add this page to a protected Super Admin router only after checking role server side.
// Review action is also enforced by a privileged SQL RPC.
class KaisaIdentityReviewPage extends StatefulWidget {
  const KaisaIdentityReviewPage({super.key});
  @override
  State<KaisaIdentityReviewPage> createState() =>
      _KaisaIdentityReviewPageState();
}

class _KaisaIdentityReviewPageState extends State<KaisaIdentityReviewPage> {
  final db = Supabase.instance.client;
  List<Map<String, dynamic>> queue = [];
  bool busy = true, authorized = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => busy = true);
    try {
      final permitted = await db.rpc('kaisa_is_super_admin');
      if (permitted != true) {
        if (mounted) setState(() => authorized = false);
        return;
      }
      final data = await db
          .from('kaisa_identity_requests')
          .select(
            'id,user_id,id_type,id_path,extracted_name,extracted_address,ocr_preview,status,submitted_at',
          )
          .eq('status', 'pending')
          .order('submitted_at', ascending: true);
      if (mounted)
        setState(() {
          authorized = true;
          queue = (data as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Review queue unavailable: $e')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _review(Map<String, dynamic> request, bool approve) async {
    final note = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(approve ? 'Approve Tier 2?' : 'Reject verification?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Review the original ID image and compare it against the resident record before deciding.',
            ),
            TextField(
              controller: note,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Review notes (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
    if (confirm != true) {
      note.dispose();
      return;
    }
    try {
      await db.rpc(
        'kaisa_admin_review_identity',
        params: {
          'p_request_id': request['id'],
          'p_approve': approve,
          'p_note': note.text,
        },
      );
      await _load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Review failed: $e')));
    } finally {
      note.dispose();
    }
  }

  Future<void> _viewId(Map<String, dynamic> r) async {
    try {
      final url = await db.storage
          .from('kaisa-identity')
          .createSignedUrl('${r['id_path']}', 90);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (c) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850, maxHeight: 650),
            child: InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Private ID image unavailable: $e')),
        );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('KAISA · Identity review'),
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
    ),
    body: busy
        ? const Center(child: CircularProgressIndicator())
        : !authorized
        ? const Center(child: Text('Restricted: Super Admin access required.'))
        : queue.isEmpty
        ? const Center(child: Text('No pending ID verification requests.'))
        : ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: queue.length,
            itemBuilder: (c, i) {
              final r = queue[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${r['extracted_name'] ?? 'Resident'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      Text('ID type: ${r['id_type']}'),
                      Text(
                        'Address on ID: ${r['extracted_address'] ?? 'Not supplied'}',
                      ),
                      Text(
                        'OCR preview (unverified): ${r['ocr_preview'] ?? 'Not available'}',
                      ),
                      Text(
                        'OCR preview (unverified): ${r['ocr_preview'] ?? 'Not available'}',
                      ),
                      Text('User ID: ${r['user_id']}'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _viewId(r),
                            icon: const Icon(Icons.image_search),
                            label: const Text('Inspect private ID'),
                          ),
                          FilledButton.icon(
                            onPressed: () => _review(r, true),
                            icon: const Icon(Icons.verified),
                            label: const Text('Approve Tier 2'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _review(r, false),
                            icon: const Icon(Icons.close),
                            label: const Text('Reject'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
  );
}
