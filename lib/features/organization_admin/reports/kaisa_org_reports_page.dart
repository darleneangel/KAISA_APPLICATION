import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_html/html.dart' as html;

/// Full report page, protected by the existing Organization Admin route guard.
/// All data is obtained through organization-scoped Supabase RPCs.
class KaisaOrgReportsPage extends StatefulWidget {
  const KaisaOrgReportsPage({super.key});

  @override
  State<KaisaOrgReportsPage> createState() => _KaisaOrgReportsPageState();
}

class _KaisaOrgReportsPageState extends State<KaisaOrgReportsPage> {
  static const green = Color(0xFF14532D);
  static const surface = Color(0xFFF8FAF8);
  final db = Supabase.instance.client;
  bool loading = true;
  bool exporting = false;
  String? error;
  String? selectedEventId;
  List<Map<String, dynamic>> events = [];
  String? orgId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final qp = GoRouterState.of(context).uri.queryParameters;
    final incomingOrgId = qp['organizationId'];
    if (incomingOrgId != orgId) {
      orgId = incomingOrgId;
      selectedEventId = qp['eventId'];
      _load();
    } else if (selectedEventId == null && qp['eventId'] != null) {
      selectedEventId = qp['eventId'];
    }
  }

  int count(Map<String, dynamic> event, String key) {
    final v = event[key];
    return v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;
  }

  Future<void> _load() async {
    final id = orgId;
    if (id == null || id.isEmpty) {
      setState(() {
        loading = false;
        error = 'Select an organization before viewing reports.';
      });
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      // A protected RPC is required; the client-side guard alone is insufficient.
      final result = await db.rpc(
        'kaisa_admin_overview',
        params: {'p_organization_id': id},
      );
      if (!mounted || orgId != id) return;
      final overview = Map<String, dynamic>.from(result as Map);
      final raw = overview['event_summary'];
      final list = raw is List
          ? raw.map((v) => Map<String, dynamic>.from(v as Map)).toList()
          : <Map<String, dynamic>>[];
      setState(() {
        events = list;
        if (!list.any((e) => e['event_id']?.toString() == selectedEventId)) {
          selectedEventId = list.isEmpty
              ? null
              : list.first['event_id'].toString();
        }
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted && orgId == id) setState(() => loading = false);
    }
  }

  String _csvCell(Object? value) {
    var s = (value ?? '').toString();
    if (RegExp(r'^\s*[=+@\-]').hasMatch(s)) s = "'$s";
    return '"${s.replaceAll('"', '""')}"';
  }

  Future<void> _export({required bool pdf}) async {
    if (exporting || orgId == null || selectedEventId == null) return;
    setState(() => exporting = true);
    try {
      final raw = await db.rpc(
        'kaisa_admin_attendance_report',
        params: {'p_organization_id': orgId, 'p_event_id': selectedEventId},
      );
      final rows = (raw as List)
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList();
      final title = events
          .firstWhere(
            (e) => e['event_id']?.toString() == selectedEventId,
            orElse: () => <String, dynamic>{'event': 'Event'},
          )['event']
          .toString();
      if (pdf) {
        final doc = pw.Document();
        doc.addPage(
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
                      (r) => [
                        '${r['name'] ?? ''}',
                        '${r['registration_status'] ?? ''}',
                        '${r['checked_in_at'] ?? ''}',
                        '${r['checked_out_at'] ?? ''}',
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
        await Printing.layoutPdf(onLayout: (_) => doc.save());
      } else {
        if (!kIsWeb) {
          throw UnsupportedError(
            'CSV download is available on web. Use PDF on mobile.',
          );
        }
        final lines = <String>[
          'Resident,Registration,Check-in (UTC),Check-out (UTC)',
          for (final r in rows)
            [
              r['name'],
              r['registration_status'],
              r['checked_in_at'],
              r['checked_out_at'],
            ].map(_csvCell).join(','),
        ];
        final blob = html.Blob([
          utf8.encode('\uFEFF${lines.join('\r\n')}'),
        ], 'text/csv;charset=utf-8');
        final url = html.Url.createObjectUrlFromBlob(blob);
        try {
          html.AnchorElement(href: url)
            ..setAttribute('download', 'kaisa_attendance_$selectedEventId.csv')
            ..click();
        } finally {
          html.Url.revokeObjectUrl(url);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Report export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chosen = events.where(
      (e) => e['event_id']?.toString() == selectedEventId,
    );
    final event = chosen.isEmpty ? null : chosen.first;
    return ColoredBox(
      color: surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: orgId == null
                      ? null
                      : () => context.go(
                          Uri(
                            path: '/organization-admin/dashboard',
                            queryParameters: {'organizationId': orgId!},
                          ).toString(),
                        ),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back to Dashboard'),
                ),
                const SizedBox(height: 10),
                const Text(
                  'ORGANIZATION MANAGEMENT',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF237A50),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Reports & Exports',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    color: green,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'View event participation and export authorized attendance records.',
                ),
                const SizedBox(height: 22),
                if (loading) const Center(child: CircularProgressIndicator()),
                if (error != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Unable to load reports: $error'),
                    ),
                  ),
                if (!loading && error == null) ...[
                  if (events.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No events with assigned attendance sessions yet.',
                        ),
                      ),
                    ),
                  if (events.isNotEmpty) ...[
                    Card(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Choose an event',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: green,
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              key: ValueKey(selectedEventId),
                              initialValue: selectedEventId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Event',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                for (final e in events)
                                  DropdownMenuItem<String>(
                                    value: e['event_id'].toString(),
                                    child: Text(
                                      e['event']?.toString() ?? 'Event',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: (id) =>
                                  setState(() => selectedEventId = id),
                            ),
                            if (event != null) ...[
                              const SizedBox(height: 18),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _metric(
                                    'Registered',
                                    count(event, 'registered'),
                                    Icons.people_outline,
                                  ),
                                  _metric(
                                    'Checked in',
                                    count(event, 'present'),
                                    Icons.how_to_reg_outlined,
                                  ),
                                  _metric(
                                    'Checked out',
                                    count(event, 'completed'),
                                    Icons.fact_check_outlined,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: exporting || !kIsWeb
                                        ? null
                                        : () => _export(pdf: false),
                                    icon: const Icon(
                                      Icons.table_chart_outlined,
                                    ),
                                    label: const Text('Export CSV (Web)'),
                                  ),
                                  FilledButton.icon(
                                    onPressed: exporting
                                        ? null
                                        : () => _export(pdf: true),
                                    icon: const Icon(
                                      Icons.picture_as_pdf_outlined,
                                    ),
                                    label: const Text('Export PDF'),
                                  ),
                                  IconButton(
                                    onPressed: loading || exporting
                                        ? null
                                        : _load,
                                    tooltip: 'Refresh',
                                    icon: const Icon(
                                      Icons.refresh,
                                      color: green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
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

  Widget _metric(String label, int value, IconData icon) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5EE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: green),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: green,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
