import 'package:flutter/material.dart';
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
  DateTime? date(Object? v) => DateTime.tryParse(v?.toString() ?? '')?.toLocal();
  String key(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  int? count(Object? v) => int.tryParse(v?.toString() ?? '');
  String phase(Map<String,dynamic> e) {
    final raw = (e['status'] ?? '').toString().toLowerCase();
    if (raw == 'cancelled' || raw == 'canceled') return 'Cancelled';
    final start = date(e['starts_at']), end = date(e['ends_at']), now = DateTime.now();
    if (start == null) return 'Unscheduled';
    if (now.isBefore(start)) return 'Upcoming';
    if (end == null || end.isBefore(start)) return 'Schedule incomplete';
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
    if (changed) { initialized = true; organizationId = p['organizationId']; events = []; _load(); }
  }
  Future<void> _load() async {
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
    if (organizationId == null) return;
    context.go(Uri(path: '/organization-admin/events', queryParameters: {'organizationId': organizationId!, if (d != null) 'date': d}).toString());
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
    final valid=r!=null&&a!=null&&r>=0&&a>=0&&a<=r;
    final rate=valid&&r!>0?a!/r: null;
    return panel(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Wrap(spacing:12,runSpacing:6,crossAxisAlignment:WrapCrossAlignment.center,children:[Text('${e['title']??'Event'}',style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:forest)),Chip(label:Text(p))]),
      Text('Starts: ${stamp(e['starts_at'])}'),Text('Ends: ${stamp(e['ends_at'])}'),Text('Venue: ${e['location']??'TBA'}'),const Divider(height:24),
      Wrap(spacing:28,runSpacing:12,children:[metric('Registered',r?.toString()??'—'),metric('Attended',a?.toString()??'—'),metric('Capacity','${e['capacity']??'—'}'),if(valid&&p=='Completed')metric('Not attended','${r!-a!}')]),
      if(!valid)const Text('Attendance figures unavailable or inconsistent.'),
      if(valid&&p=='Ongoing')Text('${r!-a!} awaiting attendance'),
      if(rate!=null&&(p=='Ongoing'||p=='Completed')) ...[const SizedBox(height:12),Text('Attendance rate: ${(rate*100).toStringAsFixed(1)}%'),const SizedBox(height:6),LinearProgressIndicator(value:rate,color:forest,backgroundColor:const Color(0xFFE5E7EB))],
      if(p=='Upcoming')const Text('Attendance monitoring begins on the event day.')
    ]));
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
    return SingleChildScrollView(padding:const EdgeInsets.all(22),child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:1160),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('ORGANIZATION MANAGEMENT',style:TextStyle(color:forest,fontSize:11,letterSpacing:1.4)),
      Row(children:[const Expanded(child:Text('Events Management',style:TextStyle(color:forest,fontSize:27,fontWeight:FontWeight.w800))),IconButton(tooltip:'Refresh events',onPressed:loading?null:_load,icon:const Icon(Icons.refresh))]),
      const Text('Monitor event schedules, registrations and recorded attendance.'),const SizedBox(height:20),
      if(loading)const Center(child:CircularProgressIndicator()) else if(error!=null) panel(Column(children:[Text('Could not load events: $error'),TextButton(onPressed:_load,child:const Text('Retry'))])) else ...[
        panel(Wrap(spacing:30,runSpacing:12,children:[metric('Total events','${events.length}'),metric('Upcoming','${events.where((e)=>phase(e)=='Upcoming').length}'),metric('Ongoing','${events.where((e)=>phase(e)=='Ongoing').length}'),metric('Completed','${events.where((e)=>phase(e)=='Completed').length}')])),const SizedBox(height:16),
        Wrap(spacing:8,children:[ChoiceChip(label:const Text('Calendar view'),selected:calendar,onSelected:(_)=>setState(()=>calendar=true)),ChoiceChip(label:const Text('List view'),selected:!calendar,onSelected:(_){setState(()=>calendar=false);selectDate(null);})]),const SizedBox(height:12),
        if(calendar)...[calendarPanel(),const SizedBox(height:16)],
        TextField(onChanged:(v)=>setState(()=>search=v),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Search events or venue')),
        const SizedBox(height:10),Wrap(spacing:8,runSpacing:4,children:[for(final s in ['All','Upcoming','Ongoing','Completed','Cancelled','Unscheduled','Schedule incomplete'])ChoiceChip(label:Text(s),selected:status==s,onSelected:(_)=>setState(()=>status=s))]),
        if(filterDate!=null||eventId!=null)Wrap(crossAxisAlignment:WrapCrossAlignment.center,children:[Chip(label:Text(filterDate??'Selected event')),TextButton(onPressed:()=>selectDate(null),child:const Text('Clear selection'))]),
        const SizedBox(height:12),Text('${visible.length} events',style:const TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:8),
        if(visible.isEmpty)panel(const Text('No events found for this selection.')),
        for(final e in visible)Padding(padding:const EdgeInsets.only(bottom:12),child:eventCard(e)),
      ]
    ]))));
  }
}
