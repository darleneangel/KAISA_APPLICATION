import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KaisaOrgEventsManagementPage extends StatefulWidget {
  const KaisaOrgEventsManagementPage({super.key});
  @override
  State<KaisaOrgEventsManagementPage> createState() => _KaisaOrgEventsManagementPageState();
}

class _KaisaOrgEventsManagementPageState extends State<KaisaOrgEventsManagementPage> {
  static const forest = Color(0xFF14532D);
  List<Map<String, dynamic>> events = [];
  bool loading = true, initialized = false, calendar = true;
  String? error, organizationId, filterDate, eventId;
  String search = '', status = 'All';
  DateTime month = DateTime.now();
  int request = 0;
  bool mock = kDebugMode && const bool.fromEnvironment('USE_MOCK_DATA');
  int serial = 0;
  List<Map<String,dynamic>> mockRecords = [];
  bool editing = false;
  void seed({bool empty = false}) {
    final now = DateTime.now();
    mockRecords = empty ? [] : [
      for (final item in <(String,int,String,String,String,bool)>[
        ('Coastal Clean-Up Drive', 2, 'published', 'instant', 'headcount', false),
        ('Youth Leadership Seminar', 5, 'published', 'approval', 'individual', true),
        ('Volunteer Orientation', 8, 'draft', 'instant', 'individual', false),
        ('Community Health Fair', 0, 'published', 'none', 'headcount', false),
        ('Livelihood Workshop', -4, 'completed', 'instant', 'individual', true),
        ('Sports Festival', 10, 'published', 'instant', 'none', false),
        ('Community Forum', 12, 'cancelled', 'none', 'none', false),
        ('Neighborhood Assembly', 14, 'published', 'approval', 'individual', false),
      ]) {
        'event_id': 'mock-${++serial}', 'title': item.$1,
        'starts_at': (item.$2 == 0 ? now.subtract(const Duration(hours:1)) : DateTime(now.year,now.month,now.day+item.$2,9)).toIso8601String(),
        'ends_at': (item.$2 == 0 ? now.add(const Duration(hours:2)) : DateTime(now.year,now.month,now.day+item.$2,12)).toIso8601String(),
        'status': item.$3, 'registration_mode': item.$4, 'attendance_mode': item.$5,
        'certificates': item.$6, 'feedback': item.$5 == 'individual', 'location': 'Cavite City Community Hall',
        'category': 'Community Service', 'description': 'Fictional activity for development testing.',
        'objectives': 'Encourage meaningful community participation.', 'audience': 'Public', 'contact': 'demo@example.com',
        'capacity': item.$4 == 'none' ? null : 80, 'registered': item.$4 == 'none' ? null : (item.$3 == 'draft' ? 0 : 12),
        'present': item.$3 == 'completed' ? 10 : (item.$2 == 0 && item.$5 == 'headcount' ? 23 : null),
        'moderation': item.$1 == 'Neighborhood Assembly' ? 'On Hold' : 'Clear',
        'moderation_reason': item.$1 == 'Neighborhood Assembly' ? 'Mock LGU notice: clarify event objectives.' : '',
        'registration_opens': item.$4 == 'none' ? null : now.subtract(const Duration(days: 2)).toIso8601String(),
        'registration_closes': item.$4 == 'none' ? null : DateTime(now.year,now.month,now.day+item.$2,9).toIso8601String(),
        'applications': item.$4 == 'approval' ? [for (var i=1;i<=3;i++) {'name':'Demo Applicant $i','status':'Pending'}] : <Map<String,String>>[],
      },
    ];
    events = mockRecords;
  }
  void toggleMode(bool value) {
    if (!kDebugMode || editing) return;
    ++request;
    setState(() { mock = value; events = []; filterDate = null; eventId = null; status = 'All'; error = null; loading = false; if(mock) seed(); });
    if (!mock) _load();
  }

  DateTime? date(Object? v) => DateTime.tryParse(v?.toString() ?? '')?.toLocal();
  String key(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  int? count(Object? v) => int.tryParse(v?.toString() ?? '');
  String phase(Map<String,dynamic> e) {
    final raw = (e['status'] ?? '').toString().toLowerCase();
    if (raw == 'draft') return 'Draft';
    if (raw == 'cancelled' || raw == 'canceled') return 'Cancelled';
    if (e['moderation'] == 'On Hold') return 'On Hold';
    final start = date(e['starts_at']), end = date(e['ends_at']), now = DateTime.now();
    if (start == null) return 'Unscheduled';
    if (end == null || !end.isAfter(start)) return 'Schedule incomplete';
    if (now.isBefore(start)) return 'Upcoming';
    return now.isBefore(end) ? 'Ongoing' : 'Completed';
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final p = GoRouterState.of(context).uri.queryParameters;
    final changed = !initialized || organizationId != p['organizationId'];
    if (changed || filterDate != p['date'] || eventId != p['eventId']) {
      filterDate = p['date']; eventId = p['eventId'];
      final d = DateTime.tryParse(filterDate ?? '');
      if (d != null) month = DateTime(d.year,d.month);
    }
    if (changed) { initialized = true; organizationId = p['organizationId']; events = []; if(mock) { seed(); loading=false; error=null; } else { _load(); } }
  }
  Future<void> _load() async {
    if (mock) return;
    final token = ++request, id = organizationId;
    setState(() { loading = true; error = null; });
    try {
      if (id == null || id.isEmpty) throw Exception('No organization selected');
      final result = await Supabase.instance.client.rpc('kaisa_admin_event_schedule', params: {'p_organization_id': id});
      if (!mounted || token != request) return;
      setState(() { events = (result as List).map((e) => Map<String,dynamic>.from(e as Map)).toList(); loading = false; });
    } catch (e) {
      if (!mounted || token != request) return;
      setState(() { error = e.toString(); loading = false; });
    }
  }
  void selectDate(String? d) {
    if (mock) { setState(() { filterDate=d; eventId=null; }); return; }
    if (organizationId == null) return;
    context.go(Uri(path: '/organization-admin/events', queryParameters: {'organizationId': organizationId!, 'date': ?d}).toString());
  }
  void moveMonth(int n) {
    setState(() { month = DateTime(month.year,month.month+n); });
    if (filterDate != null || eventId != null) selectDate(null);
  }
  bool onDay(Map<String,dynamic> e, DateTime d) {
    final s = date(e['starts_at']);
    if (s == null) return false;
    final end = date(e['ends_at']) ?? s;
    final a = DateUtils.dateOnly(s), b = DateUtils.dateOnly(end);
    return !d.isBefore(a) && !d.isAfter(b.isBefore(a) ? a : b);
  }
  String stamp(Object? v) {
    final d = date(v);
    return d == null ? 'TBA' : '${key(d)} • ${TimeOfDay.fromDateTime(d).format(context)}';
  }
  Widget panel(Widget child) => Card(color: Colors.white, margin: EdgeInsets.zero, child: Padding(padding: const EdgeInsets.all(16), child: child));
  Widget metric(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)), Text(value, style: const TextStyle(color: forest, fontSize: 24, fontWeight: FontWeight.bold))]);
  Widget calendarPanel() {
    final first = DateTime(month.year, month.month);
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final offset = first.weekday - 1;
    final today = DateTime.now();
    final weeks = (offset + days + 6) ~/ 7;
    return panel(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Organization Events Calendar', style: TextStyle(
          color: forest, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Row(children: [
          IconButton(tooltip: 'Previous month', onPressed: () => moveMonth(-1),
            icon: const Icon(Icons.chevron_left)),
          Expanded(child: Text(MaterialLocalizations.of(context).formatMonthYear(first),
            textAlign: TextAlign.center, style: const TextStyle(color: forest,
              fontSize: 17, fontWeight: FontWeight.bold))),
          IconButton(tooltip: 'Next month', onPressed: () => moveMonth(1),
            icon: const Icon(Icons.chevron_right)),
          TextButton(onPressed: () {
            setState(() => month = DateTime(today.year, today.month));
            selectDate(null);
          }, child: const Text('Today')),
        ]),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final cellWidth = (constraints.maxWidth - 24) / 7;
          final tiny = cellWidth < 48;
          return Column(children: [
            Row(children: [for (final name in ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'])
              Expanded(child: Center(child: Text(tiny ? name.substring(0, 1) : name,
                style: const TextStyle(fontSize: 11, color: Colors.black54))))]),
            const SizedBox(height: 8),
            for (var week = 0; week < weeks; week++)
              Row(children: [for (var col = 0; col < 7; col++)
                Expanded(child: Builder(builder: (context) {
                  final n = week * 7 + col - offset + 1;
                  final height = compact ? 66.0 : 94.0;
                  if (n < 1 || n > days) return SizedBox(height: height + 4);
                  final day = DateTime(month.year, month.month, n);
                  final matches = events.where((event) => onDay(event, day)).toList();
                  final selected = filterDate == key(day);
                  final isToday = DateUtils.isSameDay(day, today);
                  final total = matches.length;
                  final countLabel = '$total ${total == 1 ? 'event' : 'events'}';
                  final label = total == 1 && !compact
                      ? (matches.first['title'] ?? 'Event').toString() : countLabel;
                  final fg = selected ? Colors.white : forest;
                  return Padding(padding: const EdgeInsets.all(2), child: Tooltip(
                    message: '${key(day)} • $countLabel${total == 0 ? '' : '\n${matches.map((event) => event['title'] ?? 'Event').join('\n')}'}',
                    child: Material(
                      color: selected ? forest : total > 0 ? const Color(0xFFE8F3EC) : const Color(0xFFF5F7F5),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(borderRadius: BorderRadius.circular(10),
                        onTap: () => selectDate(selected ? null : key(day)),
                        child: SizedBox(height: height, child: Padding(
                          padding: EdgeInsets.all(compact ? 4 : 8),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(color: isToday ? (selected ? Colors.white : forest) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6)),
                                child: Text('$n', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                                  color: isToday ? (selected ? forest : Colors.white) : fg))),
                              if (total > 0) ...[
                                const SizedBox(height: 4),
                                Expanded(child: Text(tiny ? '$total\n${total == 1 ? 'event' : 'events'}' : label,
                                  maxLines: compact ? 2 : 3, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: compact ? 9 : 12, color: fg,
                                    fontWeight: FontWeight.w500))),
                              ],
                            ]),
                        )),
                      ),
                    ),
                  ));
                })),
              ]),
          ]);
        }),
        const SizedBox(height: 12),
        const Text('Highlighted dates have scheduled events. Select a date to view its events below.',
          style: TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    ));
  }
  Widget eventCard(Map<String,dynamic> e) {
    final r=count(e['registered']), a=count(e['present']), p=phase(e);
    final valid=r!=null&&a!=null&&r>=0&&a>=0&&a<=r && (!mock || e['attendance_mode']=='individual');
    final rate=valid&&r>0?a/r: null;
    return panel(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Wrap(spacing:12,runSpacing:6,crossAxisAlignment:WrapCrossAlignment.center,children:[Text('${e['title']??'Event'}',style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:forest)),Chip(label:Text(p))]),
      Text('Starts: ${stamp(e['starts_at'])}'),Text('Ends: ${stamp(e['ends_at'])}'),Text('Venue: ${e['location']??'TBA'}'),const Divider(height:24),
      Wrap(spacing:28,runSpacing:12,children:[metric('Registered',r?.toString()??'—'),metric(mock && e['attendance_mode']=='headcount'?'Headcount':'Recorded attendance',a?.toString()??'—'),metric('Capacity','${e['capacity']??'—'}'),if(valid&&p=='Completed')metric('Not attended','${r-a}')]),
      if(!valid) Text(mock && e['attendance_mode']=='none' ? 'Attendance not tracked' : mock && a==null ? 'Attendance not recorded' : 'Attendance rate unavailable (aggregate or inconsistent figures).'),
      if(valid&&p=='Ongoing')Text('${r-a} awaiting attendance'),
      if(rate!=null&&(p=='Ongoing'||p=='Completed')) ...[const SizedBox(height:12),Text('Attendance rate: ${(rate*100).toStringAsFixed(1)}%'),const SizedBox(height:6),LinearProgressIndicator(value:rate,color:forest,backgroundColor:const Color(0xFFE5E7EB))],
      if(p=='Upcoming' && (!mock || e['attendance_mode']!='none'))const Text('Attendance monitoring begins on the event day.'),
      if(mock) Wrap(spacing:6,runSpacing:4,children:[Chip(label:Text(e['registration_mode']=='none'?'Open attendance':e['registration_mode']=='approval'?'Application approval':'Instant registration')),Chip(label:Text(e['attendance_mode']=='individual'?'Individual check-in':e['attendance_mode']=='headcount'?'Headcount':'No attendance tracking')),if(e['certificates']==true)const Chip(label:Text('E-Certificates'))]),
      const SizedBox(height:12),
      Wrap(spacing:8,runSpacing:8,children:[OutlinedButton.icon(onPressed:()=>details(e),icon:const Icon(Icons.info_outline),label:const Text('View details')), if(mock && ['Draft','Upcoming'].contains(p)) TextButton(onPressed:editing?null:()=>editEvent(e),child:const Text('Edit event'))]),
    ]));
  }
  Future<void> editEvent(Map<String,dynamic>? original) async {
    if (!mock || editing) return;
    final scope = organizationId;
    setState(()=>editing=true);
    try {
      final result = await showDialog<Map<String,dynamic>>(context:context, builder:(_)=>_EventComposer(original:original));
      if (!mounted || !mock || scope != organizationId || result == null) return;
      setState(() {
        if(original == null) { mockRecords.add({...result,'event_id':'mock-${++serial}','moderation':'Clear','applications':<Map<String,String>>[]}); }
        else { original.addAll(result); }
        events=mockRecords; filterDate=null;eventId=null;status='All';calendar=false;
      });
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Mock event saved. No database changes.')));
    } finally { if(mounted) setState(()=>editing=false); }
  }
  Future<void> details(Map<String,dynamic> e) async {
    final isMock=mock;
    final scope=organizationId;
    final action=await showDialog<String>(context:context,builder:(ctx)=>_EventDetails(event:e,isMock:isMock,phase:phase(e)));
    if(!mounted || !mock || !isMock || scope!=organizationId || !mockRecords.contains(e)) return;
    if(action=='edit') { await editEvent(e); return; }
    if(action=='cancel') {
      final reason=await showDialog<String>(context:context,builder:(_)=>const _CancelEventDialog());
      if(!mounted || !mock || scope!=organizationId || reason==null || !mockRecords.contains(e)) return;
      setState(() { e['status']='cancelled';e['cancellation_reason']=reason; });
    } else { setState((){}); }
  }
  @override
  Widget build(BuildContext context) {
    final visible=events.where((e){
      final d=DateTime.tryParse(filterDate??'');
      final s=date(e['starts_at']);
      final monthStart=DateTime(month.year,month.month), monthEnd=DateTime(month.year,month.month+1);
      final end=date(e['ends_at'])??s;
      return (eventId==null||e['event_id'].toString()==eventId)&&(d==null||onDay(e,d))&&(!calendar||d!=null||eventId!=null||(s!=null&&end!=null&&s.isBefore(monthEnd)&&!end.isBefore(monthStart)))&&(status=='All'||phase(e)==status)&&('${e['title']} ${e['location']}'.toLowerCase().contains(search.toLowerCase()));
    }).toList()..sort((a,b)=>(date(a['starts_at'])??DateTime(9999)).compareTo(date(b['starts_at'])??DateTime(9999)));
    return SingleChildScrollView(padding:EdgeInsets.all(MediaQuery.sizeOf(context).width<600?12:22),child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:1160),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('ORGANIZATION MANAGEMENT',style:TextStyle(color:forest,fontSize:11,letterSpacing:1.4)),
      Row(children:[const Expanded(child:Text('Events Management',style:TextStyle(color:forest,fontSize:27,fontWeight:FontWeight.w800))),IconButton(tooltip:'Refresh events',onPressed:loading||mock?null:_load,icon:const Icon(Icons.refresh))]),
      const Text('Plan, publish and manage community activities.'),const SizedBox(height:16),
      if(kDebugMode) panel(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Mock Data Mode'),subtitle:Text(mock?'Fictional records • no database writes':'Existing schedule service'),value:mock,onChanged:editing?null:toggleMode),if(mock) Wrap(spacing:8,children:[TextButton(onPressed:editing?null:()=>setState((){seed();filterDate=null;eventId=null;status='All';}),child:const Text('Reset mock records')),TextButton(onPressed:editing?null:()=>setState(()=>seed(empty:true)),child:const Text('Test empty state'))])])),
      const SizedBox(height:12),
      Align(alignment:Alignment.centerRight,child:FilledButton.icon(onPressed:mock&&!editing?()=>editEvent(null):null,icon:const Icon(Icons.add),label:const Text('Create event'))),
      if(!mock) const Text('Live event creation and editing require a verified write service. Existing schedule access is preserved.'),
      const SizedBox(height:16),
      if(loading)const Center(child:CircularProgressIndicator()) else if(error!=null) panel(Column(children:[Text('Could not load events: $error'),TextButton(onPressed:_load,child:const Text('Retry'))])) else ...[
        panel(Wrap(spacing:30,runSpacing:12,children:[metric('Total events','${events.length}'),metric('Upcoming','${events.where((e)=>phase(e)=='Upcoming').length}'),metric('Ongoing','${events.where((e)=>phase(e)=='Ongoing').length}'),metric('Completed','${events.where((e)=>phase(e)=='Completed').length}'),if(mock)...[metric('Drafts','${events.where((e)=>phase(e)=='Draft').length}'),metric('On hold','${events.where((e)=>phase(e)=='On Hold').length}')]])),const SizedBox(height:16),
        Wrap(spacing:8,children:[ChoiceChip(label:const Text('Calendar view'),selected:calendar,onSelected:(_)=>setState(()=>calendar=true)),ChoiceChip(label:const Text('List view'),selected:!calendar,onSelected:(_){setState(()=>calendar=false);selectDate(null);})]),const SizedBox(height:12),
        if(calendar)...[calendarPanel(),const SizedBox(height:16)],
        TextField(onChanged:(v)=>setState(()=>search=v),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Search events or venue')),
        const SizedBox(height:10),Wrap(spacing:8,runSpacing:4,children:[for(final s in ['All','Upcoming','Ongoing','Completed','Draft','On Hold','Cancelled','Unscheduled','Schedule incomplete'])ChoiceChip(label:Text(s),selected:status==s,onSelected:(_)=>setState(()=>status=s))]),
        if(filterDate!=null||eventId!=null)Wrap(crossAxisAlignment:WrapCrossAlignment.center,children:[Chip(label:Text(filterDate??'Selected event')),TextButton(onPressed:()=>selectDate(null),child:const Text('Clear selection'))]),
        const SizedBox(height:12),Text('${visible.length} events',style:const TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:8),
        if(visible.isEmpty)panel(const Text('No events found for this selection.')),
        for(final e in visible)Padding(padding:const EdgeInsets.only(bottom:12),child:eventCard(e)),
      ]
    ]))));
  }
}

// Local prototype editor. Does not call any remote service.
class _EventComposer extends StatefulWidget {
  const _EventComposer({this.original});
  final Map<String,dynamic>? original;
  @override
  State<_EventComposer> createState()=>_EventComposerState();
}
class _EventComposerState extends State<_EventComposer> {
  final form = GlobalKey<FormState>();
  final fields = <String,TextEditingController>{};
  final sections = ['Event information','Schedule & venue','Participants & registration','Attendance & certificates','Review & publish'];
  int step=0;
  late DateTime starts, ends, opens, closes;
  late String category, audience, registration, attendance;
  late bool certificates, feedback;
  bool agreed=false;
  String? warning;
  static const green=Color(0xFF14532D);
  @override
  void initState(){
    super.initState(); final e=widget.original??{}; final now=DateTime.now();
    for(final k in ['title','description','objectives','location','contact','capacity','requirements','questions','certificate_requirements']) {fields[k]=TextEditingController(text:e[k]?.toString()??'');}
    starts=DateTime.tryParse('${e['starts_at']}')?.toLocal()??now.add(const Duration(days:1));
    ends=DateTime.tryParse('${e['ends_at']}')?.toLocal()??starts.add(const Duration(hours:2));
    opens=DateTime.tryParse('${e['registration_opens']}')?.toLocal()??now;
    closes=DateTime.tryParse('${e['registration_closes']}')?.toLocal()??starts;
    category=e['category']?.toString()??'Community Service'; audience=e['audience']?.toString()??'Public';
    registration=e['registration_mode']?.toString()??'instant'; attendance=e['attendance_mode']?.toString()??'individual';
    certificates=e['certificates']==true; feedback=e['feedback']==true;
  }
  @override
  void dispose(){for(final c in fields.values){c.dispose();}super.dispose();}
  String value(String k)=>fields[k]!.text.trim();
  Widget field(String k,String label,{bool required=true,int lines=1,bool number=false})=>Padding(padding:const EdgeInsets.only(bottom:14),child:TextFormField(controller:fields[k],maxLines:lines,keyboardType:number?TextInputType.number:TextInputType.text,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder()),validator:(v){if(required&&(v??'').trim().isEmpty)return 'Required';if(number&&(v??'').trim().isNotEmpty&&(int.tryParse(v!.trim())??0)<=0)return 'Enter a positive whole number';return null;}));
  Widget dropdown(String label,String selected,Map<String,String> options,ValueChanged<String> change)=>Padding(padding:const EdgeInsets.only(bottom:14),child:DropdownButtonFormField<String>(value:options.containsKey(selected)?selected:options.keys.first,isExpanded:true,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder()),items:[for(final entry in options.entries)DropdownMenuItem(value:entry.key,child:Text(entry.value,overflow:TextOverflow.ellipsis))],onChanged:(v){if(v!=null)setState(()=>change(v));}));
  String stamp(DateTime d)=>'${MaterialLocalizations.of(context).formatMediumDate(d)} · ${TimeOfDay.fromDateTime(d).format(context)}';
  Widget dateField(String label,DateTime d,ValueChanged<DateTime> change)=>Padding(padding:const EdgeInsets.only(bottom:8),child:OutlinedButton.icon(onPressed:()async{
    final picked=await showDatePicker(context:context,initialDate:d,firstDate:DateTime(2000),lastDate:DateTime(2100));if(picked==null||!mounted)return;
    final time=await showTimePicker(context:context,initialTime:TimeOfDay.fromDateTime(d));if(time==null||!mounted)return;
    setState(()=>change(DateTime(picked.year,picked.month,picked.day,time.hour,time.minute)));
  },icon:const Icon(Icons.calendar_today_outlined),label:Text('$label: ${stamp(d)}')));
  String? validateAll(){
    if(['title','description','objectives','location','contact'].any((k)=>value(k).isEmpty))return 'Complete the required event information and venue fields.';
    if(!ends.isAfter(starts))return 'End time must be after start time.';
    if(registration!='none'&&(!closes.isAfter(opens)||closes.isAfter(starts)))return 'Registration must close after it opens and no later than event start.';
    if(value('capacity').isNotEmpty&&(int.tryParse(value('capacity'))??0)<=0)return 'Capacity must be a positive whole number.';
    final previous=widget.original?['registered'];if(previous is num && previous>0 && registration=='none')return 'Cannot disable registration while confirmed registrations exist.';if(previous is num && int.tryParse(value('capacity'))!=null && int.parse(value('capacity'))<previous)return 'Capacity cannot be lower than existing registrations.';
    if(certificates&&attendance!='individual')return 'Certificates require individual attendance.';
    return null;
  }
  void save(bool publish){
    if(!(form.currentState?.validate()??true))return;
    final error=validateAll();
    if(error!=null){setState(()=>warning=error);return;}
    if(publish&&(!agreed||!ends.isAfter(DateTime.now()))){setState(()=>warning='Accept the publishing guidelines and choose an event that has not ended.');return;}
    Navigator.pop(context,<String,dynamic>{for(final k in fields.keys)if(k!='capacity')k:value(k),'category':category,'audience':audience,'starts_at':starts.toIso8601String(),'ends_at':ends.toIso8601String(),'registration_opens':registration=='none'?null:opens.toIso8601String(),'registration_closes':registration=='none'?null:closes.toIso8601String(),'registration_mode':registration,'attendance_mode':attendance,'certificates':certificates,'feedback':feedback,'capacity':int.tryParse(value('capacity')),'registered':registration=='none'?null:(widget.original?['registered']??0),'present':widget.original?['present'],'status':publish?'published':'draft','guidelines_accepted':publish&&agreed});
  }
  List<Widget> body(){switch(step){
    case 0:return [field('title','Event title'),dropdown('Category',category,{'Community Service':'Community Service','Education & Training':'Education & Training','Environment':'Environment','Health & Wellness':'Health & Wellness','Sports & Recreation':'Sports & Recreation','Other':'Other'},(v)=>category=v),field('description','Description',lines:4),field('objectives','Objectives and community benefit',lines:3)];
    case 1:return [dateField('Start',starts,(v)=>starts=v),dateField('End',ends,(v)=>ends=v),field('location','Venue / online meeting details'),field('contact','Organizer contact information')];
    case 2:return [dropdown('Target audience',audience,{'Public':'Public','Members only':'Members only'},(v)=>audience=v),field('requirements','Eligibility requirements',required:false,lines:3),dropdown('Registration method',registration,{'none':'No online registration','instant':'Instant registration','approval':'Application with approval'},(v)=>registration=v),field('capacity','Maximum capacity (optional)',required:false,number:true),if(registration!='none')...[dateField('Registration opens',opens,(v)=>opens=v),dateField('Registration closes',closes,(v)=>closes=v)],if(registration=='approval')field('questions','Application questions (one per line)',required:false,lines:4)];
    case 3:return [dropdown('Attendance tracking',attendance,{'none':'No attendance tracking','headcount':'Aggregate headcount','individual':'Individual QR / manual check-in'},(v){attendance=v;if(v!='individual'){certificates=false;feedback=false;}}),SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Issue E-Certificates'),subtitle:const Text('Requires individual verified attendance'),value:certificates,onChanged:(v)=>setState((){certificates=v;if(v)attendance='individual';})),if(certificates)field('certificate_requirements','Additional certificate eligibility criteria',required:false,lines:3),SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Enable verified attendee feedback'),value:feedback,onChanged:attendance=='individual'?(v)=>setState(()=>feedback=v):null),const Text('Registration, attendance and certificate eligibility are separate records.')];
    default:return [Text(value('title'),style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold,color:green)),Text(value('description')),const Divider(),Text('${stamp(starts)} – ${stamp(ends)}'),Text('Venue: ${value('location')}'),Text('Audience: $audience'),Text('Registration: $registration'),Text('Attendance: $attendance'),Text('Certificates: ${certificates?'Enabled':'Disabled'}'),Text('Verified feedback: ${feedback?'Enabled':'Disabled'}'),const Divider(),CheckboxListTile(contentPadding:EdgeInsets.zero,value:agreed,onChanged:(v)=>setState(()=>agreed=v??false),title:const Text('I confirm this activity is appropriate, accurate and consistent with KAISA community publishing guidelines.'),subtitle:const Text('Prototype acknowledgement only; final policy requires LGU approval.')),const Text('Mock publishing updates this workspace only. It does not publish to the real Feed.')];
  }}
  @override
  Widget build(BuildContext context)=>AlertDialog(title:Text(widget.original==null?'Create Event':'Edit Event'),content:SizedBox(width:640,child:SingleChildScrollView(child:Form(key:form,child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,mainAxisSize:MainAxisSize.min,children:[Text('STEP ${step+1} OF ${sections.length}',style:const TextStyle(color:green,fontWeight:FontWeight.bold,fontSize:12)),const SizedBox(height:8),LinearProgressIndicator(value:(step+1)/sections.length,color:green),const SizedBox(height:16),Text(sections[step],style:const TextStyle(fontWeight:FontWeight.bold,fontSize:20)),const SizedBox(height:16),...body(),if(warning!=null)Padding(padding:const EdgeInsets.only(top:8),child:Text(warning!,style:const TextStyle(color:Colors.red)))])))),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Close')),if(step>0)TextButton(onPressed:()=>setState((){step--;warning=null;}),child:const Text('Back')),if(step<sections.length-1)FilledButton(onPressed:(){if(form.currentState?.validate()??false)setState((){step++;warning=null;});},child:const Text('Continue')) else ...[if(widget.original?['status']!='published')OutlinedButton(onPressed:()=>save(false),child:const Text('Save draft')),FilledButton(onPressed:()=>save(true),child:Text(widget.original?['status']=='published'?'Save changes':'Publish event'))]]);
}

class _EventDetails extends StatefulWidget {
  const _EventDetails({required this.event,required this.isMock,required this.phase});
  final Map<String,dynamic> event; final bool isMock; final String phase;
  @override State<_EventDetails> createState()=>_EventDetailsState();
}
class _EventDetailsState extends State<_EventDetails>{
  Map<String,dynamic> get e=>widget.event;
  bool get canReview=>widget.isMock&&widget.phase=='Upcoming';
  @override Widget build(BuildContext context)=>AlertDialog(title:Text('${e['title']??'Event'}'),content:SizedBox(width:640,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[Chip(label:Text(widget.phase)),const SizedBox(height:8),for(final entry in <String,String>{'Description':'description','Objectives':'objectives','Category':'category','Venue':'location','Starts':'starts_at','Ends':'ends_at','Contact':'contact','Audience':'audience','Capacity':'capacity','Registered':'registered','Recorded attendance':'present','Registration method':'registration_mode','Attendance method':'attendance_mode','Eligibility':'requirements','Application questions':'questions','Certificate eligibility':'certificate_requirements','Moderation':'moderation','Moderation notice':'moderation_reason','Cancellation reason':'cancellation_reason'}.entries)if(e[entry.value]!=null&&e[entry.value].toString().isNotEmpty)Padding(padding:const EdgeInsets.only(bottom:8),child:Text('${entry.key}: ${e[entry.value]}')),if(widget.isMock)...[Text('E-Certificates: ${e['certificates']==true?'Enabled':'Disabled'}'),Text('Verified feedback: ${e['feedback']==true?'Enabled':'Disabled'}'),const Divider(),const Text('Event applications',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),if(e['registration_mode']!='approval')const Text('Application approval is not enabled.') else if((e['applications'] as List? ?? []).isEmpty)const Text('No applications yet.') else for(final a in (e['applications'] as List)) ListTile(contentPadding:EdgeInsets.zero,title:Text('${a['name']}'),subtitle:Text('${a['status']}'),trailing:canReview&&a['status']=='Pending'?PopupMenuButton<String>(onSelected:(v){final registered=int.tryParse('${e['registered']}')??0;final capacity=int.tryParse('${e['capacity']}');if(v=='Approved'&&capacity!=null&&registered>=capacity){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Event capacity reached.')));return;}setState((){a['status']=v;if(v=='Approved')e['registered']=registered+1;});},itemBuilder:(_)=>const [PopupMenuItem(value:'Approved',child:Text('Approve')),PopupMenuItem(value:'Rejected',child:Text('Reject'))]):null),const Divider(),const Text('Mock record only. Attendance, certificates and Feed delivery will be connected in their respective modules.')]]))),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Close')),if(widget.isMock&&['Draft','Upcoming'].contains(widget.phase))OutlinedButton(onPressed:()=>Navigator.pop(context,'edit'),child:const Text('Edit')),if(widget.isMock&&['Upcoming','Ongoing','On Hold'].contains(widget.phase))TextButton(onPressed:()=>Navigator.pop(context,'cancel'),child:const Text('Cancel event',style:TextStyle(color:Colors.red)))]);
}
class _CancelEventDialog extends StatefulWidget {
  const _CancelEventDialog();
  @override State<_CancelEventDialog> createState()=>_CancelEventDialogState();
}
class _CancelEventDialogState extends State<_CancelEventDialog>{
  final reason=TextEditingController();
  @override void dispose(){reason.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>AlertDialog(title:const Text('Cancel event?'),content:Column(mainAxisSize:MainAxisSize.min,children:[const Text('The event will remain in history. This is a mock cancellation; no notifications are sent.'),const SizedBox(height:12),TextField(controller:reason,maxLines:3,onChanged:(_)=>setState((){}),decoration:const InputDecoration(labelText:'Cancellation reason',border:OutlineInputBorder()))]),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Back')),FilledButton(onPressed:reason.text.trim().isEmpty?null:()=>Navigator.pop(context,reason.text.trim()),child:const Text('Confirm cancellation'))]);
}
