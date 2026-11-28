import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const _green = Color(0xFF154E2E);
const _paper = Color(0xFFF5F8F4);

// Development-only fixture; never reads or writes real identity records.
class IdentityVerificationPreviewPage extends StatefulWidget {
  const IdentityVerificationPreviewPage({super.key});
  @override
  State<IdentityVerificationPreviewPage> createState() => _IdentityVerificationPreviewPageState();
}

class _Application {
  _Application(this.id, this.name, this.document, this.status, {this.reason = '', this.complete = true});
  final String id, name, document;
  String status, reason;
  bool complete;
}

List<_Application> _seed() => [
  _Application('DEMO-002', 'Demo Resident 02', 'Sample government ID', 'Pending'),
  _Application('DEMO-008', 'Demo Resident 08', 'Sample government ID', 'Pending', complete: false),
  _Application('DEMO-012', 'Demo Resident 12', 'Sample government ID', 'Pending'),
  _Application('DEMO-004', 'Demo Resident 04', 'Sample government ID', 'Needs information', reason: 'Please provide a clearer image.', complete: false),
  _Application('DEMO-005', 'Demo Resident 05', 'Sample government ID', 'Rejected', reason: 'Sample eligibility mismatch.'),
  _Application('DEMO-001', 'Demo Resident 01', 'Sample government ID', 'Verified'),
];

class _IdentityVerificationPreviewPageState extends State<IdentityVerificationPreviewPage> {
  List<_Application> _records = _seed();
  final _search = TextEditingController();
  String _filter = 'Pending';
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _review(_Application a) async {
    final reason = TextEditingController();
    bool identity = false, readable = false, eligible = false;
    String? error;
    final decision = await showDialog<String>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, update) {
      final pending = a.status == 'Pending';
      void decide(String status) {
        if (status == 'Verified' && (!identity || !readable || !eligible || !a.complete)) {
          update(() => error = 'All checks and a complete submission are required.'); return;
        }
        if (status != 'Verified' && reason.text.trim().isEmpty) {
          update(() => error = 'Enter a reason for the applicant.'); return;
        }
        Navigator.of(ctx).pop(status);
      }
      return AlertDialog(
        title: Text(a.name),
        content: SizedBox(width: 520, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('${a.id} · ${a.status}'),
          const SizedBox(height: 12),
          Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: _paper, borderRadius: BorderRadius.circular(12)), child: Column(children: [
            const Icon(Icons.badge_outlined, size: 48, color: _green),
            Text(a.document), const Text('FICTIONAL DOCUMENT — NOT A REAL ID'),
            Text(a.complete ? 'Sample submission complete' : 'Sample document incomplete'),
          ])),
          if (a.reason.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text('Previous reason: ${a.reason}')),
          if (pending) ...[
            const SizedBox(height: 12), const Text('Review checklist', style: TextStyle(fontWeight: FontWeight.bold)),
            CheckboxListTile(contentPadding: EdgeInsets.zero, title: const Text('Identity information matches'), value: identity, onChanged: (v) => update(() => identity = v ?? false)),
            CheckboxListTile(contentPadding: EdgeInsets.zero, title: const Text('Document is readable and complete'), value: readable, onChanged: (v) => update(() => readable = v ?? false)),
            CheckboxListTile(contentPadding: EdgeInsets.zero, title: const Text('Eligibility requirements satisfied'), value: eligible, onChanged: (v) => update(() => eligible = v ?? false)),
            TextField(controller: reason, maxLines: 3, maxLength: 500, decoration: const InputDecoration(labelText: 'Reason / requested corrections', border: OutlineInputBorder())),
            if (error != null) Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ],
          if (a.status == 'Needs information') const Text('Only the mock applicant can resubmit. Use the simulation button below.'),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
          if (pending) ...[
            TextButton(onPressed: () => decide('Needs information'), child: const Text('Request corrections')),
            TextButton(onPressed: () => decide('Rejected'), child: const Text('Reject')),
            FilledButton(onPressed: () => decide('Verified'), child: const Text('Approve')),
          ],
          if (a.status == 'Needs information') OutlinedButton(onPressed: () => Navigator.of(ctx).pop('Resubmit'), child: const Text('Simulate applicant resubmission')),
        ],
      );
    }));
    final note = reason.text.trim();
    reason.dispose();
    if (!mounted || decision == null) return;
    setState(() {
      if (decision == 'Resubmit') { a.status = 'Pending'; a.complete = true; }
      else { a.status = decision; a.reason = note; }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mock decision: ${a.status}. No real account changed.')));
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    final rows = _records.where((a) => (_filter == 'All' || a.status == _filter) && '${a.name} ${a.id}'.toLowerCase().contains(_search.text.toLowerCase())).toList();
    return Material(color: _paper, child: ListView(padding: const EdgeInsets.all(24), children: [
      const Text('KAISA / RESIDENT MANAGEMENT', style: TextStyle(color: _green, fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      const Text('Identity Verification', style: TextStyle(color: _green, fontSize: 28, fontWeight: FontWeight.bold)),
      const Text('Review identity applications and eligibility for Tier 2 access.'),
      const SizedBox(height: 16),
      const Card(child: ListTile(leading: Icon(Icons.science_outlined), title: Text('Mock Data Mode'), subtitle: Text('Isolated developer preview. No real documents or account changes.'))),
      Wrap(spacing: 8, runSpacing: 8, children: [for (final s in ['Pending', 'Needs information', 'Verified', 'Rejected']) ActionChip(label: Text('$s · ${_records.where((a) => a.status == s).length}'), onPressed: () => setState(() => _filter = s))]),
      const SizedBox(height: 16),
      TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search name or resident ID', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [for (final s in ['All', 'Pending', 'Needs information', 'Verified', 'Rejected']) ChoiceChip(label: Text(s), selected: _filter == s, onSelected: (_) => setState(() => _filter = s))]),
      const SizedBox(height: 12),
      if (rows.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('No matching applications.'))),
      for (final a in rows) Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.person_outline)), title: Text(a.name), subtitle: Text('${a.id} · ${a.status} · ${a.status == 'Verified' ? 'Tier 2' : 'Tier 1'}'), trailing: const Icon(Icons.chevron_right), onTap: () => _review(a))),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [OutlinedButton(onPressed: () => setState(() { _records = _seed(); _filter = 'Pending'; _search.clear(); }), child: const Text('Reset mock records')), TextButton(onPressed: () => setState(() => _records = []), child: const Text('Test empty state'))]),
    ]));
  }
}
