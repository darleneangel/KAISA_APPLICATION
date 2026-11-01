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

  final SupabaseClient db = Supabase.instance.client;

  List<Map<String, dynamic>> orgs = [];
  Map<String, dynamic>? data;
  String? orgId;
  String? error;
  String? busyReport;
  bool loading = true;

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
        orgId = items.isEmpty ? null : items.first['id'].toString();
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
    });

    try {
      final result = await db.rpc(
        'kaisa_admin_overview',
        params: {'p_organization_id': selectedId},
      );
      if (!mounted || orgId != selectedId) return;
      setState(() => data = Map<String, dynamic>.from(result as Map));
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
        final width = constraints.maxWidth > 750
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        final checkedIn = number('checked_in');
        final remaining = (number('registrations') - checkedIn).clamp(
          0,
          999999,
        );

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: width,
              child: _panel(
                'Event participation (bar chart)',
                SizedBox(
                  height: 230,
                  child: events.isEmpty
                      ? const Center(child: Text('No assigned events yet'))
                      : BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            barGroups: [
                              for (var i = 0; i < events.length && i < 8; i++)
                                BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: eventNumber(events[i], 'registered'),
                                      color: green,
                                      width: 13,
                                    ),
                                    BarChartRodData(
                                      toY: eventNumber(events[i], 'present'),
                                      color: gold,
                                      width: 13,
                                    ),
                                  ],
                                ),
                            ],
                            titlesData: const FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: const FlGridData(show: false),
                          ),
                        ),
                ),
              ),
            ),
            SizedBox(
              width: width,
              child: _panel(
                'Attendance progress (pie chart)',
                SizedBox(
                  height: 230,
                  child: number('registrations') == 0
                      ? const Center(child: Text('No registrations yet'))
                      : PieChart(
                          PieChartData(
                            centerSpaceRadius: 44,
                            sections: [
                              if (checkedIn > 0)
                                PieChartSectionData(
                                  value: checkedIn.toDouble(),
                                  color: green,
                                  title: 'Present',
                                  radius: 70,
                                  titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              if (remaining > 0)
                                PieChartSectionData(
                                  value: remaining.toDouble(),
                                  color: gold,
                                  title: 'Awaiting',
                                  radius: 70,
                                  titleStyle: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _eventReports() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Event Attendance Reports',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: green,
          ),
        ),
        const SizedBox(height: 8),
        if (events.isEmpty)
          const Text(
            'Assign an event check-in session to this organization to enable attendance reports.',
          ),
        for (final event in events)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${event['event'] ?? 'Event'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Registered: ${event['registered'] ?? 0}  ·  '
                      'Checked in: ${event['present'] ?? 0}  ·  '
                      'Checked out: ${event['completed'] ?? 0}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: busyReport != null || !kIsWeb
                              ? null
                              : () => _export(event, pdf: false),
                          icon: const Icon(Icons.table_chart_outlined),
                          label: const Text('CSV (Web)'),
                        ),
                        FilledButton.icon(
                          onPressed: busyReport != null
                              ? null
                              : () => _export(event, pdf: true),
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: const Text('PDF'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
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
                      _refresh();
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () =>
                              context.go('/organization-admin/attendance'),
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
