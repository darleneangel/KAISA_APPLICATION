import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const _forest = Color(0xFF154E2E);
const _paper = Color(0xFFF5F8F4);
const _muted = Color(0xFF596D60);

class ResidentDirectoryPage extends StatefulWidget {
  const ResidentDirectoryPage({super.key, this.previewOnly = false});
  final bool previewOnly;

  @override
  State<ResidentDirectoryPage> createState() => _ResidentDirectoryPageState();
}

class _Resident {
  const _Resident(this.id, this.name, this.barangay, this.tier, this.verification,
      this.account, this.memberships, this.affiliations, this.events);
  final String id, name, barangay, tier, verification, account;
  final List<String> memberships, affiliations, events;
}

List<_Resident> _samples() => const [
  _Resident('DEMO-001','Demo Resident 01','Sample Barangay A','Tier 2','Verified','Active',['Community Volunteers'],['Community Volunteers · Event Coordinator'],['Livelihood Workshop','Coastal Clean-Up Drive']),
  _Resident('DEMO-002','Demo Resident 02','Sample Barangay B','Tier 1','Pending','Active',[],[],[]),
  _Resident('DEMO-003','Demo Resident 03','Sample Barangay A','Tier 1','Not submitted','Active',[],[],[]),
  _Resident('DEMO-004','Demo Resident 04','Sample Barangay C','Tier 1','Needs information','Active',[],[],[]),
  _Resident('DEMO-005','Demo Resident 05','Sample Barangay B','Tier 1','Rejected','Active',[],[],[]),
  _Resident('DEMO-006','Demo Resident 06','Sample Barangay C','Tier 2','Verified','Restricted',['Youth Volunteers'],[],['Youth Leadership Seminar']),
  _Resident('DEMO-007','Demo Resident 07','Sample Barangay A','Tier 2','Verified','Active',['Environmental Volunteers'],[],['Coastal Clean-Up Drive']),
  _Resident('DEMO-008','Demo Resident 08','Sample Barangay B','Tier 1','Pending','Active',[],[],[]),
  _Resident('DEMO-009','Demo Resident 09','Sample Barangay C','Tier 2','Verified','Active',['Community Volunteers'],['Community Volunteers · Representative'],['Livelihood Workshop']),
  _Resident('DEMO-010','Demo Resident 10','Sample Barangay A','Tier 1','Not submitted','Active',[],[],[]),
  _Resident('DEMO-011','Demo Resident 11','Sample Barangay B','Tier 2','Verified','Active',[],[],[]),
  _Resident('DEMO-012','Demo Resident 12','Sample Barangay C','Tier 1','Pending','Active',[],[],[]),
];

class _ResidentDirectoryPageState extends State<ResidentDirectoryPage> {
  late bool _mock;
  List<_Resident> _records = _samples();
  final _search = TextEditingController();
  String _tier = 'All', _verification = 'All', _account = 'All', _barangay = 'All';
  bool _ascending = true;
  int _page = 0;
  static const _pageSize = 6;

  @override
  void initState() {
    super.initState();
    _mock = kDebugMode && (widget.previewOnly || const bool.fromEnvironment('USE_MOCK_DATA'));
  }
  @override
  void dispose() { _search.dispose(); super.dispose(); }
  void _resetFilters() {
    _search.clear(); _tier = _verification = _account = _barangay = 'All'; _page = 0; _ascending = true;
  }
  List<_Resident> get _filtered {
    final q = _search.text.trim().toLowerCase();
    return _records.where((r) => '${r.id} ${r.name} ${r.barangay}'.toLowerCase().contains(q) &&
      (_tier == 'All' || r.tier == _tier) && (_verification == 'All' || r.verification == _verification) &&
      (_account == 'All' || r.account == _account) && (_barangay == 'All' || r.barangay == _barangay)).toList()
      ..sort((a,b) => _ascending ? a.name.compareTo(b.name) : b.name.compareTo(a.name));
  }
  Widget _filter(String label, String value, List<String> options, ValueChanged<String> change) => SizedBox(
    width: 200, child: InputDecorator(decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: value, isExpanded: true, isDense: true,
        items: options.map((v) => DropdownMenuItem(value: v, child: Text(v, overflow: TextOverflow.ellipsis))).toList(),
        onChanged: (v) { if (v != null) setState(() { change(v); _page = 0; }); }))));
  Widget _stat(String label, int count, IconData icon, VoidCallback action) => SizedBox(width: 200, child: Card(
    elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFDDE7DE))),
    child: InkWell(borderRadius: BorderRadius.circular(12), onTap: action, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: _forest), const SizedBox(height: 8), Text('$count', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: _forest)), Text(label, style: const TextStyle(color: _muted)),
    ])))));
  Widget _tag(String value) {
    final color = value == 'Verified' || value == 'Active' || value == 'Tier 2' ? _forest : value == 'Rejected' || value == 'Restricted' ? const Color(0xFFA62929) : const Color(0xFF79591A);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: color.withValues(alpha: .09), borderRadius: BorderRadius.circular(6)), child: Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)));
  }
  Future<void> _details(_Resident r) => showDialog<void>(context: context, builder: (context) => AlertDialog(
    title: Text(r.name), content: SizedBox(width: 520, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      const Text('FICTIONAL RESIDENT · READ ONLY', style: TextStyle(color: _muted, fontSize: 12)), const SizedBox(height: 12),
      _field('Resident reference', r.id), _field('Barangay', r.barangay), _field('Account tier', r.tier), _field('Identity verification', r.verification), _field('Account status', r.account),
      const Divider(), _history('Organization memberships', r.memberships), _history('Administrative affiliations', r.affiliations), _history('Recorded participation', r.events),
      const Divider(), const Text('Identity decisions belong to Identity Verification. Account restrictions belong to Systems. No actual identity documents are displayed.'),
    ]))), actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
  ));
  Widget _field(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text(label, style: const TextStyle(color: _muted))), Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)))]));
  Widget _history(String title, List<String> entries) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 6), if (entries.isEmpty) const Text('No sample records', style: TextStyle(color: _muted)) else for (final e in entries) Padding(padding: const EdgeInsets.only(bottom: 5), child: Text(e))]));

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;
    final pages = rows.isEmpty ? 1 : (rows.length / _pageSize).ceil();
    final current = _page.clamp(0, pages - 1).toInt();
    final visible = rows.skip(current * _pageSize).take(_pageSize);
    final showMock = kDebugMode && _mock;
    return Material(color: _paper, child: SafeArea(child: ListView(padding: const EdgeInsets.all(24), children: [
      const Text('KAISA / RESIDENT MANAGEMENT', style: TextStyle(color: _forest, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: .6)),
      const SizedBox(height: 8), Text('Resident Directory', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: _forest, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4), const Text('Review resident eligibility, verification and community affiliations.', style: TextStyle(color: _muted)), const SizedBox(height: 20),
      if (kDebugMode) Card(elevation: 0, color: Colors.white, child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Mock Data Mode'), subtitle: Text(showMock ? 'Fictional records only. No database operations.' : 'Live directory integration not connected.'), value: showMock, onChanged: widget.previewOnly ? null : (v) => setState(() { _mock = v; _resetFilters(); })),
        if (showMock) Wrap(spacing: 8, runSpacing: 8, children: [OutlinedButton.icon(onPressed: () => setState(() { _records = _samples(); _resetFilters(); }), icon: const Icon(Icons.refresh), label: const Text('Reset samples')), TextButton(onPressed: () => setState(() { _records = []; _resetFilters(); }), child: const Text('Test empty state'))]),
      ]))),
      if (!showMock) const Card(elevation: 0, child: Padding(padding: EdgeInsets.all(24), child: Column(children: [Icon(Icons.storage_outlined, size: 40, color: _forest), SizedBox(height: 12), Text('Live resident directory is not connected', style: TextStyle(fontWeight: FontWeight.w700)), SizedBox(height: 8), Text('No authorized directory endpoint has been supplied. Resident totals and records are unavailable, not zero.', textAlign: TextAlign.center)])))
      else ...[
        const SizedBox(height: 12), Wrap(spacing: 8, runSpacing: 8, children: [
          _stat('Total residents', _records.length, Icons.groups_outlined, () => setState(_resetFilters)),
          _stat('Tier 1 residents', _records.where((r) => r.tier == 'Tier 1').length, Icons.person_outline, () => setState(() { _resetFilters(); _tier = 'Tier 1'; })),
          _stat('Tier 2 residents', _records.where((r) => r.tier == 'Tier 2').length, Icons.verified_user_outlined, () => setState(() { _resetFilters(); _tier = 'Tier 2'; })),
          _stat('Pending verification', _records.where((r) => r.verification == 'Pending').length, Icons.pending_actions, () => setState(() { _resetFilters(); _verification = 'Pending'; })),
        ]), const SizedBox(height: 16),
        Card(elevation: 0, color: Colors.white, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(controller: _search, onChanged: (_) => setState(() => _page = 0), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search resident name, reference or barangay', border: OutlineInputBorder())),
          const SizedBox(height: 12), Wrap(spacing: 12, runSpacing: 12, children: [
            _filter('Account tier', _tier, ['All','Tier 1','Tier 2'], (v) => _tier = v),
            _filter('Verification', _verification, ['All','Verified','Pending','Not submitted','Needs information','Rejected'], (v) => _verification = v),
            _filter('Account status', _account, ['All','Active','Restricted'], (v) => _account = v),
            _filter('Barangay', _barangay, ['All','Sample Barangay A','Sample Barangay B','Sample Barangay C'], (v) => _barangay = v),
            TextButton(onPressed: () => setState(_resetFilters), child: const Text('Clear filters')),
          ]), const SizedBox(height: 14), Row(children: [Expanded(child: Text('${rows.length} matching residents')), TextButton.icon(onPressed: () => setState(() { _ascending = !_ascending; _page = 0; }), icon: Icon(_ascending ? Icons.arrow_upward : Icons.arrow_downward), label: Text(_ascending ? 'Name A–Z' : 'Name Z–A'))]),
          if (rows.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Center(child: Text('No matching sample residents.')))
          else LayoutBuilder(builder: (context, c) => c.maxWidth >= 850 ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(columns: const [DataColumn(label: Text('Resident')),DataColumn(label: Text('Barangay')),DataColumn(label: Text('Tier')),DataColumn(label: Text('Verification')),DataColumn(label: Text('Account')),DataColumn(label: Text('Action'))], rows: [for (final r in visible) DataRow(cells: [DataCell(Text('${r.name}\n${r.id}')),DataCell(Text(r.barangay)),DataCell(_tag(r.tier)),DataCell(_tag(r.verification)),DataCell(_tag(r.account)),DataCell(TextButton(onPressed: () => _details(r), child: const Text('View details')))])])) : Column(children: [for (final r in visible) ...[ListTile(contentPadding: EdgeInsets.zero, leading: const CircleAvatar(child: Icon(Icons.person_outline)), title: Text(r.name), subtitle: Text('${r.id} · ${r.barangay}\n${r.tier} · ${r.verification} · ${r.account}'), isThreeLine: true, trailing: IconButton(tooltip: 'View details', onPressed: () => _details(r), icon: const Icon(Icons.chevron_right)), onTap: () => _details(r)), const Divider()]])),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [IconButton(tooltip: 'Previous page', onPressed: current == 0 ? null : () => setState(() => _page = current - 1), icon: const Icon(Icons.chevron_left)), Text('Page ${current + 1} of $pages'), IconButton(tooltip: 'Next page', onPressed: current + 1 >= pages ? null : () => setState(() => _page = current + 1), icon: const Icon(Icons.chevron_right))]),
        ]))),
      ],
    ])));
  }
}
