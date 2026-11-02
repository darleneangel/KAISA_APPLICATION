import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_html/html.dart' as html;

/// Reads only organization-scoped information from Supabase RPCs.
/// RLS/RPC permission checks must also be enforced by the database.
class KaisaOrgAdminDashboardPage extends StatefulWidget {
  const KaisaOrgAdminDashboardPage({super.key});

  @override
  State<KaisaOrgAdminDashboardPage> createState() =>
      _KaisaOrgAdminDashboardPageState();
}

class _KaisaOrgAdminDashboardPageState
    extends State<KaisaOrgAdminDashboardPage> {
  static const Color green = Color(0xFF14532D);
  static const Color gold = Color(0xFFFBC02D);
  static const Color paper = Color(0xFFF8FAF8);
  static const Color accent = Color(0xFF237A50);

  final SupabaseClient db = Supabase.instance.client;

  List<Map<String, dynamic>> orgs = [];
  Map<String, dynamic>? data;
  String? orgId;
  String? error;
  String? busyReport;
  bool loading = true;
  List<Map<String, dynamic>> schedule = [];
  DateTime calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      loading = true;
      error = null;
      data = null;
    });

    try {
      final raw = await db.rpc('kaisa_admin_my_organizations');
      final items = (raw as List)
          .map((entry) => Map<String, dynamic>.from(entry as Map))
          .toList();

      if (!mounted) return;

      setState(() {
        orgs = items;
        final requestedId = GoRouterState.of(
          context,
        ).uri.queryParameters['organizationId'];
        orgId = items.isEmpty
            ? null
            : items.any((org) => org['id'].toString() == requestedId)
            ? requestedId
            : items.first['id'].toString();
      });

      if (orgId != null) {
        await _refresh();
      } else if (mounted) {
        setState(() => loading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    final selectedId = orgId;
    if (selectedId == null) return;

    setState(() {
      loading = true;
      error = null;
      data = null;
      schedule = [];
    });

    try {
      final result = await db.rpc(
        'kaisa_admin_overview',
        params: {'p_organization_id': selectedId},
      );
      // Schedule is fetched from a separate organization-authorized RPC.
      // If the new migration has not been installed, existing analytics still work.
      List<Map<String, dynamic>> nextSchedule = [];
      try {
        final response = await db.rpc(
          'kaisa_admin_event_schedule',
          params: {'p_organization_id': selectedId},
        );
        nextSchedule = (response as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } catch (scheduleError) {
        debugPrint('KAISA schedule RPC unavailable: $scheduleError');
      }
      if (!mounted || orgId != selectedId) return;
      setState(() {
        data = Map<String, dynamic>.from(result as Map);
        schedule = nextSchedule;
      });
    } catch (e) {
      if (!mounted || orgId != selectedId) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted && orgId == selectedId) {
        setState(() => loading = false);
      }
    }
  }

  int number(String key) => (data?[key] as num?)?.toInt() ?? 0;

  List<Map<String, dynamic>> get events {
    final list = data?['event_summary'];
    if (list is! List) return [];
    return list
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList();
  }

  List<Map<String, dynamic>> get scheduledEvents {
    if (schedule.isNotEmpty) return schedule;
    // Backward-compatible fallback: overview contains event title and start date.
    return events
        .map(
          (event) => <String, dynamic>{
            'event_id': event['event_id'],
            'title': event['event'],
            'starts_at': event['starts_at'],
            'registered': event['registered'],
            'present': event['present'],
            'completed': event['completed'],
          },
        )
        .toList();
  }

  DateTime? _eventDate(Map<String, dynamic> event, String field) {
    final value = event[field];
    if (value == null) return null;
    final parsed = DateTime.tryParse(value.toString());
    // The app's local timezone is used for display, matching the resident UI.
    return parsed?.toLocal();
  }

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String _dayLabel(DateTime? date) {
    if (date == null) return 'Date TBA';
    return '${_months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _timeLabel(DateTime? date) {
    if (date == null) return 'Time TBA';
    final h = date.hour % 12 == 0 ? 12 : date.hour % 12;
    return '$h:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
  }

  void _openManagement({DateTime? day, String? eventId}) {
    if (orgId == null) return;
    context.go(
      Uri(
        path: '/organization-admin/events',
        queryParameters: {
          'organizationId': orgId!,
          if (day != null)
            'date':
                '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
          if (eventId != null && eventId.isNotEmpty) 'eventId': eventId,
        },
      ).toString(),
    );
  }

  double eventNumber(Map<String, dynamic> event, String key) {
    final value = event[key];
    if (value is num) return value.toDouble();
    return num.tryParse(value?.toString() ?? '')?.toDouble() ?? 0;
  }

  String csvEscape(Object? value) {
    var content = (value ?? '').toString();
    // Prevent Excel and similar software from interpreting user data as formulas.
    if (RegExp(r'^\s*[=+@\-]').hasMatch(content)) content = "'$content";
    return '"${content.replaceAll('"', '""')}"';
  }

  Future<List<Map<String, dynamic>>> _report(String eventId) async {
    final result = await db.rpc(
      'kaisa_admin_attendance_report',
      params: {'p_organization_id': orgId, 'p_event_id': eventId},
    );
    return (result as List)
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList();
  }

  Future<void> _export(Map<String, dynamic> event, {required bool pdf}) async {
    if (busyReport != null || orgId == null) return;
    final eventId = event['event_id'].toString();
    setState(() => busyReport = eventId);

    try {
      final rows = await _report(eventId);
      final title = event['event']?.toString() ?? 'Event';

      if (pdf) {
        final document = pw.Document();
        document.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            build: (_) => [
              pw.Text(
                'KAISA - Organization Attendance Report',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(title),
              pw.Text('Generated: ${DateTime.now().toIso8601String()}'),
              pw.SizedBox(height: 14),
              pw.TableHelper.fromTextArray(
                headers: [
                  'Resident',
                  'Registration',
                  'Check-in (UTC)',
                  'Check-out (UTC)',
                ],
                data: rows
                    .map(
                      (row) => [
                        '${row['name'] ?? ''}',
                        '${row['registration_status'] ?? ''}',
                        '${row['checked_in_at'] ?? ''}',
                        '${row['checked_out_at'] ?? ''}',
                      ],
                    )
                    .toList(),
                cellStyle: const pw.TextStyle(fontSize: 8),
                headerStyle: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        );
        await Printing.layoutPdf(onLayout: (_) => document.save());
      } else {
        if (!kIsWeb) {
          throw UnsupportedError(
            'CSV download is currently available on web. PDF works on Android.',
          );
        }
        final lines = <String>[
          'Resident,Registration,Check-in (UTC),Check-out (UTC)',
        ];
        for (final row in rows) {
          lines.add(
            [
              row['name'],
              row['registration_status'],
              row['checked_in_at'],
              row['checked_out_at'],
            ].map(csvEscape).join(','),
          );
        }
        final csv = '\uFEFF${lines.join('\r\n')}';
        final blob = html.Blob([utf8.encode(csv)], 'text/csv;charset=utf-8');
        final url = html.Url.createObjectUrlFromBlob(blob);
        try {
          html.AnchorElement(href: url)
            ..setAttribute('download', 'kaisa_attendance_$eventId.csv')
            ..click();
        } finally {
          html.Url.revokeObjectUrl(url);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => busyReport = null);
    }
  }

  Widget _panel(String title, Widget child) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: green,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, int value, IconData icon) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Icon(icon, color: green, size: 29),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      color: green,
                    ),
                  ),
                  Text(label, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statistics() {
    final cards = <({String label, int value, IconData icon})>[
      (
        label: 'Approved members',
        value: number('approved_members'),
        icon: Icons.people_alt_outlined,
      ),
      (
        label: 'Pending requests',
        value: number('pending_members'),
        icon: Icons.pending_actions,
      ),
      (
        label: 'Events with attendance setup',
        value: number('events'),
        icon: Icons.event_outlined,
      ),
      (
        label: 'Checked in',
        value: number('checked_in'),
        icon: Icons.how_to_reg_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 500
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 112,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (_, index) {
            final card = cards[index];
            return _statCard(card.label, card.value, card.icon);
          },
        );
      },
    );
  }

  Widget _charts() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final panelWidth = constraints.maxWidth > 750
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        final totalRegistered = number('registrations');
        final checkedIn = number('checked_in');
        final awaiting = (totalRegistered - checkedIn).clamp(0, 999999);
        final plotted = events.take(8).toList();
        final hasParticipation = plotted.any(
          (event) =>
              eventNumber(event, 'registered') > 0 ||
              eventNumber(event, 'present') > 0,
        );

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: panelWidth,
              child: _panel(
                'Event participation (bar chart)',
                SizedBox(
                  height: 260,
                  child: events.isEmpty
                      ? const Center(child: Text('No assigned events yet'))
                      : !hasParticipation
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No event registrations yet. Register QA attendees to populate this chart.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.square, color: green, size: 13),
                                SizedBox(width: 4),
                                Text(
                                  'Registered',
                                  style: TextStyle(fontSize: 11),
                                ),
                                SizedBox(width: 16),
                                Icon(Icons.square, color: gold, size: 13),
                                SizedBox(width: 4),
                                Text(
                                  'Checked in',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  minY: 0,
                                  maxY:
                                      plotted.fold<double>(1, (highest, event) {
                                        final registered = eventNumber(
                                          event,
                                          'registered',
                                        );
                                        final present = eventNumber(
                                          event,
                                          'present',
                                        );
                                        return [
                                          highest,
                                          registered,
                                          present,
                                        ].reduce((a, b) => a > b ? a : b);
                                      }) +
                                      1,
                                  barGroups: [
                                    for (var i = 0; i < plotted.length; i++)
                                      BarChartGroupData(
                                        x: i,
                                        barRods: [
                                          BarChartRodData(
                                            toY: eventNumber(
                                              plotted[i],
                                              'registered',
                                            ),
                                            color: green,
                                            width: 13,
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                          ),
                                          BarChartRodData(
                                            toY: eventNumber(
                                              plotted[i],
                                              'present',
                                            ),
                                            color: gold,
                                            width: 13,
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                  titlesData: FlTitlesData(
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 24,
                                        getTitlesWidget: (value, meta) {
                                          if (value != value.roundToDouble() ||
                                              value < 0 ||
                                              value >= plotted.length) {
                                            return const SizedBox.shrink();
                                          }
                                          return Text(
                                            (plotted[value.toInt()]['event']
                                                        ?.toString() ??
                                                    'Event')
                                                .replaceFirst('[QA] ', '')
                                                .split(' ')
                                                .take(2)
                                                .join(' '),
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    horizontalInterval: 2,
                                    getDrawingHorizontalLine: (_) => FlLine(
                                      color: const Color(0xFFE7EFEA),
                                      strokeWidth: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            SizedBox(
              width: panelWidth,
              child: _panel(
                'Attendance progress (pie chart)',
                SizedBox(
                  height: 260,
                  child: totalRegistered == 0
                      ? const Center(child: Text('No registrations yet'))
                      : Column(
                          children: [
                            Text(
                              '$checkedIn checked in / $totalRegistered registrations',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: PieChart(
                                PieChartData(
                                  centerSpaceRadius: 44,
                                  sections: [
                                    if (checkedIn > 0)
                                      PieChartSectionData(
                                        value: checkedIn.toDouble(),
                                        color: green,
                                        title: 'Present',
                                        radius: 67,
                                        titleStyle: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                      ),
                                    if (awaiting > 0)
                                      PieChartSectionData(
                                        value: awaiting.toDouble(),
                                        color: gold,
                                        title: 'Awaiting',
                                        radius: 67,
                                        titleStyle: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _eventScheduleTable() {
    final rows = [...scheduledEvents];
    rows.sort(
      (a, b) => (_eventDate(a, 'starts_at') ?? DateTime(2100)).compareTo(
        _eventDate(b, 'starts_at') ?? DateTime(2100),
      ),
    );
    return _panel(
      'Upcoming & Scheduled Events',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Event details, schedules and participation',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ),
              TextButton.icon(
                onPressed: orgId == null ? null : () => _openManagement(),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Manage events'),
              ),
            ],
          ),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('No organization events with attendance setup yet.'),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFEAF5EE),
                ),
                columnSpacing: 22,
                columns: const [
                  DataColumn(label: Text('Event name')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('When')),
                  DataColumn(label: Text('Location')),
                  DataColumn(label: Text('Registered')),
                  DataColumn(label: Text('Attended')),
                ],
                rows: rows.map((event) {
                  final start = _eventDate(event, 'starts_at');
                  final end = _eventDate(event, 'ends_at');
                  final name =
                      (event['title'] ?? event['event'] ?? 'Untitled event')
                          .toString();
                  return DataRow(
                    onSelectChanged: (_) =>
                        _openManagement(eventId: event['event_id']?.toString()),
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 220,
                          child: Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(_dayLabel(start))),
                      DataCell(
                        Text(
                          end == null
                              ? _timeLabel(start)
                              : '${_timeLabel(start)}–${_timeLabel(end)}',
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 160,
                          child: Text(
                            (event['location'] ?? '—').toString(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text('${event['registered'] ?? 0}')),
                      DataCell(Text('${event['present'] ?? 0}')),
                    ],
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 6),
          const Text(
            'Select a row to open Events Management.',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _eventCalendar() {
    final startOfMonth = DateTime(calendarMonth.year, calendarMonth.month);
    final offset = startOfMonth.weekday - 1;
    final days = DateUtils.getDaysInMonth(
      calendarMonth.year,
      calendarMonth.month,
    );
    final cells = ((offset + days + 6) ~/ 7) * 7;
    final all = scheduledEvents;
    final byDay = <int, List<Map<String, dynamic>>>{};
    for (final event in all) {
      final date = _eventDate(event, 'starts_at');
      if (date == null ||
          date.year != calendarMonth.year ||
          date.month != calendarMonth.month)
        continue;
      byDay.putIfAbsent(date.day, () => []).add(event);
    }
    final now = DateTime.now();
    return _panel(
      'Organization Events Calendar',
      Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(
                  () => calendarMonth = DateTime(
                    calendarMonth.year,
                    calendarMonth.month - 1,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '${_months[calendarMonth.month - 1]} ${calendarMonth.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: green,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(
                  () => calendarMonth = DateTime(
                    calendarMonth.year,
                    calendarMonth.month + 1,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => setState(
                  () => calendarMonth = DateTime(now.year, now.month),
                ),
                child: const Text('Today'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final day in _weekdays)
                Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;
              final cellHeight = compact ? 54.0 : 78.0;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cells,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisExtent: cellHeight,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemBuilder: (_, index) {
                  final day = index - offset + 1;
                  if (day < 1 || day > days) return const SizedBox.shrink();
                  final matches = byDay[day] ?? [];
                  final isToday =
                      day == now.day &&
                      calendarMonth.month == now.month &&
                      calendarMonth.year == now.year;
                  return Material(
                    color: matches.isNotEmpty
                        ? const Color(0xFFEAF5EE)
                        : const Color(0xFFF8FAF8),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () => _openManagement(
                        day: DateTime(
                          calendarMonth.year,
                          calendarMonth.month,
                          day,
                        ),
                      ),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isToday ? green : Colors.transparent,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  fontSize: compact ? 11 : 12,
                                  fontWeight: FontWeight.w700,
                                  color: isToday ? Colors.white : green,
                                ),
                              ),
                            ),
                            if (matches.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              if (compact)
                                Row(
                                  children: List.generate(
                                    matches.length.clamp(1, 3),
                                    (_) => Container(
                                      margin: const EdgeInsets.only(right: 2),
                                      width: 5,
                                      height: 5,
                                      decoration: const BoxDecoration(
                                        color: gold,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Expanded(
                                  child: Text(
                                    matches.length == 1
                                        ? (matches.first['title'] ??
                                                  matches.first['event'] ??
                                                  'Event')
                                              .toString()
                                        : '${matches.length} events',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: accent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.circle, color: gold, size: 10),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Dates with organization events are highlighted. Select any date to open Events Management.',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ),
              TextButton(
                onPressed: () => _openManagement(),
                child: const Text('View all'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Dashboard preview only. Full attendance reports live in the Reports module.
  void _openReports({String? eventId}) {
    if (orgId == null) return;
    context.go(
      Uri(
        path: '/organization-admin/reports',
        queryParameters: {
          'organizationId': orgId!,
          if (eventId != null) 'eventId': eventId,
        },
      ).toString(),
    );
  }

  Widget _eventReports() {
    final preview = events.take(3).toList();
    return Card(
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Event Attendance',
                      style: TextStyle(
                        color: green,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Recent event overview',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: orgId == null ? null : () => _openReports(),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('View all reports'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (preview.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text('No assigned attendance events yet.'),
              ),
            for (final event in preview) ...[
              const Divider(height: 1, color: Color(0xFFE7EFEA)),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: orgId == null
                    ? null
                    : () =>
                          _openReports(eventId: event['event_id']?.toString()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF5EE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.event_available_outlined,
                          color: green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event['event']?.toString() ?? 'Event',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: green,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Registered: ${event['registered'] ?? 0}   •   '
                              'Checked in: ${event['present'] ?? 0}   •   '
                              'Checked out: ${event['completed'] ?? 0}',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right_rounded, color: accent),
                    ],
                  ),
                ),
              ),
            ],
            if (events.length > preview.length) ...[
              const SizedBox(height: 8),
              Text(
                '${events.length - preview.length} more event(s) in Reports & Exports',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: paper,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ORGANIZATION MANAGEMENT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Color(0xFF237A50),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Dashboard & Analytics',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: green,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Live organization metrics, attendance operations, and exportable reports.',
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF14532D), Color(0xFF237A50)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'YOUR ORGANIZATION SPACE',
                            style: TextStyle(
                              color: gold,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 7),
                          Text(
                            'Make a difference, together.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 7),
                          Text(
                            'Monitor participation, manage attendance, and track impact.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.groups_rounded,
                        color: Color(0x55FFFFFF),
                        size: 64,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                if (error != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text('Unable to load: $error'),
                    ),
                  ),
                if (loading && orgs.isEmpty)
                  const Center(child: CircularProgressIndicator()),
                if (orgs.isEmpty && !loading)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'No approved Organization Admin assignment was found for this account.',
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _init,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (orgs.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    key: ValueKey(orgId),
                    initialValue: orgId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Active organization',
                      border: OutlineInputBorder(),
                    ),
                    items: orgs
                        .map(
                          (org) => DropdownMenuItem<String>(
                            value: org['id'].toString(),
                            child: Text(
                              '${org['name'] ?? 'Organization'}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => orgId = value);
                      context.go(
                        Uri(
                          path: '/organization-admin/dashboard',
                          queryParameters: {'organizationId': value},
                        ).toString(),
                      );
                      _refresh();
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => context.go(
                            Uri(
                              path: '/organization-admin/attendance',
                              queryParameters: {'organizationId': orgId!},
                            ).toString(),
                          ),
                          icon: const Icon(Icons.qr_code_scanner_rounded),
                          label: const Text('Open Attendance Scanner'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: loading ? null : _refresh,
                        tooltip: 'Refresh',
                        icon: const Icon(Icons.refresh, color: green),
                      ),
                    ],
                  ),
                  if (loading)
                    const Padding(
                      padding: EdgeInsets.all(25),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (!loading && data != null) ...[
                    const SizedBox(height: 18),
                    _statistics(),
                    const SizedBox(height: 18),
                    _charts(),
                    const SizedBox(height: 16),
                    _eventScheduleTable(),
                    const SizedBox(height: 16),
                    _eventCalendar(),
                    const SizedBox(height: 16),
                    _eventReports(),
                    const SizedBox(height: 20),
                    const Text(
                      'Scope: data is restricted to the selected organization. '
                      'Admin approvals and event publishing require a separate protected workflow.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
