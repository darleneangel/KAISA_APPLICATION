import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Organization scope is enforced by the existing server RPCs, not by this UI.
// Missing data is deliberately not replaced with synthetic metrics.
class KaisaOrgAdminDashboardPage extends StatefulWidget {
  const KaisaOrgAdminDashboardPage({super.key});
  @override
  State<KaisaOrgAdminDashboardPage> createState() => _KaisaOrgAdminDashboardPageState();
}

class _KaisaOrgAdminDashboardPageState extends State<KaisaOrgAdminDashboardPage> {
  static const forest = Color(0xFF00301B);
  static const green = Color(0xFF2C6A4A);
  static const gold = Color(0xFFFDBC19);
  static const ink = Color(0xFF151C27);
  static const muted = Color(0xFF404942);
  static const canvas = Color(0xFFF9F9FF);
  static const soft = Color(0xFFF0F3FF);
  static const line = Color(0xFFE2E8F8);
  static const blue = Color(0xFFB5C3DA);
  static const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  final db = Supabase.instance.client;
  List<Map<String, dynamic>> orgs = [], schedule = [];
  Map<String, dynamic>? data;
  String? orgId, error, scheduleError, _routeId;
  bool loading = true, exporting = false, _started = false;
  int _request = 0, period = 1;
  DateTime? updatedAt;
  String? selectedReportEvent;
  int reportMonthOffset = 0;
  bool demographicSectors = false;
  bool categoryByAttendance = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final requested = GoRouterState.of(context).uri.queryParameters['organizationId'];
    if (!_started || requested != _routeId) {
      _started = true;
      _routeId = requested;
      // Invalidate requests immediately and hide the previous organization's data.
      final token = ++_request;
      loading = true;
      data = null;
      schedule = [];
      error = null;
      scheduleError = null;
      updatedAt = null;
      selectedReportEvent = null;
      reportMonthOffset = 0;
      orgId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && token == _request) _init(requested, token);
      });
    }
  }

  List<Map<String, dynamic>> _rows(Object? raw) => (raw as List)
      .map((e) => Map<String, dynamic>.from(e as Map)).toList();

  Future<void> _init(String? requested, int token) async {
    try {
      final items = _rows(await db.rpc('kaisa_admin_my_organizations'));
      if (!mounted || token != _request) return;
      final chosen = items.isEmpty ? null : items.any((e) => '${e['id']}' == requested)
          ? requested : items.first['id'].toString();
      setState(() { orgs = items; orgId = chosen; loading = chosen != null; });
      if (chosen != null) await _refresh();
    } catch (e) {
      if (!mounted || token != _request) return;
      debugPrint('KAISA organization lookup: $e');
      setState(() { error = 'Unable to load organizations.'; loading = false; orgs = []; });
    }
  }

  void _retry() {
    if (orgId != null) { _refresh(); return; }
    final token = ++_request;
    setState(() { loading = true; error = null; });
    _init(_routeId, token);
  }

  Future<void> _refresh() async {
    final id = orgId;
    if (id == null) return;
    final token = ++_request;
    setState(() { loading = true; error = null; scheduleError = null; data = null; schedule = []; });
    try {
      final raw = await db.rpc('kaisa_admin_overview', params: {'p_organization_id': id});
      if (!mounted || token != _request) return;
      final overview = Map<String, dynamic>.from(raw as Map);
      List<Map<String, dynamic>> rows = [];
      String? warning;
      try {
        rows = _rows(await db.rpc('kaisa_admin_event_schedule', params: {'p_organization_id': id}));
      } catch (e) {
        debugPrint('KAISA schedule: $e');
        warning = 'Schedule data unavailable. Overview records are used where possible.';
      }
      if (!mounted || token != _request) return;
      setState(() { data = overview; schedule = rows; scheduleError = warning; updatedAt = DateTime.now(); loading = false; });
    } catch (e) {
      if (!mounted || token != _request) return;
      debugPrint('KAISA dashboard: $e');
      setState(() { error = 'Unable to load organization analytics.'; loading = false; });
    }
  }

  String get orgName {
    for (final org in orgs) {
      if ('${org['id']}' == orgId) return '${org['name'] ?? 'Organization'}';
    }
    return 'Organization';
  }
  void _go(String path, {String? eventId}) {
    final id = orgId;
    if (id == null) return;
    context.go(Uri(path: path, queryParameters: {'organizationId': id,
      if (eventId != null && eventId.isNotEmpty) 'eventId': eventId}).toString());
  }
  String? _id(Map<String, dynamic> e) => e['event_id']?.toString();
  String _name(Map<String, dynamic> e) => '${e['title'] ?? e['event'] ?? 'Untitled event'}';
  DateTime? _date(Map<String, dynamic> e, String field) => DateTime.tryParse('${e[field] ?? ''}')?.toLocal();
  int? _count(Object? value) {
    final n = num.tryParse('${value ?? ''}');
    return n == null || !n.isFinite || n < 0 || n != n.roundToDouble() ? null : n.toInt();
  }
  String _fmt(Object? v) => _count(v)?.toString() ?? '—';
  String _day(DateTime? d) => d == null ? 'Date TBA' : '${months[d.month - 1]} ${d.day}, ${d.year}';
  String _month(DateTime d) => '${months[d.month - 1]} ${d.year}';
  DateTime get _now => DateTime.now();
  DateTime get _from => DateTime(_now.year, _now.month - period + 1);
  String get _range => '${_month(_from)} – ${_month(_now)}';
  bool _cancelled(Map<String, dynamic> e) => ['cancelled','canceled'].contains('${e['status'] ?? ''}'.toLowerCase());
  bool _complete(Map<String, dynamic> e, DateTime now) {
    final s = _date(e, 'starts_at'), end = _date(e, 'ends_at');
    return !_cancelled(e) && s != null && end != null && !end.isBefore(s) && !now.isBefore(end);
  }
  bool _inRange(Map<String, dynamic> e, DateTime start, DateTime now) {
    final d = _date(e, 'starts_at');
    return !_cancelled(e) && d != null && !d.isBefore(start) && !d.isAfter(now);
  }
  List<Map<String, dynamic>> get events {
    // Merge by event_id, preferring non-null schedule fields. Do not sum the same event twice.
    final merged = <String, Map<String, dynamic>>{};
    final unkeyedOverview = <Map<String, dynamic>>[];
    final unkeyedSchedule = <Map<String, dynamic>>[];
    final raw = data?['event_summary'];
    if (raw is List) {
      for (final e in _rows(raw)) {
        final id = _id(e);
        if (id == null || id.isEmpty) { unkeyedOverview.add(e); } else { merged[id] = e; }
      }
    }
    for (final e in schedule) {
      final id = _id(e);
      if (id == null || id.isEmpty) { unkeyedSchedule.add(e); continue; }
      merged[id] = {...?merged[id], for (final p in e.entries) if (p.value != null) p.key: p.value};
    }
    // Rows without identifiers cannot be reliably deduplicated across sources.
    // Prefer schedule rows, if present; they are never included in numerical totals.
    return [...merged.values, ...(schedule.isNotEmpty ? unkeyedSchedule : unkeyedOverview)];
  }
  List<Map<String, dynamic>> get periodEvents {
    final now = _now, from = _from;
    return events.where((e) => _inRange(e, from, now)).toList();
  }
  bool _identified(Map<String, dynamic> e) => (_id(e) ?? '').isNotEmpty;
  int? _sum(List<Map<String, dynamic>> rows, String field) {
    if (rows.any((e) => !_identified(e) || _count(e[field]) == null)) return null;
    return rows.fold<int>(0, (sum, e) => sum + _count(e[field])!);
  }
  ({int registered, int attended, int included, int excluded}) _turnout(List<Map<String, dynamic>> rows) {
    var registered = 0, attended = 0, included = 0, excluded = 0;
    final now = _now;
    for (final e in rows) {
      if (!_complete(e, now)) {
        // Ongoing events are not part of final turnout; unknown end dates are excluded.
        final end = _date(e, 'ends_at'), start = _date(e, 'starts_at');
        if (end == null || (start != null && end.isBefore(start))) excluded++;
        continue;
      }
      final r = _count(e['registered']), a = _count(e['present']);
      if (!_identified(e) || r == null || a == null || a > r) { excluded++; continue; }
      registered += r; attended += a; included++;
    }
    return (registered: registered, attended: attended, included: included, excluded: excluded);
  }
  String _rate(List<Map<String, dynamic>> rows) {
    final t = _turnout(rows);
    return t.registered == 0 ? '—' : '${(100 * t.attended / t.registered).toStringAsFixed(1)}%';
  }
  String _status(Map<String, dynamic> e) {
    if (_cancelled(e)) return 'Cancelled';
    final now = _now, start = _date(e, 'starts_at'), end = _date(e, 'ends_at');
    if (start == null) return 'Date TBA';
    if (_complete(e, now)) return 'Completed';
    if (!now.isBefore(start)) return end == null || end.isBefore(start) ? 'End time TBA' : 'Ongoing';
    final cap = _count(e['capacity']), registered = _count(e['registered']);
    if (cap != null && cap > 0 && registered != null && registered >= cap) return 'Full';
    // A future event does not necessarily have open registration.
    final opens = _date(e, 'registration_opens_at'), closes = _date(e, 'registration_closes_at');
    if (opens != null && closes != null && !now.isBefore(opens) && now.isBefore(closes)) return 'Open';
    return 'Upcoming';
  }

  TextStyle _heading(double size) => TextStyle(fontFamily: 'Outfit', color: ink, fontSize: size, fontWeight: FontWeight.w600);
  BoxDecoration _surface() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 3, offset: Offset(0, 1))]);
  ButtonStyle _primary() => FilledButton.styleFrom(backgroundColor: forest, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12));
  Widget _panel(String title, String subtitle, Widget child, {Widget? action}) => Container(
    width: double.infinity, padding: const EdgeInsets.all(24), decoration: _surface(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: _heading(20)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(color: muted, fontSize: 13, height: 1.4))])), if (action != null) ...[const SizedBox(width: 8), action]]),
      const SizedBox(height: 20), child,
    ]),
  );
  Widget _columns(List<Widget> children, {double minWidth = 410}) => LayoutBuilder(builder: (_, c) {
    final columns = c.maxWidth >= minWidth * 2 + 24 ? 2 : 1;
    final width = (c.maxWidth - (columns - 1) * 24) / columns;
    return Wrap(spacing: 24, runSpacing: 24, children: [for (final child in children) SizedBox(width: width, child: child)]);
  });
  Widget _metric(String label, String value, String hint, IconData icon, {Widget? footer, bool rating = false}) => Container(
    constraints: const BoxConstraints(minHeight: 220), padding: const EdgeInsets.all(20), decoration: _surface(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: muted, fontWeight: FontWeight.w500))), const SizedBox(width: 8),
        Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: rating ? const Color(0xFFFFEBC9) : const Color(0xFFDDF6E7), borderRadius: BorderRadius.circular(4)), child: Icon(icon, color: rating ? const Color(0xFF7B5900) : forest, size: 20))]),
      const SizedBox(height: 18), Text(value, style: _heading(30)),
      const SizedBox(height: 4), Text(hint, style: const TextStyle(color: muted, fontSize: 13, height: 1.45)),
      const SizedBox(height: 14), if (footer != null) footer,
    ]),
  );
  Widget _smallNote(String s) => Text(s, style: const TextStyle(color: muted, fontSize: 11, height: 1.35));
  Widget _snapshot() {
    final t = _turnout(periodEvents);
    final cards = [
      _metric('Total Participants', '—', 'Unique residents who attended organization events', Icons.groups_outlined, footer: _smallNote('Monthly comparison unavailable')),
      _metric('Attendance Turnout Rate', _rate(periodEvents), 'Registered participants who attended completed events', Icons.how_to_reg_outlined, footer: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (t.registered > 0) ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: t.attended/t.registered, color: forest, backgroundColor: line, minHeight: 7)), const SizedBox(height: 5), _smallNote('${t.included} completed events · ${t.excluded} incomplete records excluded')])),
      _metric('Total Volunteer Hours', '—', 'Combined verified community service hours', Icons.schedule_rounded, footer: _smallNote('Verified service data unavailable')),
      _metric('Average Event Rating', '— / 5', 'Resident ratings after attending events', Icons.star_border_rounded, rating: true, footer: _smallNote('Rating data unavailable')),
    ];
    return LayoutBuilder(builder: (_, c) {
      final n = c.maxWidth >= 960 ? 4 : c.maxWidth >= 470 ? 2 : 1;
      final width = (c.maxWidth - (n - 1) * 24) / n;
      return Wrap(spacing: 24, runSpacing: 16, children: [for (final card in cards) SizedBox(width: width, child: card)]);
    });
  }
  Widget _indicatorStrip() => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(8)), child: LayoutBuilder(builder: (_, c) {
    final n = c.maxWidth >= 840 ? 4 : c.maxWidth >= 360 ? 2 : 1;
    final entries = <(String, String)>[('Approved members', _fmt(data?['approved_members'])), ('Pending membership requests', _fmt(data?['pending_members'])), ('Total organization events', _fmt(data?['events'])), ('Recorded event attendances', _fmt(_sum(periodEvents, 'present')))];
    return Wrap(spacing: 16, runSpacing: 16, children: [for (final e in entries) SizedBox(width: (c.maxWidth - (n-1)*16)/n, child: Row(children: [Expanded(child: Text(e.$1, style: const TextStyle(fontSize: 13, color: muted))), const SizedBox(width: 10), Text(e.$2, style: _heading(20))]))]);
  }));
  Widget _notice(String title, String description, IconData icon) => Container(
    constraints: const BoxConstraints(minHeight: 185), width: double.infinity, padding: const EdgeInsets.all(19),
    decoration: BoxDecoration(color: const Color(0xFFF9F9FF), borderRadius: BorderRadius.circular(8)),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 28, color: green), const SizedBox(height: 10),
      Text(title, textAlign: TextAlign.center, style: const TextStyle(color: forest, fontWeight: FontWeight.w700)),
      const SizedBox(height: 5), Text(description, textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 12, height: 1.45)),
    ]),
  );
  Widget _legend(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 6), Text(label, style: const TextStyle(color: muted, fontSize: 12)),
  ]);

  Widget _monthlyChart() {
    final now = _now;
    final dates = List.generate(period, (i) => DateTime(now.year, now.month - period + 1 + i));
    final rows = periodEvents;
    final bins = dates.map((m) => rows.where((e) {
      final d = _date(e, 'starts_at')!;
      return d.year == m.year && d.month == m.month;
    }).toList()).toList();
    final reg = bins.map((b) => _sum(b, 'registered')).toList();
    final att = bins.map((b) => _sum(b, 'present')).toList();
    final values = [...reg, ...att].whereType<int>();
    final highest = values.fold<int>(0, (a, b) => math.max(a, b));
    final step = math.max(1, (highest / 4).ceil()).toDouble();
    final ceiling = step * 4;
    // Minimum horizontal spacing per month prevents x-axis text collisions.
    // Long event names never appear on chart axes.
    return _panel('Monthly Participation', 'Comparison of registered vs. actual attended participants ($_range). Started events only; counts from loaded records.',
      rows.isEmpty ? _notice('No dated events in this period', 'The trend appears after event records are available.', Icons.show_chart_rounded) : !values.any((v) => v >= 0) ? _notice('Counts unavailable', 'Event records lack usable registration and attendance counts.', Icons.show_chart_rounded) : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 20, runSpacing: 8, children: [_legend(blue, 'Registered participants'), _legend(forest, 'Actual attended participants')]),
      const SizedBox(height: 16),
      LayoutBuilder(builder: (_, c) {
        final width = math.max(c.maxWidth, period * 65.0 + 90);
        return SingleChildScrollView(scrollDirection: Axis.horizontal, child: SizedBox(width: width, height: 250,
          child: Padding(padding: const EdgeInsets.only(right: 20), child: LineChart(LineChartData(
            minX: 0, maxX: period == 1 ? 1 : (period - 1).toDouble(), minY: 0, maxY: ceiling,
            gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: step,
              getDrawingHorizontalLine: (_) => const FlLine(color: line, strokeWidth: 1)),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 56, interval: step,
                getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(right: 6), child: Text(v.toInt().toString(), textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, color: muted))))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36, interval: 1,
                getTitlesWidget: (v, _) {
                  final i = v.round();
                  if (i < 0 || i >= dates.length || (v - i).abs() > .001) return const SizedBox.shrink();
                  return Padding(padding: const EdgeInsets.only(top: 7), child: Text('${months[dates[i].month - 1]}\n${dates[i].year}', textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 10, height: 1.1)));
                })),
            ),
            lineBarsData: [
              for (final series in [(reg, blue), (att, forest)])
                if (series.$1.any((v) => v != null)) LineChartBarData(spots: [for (var i = 0; i < series.$1.length; i++)
                  if (series.$1[i] != null) FlSpot(i.toDouble(), series.$1[i]!.toDouble()) else FlSpot.nullSpot],
                  isCurved: false, color: series.$2, barWidth: 2.5, dotData: const FlDotData(show: true)),
            ],
          ))),
        ));
      }),
      if (reg.contains(null) || att.contains(null)) const Text('Gaps indicate incomplete event counts, not zero.', style: TextStyle(color: muted, fontSize: 11)),
      const SizedBox(height: 8),
      Text('Loaded totals: ${_fmt(_sum(rows, 'registered'))} registrations · ${_fmt(_sum(rows, 'present'))} attendance records', style: const TextStyle(color: muted, fontSize: 12)),
    ]));
  }

  Widget _categoryChart() {
    final rows = periodEvents;
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final e in rows) {
      final name = '${e['category'] ?? ''}'.trim();
      if (name.isNotEmpty) groups.putIfAbsent(name, () => []).add(e);
    }
    final complete = rows.isNotEmpty && rows.every(_identified) && groups.values.fold<int>(0, (a,b) => a+b.length) == rows.length;
    final validAttendance = complete && _sum(rows, 'present') != null;
    final entries = groups.entries.toList()..sort((a,b) => b.value.length.compareTo(a.value.length));
    final byAttendance = categoryByAttendance && validAttendance;
    final values = entries.map((e) => byAttendance ? _sum(e.value, 'present')! : e.value.length).toList();
    final total = values.fold<int>(0, (a,b) => a+b);
    const colors = [forest, Color(0xFF95D4AD), gold, blue, Color(0xFF8C75A9), Color(0xFF8C694D)];
    // No text is drawn inside pie slices. Full names are in a wrapping legend.
    return _panel('Program & Advocacy Breakdown', 'Distribution across civic initiatives',
      !complete ? _notice('Category data not available', 'Event categories must be returned for all events in the selected period.', Icons.donut_large_rounded) : Column(children: [
      Wrap(spacing: 8, children: [ChoiceChip(label: const Text('Events'), selected: !byAttendance, onSelected: (_) => setState(() => categoryByAttendance = false)),
        ChoiceChip(label: const Text('Attended'), selected: byAttendance, onSelected: validAttendance ? (_) => setState(() => categoryByAttendance = true) : null)]),
      const SizedBox(height: 12),
      if (total > 0) SizedBox(height: 185, child: Stack(alignment: Alignment.center, children: [
        PieChart(PieChartData(centerSpaceRadius: 51, sectionsSpace: 2, sections: [for (var i=0;i<values.length;i++) if (values[i]>0)
          PieChartSectionData(value: values[i].toDouble(), color: colors[i % colors.length], radius: 27, showTitle: false)])),
        Column(mainAxisSize: MainAxisSize.min, children: [Text('$total', style: const TextStyle(color: forest, fontSize: 25, fontWeight: FontWeight.w800)), Text(byAttendance ? 'Attended' : 'Events', style: const TextStyle(color: muted, fontSize: 11))]),
      ])) else const Text('No attendance recorded for these categories.'),
      for (var i=0;i<entries.length;i++) Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
        Container(width: 10, height: 10, color: colors[i % colors.length]), const SizedBox(width: 8),
        Expanded(child: Text(entries[i].key, style: const TextStyle(fontSize: 12))), const SizedBox(width: 8), Text('${values[i]}', style: const TextStyle(fontWeight: FontWeight.w700)),
      ])),
    ]));
  }

  int? _slots(Map<String, dynamic> e) {
    final cap = _count(e['capacity']), r = _count(e['registered']);
    return cap == null || cap <= 0 || r == null ? null : math.max(0, cap-r);
  }
  String _dateTime(Map<String, dynamic> e) {
    final d = _date(e, 'starts_at');
    return d == null ? 'Date TBA' : '${_day(d)} • ${TimeOfDay.fromDateTime(d).format(context)}';
  }
  Widget _statusTag(String status) {
    final color = switch (status) {'Full' => const Color(0xFFFFDAD6), 'Ongoing' => const Color(0xFFFFDEA4), 'Open' => const Color(0xFFB0F1C8), _ => line};
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)), child: Text(status == 'Open' ? 'Registration Open' : status, style: const TextStyle(fontSize: 11, color: ink)));
  }
  List<Map<String, dynamic>> _trackedEvents() {
    final now = _now;
    final active = events.where((e) {
      final d = _date(e, 'starts_at'), end = _date(e, 'ends_at');
      return !_cancelled(e) && d != null && (d.isAfter(now) || (end != null && end.isAfter(now) && !end.isBefore(d)));
    }).toList()..sort((a,b) => _date(a,'starts_at')!.compareTo(_date(b,'starts_at')!));
    final completed = events.where((e) => _complete(e, now)).toList()..sort((a,b) => _date(b,'starts_at')!.compareTo(_date(a,'starts_at')!));
    return [...active, ...completed].take(5).toList();
  }
  Widget _capacity(Map<String, dynamic> e) {
    final r = _count(e['registered']), cap = _count(e['capacity']);
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${_fmt(r)} / ${_fmt(cap)}'), if (r != null && cap != null && cap > 0) ...[const SizedBox(height: 5), SizedBox(width: 90, child: ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(value: (r/cap).clamp(0.0,1.0).toDouble(), color: _status(e) == 'Ongoing' ? gold : forest, backgroundColor: line, minHeight: 5)))]]);
  }
  Widget _tracker() => LayoutBuilder(builder: (_, c) {
    if (c.maxWidth < 820) return _mobileTracker();
    final rows = _trackedEvents();
    return _panel('Upcoming & Ongoing Events Tracker', 'Registration capacity and event status · active events first, then recent completed events', rows.isEmpty ? _notice('No events available', 'Manage your schedules in Events Management.', Icons.event_outlined) : SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
      headingRowColor: WidgetStateProperty.all(soft), headingTextStyle: const TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w600), dataTextStyle: const TextStyle(fontSize: 13, color: ink), columnSpacing: 18, horizontalMargin: 12, dataRowMinHeight: 70, dataRowMaxHeight: 100, showCheckboxColumn: false, dividerThickness: 0,
      columns: const [DataColumn(label: Text('Event Name')), DataColumn(label: Text('Scheduled Date & Time')), DataColumn(label: Text('Venue / Barangay')), DataColumn(label: Text('Registered / Capacity')), DataColumn(label: Text('Available Slots')), DataColumn(label: Text('Status')), DataColumn(label: Text('Action'))],
      rows: [for (final e in rows) DataRow(cells: [DataCell(SizedBox(width: 145, child: Text(_name(e), maxLines: 3, overflow: TextOverflow.ellipsis))), DataCell(SizedBox(width: 140, child: Text(_dateTime(e)))), DataCell(SizedBox(width: 120, child: Text('${e['location'] ?? 'Venue TBA'}', maxLines: 3, overflow: TextOverflow.ellipsis))), DataCell(_capacity(e)), DataCell(Text(_fmt(_slots(e)))), DataCell(_statusTag(_status(e))), DataCell(TextButton(onPressed: !_identified(e) ? null : () => _go('/organization-admin/events', eventId: _id(e)), child: const Text('View')))])],
    )), action: FilledButton(style: _primary(), onPressed: () => _go('/organization-admin/events'), child: const Text('Manage Events')));
  });
  Widget _mobileTracker() {
    final rows = _trackedEvents();
    return _panel('Upcoming & Ongoing Events Tracker', 'Up to 5 activities across all dates; active events first.',
      rows.isEmpty ? _notice('No upcoming or ongoing events found', 'Open Events Management to view the complete schedule.', Icons.event_outlined) : Column(children: [
      for (final e in rows.take(5)) ...[
        InkWell(borderRadius: BorderRadius.circular(9), onTap: () => _go('/organization-admin/events', eventId: _id(e)),
          child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 48, padding: const EdgeInsets.symmetric(vertical: 7), decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(9)), child: Column(children: [
              Text(months[_date(e,'starts_at')!.month-1], style: const TextStyle(color: green, fontSize: 11)), Text('${_date(e,'starts_at')!.day}', style: const TextStyle(color: forest, fontSize: 21, fontWeight: FontWeight.w800))])),
            const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_name(e), style: const TextStyle(color: ink, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4), Text('${e['location'] ?? 'Venue TBA'} · ${_day(_date(e,'starts_at'))}', style: const TextStyle(color: muted, fontSize: 12)),
              const SizedBox(height: 8), Wrap(spacing: 12, runSpacing: 6, children: [Text('${_fmt(e['registered'])} / ${_fmt(e['capacity'])} slots', style: const TextStyle(fontSize: 12)), _statusTag(_status(e)), Text('${_fmt(_slots(e))} available', style: const TextStyle(fontSize: 12))]),
              if ((_count(e['capacity']) ?? 0) > 0 && _count(e['registered']) != null) ...[
                const SizedBox(height: 6), ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(value: (_count(e['registered'])! / _count(e['capacity'])!).clamp(0.0,1.0).toDouble(), color: green, backgroundColor: soft)),
              ],
            ])), const SizedBox(width: 6), const Icon(Icons.chevron_right_rounded, color: green),
          ]))), const Divider(color: line, height: 1),
      ],
    ]), action: TextButton(onPressed: () => _go('/organization-admin/events'), child: const Text('Manage events')));
  }

  Future<void> _export(List<Map<String,dynamic>> rows, String title, String scope) async {
    if (exporting || orgId == null || data == null) return;
    final organization = orgName;
    final t = _turnout(rows);
    final r = _sum(rows, 'registered'), a = _sum(rows, 'present');
    // Capture the selected scope before asynchronous printing.
    final records = rows.map((e) => [_name(e), _day(_date(e,'starts_at')), '${e['location'] ?? 'TBA'}',
      _count(e['registered'])?.toString() ?? 'N/A', _count(e['present'])?.toString() ?? 'N/A', _status(e)]).toList();
    setState(() => exporting = true);
    try {
      final pdf = pw.Document();
      pdf.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4, build: (_) => [
        pw.Text('KAISA | $title', style: pw.TextStyle(fontSize: 19, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 9), pw.Text(organization), pw.Text(scope), pw.Text('Generated: ${_now.toIso8601String()}'),
        pw.SizedBox(height: 14), pw.Text('Loaded event records: ${rows.length}'),
        pw.Text('Registrations: ${r ?? 'N/A'}'), pw.Text('Recorded attendance: ${a ?? 'N/A'}'),
        pw.Text('Completed-event turnout: ${t.registered == 0 ? 'N/A' : (100*t.attended/t.registered).toStringAsFixed(1)+'%'}'),
        pw.Text('Completed events included: ${t.included}; incomplete records excluded: ${t.excluded}'),
        pw.SizedBox(height: 12),
        if (records.isNotEmpty) pw.TableHelper.fromTextArray(headers: ['Event','Date','Venue','Registered','Attended','Status'], data: records, cellStyle: const pw.TextStyle(fontSize: 8), headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 14), pw.Text('Coverage and limitations', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text('This is a partial summary of loaded event records, not a certified accreditation report. Attendance totals count event participations, not distinct residents. Upcoming events and incomplete schedules are not included in final turnout. Unique participants, barangay reach, demographics, verified hours, satisfaction and engagement are not available in this export.'),
      ]));
      await Printing.layoutPdf(onLayout: (_) => pdf.save());
    } catch (e) {
      debugPrint('KAISA summary export: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to prepare summary PDF.')));
    } finally { if (mounted) setState(() => exporting = false); }
  }

  Widget _reportTile(String title, Widget selection, VoidCallback? export, {String status = 'Partial', Widget? extra}) => Container(
    padding: const EdgeInsets.all(20), decoration: _surface(), constraints: const BoxConstraints(minHeight: 180), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [Text(title, style: const TextStyle(color: ink, fontWeight: FontWeight.w600, fontSize: 14)), Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFFFDEA4), borderRadius: BorderRadius.circular(12)), child: Text(status, style: const TextStyle(color: Color(0xFF6C4D00), fontSize: 11)))]),
      const SizedBox(height: 16), selection, const SizedBox(height: 12), FilledButton(style: _primary(), onPressed: exporting ? null : export, child: Text(exporting ? 'Preparing…' : 'PDF')), if(extra != null) extra,
    ]));
  InputDecoration _selectDecoration() => InputDecoration(isDense: true, filled: true, fillColor: soft, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide.none));
  Widget _reportPanel() {
    final now = _now;
    final completed = events.where((e) => _identified(e) && _complete(e, now)).toList()..sort((a,b) => _date(b,'starts_at')!.compareTo(_date(a,'starts_at')!));
    final chosen = completed.any((e) => _id(e) == selectedReportEvent) ? selectedReportEvent : completed.isEmpty ? null : _id(completed.first);
    final chosenMonth = DateTime(now.year, now.month-reportMonthOffset);
    final nextMonth = DateTime(chosenMonth.year, chosenMonth.month+1);
    final monthRows = events.where((e) {final d = _date(e,'starts_at'); return !_cancelled(e) && d != null && !d.isBefore(chosenMonth) && d.isBefore(nextMonth) && !d.isAfter(now);}).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Reports & Documentation', style: _heading(24)), const SizedBox(height: 4), const Text('LGU summary preparation and attendance records', style: TextStyle(color: muted, fontSize: 13))])), TextButton(onPressed: () => _go('/organization-admin/reports'), child: const Text('All reports'))]),
      const SizedBox(height: 16), LayoutBuilder(builder: (_, c) {
        final n = c.maxWidth >= 960 ? 4 : c.maxWidth >= 470 ? 2 : 1;
        final width = (c.maxWidth - (n-1)*24)/n;
        final cards = [
          _reportTile('Post-Event Summary', DropdownButtonFormField<String>(key: ValueKey('event-$chosen'), initialValue: chosen, isExpanded: true, decoration: _selectDecoration(), hint: const Text('No completed events', style: TextStyle(fontSize: 12)), items: [for(final e in completed) DropdownMenuItem(value: _id(e), child: Text(_name(e), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))], onChanged: (v) => setState(() => selectedReportEvent = v)), chosen == null ? null : () { final e = completed.firstWhere((e) => _id(e) == chosen); _export([e], 'Post-event summary', _name(e)); }, extra: TextButton(onPressed: chosen == null ? null : () => _go('/organization-admin/reports', eventId: chosen), child: const Text('View attendance report'))),
          _reportTile('Monthly Organization Summary', DropdownButtonFormField<int>(initialValue: reportMonthOffset, decoration: _selectDecoration(), isExpanded: true, items: [for (var i=0;i<12;i++) DropdownMenuItem(value: i, child: Text(_month(DateTime(now.year,now.month-i)), style: const TextStyle(fontSize: 12)))], onChanged: (v) {if(v != null) setState(() => reportMonthOffset=v);}), monthRows.isEmpty ? null : () => _export(monthRows, 'Monthly organization summary', _month(chosenMonth))),
          _reportTile('Community Reach Report', _smallNote('Requires barangay and demographic aggregates.'), null, status: 'Incomplete'),
          _reportTile('Volunteer Service Report', _smallNote('Requires verified service-hour records.'), null, status: 'Incomplete'),
        ];
        return Wrap(spacing: 24, runSpacing: 16, children: [for(final card in cards) SizedBox(width: width, child: card)]);
      }), const SizedBox(height: 8), _smallNote('Available PDFs contain loaded event and attendance totals; unavailable indicators are disclosed. Detailed attendance reports remain in Reports & Exports.'),
    ]);
  }
  Widget _periodControl() => Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(8)), child: Wrap(spacing: 3, runSpacing: 4, children: [for (final entry in const [(1,'This Month'),(6,'Last 6 Months'),(12,'Last 12 Months')]) TextButton(style: TextButton.styleFrom(backgroundColor: period == entry.$1 ? forest : Colors.transparent, foregroundColor: period == entry.$1 ? Colors.white : muted, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9), minimumSize: const Size(0,36), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), onPressed: () => setState(() => period=entry.$1), child: Text(entry.$2))]));
  Widget _header() => LayoutBuilder(builder: (_, c) {
    final title = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('KAISA / ORGANIZATION INSIGHTS', style: TextStyle(color: muted, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w600)), const SizedBox(height: 6), Text('Dashboard & Analytics', style: _heading(32)), const SizedBox(height: 5), const Text('Understand your reach. Measure your impact.', style: TextStyle(color: muted, fontSize: 16, height: 1.4))]);
    final controls = Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
      if (orgId != null && orgs.isNotEmpty) SizedBox(width: math.min(280.0, c.maxWidth), child: Container(decoration: _surface(), child: DropdownButtonFormField<String>(key: ValueKey(orgId), initialValue: orgId, isExpanded: true, decoration: const InputDecoration(isDense: true, prefixIcon: Icon(Icons.corporate_fare_outlined, color: forest, size: 18), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10)), items: [for (final org in orgs) DropdownMenuItem(value: '${org['id']}', child: Text('${org['name'] ?? 'Organization'}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)))], onChanged: (id) {if(id != null && id != orgId) context.go(Uri(path: '/organization-admin/dashboard', queryParameters: {'organizationId': id}).toString());}))),
      _periodControl(),
      OutlinedButton.icon(onPressed: loading ? null : _retry, icon: const Icon(Icons.refresh, size: 18), label: const Text('Refresh')),
      OutlinedButton.icon(onPressed: data == null || exporting || loading ? null : () => _export(periodEvents, 'Participation summary', _range), icon: const Icon(Icons.download_outlined, size: 18), label: const Text('Export Report')),
      FilledButton.icon(style: _primary(), onPressed: orgId == null ? null : () => _go('/organization-admin/attendance'), icon: const Icon(Icons.qr_code_scanner_rounded, size: 18), label: const Text('Attendance Scanner')),
    ]);
    return c.maxWidth >= 900 ? Row(crossAxisAlignment: CrossAxisAlignment.end, children: [SizedBox(width: c.maxWidth*.27, child: title), const SizedBox(width: 24), Expanded(child: controls)]) : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title, const SizedBox(height: 16), controls]);
  });
  Widget _demographics() => _panel('Community Demographics', 'Participant representation', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Wrap(spacing: 6, children: [ChoiceChip(label: const Text('Age Groups'), selected: !demographicSectors, onSelected: (_) => setState(() => demographicSectors=false)), ChoiceChip(label: const Text('Community Sectors'), selected: demographicSectors, onSelected: (_) => setState(() => demographicSectors=true))]), const SizedBox(height: 12), _notice('No demographic data available', demographicSectors ? 'Community sector aggregates are not connected.' : 'Age group aggregates are not connected.', Icons.groups_outlined), const SizedBox(height: 10), Container(padding: const EdgeInsets.all(10), color: soft, child: const Row(children: [Icon(Icons.shield_outlined, size: 18, color: muted), SizedBox(width: 8), Expanded(child: Text('Aggregate and anonymized data only. Protect small groups.', style: TextStyle(fontSize: 12, color: muted)))]))]));
  Widget _engagement() => _panel('Announcement Reach & Engagement', 'Performance of civic updates and calls to action', Wrap(spacing: 30, runSpacing: 16, children: [for(final label in ['Post views','Sign-up taps','Shares']) SizedBox(width: 125, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: muted, fontSize: 13)), Text('—', style: _heading(24))])), const SizedBox(width: 210, child: Text('Engagement analytics are not connected.', style: TextStyle(color: muted, fontSize: 13)))]));
  @override
  Widget build(BuildContext context) => ColoredBox(color: canvas, child: LayoutBuilder(builder: (_, c) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(c.maxWidth < 600 ? 14 : 24, 24, c.maxWidth < 600 ? 14 : 24, 32),
    child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1400), child: DefaultTextStyle.merge(style: const TextStyle(fontFamily: 'Inter', color: ink), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _header(), const SizedBox(height: 12),
      if(updatedAt != null) Align(alignment: Alignment.centerRight, child: Text('● Updated ${_day(updatedAt)} • ${TimeOfDay.fromDateTime(updatedAt!).format(context)}', style: const TextStyle(color: muted, fontSize: 11))),
      const SizedBox(height: 24),
      if (loading) const Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator(color: green)))
      else if (error != null) _panel('Unable to load dashboard', error!, TextButton(onPressed: _retry, child: const Text('Try again')))
      else if (orgId == null) _panel('No organization selected', 'No approved organization admin assignment was found.', TextButton(onPressed: _retry, child: const Text('Retry')))
      else if (data != null) ...[
        if(scheduleError != null) ...[Text(scheduleError!, style: const TextStyle(color: muted)), const SizedBox(height: 12)],
        _snapshot(), const SizedBox(height: 16), _indicatorStrip(), const SizedBox(height: 8), _smallNote('Membership and total event counts are overview totals; recorded attendance is for $_range. A dash means unavailable, not zero.'),
        const SizedBox(height: 32), _monthlyChart(), const SizedBox(height: 32),
        _columns([_panel('Barangay Reach','Top participating barangays in Cavite City',_notice('Barangay data unavailable','Requires authorized participant home-barangay aggregates.',Icons.location_on_outlined)), _categoryChart()]),
        const SizedBox(height: 24), _columns([_demographics(), _panel('New vs. Returning','Per-event participant composition',_notice('Retention data unavailable','Requires stable resident IDs and attendance history.',Icons.repeat_rounded))]),
        const SizedBox(height: 32), _engagement(), const SizedBox(height: 32), _tracker(),
        const SizedBox(height: 32), _columns([_panel('Top Volunteers','Verified community service leaders',_notice('Volunteer leaderboard unavailable','Requires verified hours and authorized display data.',Icons.emoji_events_outlined)), _panel('Recent Resident Feedback','Direct ratings from event attendees',_notice('Feedback data unavailable','Requires attendance-linked resident ratings and comments.',Icons.rate_review_outlined))]),
        const SizedBox(height: 32), _reportPanel(),
      ],
    ])))),
  )));
}
