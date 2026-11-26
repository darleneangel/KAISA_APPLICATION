import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/organization/kaisa_organization_access.dart';

/// Organization-scoped invitation composer. Authorization remains in the service/RPC.
class _LiveInviteStaffPage extends StatefulWidget {
  const _LiveInviteStaffPage({super.key, required this.organizationId});
  final String organizationId;
  @override
  State<_LiveInviteStaffPage> createState() => _KaisaInviteStaffPageState();
}

class _KaisaInviteStaffPageState extends State<_LiveInviteStaffPage> {
  static const forest=Color(0xFF00301B), green=Color(0xFF2C6A4A), gold=Color(0xFFFDBC19), ink=Color(0xFF151C27), muted=Color(0xFF404942), canvas=Color(0xFFF9F9FF), soft=Color(0xFFF0F3FF), line=Color(0xFFE2E8F8), amber=Color(0xFF7B5900), red=Color(0xFFBA1A1A);
  final search=TextEditingController(), note=TextEditingController();
  Timer? debounce;
  List<Map<String,dynamic>> matches=[];
  Map<String,dynamic>? selected;
  String role='Officer';
  bool searching=false,sending=false,confirming=false,history=false;
  String? error;
  int generation=0,scopeGeneration=0;
  bool get busy=>sending||confirming;
  @override
  void didUpdateWidget(covariant _LiveInviteStaffPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if(oldWidget.organizationId!=widget.organizationId){
      ++generation; ++scopeGeneration; debounce?.cancel();
      search.clear();note.clear();matches=[];selected=null;role='Officer';
      searching=false;sending=false;confirming=false;error=null;history=false;
    }
  }
  @override
  void dispose(){debounce?.cancel();search.dispose();note.dispose();super.dispose();}
  void onSearch(String value){
    if(busy)return;
    debounce?.cancel();final id=++generation;final organization=widget.organizationId;final query=value.trim();
    setState((){selected=null;matches=[];error=null;searching=query.length>=3&&organization.isNotEmpty;});
    if(query.length<3||organization.isEmpty)return;
    debounce=Timer(const Duration(milliseconds:320),()async{
      try{
        final results=await KaisaOrganizationAccess.instance.searchResidents(organization,query);
        if(mounted&&id==generation&&organization==widget.organizationId){setState((){matches=results;searching=false;});}
      }catch(e){if(mounted&&id==generation&&organization==widget.organizationId){setState((){error='$e';searching=false;});}}
    });
  }
  String _name(Map<String,dynamic> person)=>'${person['full_name']??'Resident'}';
  String _initials(String name){final parts=name.trim().split(RegExp(r'\s+')).where((s)=>s.isNotEmpty).take(2);return parts.isEmpty?'?':parts.map((s)=>s.characters.first.toUpperCase()).join();}
  String? _residentId(Map<String,dynamic>? person){final id=person?['user_id']?.toString().trim();return id==null||id.isEmpty?null:id;}
  Future<void> submit()async{
    final person=selected;final residentId=_residentId(person);final organization=widget.organizationId;final proposedRole=role;final message=note.text.trim();final scope=scopeGeneration;
    if(person==null||residentId==null||busy||organization.trim().isEmpty||!['Officer','Admin'].contains(proposedRole)||message.characters.length>500)return;
    setState(()=>confirming=true);
    bool? confirmed;
    try{
      confirmed=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(backgroundColor:Colors.white,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)),title:Text('Confirm staff invitation',style:_heading(22)),content:SizedBox(width:480,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
        Container(padding:const EdgeInsets.all(14),decoration:_surface(color:soft),child:Row(children:[_avatar(person),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(_name(person),style:_heading(18)),Text(proposedRole=='Admin'?'Proposed Administrator':'Proposed Officer',style:_body)]))])),const SizedBox(height:14),Text('Send an invitation for the currently selected organization?',style:_body),if(message.isNotEmpty)...[const SizedBox(height:12),Text('Invitation message',style:_heading(15)),Text(message,style:_body)],const SizedBox(height:14),_notice(proposedRole=='Admin'?'The resident must accept. Administrator elevation also requires Super Admin review.':'The resident must accept before Officer access can be granted under the existing authorization workflow.',Icons.shield_outlined),
      ]))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton.icon(style:_primary(),onPressed:()=>Navigator.pop(ctx,true),icon:const Icon(Icons.send_outlined,size:18),label:const Text('Confirm & Send'))]));
    }finally{if(mounted&&scope==scopeGeneration)setState(()=>confirming=false);}
    if(!mounted||scope!=scopeGeneration||confirmed!=true||organization!=widget.organizationId)return;
    ++generation;debounce?.cancel();
    setState((){sending=true;searching=false;error=null;});
    try{
      await KaisaOrganizationAccess.instance.invite(organizationId:organization,residentId:residentId,role:proposedRole,note:message);
      if(!mounted||scope!=scopeGeneration)return;
      search.clear();note.clear();setState((){selected=null;matches=[];role='Officer';});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Invitation sent for resident approval.')));
    }catch(e){if(mounted&&scope==scopeGeneration)setState(()=>error='$e');}
    finally{if(mounted&&scope==scopeGeneration)setState(()=>sending=false);}
  }
  TextStyle _heading(double size)=>TextStyle(fontFamily:'Outfit',fontSize:size,fontWeight:FontWeight.w600,color:ink);
  TextStyle get _body=>const TextStyle(fontFamily:'Inter',color:muted,fontSize:14,height:1.45);
  BoxDecoration _surface({Color color=Colors.white})=>BoxDecoration(color:color,borderRadius:BorderRadius.circular(8),border:Border.all(color:line));
  ButtonStyle _primary()=>FilledButton.styleFrom(backgroundColor:forest,foregroundColor:Colors.white,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(5)),padding:const EdgeInsets.symmetric(horizontal:18,vertical:14));
  Widget _panel(String title,String description,Widget child)=>Container(width:double.infinity,padding:const EdgeInsets.all(22),decoration:_surface(),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text(title,style:_heading(22)),const SizedBox(height:5),Text(description,style:_body),const SizedBox(height:20),child]));
  Widget _avatar(Map<String,dynamic> person)=>Container(width:44,height:44,alignment:Alignment.center,decoration:BoxDecoration(color:const Color(0xFFD4F4E0),borderRadius:BorderRadius.circular(12)),child:Text(_initials(_name(person)),style:const TextStyle(color:forest,fontWeight:FontWeight.w700)));
  Widget _notice(String message,IconData icon,{Color color=amber,Color bg=const Color(0xFFFFF1D6)})=>Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:bg,borderRadius:BorderRadius.circular(6)),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:color,size:20),const SizedBox(width:10),Expanded(child:Text(message,style:TextStyle(color:color,fontSize:13,height:1.45)))]));
  Widget _empty(String title,String description,IconData icon)=>Container(padding:const EdgeInsets.symmetric(vertical:30,horizontal:16),decoration:_surface(color:canvas),child:Column(children:[Icon(icon,color:green,size:32),const SizedBox(height:12),Text(title,style:_heading(18),textAlign:TextAlign.center),const SizedBox(height:6),Text(description,style:_body,textAlign:TextAlign.center)]));
  Widget _tabs()=>Container(padding:const EdgeInsets.all(4),decoration:BoxDecoration(color:soft,borderRadius:BorderRadius.circular(6)),child:Wrap(spacing:4,runSpacing:4,children:[for(final entry in [(false,'Invite Staff'),(true,'Invitation History (Proposed Enhancement)')])TextButton(style:TextButton.styleFrom(backgroundColor:history==entry.$1?Colors.white:Colors.transparent,foregroundColor:history==entry.$1?forest:muted,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(5)),padding:const EdgeInsets.symmetric(horizontal:14,vertical:12)),onPressed:busy?null:()=>setState(()=>history=entry.$1),child:Text(entry.$2,style:TextStyle(fontSize:13,fontWeight:history==entry.$1?FontWeight.w600:FontWeight.w400))) ]));
  Widget _header()=>LayoutBuilder(builder:(_,c){final title=Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('KAISA / PEOPLE MANAGEMENT',style:TextStyle(color:forest,fontWeight:FontWeight.w600,letterSpacing:1,fontSize:12)),const SizedBox(height:8),Text('Staff & Permissions',style:_heading(32)),const SizedBox(height:6),Text('Invite verified residents to support and manage your organization.',style:_body)]);return c.maxWidth>=950?Row(crossAxisAlignment:CrossAxisAlignment.end,children:[Expanded(child:title),const SizedBox(width:20),Flexible(child:_tabs())]):Column(crossAxisAlignment:CrossAxisAlignment.start,children:[title,const SizedBox(height:16),_tabs()]);});
  Widget _steps()=>Container(padding:const EdgeInsets.all(16),decoration:_surface(),child:Wrap(spacing:20,runSpacing:12,children:[for(final step in [(1,'Find Resident'),(2,'Assign Role'),(3,'Send Invitation')])Row(mainAxisSize:MainAxisSize.min,children:[Container(width:30,height:30,alignment:Alignment.center,decoration:BoxDecoration(color:(selected==null?step.$1==1:step.$1<=2||sending)?forest:soft,borderRadius:BorderRadius.circular(20)),child:Text('${step.$1}',style:TextStyle(color:(selected==null?step.$1==1:step.$1<=2||sending)?Colors.white:muted,fontWeight:FontWeight.w600))),const SizedBox(width:8),Text(step.$2,style:_body)])]));
  Widget _searchPanel()=>_panel('Find Eligible Residents','Search by full name or exact email. Only verified Tier 2 residents are eligible.',Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    TextField(controller:search,enabled:!busy,onChanged:onSearch,decoration:InputDecoration(hintText:'Type at least 3 characters',prefixIcon:const Icon(Icons.search_rounded),suffixIcon:search.text.isEmpty?null:IconButton(tooltip:'Clear search',onPressed:busy?null:(){search.clear();onSearch('');},icon:const Icon(Icons.close)),filled:true,fillColor:canvas,border:OutlineInputBorder(borderRadius:BorderRadius.circular(6),borderSide:const BorderSide(color:line)))),const SizedBox(height:12),
    if(searching)const LinearProgressIndicator(color:green) else if(error!=null&&selected==null)_notice('Search failed: $error',Icons.error_outline,color:red,bg:const Color(0xFFFFE5E2)) else if(search.text.trim().isEmpty)_empty('Find a resident','Search by name or exact email to get started.',Icons.person_search_outlined) else if(search.text.trim().length<3)_empty('Keep typing','Enter at least three characters to search.',Icons.search) else if(matches.isEmpty)_empty('No matching eligible residents','Try another name or exact email address.',Icons.person_search_outlined) else ...[
      Text('${matches.length} matching resident(s)',style:_body),const SizedBox(height:10),for(final person in matches)Padding(padding:const EdgeInsets.only(bottom:8),child:Material(color:selected?['user_id']==person['user_id']?const Color(0xFFE5F5EB):canvas,borderRadius:BorderRadius.circular(8),child:ListTile(enabled:!busy&&_residentId(person)!=null,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(8),side:BorderSide(color:selected?['user_id']==person['user_id']?green:line)),leading:_avatar(person),title:Text(_name(person),style:const TextStyle(fontWeight:FontWeight.w600,color:ink)),subtitle:const Text('Tier 2 · Verified',style:TextStyle(color:green,fontSize:12)),trailing:Icon(selected?['user_id']==person['user_id']?Icons.check_circle:Icons.add_circle_outline,color:green),onTap:()=>setState((){selected=person;error=null;})))),
    ],const SizedBox(height:12),const Text('Email addresses are never shown in search suggestions.',style:TextStyle(color:muted,fontSize:12)),
  ]));
  Widget _roleCard(String value,String title,String description,IconData icon)=>Material(color:role==value?const Color(0xFFE5F5EB):canvas,borderRadius:BorderRadius.circular(8),child:InkWell(borderRadius:BorderRadius.circular(8),onTap:busy?null:()=>setState(()=>role=value),child:Container(padding:const EdgeInsets.all(13),decoration:BoxDecoration(border:Border.all(color:role==value?green:line),borderRadius:BorderRadius.circular(8)),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:forest,size:22),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(color:ink,fontWeight:FontWeight.w600,fontSize:15)),const SizedBox(height:4),Text(description,style:_body)])),Icon(role==value?Icons.radio_button_checked:Icons.radio_button_unchecked,color:green,size:20)]))));
  Widget _details()=>_panel('Invitation Details','Select the proposed role and prepare an invitation.',selected==null?_empty('No resident selected','Select an eligible resident to continue.',Icons.person_add_alt_1_outlined):Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Container(padding:const EdgeInsets.all(12),decoration:_surface(color:soft),child:Row(children:[_avatar(selected!),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(_name(selected!),style:_heading(17)),const Text('Tier 2 · Verified',style:TextStyle(color:green,fontSize:12))])),TextButton(onPressed:busy?null:()=>setState(()=>selected=null),child:const Text('Change'))])),const SizedBox(height:18),Text('Proposed role',style:_heading(16)),const SizedBox(height:10),_roleCard('Officer','Officer','Limited organization workspace.',Icons.groups_outlined),const SizedBox(height:8),_roleCard('Admin','Administrator elevation','Super Admin approval required (legacy workflow).',Icons.admin_panel_settings_outlined),if(role=='Admin')...[const SizedBox(height:12),_notice('Administrator access is not granted automatically. Super Admin review is required.',Icons.shield_outlined)],const SizedBox(height:18),TextField(controller:note,enabled:!busy,maxLength:500,maxLines:3,decoration:InputDecoration(labelText:'Invitation message (optional)',alignLabelWithHint:true,filled:true,fillColor:canvas,border:OutlineInputBorder(borderRadius:BorderRadius.circular(6),borderSide:const BorderSide(color:line)))),const SizedBox(height:8),if(error!=null)...[_notice(error!,Icons.error_outline,color:red,bg:const Color(0xFFFFE5E2)),const SizedBox(height:10)],FilledButton.icon(style:_primary(),onPressed:busy||_residentId(selected)==null?null:submit,icon:sending?const SizedBox(width:17,height:17,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.send_outlined,size:18),label:Text(sending?'Sending…':'Send invitation')),
  ]));
  Widget _process()=>_panel('How Staff Access Works','Invitations and administrative authorization are separate.',Column(children:[for(final step in [(Icons.mail_outline,'Invitation sent','The administrator proposes an organization role.'),(Icons.person_outline,'Resident acceptance','The invitee must accept the invitation.'),(Icons.shield_outlined,'Required approval','Administrator elevation requires Super Admin review. Officer access follows the existing role checks.')])Padding(padding:const EdgeInsets.only(bottom:16),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:soft,borderRadius:BorderRadius.circular(6)),child:Icon(step.$1,color:forest)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(step.$2,style:_heading(17)),const SizedBox(height:3),Text(step.$3,style:_body)]))]))]));
  Widget _compose()=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[_steps(),const SizedBox(height:24),LayoutBuilder(builder:(_,c)=>c.maxWidth>=850?Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:_searchPanel()),const SizedBox(width:24),Expanded(child:_details())]):Column(children:[_searchPanel(),const SizedBox(height:16),_details()])),const SizedBox(height:24),_process()]);
  Widget _historyCard(String label,String status,Color color,Color bg)=>Container(padding:const EdgeInsets.all(20),constraints:const BoxConstraints(minHeight:145),decoration:_surface(),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:Text(label,style:_body)),Icon(Icons.circle,color:color,size:10)]),const SizedBox(height:16),Wrap(spacing:10,runSpacing:6,crossAxisAlignment:WrapCrossAlignment.center,children:[Text('—',style:_heading(32)),Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:4),decoration:BoxDecoration(color:bg,borderRadius:BorderRadius.circular(12)),child:Text(status,style:TextStyle(fontSize:12,color:color)))])]));
  Widget _history()=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    _notice('Proposed Backend Enhancement — Invitation response and Super Admin review history is not connected to this page yet.',Icons.science_outlined),const SizedBox(height:24),LayoutBuilder(builder:(_,c){final n=c.maxWidth>=900?4:c.maxWidth>=480?2:1;final w=(c.maxWidth-(n-1)*16)/n;return Wrap(spacing:16,runSpacing:16,children:[for(final item in [('Awaiting Resident Response','Pending',amber,const Color(0xFFFFEDC9)),('Awaiting Super Admin Review','In Review',ink,line),('Approved or Active','Active',forest,const Color(0xFFD4F4E0)),('Declined','Closed',red,const Color(0xFFFFE5E2))])SizedBox(width:w,child:_historyCard(item.$1,item.$2,item.$3,item.$4))]);}),const SizedBox(height:24),Container(decoration:_surface(),clipBehavior:Clip.antiAlias,child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Padding(padding:const EdgeInsets.all(20),child:Wrap(spacing:12,runSpacing:10,crossAxisAlignment:WrapCrossAlignment.center,children:[Text('Invitation History',style:_heading(22)),const Text('Data unavailable',style:TextStyle(color:muted,fontSize:12)),for(final text in ['All Invitations','Awaiting Response','Under Review','Accepted','Declined'])Chip(label:Text(text,style:const TextStyle(fontSize:12,color:muted)),backgroundColor:soft,side:BorderSide.none)])),LayoutBuilder(builder:(_,c)=>c.maxWidth<760?const SizedBox.shrink():Container(color:soft,padding:const EdgeInsets.all(16),child:Row(children:[for(final label in ['INVITED RESIDENT','PROPOSED ROLE','DATE SENT','RESPONSE STATUS','APPROVAL STATUS','ACTIONS'])Expanded(child:Padding(padding:const EdgeInsets.only(right:8),child:Text(label,style:const TextStyle(fontSize:11,letterSpacing:.4,fontWeight:FontWeight.w600,color:muted))))]))),Padding(padding:const EdgeInsets.all(20),child:_empty('Invitation history unavailable','The existing invitation service supports sending invitations. A server-authorized history endpoint is required to display responses and approval status.',Icons.history)),Container(color:canvas,padding:const EdgeInsets.all(16),child:Text('No sample records are shown. History filters, resend, cancel and revoke require backend support.',style:_body))])),
  ]);
  @override
  Widget build(BuildContext context){if(widget.organizationId.trim().isEmpty)return const Center(child:Text('Select an organization before inviting staff.'));return ColoredBox(color:canvas,child:LayoutBuilder(builder:(_,c)=>SingleChildScrollView(padding:EdgeInsets.all(c.maxWidth<600?16:24),child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:1400),child:DefaultTextStyle.merge(style:const TextStyle(fontFamily:'Inter',color:ink),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Align(alignment:Alignment.centerLeft,child:TextButton.icon(onPressed:busy?null:()=>context.go(Uri(path:'/organization-admin/dashboard',queryParameters:{'organizationId':widget.organizationId}).toString()),icon:const Icon(Icons.arrow_back,size:18),label:const Text('Dashboard'))),const SizedBox(height:8),_header(),const SizedBox(height:24),if(history)_history()else _compose(),
  ])))))));}
}


/// Keep the existing route and constructor. Mock mode never invokes the service.
class KaisaInviteStaffPage extends StatefulWidget {
  const KaisaInviteStaffPage({super.key, required this.organizationId});
  final String organizationId;
  @override
  State<KaisaInviteStaffPage> createState() => _StaffSwitchState();
}

class _StaffSwitchState extends State<KaisaInviteStaffPage> {
  bool mock = kDebugMode && const bool.fromEnvironment('USE_MOCK_DATA');
  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (kDebugMode) Material(
        color: const Color(0xFFEAF5EB),
        child: SwitchListTile(
          title: Text(mock ? 'Mock data mode' : 'Existing service mode'),
          subtitle: Text(mock ? 'Fictional staff; no database writes.' : 'Real invitations use the existing authorized service.'),
          value: mock,
          onChanged: (v) => setState(() => mock = v),
        ),
      ),
      Expanded(child: mock && kDebugMode
        ? _MockStaffPage(key: ValueKey('mock-${widget.organizationId}'))
        : _LiveInviteStaffPage(key: ValueKey('live-${widget.organizationId}'), organizationId: widget.organizationId)),
    ],
  );
}

const _permissionGroups = <String, List<String>>{
  'Members & Requests': ['View members', 'Review applications', 'Decide applications'],
  'Events Management': ['Create drafts', 'Edit events', 'Publish events', 'Review event applications', 'Manage participants'],
  'Attendance Management': ['Scan QR codes', 'Manual check-in', 'Finalize attendance'],
  'E-Certificate Studio': ['Manage templates', 'Generate certificates', 'Issue certificates'],
  'Feed & Announcements': ['Create announcements', 'Publish announcements'],
  'Reports & Exports': ['View reports', 'Export records'],
  'Organization Profile': ['Edit public profile'],
};
const _presets = <String, List<String>>{
  'Custom': [],
  'Event Coordinator': ['Create drafts', 'Edit events', 'Review event applications', 'Manage participants'],
  'Attendance Officer': ['Scan QR codes', 'Manual check-in'],
  'Membership Secretary': ['View members', 'Review applications'],
  'Certificate Officer': ['Manage templates', 'Generate certificates'],
  'Communications Officer': ['Create announcements'],
};

class _DemoStaff {
  _DemoStaff(this.email, this.designation, this.status, Iterable<String> permissions)
    : permissions = permissions.toSet();
  final String email;
  String designation;
  String status;
  Set<String> permissions;
}

class _MockStaffPage extends StatefulWidget {
  const _MockStaffPage({super.key});
  @override
  State<_MockStaffPage> createState() => _MockStaffState();
}

class _MockStaffState extends State<_MockStaffPage> {
  static const forest = Color(0xFF00301B);
  static const canvas = Color(0xFFF9F9FF);
  final search = TextEditingController();
  final List<_DemoStaff> records = [];
  final List<String> logs = [];
  String tab = 'Staff Directory';
  @override
  void initState() { super.initState(); _seed(); }
  @override
  void dispose() { search.dispose(); super.dispose(); }
  void _seed() {
    records..clear()..addAll([
      _DemoStaff('alex@example.com','Event Coordinator','Active',_presets['Event Coordinator']!),
      _DemoStaff('sam@example.com','Attendance Officer','Active',_presets['Attendance Officer']!),
      _DemoStaff('jordan@example.com','Membership Secretary','Pending',_presets['Membership Secretary']!),
      _DemoStaff('casey@example.com','Certificate Officer','Pending',_presets['Certificate Officer']!),
      _DemoStaff('taylor@example.com','Communications Officer','Revoked',_presets['Communications Officer']!),
      _DemoStaff('morgan@example.com','Attendance Officer','Declined',_presets['Attendance Officer']!),
    ]);
    logs..clear()..add('Demo records initialized');
  }
  void _log(String message) => logs.insert(0, '${DateTime.now().toLocal().toString().substring(0,16)} · $message');
  Future<void> _edit([_DemoStaff? staff]) async {
    final result = await showDialog<_DemoStaff>(context: context, builder: (_) => _StaffEditor(staff: staff, existingEmails: records.where((r) => r.status == 'Active' || r.status == 'Pending' || r.status == 'Awaiting verification').map((r) => r.email).toSet()));
    if (!mounted || result == null) return;
    setState(() {
      if (staff == null) { records.add(result); _log('Mock invitation sent to ${result.email}'); tab = 'Invitations'; }
      else { staff.designation = result.designation; staff.permissions = result.permissions; _log('Permissions updated for ${staff.email}'); }
    });
  }
  Future<void> _transition(_DemoStaff staff, String status) async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text('Change status to $status?'),
      content: Text('${staff.email} — mock action only. No actual access will change.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx,false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx,true), child: const Text('Confirm'))],
    ));
    if (!mounted || confirmed != true) return;
    setState(() { staff.status = status; _log('${staff.email}: $status'); });
  }
  Widget _stat(String label, String status, String destination) => Expanded(child: Card(child: InkWell(onTap: () => setState(() {tab=destination; search.clear();}), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label), const SizedBox(height: 8), Text('${records.where((r)=>r.status==status).length}', style: const TextStyle(fontSize: 28,fontWeight: FontWeight.bold,color: forest))])))));
  Widget _record(_DemoStaff r) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [const CircleAvatar(child: Icon(Icons.person_outline)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r.email,style: const TextStyle(fontWeight: FontWeight.bold)),Text(r.designation)])), Chip(label: Text(r.status))]),
    const SizedBox(height: 8), Text('${r.permissions.length} assigned permissions'),
    Wrap(spacing: 6, runSpacing: 4, children: r.permissions.map((p)=>Chip(label: Text(p, style: const TextStyle(fontSize: 11)))).toList()),
    Wrap(spacing: 8, runSpacing: 8, children: [
      if (r.status == 'Active' || r.status == 'Pending') OutlinedButton(onPressed: ()=>_edit(r),child: const Text('Edit permissions')),
      if (r.status == 'Active') TextButton(onPressed: ()=>_transition(r,'Revoked'),child: const Text('Revoke access')),
      if (r.status == 'Pending') ...[
        TextButton(onPressed: ()=>_transition(r,'Awaiting verification'),child: const Text('Simulate acceptance')),
        TextButton(onPressed: ()=>_transition(r,'Declined'),child: const Text('Simulate decline')),
        TextButton(onPressed: ()=>_transition(r,'Expired'),child: const Text('Simulate expiry')),
        TextButton(onPressed: ()=>_transition(r,'Cancelled'),child: const Text('Cancel invitation')),
      ],
      if (r.status == 'Awaiting verification') ...[
        FilledButton(onPressed: ()=>_transition(r,'Active'),child: const Text('Simulate eligibility clearance')),
        TextButton(onPressed: ()=>_transition(r,'Cancelled'),child: const Text('Cancel invitation')),
      ],
    ]),
  ])));
  @override
  Widget build(BuildContext context) {
    final q = search.text.trim().toLowerCase();
    final rows = records.where((r) => (tab == 'Invitations' ? r.status != 'Active' && r.status != 'Revoked' : r.status == 'Active') && '${r.email} ${r.designation} ${r.status}'.toLowerCase().contains(q)).toList();
    return ColoredBox(color: canvas, child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1400), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('KAISA / PEOPLE MANAGEMENT', style: TextStyle(color: forest,fontSize: 12,fontWeight: FontWeight.bold)),
      const SizedBox(height: 8), const Text('Staff & Permissions',style: TextStyle(fontFamily: 'Outfit',fontSize: 32,fontWeight: FontWeight.w600)),
      const Text('Manage delegated organization access. Fictional preview only.'), const SizedBox(height: 16),
      Wrap(spacing: 8,runSpacing: 8,children: [FilledButton.icon(onPressed: ()=>_edit(),icon: const Icon(Icons.person_add_alt_1),label: const Text('Invite staff')), OutlinedButton(onPressed: ()=>setState(() {_seed();search.clear();}),child: const Text('Reset mock records')),OutlinedButton(onPressed: ()=>setState(() {records.clear();logs.clear();search.clear();}),child: const Text('Test empty state'))]),
      const SizedBox(height: 16), Row(children: [_stat('Active staff','Active','Staff Directory'),_stat('Pending invitations','Pending','Invitations'),_stat('Revoked access','Revoked','Access History')]),
      const SizedBox(height: 16), Wrap(spacing: 8,runSpacing: 8,children: [for(final t in ['Staff Directory','Invitations','Permission Management','Access History']) ChoiceChip(label: Text(t),selected: tab==t,onSelected: (_)=>setState(() {tab=t;search.clear();}))]),
      const SizedBox(height: 16),
      if(tab=='Access History') ...[for(final r in records.where((r)=>r.status=='Revoked')) _record(r), if(logs.isEmpty) const Text('No access history.'), for(final log in logs) ListTile(leading: const Icon(Icons.history),title: Text(log))]
      else ...[
        if(tab=='Permission Management') const Padding(padding: EdgeInsets.only(bottom: 12),child: Text('Select an active staff member to edit delegated actions. Staff management, event cancellation and final LGU moderation responses remain reserved for the organization administrator.')),
        TextField(controller: search,onChanged: (_)=>setState((){}),decoration: const InputDecoration(prefixIcon: Icon(Icons.search),hintText: 'Search staff or invitations',border: OutlineInputBorder())),
        const SizedBox(height: 12), if(rows.isEmpty) const Padding(padding: EdgeInsets.all(32),child: Center(child: Text('No matching records.'))), for(final r in rows) _record(r),
      ],
    ])))));
  }
}

class _StaffEditor extends StatefulWidget {
  const _StaffEditor({required this.staff, required this.existingEmails});
  final _DemoStaff? staff;
  final Set<String> existingEmails;
  @override
  State<_StaffEditor> createState() => _StaffEditorState();
}
class _StaffEditorState extends State<_StaffEditor> {
  final form = GlobalKey<FormState>();
  late final TextEditingController email;
  late final TextEditingController designation;
  late Set<String> permissions;
  String preset = 'Custom';
  @override
  void initState() {
    super.initState(); email=TextEditingController(text:widget.staff?.email); designation=TextEditingController(text:widget.staff?.designation ?? ''); permissions={...?widget.staff?.permissions};
  }
  @override
  void dispose(){email.dispose();designation.dispose();super.dispose();}
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.staff==null?'Invite staff (mock)':'Edit staff permissions (mock)'),
    content: SizedBox(width: 600,child: SingleChildScrollView(child: Form(key: form,child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,mainAxisSize: MainAxisSize.min,children: [
      TextFormField(controller: email,enabled: widget.staff==null,decoration: const InputDecoration(labelText:'Fictional email'),validator:(v){final e=(v??'').trim().toLowerCase();if(!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e))return 'Enter a valid email';if(widget.staff==null&&widget.existingEmails.contains(e))return 'An active assignment or invitation already exists';return null;}),
      const SizedBox(height: 12), DropdownButtonFormField<String>(initialValue:preset,isExpanded:true,decoration: const InputDecoration(labelText:'Permission preset'),items:_presets.keys.map((p)=>DropdownMenuItem(value:p,child:Text(p))).toList(),onChanged:(v){if(v!=null)setState((){preset=v;permissions=_presets[v]!.toSet();if(v!='Custom')designation.text=v;});}),
      const SizedBox(height: 12),TextFormField(controller:designation,decoration:const InputDecoration(labelText:'Staff designation'),validator:(v)=>(v??'').trim().isEmpty?'Enter a designation':null),
      const SizedBox(height: 12),Text('${permissions.length} permissions selected'),
      for(final group in _permissionGroups.entries) ...[const Divider(),Text(group.key,style:const TextStyle(fontWeight:FontWeight.bold)),for(final p in group.value) CheckboxListTile(contentPadding:EdgeInsets.zero,title:Text(p),value:permissions.contains(p),onChanged:(v)=>setState((){preset='Custom';if(v==true){permissions.add(p);}else{permissions.remove(p);}}))],
      const Text('Preview only. These permissions do not authorize any real backend action.'),
    ])))),
    actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),FilledButton(onPressed:permissions.isEmpty?null:(){if(form.currentState!.validate())Navigator.pop(context,_DemoStaff(email.text.trim().toLowerCase(),designation.text.trim(),widget.staff?.status??'Pending',permissions));},child:Text(widget.staff==null?'Send mock invitation':'Save mock permissions'))],
  );
}
