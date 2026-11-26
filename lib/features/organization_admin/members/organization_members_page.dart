import 'package:flutter/material.dart';
import '../../../shared/models/organization_membership_model.dart';
import '../../../shared/repositories/organization_membership_repository.dart';

/// Civic Dignity roster. Uses the existing prototype membership repository.
class OrganizationMembersPage extends StatefulWidget {
  final String organizationId;
  const OrganizationMembersPage({super.key, required this.organizationId});
  @override
  State<OrganizationMembersPage> createState() => _OrganizationMembersPageState();
}

class _OrganizationMembersPageState extends State<OrganizationMembersPage> {
  static const forest = Color(0xFF00301B);
  static const green = Color(0xFF2C6A4A);
  static const gold = Color(0xFFFDBC19);
  static const ink = Color(0xFF151C27);
  static const muted = Color(0xFF404942);
  static const canvas = Color(0xFFF9F9FF);
  static const soft = Color(0xFFF0F3FF);
  static const line = Color(0xFFE2E8F8);
  static const red = Color(0xFFBA1A1A);
  static const amber = Color(0xFF7B5900);
  static const pageSize = 6;
  final repository = OrganizationMembershipRepository.instance;
  final searchController = TextEditingController();
  String selectedFilter = 'Pending';
  bool newest = true, reviewing = false;
  int page = 0;

  @override
  void initState() {
    super.initState();
    repository.addListener(_refresh);
  }
  @override
  void didUpdateWidget(covariant OrganizationMembersPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.organizationId != widget.organizationId) {
      searchController.clear();
      selectedFilter = 'Pending';
      page = 0;
    }
  }
  void _refresh() { if (mounted) setState(() {}); }
  @override
  void dispose() {
    repository.removeListener(_refresh);
    searchController.dispose();
    super.dispose();
  }
  List<OrganizationMembership> get filteredMembers {
    final q = searchController.text.trim().toLowerCase();
    return repository.forOrganization(widget.organizationId).where((m) {
      return (selectedFilter == 'All' || m.status.label == selectedFilter) &&
        (m.residentName.toLowerCase().contains(q) ||
         m.residentEmail.toLowerCase().contains(q) || m.residentId.toLowerCase().contains(q));
    }).toList()..sort((a,b) => newest ? b.requestedAt.compareTo(a.requestedAt) : a.requestedAt.compareTo(b.requestedAt));
  }
  String _date(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final local = d.toLocal();
    return '${months[local.month-1]} ${local.day}, ${local.year}';
  }
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).take(2);
    return parts.isEmpty ? '?' : parts.map((s) => s.characters.first.toUpperCase()).join();
  }
  TextStyle _heading(double size) => TextStyle(fontFamily: 'Outfit', fontSize: size, fontWeight: FontWeight.w600, color: ink);
  TextStyle get _body => const TextStyle(fontFamily: 'Inter', color: muted, fontSize: 13, height: 1.45);
  BoxDecoration _surface({Color color = Colors.white}) => BoxDecoration(color: color, borderRadius: BorderRadius.circular(8), border: Border.all(color: line));
  ButtonStyle _primary({Color color = forest}) => FilledButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)));
  Widget _avatar(OrganizationMembership m) => Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: m.status == MembershipStatus.approved ? const Color(0xFFB0F1C8) : soft, borderRadius: BorderRadius.circular(12)), child: Text(_initials(m.residentName), style: const TextStyle(color: forest, fontWeight: FontWeight.w700)));
  Widget _status(OrganizationMembership m) {
    final (label, fg, bg, icon) = switch(m.status) {
      MembershipStatus.pending => ('Pending Review', amber, const Color(0xFFFFEDC9), Icons.schedule_rounded),
      MembershipStatus.approved => ('Active Member', forest, const Color(0xFFD4F4E0), Icons.check_rounded),
      MembershipStatus.rejected => ('Rejected', red, const Color(0xFFFFE5E2), Icons.close_rounded),
    };
    return Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon,size:13,color:fg),const SizedBox(width:5),Flexible(child: Text(label,style:TextStyle(color:fg,fontSize:12,fontWeight:FontWeight.w600)))]));
  }
  Future<void> _review(OrganizationMembership m, bool approve) async {
    if (reviewing || widget.organizationId.isEmpty) return;
    final organization = widget.organizationId;
    setState(() => reviewing = true);
    try {
      final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(children: [const Icon(Icons.how_to_reg_outlined,color:forest),const SizedBox(width:10),Expanded(child:Text('Review Membership Application',style:_heading(22)))]),
        content: SizedBox(width: 550, child: SingleChildScrollView(child: Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
          Container(padding:const EdgeInsets.all(16),decoration:_surface(color:soft),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[_avatar(m),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(m.residentName,style:_heading(18)),Text('Resident ID: ${m.residentId}',style:_body)]))]),
            const SizedBox(height:12),_status(m),const SizedBox(height:8),Text('Submitted ${_date(m.requestedAt)}',style:_body),
          ])),
          const SizedBox(height:16),Text(approve ? 'Approve this membership application?' : 'Reject this membership application?',style:_heading(17)),
          const SizedBox(height:10),Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:const Color(0xFFFFF4DD),borderRadius:BorderRadius.circular(6)),child:const Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.shield_outlined,color:amber,size:20),SizedBox(width:10),Expanded(child:Text('Membership approval does not grant Officer or Organization Administrator privileges. These decisions currently use prototype records, not a verified civil registry.',style:TextStyle(color:amber,fontSize:13,height:1.5)))])),
        ]))),
        actions:[TextButton(onPressed:()=>Navigator.pop(dialogContext,false),child:const Text('Cancel')),FilledButton.icon(style:_primary(color:approve?forest:red),onPressed:()=>Navigator.pop(dialogContext,true),icon:Icon(approve?Icons.check:Icons.close),label:Text(approve?'Confirm & Approve Member':'Confirm Rejection'))],
      ));
      if (!mounted || confirmed != true || organization != widget.organizationId) return;
      // Existing synchronous prototype repository methods are retained.
      if (approve) { repository.approveMembership(m.id, organization); }
      else { repository.rejectMembership(m.id, organization); }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(approve?'Membership application approved.':'Membership application rejected.')));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e is StateError ? e.message.toString() : 'Unable to review membership.')));
    } finally { if(mounted) setState(()=>reviewing=false); }
  }
  Widget _summary(String title,int count,IconData icon,Color color,Color bg,String hint,String filter) => Material(color:Colors.white,borderRadius:BorderRadius.circular(8),child:InkWell(borderRadius:BorderRadius.circular(8),onTap:()=>setState((){selectedFilter=filter;page=0;}),child:Container(constraints:const BoxConstraints(minHeight:155),padding:const EdgeInsets.all(20),decoration:BoxDecoration(border:Border(left:BorderSide(color:color,width:3)),borderRadius:BorderRadius.circular(8)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:Text(title,style:_body)),Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:bg,borderRadius:BorderRadius.circular(5)),child:Icon(icon,color:color,size:21))]),Text('$count',style:_heading(32)),const SizedBox(height:12),Text(hint,style:TextStyle(color:color,fontSize:12)),
  ]))));
  Widget _summaries(int pending,int approved,int rejected) => LayoutBuilder(builder:(_,c){final n=c.maxWidth>=800?3:c.maxWidth>=500?2:1;final width=(c.maxWidth-(n-1)*16)/n;return Wrap(spacing:16,runSpacing:16,children:[
    SizedBox(width:width,child:_summary('Pending Applications',pending,Icons.hourglass_top_rounded,gold,const Color(0xFFFFEDC9),'Requires review','Pending')),
    SizedBox(width:width,child:_summary('Active Members',approved,Icons.groups_outlined,forest,const Color(0xFFD4F4E0),'Approved membership records','Approved')),
    SizedBox(width:width,child:_summary('Rejected Applications',rejected,Icons.person_off_outlined,red,const Color(0xFFFFE5E2),'Historical decisions','Rejected')),
  ]);});
  Widget _tab(String filter,String label,int count) => TextButton(style:TextButton.styleFrom(backgroundColor:selectedFilter==filter?forest:soft,foregroundColor:selectedFilter==filter?Colors.white:muted,padding:const EdgeInsets.symmetric(horizontal:12,vertical:9),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(5))),onPressed:()=>setState((){selectedFilter=filter;page=0;}),child:Text('$label ($count)',style:const TextStyle(fontSize:12)));
  Widget _actions(OrganizationMembership m) => m.status!=MembershipStatus.pending ? Text(m.reviewedAt==null?m.status.label:'${m.status.label} · ${_date(m.reviewedAt!)}',style:_body) : Wrap(spacing:6,runSpacing:6,children:[
    FilledButton(style:_primary(),onPressed:reviewing?null:()=>_review(m,true),child:const Text('Approve')),
    OutlinedButton(style:OutlinedButton.styleFrom(foregroundColor:red,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(5))),onPressed:reviewing?null:()=>_review(m,false),child:const Text('Reject')),
  ]);
  Widget _person(OrganizationMembership m) => Row(children:[_avatar(m),const SizedBox(width:10),Expanded(child:Text(m.residentName,style:const TextStyle(color:ink,fontSize:14,fontWeight:FontWeight.w600),maxLines:3,overflow:TextOverflow.ellipsis))]);
  Widget _desktop(List<OrganizationMembership> rows) => LayoutBuilder(builder:(_,c)=>SingleChildScrollView(scrollDirection:Axis.horizontal,child:ConstrainedBox(constraints:BoxConstraints(minWidth:c.maxWidth),child:DataTable(
    showCheckboxColumn:false,headingRowColor:WidgetStateProperty.all(soft),headingTextStyle:const TextStyle(fontFamily:'Inter',fontSize:11,fontWeight:FontWeight.w600,color:muted,letterSpacing:.5),dataTextStyle:const TextStyle(fontFamily:'Inter',fontSize:13,color:ink),dataRowMinHeight:92,dataRowMaxHeight:120,columnSpacing:18,horizontalMargin:20,dividerThickness:0.6,
    columns:const [DataColumn(label:Text('RESIDENT APPLICANT')),DataColumn(label:Text('RESIDENT ID')),DataColumn(label:Text('CONTACT EMAIL')),DataColumn(label:Text('APPLICATION DATE')),DataColumn(label:Text('REVIEW STATUS')),DataColumn(label:Text('REVIEW ACTION'))],
    rows:[for(final m in rows) DataRow(cells:[DataCell(SizedBox(width:176,child:_person(m))),DataCell(SizedBox(width:100,child:Text(m.residentId,maxLines:3,overflow:TextOverflow.ellipsis))),DataCell(SizedBox(width:175,child:Text(m.residentEmail,maxLines:3,overflow:TextOverflow.ellipsis))),DataCell(Text(_date(m.requestedAt))),DataCell(SizedBox(width:135,child:_status(m))),DataCell(SizedBox(width:168,child:_actions(m)))])],
  ))));
  Widget _mobile(List<OrganizationMembership> rows) => Column(children:[for(final m in rows) Container(width:double.infinity,padding:const EdgeInsets.all(16),decoration:const BoxDecoration(border:Border(bottom:BorderSide(color:line))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_person(m),const SizedBox(height:12),Text('Resident ID: ${m.residentId}',style:_body),Text(m.residentEmail,style:_body),const SizedBox(height:8),Wrap(spacing:12,runSpacing:8,crossAxisAlignment:WrapCrossAlignment.center,children:[_status(m),Text('Applied ${_date(m.requestedAt)}',style:_body),if(m.reviewedAt!=null)Text('Reviewed ${_date(m.reviewedAt!)}',style:_body)]),const SizedBox(height:10),_actions(m)]))]);
  Widget _records(int pending,int approved,int rejected,int total) {
    final all=filteredMembers; final pages=all.isEmpty?1:(all.length/pageSize).ceil(); final current=page.clamp(0,pages-1).toInt(); final rows=all.skip(current*pageSize).take(pageSize).toList();
    return Container(decoration:_surface(),clipBehavior:Clip.antiAlias,child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Padding(padding:const EdgeInsets.all(20),child:Wrap(alignment:WrapAlignment.spaceBetween,crossAxisAlignment:WrapCrossAlignment.center,spacing:12,runSpacing:10,children:[Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Membership Records',style:_heading(21)),Text('$total total records · Organization-scoped roster',style:_body)]),Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),decoration:BoxDecoration(color:soft,borderRadius:BorderRadius.circular(12)),child:const Text('Prototype records',style:TextStyle(color:muted,fontSize:12)))])),
      Container(color:soft,padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Wrap(spacing:6,runSpacing:6,children:[_tab('Pending','Pending',pending),_tab('Approved','Approved',approved),_tab('Rejected','Rejected',rejected),_tab('All','All Records',total)]),const SizedBox(height:12),LayoutBuilder(builder:(_,c){final search=TextField(controller:searchController,onChanged:(_)=>setState(()=>page=0),decoration:InputDecoration(filled:true,fillColor:Colors.white,isDense:true,prefixIcon:const Icon(Icons.search_rounded),hintText:'Search name, email or resident ID',suffixIcon:searchController.text.isEmpty?null:IconButton(tooltip:'Clear search',onPressed:()=>setState((){searchController.clear();page=0;}),icon:const Icon(Icons.close)),border:OutlineInputBorder(borderRadius:BorderRadius.circular(5),borderSide:BorderSide.none)));final sort=DropdownButtonHideUnderline(child:DropdownButton<bool>(value:newest,isExpanded:true,items:const [DropdownMenuItem(value:true,child:Text('Sort: Most Recent')),DropdownMenuItem(value:false,child:Text('Sort: Oldest First'))],onChanged:(v){if(v!=null)setState((){newest=v;page=0;});}));final sortBox=Container(padding:const EdgeInsets.symmetric(horizontal:10),decoration:_surface(),child:sort);return c.maxWidth>=560?Row(children:[Expanded(child:search),const SizedBox(width:12),SizedBox(width:210,child:sortBox)]):Column(children:[search,const SizedBox(height:10),sortBox]);})])),
      if(rows.isEmpty) Padding(padding:const EdgeInsets.symmetric(vertical:56,horizontal:20),child:Column(children:[const Icon(Icons.people_outline,color:green,size:34),const SizedBox(height:12),Text(searchController.text.trim().isNotEmpty?'No matching records':selectedFilter=='Pending'?'No pending applications':'No membership records found',style:_heading(18),textAlign:TextAlign.center),const SizedBox(height:6),Text('Try a different filter or search.',style:_body,textAlign:TextAlign.center)])) else LayoutBuilder(builder:(_,c)=>c.maxWidth>=760?_desktop(rows):_mobile(rows)),
      Container(color:canvas,padding:const EdgeInsets.all(16),child:Wrap(alignment:WrapAlignment.spaceBetween,crossAxisAlignment:WrapCrossAlignment.center,spacing:12,runSpacing:8,children:[Text(all.isEmpty?'Showing 0 records':'Showing ${current*pageSize+1}–${current*pageSize+rows.length} of ${all.length} records',style:_body),Row(mainAxisSize:MainAxisSize.min,children:[IconButton(tooltip:'Previous page',onPressed:current==0?null:()=>setState(()=>page=current-1),icon:const Icon(Icons.chevron_left)),Text('${current+1} / $pages',style:const TextStyle(color:forest,fontWeight:FontWeight.w600)),IconButton(tooltip:'Next page',onPressed:current>=pages-1?null:()=>setState(()=>page=current+1),icon:const Icon(Icons.chevron_right))])])),
    ]));
  }
  @override
  Widget build(BuildContext context) {
    if(widget.organizationId.trim().isEmpty) return const Center(child:Text('Select an organization to view membership records.'));
    final pending=repository.countByStatus(widget.organizationId,MembershipStatus.pending);
    final approved=repository.countByStatus(widget.organizationId,MembershipStatus.approved);
    final rejected=repository.countByStatus(widget.organizationId,MembershipStatus.rejected);
    return ColoredBox(color:canvas,child:LayoutBuilder(builder:(_,c)=>SingleChildScrollView(padding:EdgeInsets.all(c.maxWidth<600?16:24),child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:1400),child:DefaultTextStyle.merge(style:const TextStyle(fontFamily:'Inter',color:ink),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      const Text('KAISA / PEOPLE MANAGEMENT',style:TextStyle(color:forest,fontSize:12,fontWeight:FontWeight.w600,letterSpacing:1)),const SizedBox(height:8),Text('Members & Requests',style:_heading(32)),const SizedBox(height:6),Text('Review membership applications and manage your organization’s civic volunteer roster.',style:_body),const SizedBox(height:24),
      _summaries(pending,approved,rejected),const SizedBox(height:24),_records(pending,approved,rejected,pending+approved+rejected),const SizedBox(height:18),Container(padding:const EdgeInsets.all(14),decoration:_surface(color:soft),child:const Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.info_outline,color:green,size:19),SizedBox(width:10),Expanded(child:Text('Prototype records only. Membership decisions are currently stored in memory; database persistence and civil registry verification are not connected.',style:TextStyle(fontSize:12,color:muted,height:1.5)))])),
    ])))))));
  }
}
