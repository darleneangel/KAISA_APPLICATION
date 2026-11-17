import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';

import '../../../shared/models/community_event_model.dart';
import '../../../shared/repositories/community_event_repository.dart';
import '../../../shared/repositories/organization_repository.dart';

// KAISA LGU Operations visual system — prototype repository data only.
const _forest = Color(0xFF00492C);
const _green = Color(0xFF287D55);
const _paper = Color(0xFFF6F8F5);
const _ink = Color(0xFF173D2B);
const _muted = Color(0xFF687B70);
const _gold = Color(0xFFFBBA16);
const _stroke = Color(0xFFE2EBE4);
const _soft = Color(0xFFEAF5EE);

class LguReportsPage extends StatefulWidget {
  const LguReportsPage({super.key});

  @override
  State<LguReportsPage> createState() => _LguReportsPageState();
}

class _LguReportsPageState extends State<LguReportsPage> {
  final OrganizationRepository organizationRepository =
      OrganizationRepository.instance;
  final CommunityEventRepository eventRepository =
      CommunityEventRepository.instance;
  final TextEditingController _search = TextEditingController();

  String _status = 'All';
  String _organization = 'All';
  String _sort = 'Newest first';
  String _reportTemplate = 'Organizations & Performance Summary';
  DateTimeRange? _range;
  String? _importName;
  List<String> _importHeaders = [];
  List<List<String>> _importRows = [];
  bool _importing = false;
  bool _exporting = false;
  String _importSearch = '';
  final TextEditingController _importSearchController = TextEditingController();
  int _importPage = 0;
  static const int _rowsPerPage = 20;

  @override
  void initState() {
    super.initState();
    organizationRepository.addListener(_refresh);
    eventRepository.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    organizationRepository.removeListener(_refresh);
    eventRepository.removeListener(_refresh);
    _search.dispose();
    _importSearchController.dispose();
    super.dispose();
  }

  String _orgName(String id) {
    for (final org in organizationRepository.organizations) {
      if (org.id == id) return org.name;
    }
    return 'Unknown organization';
  }

  String _date(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }

  List<CommunityEvent> get _filtered {
    final query = _search.text.trim().toLowerCase();
    final result = eventRepository.events.where((event) {
      if (_status != 'All' && event.status.label != _status) return false;
      if (_organization != 'All' && event.organizationId != _organization)
        return false;
      if (_range != null) {
        final day = DateUtils.dateOnly(event.startsAt);
        if (day.isBefore(DateUtils.dateOnly(_range!.start)) ||
            day.isAfter(DateUtils.dateOnly(_range!.end)))
          return false;
      }
      return query.isEmpty ||
          event.title.toLowerCase().contains(query) ||
          event.id.toLowerCase().contains(query) ||
          event.location.toLowerCase().contains(query) ||
          _orgName(event.organizationId).toLowerCase().contains(query);
    }).toList();
    if (_sort == 'Oldest first') {
      result.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    } else if (_sort == 'Most attended') {
      result.sort((a, b) => b.attendanceCount.compareTo(a.attendanceCount));
    } else if (_sort == 'Most registrations') {
      result.sort((a, b) => b.registrationCount.compareTo(a.registrationCount));
    } else {
      result.sort((a, b) => b.startsAt.compareTo(a.startsAt));
    }
    return result;
  }

  Future<void> _chooseDates() async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _range,
      helpText: 'Filter events by start date',
    );
    if (selected != null && mounted) setState(() => _range = selected);
  }

  void _clearFilters() {
    _search.clear();
    setState(() {
      _status = 'All';
      _organization = 'All';
      _sort = 'Newest first';
      _range = null;
    });
  }

  String _csvCell(Object? v) => _safeCsvCell((v ?? '').toString());

  Future<void> _copyCsv(List<CommunityEvent> events) async {
    final lines = <String>[
      'Event ID,Title,Organization ID,Organization,Start Date,End Date,Status,Location,Capacity,Registrations,Recorded Attendance,Description',
      for (final event in events)
        [
          event.id,
          event.title,
          event.organizationId,
          _orgName(event.organizationId),
          event.startsAt.toIso8601String(),
          event.endsAt.toIso8601String(),
          event.status.label,
          event.location,
          event.capacity,
          event.registrationCount,
          event.attendanceCount,
          event.description,
        ].map(_csvCell).join(','),
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\r\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied ${events.length} event records as CSV.')),
    );
  }

  // Imported files are a READ-ONLY report preview. No repository or Supabase writes.
  // File downloads are generated from the current prototype repositories.
  // They do not read or modify Supabase and never modify source records.
  String _exportName(String kind) {
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    return 'KAISA_${kind}_$stamp';
  }

  String _eventsCsv(List<CommunityEvent> events) {
    final lines = <String>[
      'Event ID,Title,Organization ID,Organization,Start Date,End Date,Status,Location,Capacity,Registrations,Recorded Attendance,Description',
      for (final event in events)
        [
          event.id,
          event.title,
          event.organizationId,
          _orgName(event.organizationId),
          event.startsAt.toIso8601String(),
          event.endsAt.toIso8601String(),
          event.status.label,
          event.location,
          event.capacity,
          event.registrationCount,
          event.attendanceCount,
          event.description,
        ].map(_csvCell).join(','),
    ];
    return lines.join('\r\n');
  }

  String _organizationsCsv() {
    final lines = <String>[
      'Organization ID,Name,Category,Status,Registry Reference,Contact Email,Assigned Representative,Description',
      for (final org in organizationRepository.organizations)
        [
          org.id,
          org.name,
          org.category,
          org.status,
          org.registryReference,
          org.email,
          org.adminEmail,
          org.description,
        ].map(_csvCell).join(','),
    ];
    return lines.join('\r\n');
  }

  Future<void> _saveExport(
    String kind,
    Uint8List bytes,
    String extension,
    MimeType mimeType,
  ) async {
    await FileSaver.instance.saveFile(
      name: _exportName(kind),
      bytes: bytes,
      fileExtension: extension,
      mimeType: mimeType,
    );
    if (mounted)
      _snack(
        '$extension.toUpperCase() export requested. Check your downloads.',
      );
  }

  Future<void> _exportCsv({
    required bool organizations,
    bool imported = false,
  }) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final content = imported
          ? <String>[
              _importHeaders.map(_safeCsvCell).join(','),
              for (final row in _importFiltered)
                row.map(_safeCsvCell).join(','),
            ].join('\r\n')
          : organizations
          ? _organizationsCsv()
          : _eventsCsv(_filtered);
      // UTF-8 BOM helps Excel recognize international text.
      await _saveExport(
        imported
            ? 'Imported_CSV'
            : organizations
            ? 'Organizations'
            : 'Events_Report',
        Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(content)]),
        'csv',
        MimeType.csv,
      );
    } catch (error) {
      if (mounted) _snack('CSV download failed: $error', error: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // Built-in PDF fonts have limited Unicode support. Normalize uncommon glyphs
  // to keep prototype reports exportable; UTF-8 CSV retains original text.
  String _pdfText(Object? value) =>
      (value ?? '').toString().replaceAll(RegExp(r'[^\x20-\x7E\n\r\t]'), '?');

  pw.Widget _pdfDetail(String label, Object? value) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Text(
      '${_pdfText(label)}: ${_pdfText(value)}',
      style: const pw.TextStyle(fontSize: 9),
    ),
  );

  Future<void> _exportPdf({required bool organizations}) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final reportEvents = _filtered;
      final orgs = organizationRepository.organizations.toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      final attendance = reportEvents.fold<int>(
        0,
        (v, e) => v + e.attendanceCount,
      );
      final registrations = reportEvents.fold<int>(
        0,
        (v, e) => v + e.registrationCount,
      );
      final pdf = pw.Document(
        title: 'KAISA Operations Prototype Report',
        author: 'KAISA Operations',
      );
      final forest = PdfColor.fromHex('#00492C');
      final gold = PdfColor.fromHex('#FBBA16');
      final generatedAt = DateTime.now().toIso8601String();
      final children = <pw.Widget>[
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(15),
          color: forest,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'KAISA / LGU OPERATIONS',
                style: pw.TextStyle(
                  color: gold,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 7),
              pw.Text(
                organizations
                    ? 'Organization Registry Report'
                    : 'Event Activity Report',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'PROTOTYPE DATA - not official LGU records',
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          'Generated: $generatedAt',
          style: const pw.TextStyle(fontSize: 9),
        ),
        if (!organizations) ...[
          _pdfDetail(
            'Filters',
            'Status: $_status; Organization: ${_organization == 'All' ? 'All' : _orgName(_organization)}; '
                'Date range: ${_range == null ? 'All dates' : '${_date(_range!.start)} to ${_date(_range!.end)}'}; '
                'Search: ${_search.text.isEmpty ? 'None' : _search.text}',
          ),
          _pdfDetail('Events in report', reportEvents.length),
          _pdfDetail('Registrations', registrations),
          _pdfDetail('Recorded attendance', attendance),
        ] else
          _pdfDetail('Organization records', orgs.length),
        pw.SizedBox(height: 10),
        pw.Divider(color: forest),
      ];
      if (organizations) {
        for (final org in orgs) {
          children.add(pw.Header(level: 2, text: _pdfText(org.name)));
          children.add(_pdfDetail('Organization ID', org.id));
          children.add(_pdfDetail('Category', org.category));
          children.add(_pdfDetail('Status', org.status));
          children.add(_pdfDetail('Registry reference', org.registryReference));
          children.add(_pdfDetail('Contact email', org.email));
          children.add(_pdfDetail('Assigned representative', org.adminEmail));
          children.add(_pdfDetail('Description', org.description));
          children.add(pw.SizedBox(height: 10));
        }
      } else {
        for (final event in reportEvents) {
          children.add(pw.Header(level: 2, text: _pdfText(event.title)));
          children.add(_pdfDetail('Event ID', event.id));
          children.add(
            _pdfDetail('Organization', _orgName(event.organizationId)),
          );
          children.add(_pdfDetail('Status', event.status.label));
          children.add(_pdfDetail('Start', event.startsAt.toIso8601String()));
          children.add(_pdfDetail('End', event.endsAt.toIso8601String()));
          children.add(_pdfDetail('Location', event.location));
          children.add(_pdfDetail('Capacity', event.capacity));
          children.add(_pdfDetail('Registrations', event.registrationCount));
          children.add(
            _pdfDetail('Recorded attendance', event.attendanceCount),
          );
          children.add(_pdfDetail('Description', event.description));
          children.add(pw.SizedBox(height: 10));
        }
      }
      if ((organizations ? orgs.length : reportEvents.length) == 0) {
        children.add(pw.Text('No records match the current selection.'));
      }
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          maxPages: 250,
          footer: (ctx) => pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'KAISA Prototype - Page ${ctx.pageNumber} / ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
            ),
          ),
          build: (_) => children,
        ),
      );
      await _saveExport(
        organizations ? 'Organizations_Report' : 'Events_Report',
        await pdf.save(),
        'pdf',
        MimeType.pdf,
      );
    } catch (error) {
      if (mounted) _snack('PDF export failed: $error', error: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  static const _templates = <String>[
    'Organizations & Performance Summary',
    'Organization Roster (Admins & Members)',
    'Event Attendance & Civic Turnout Sheet',
    'Community Filings & Incident Log',
  ];

  // Do not fabricate individual membership, QR-verified check-ins, or filings.
  bool get _templateAvailable =>
      _reportTemplate == _templates[0] || _reportTemplate == _templates[2];

  String get _templateScopeNote {
    switch (_reportTemplate) {
      case 'Organizations & Performance Summary':
        return 'Available prototype fields: organization, category, local registry status, '
            'assigned representative, events hosted and recorded event attendance. '
            'Barangay, accreditation, member totals and verified turnout are not connected.';
      case 'Organization Roster (Admins & Members)':
        return 'Requires organization_members, approved profiles, verification tiers and joined dates. '
            'This data is not connected, so exporting this template is disabled.';
      case 'Event Attendance & Civic Turnout Sheet':
        return 'Event-level summary only. Individual participants, verification tiers, '
            'QR check-in timestamps, methods and verified turnout are not connected.';
      default:
        return 'Requires operational_filings and authorized reviewer/audit data. '
            'This data is not connected, so exporting this template is disabled.';
    }
  }

  // Rows share the existing event date and organization filters.
  // Organization attributes not present in the prototype model remain explicit N/A.
  (List<String>, List<List<String>>) _generateTemplateRows() {
    if (_reportTemplate == _templates[0]) {
      final scopedOrganizations =
          organizationRepository.organizations
              .where((org) => _organization == 'All' || org.id == _organization)
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));
      final records = <List<String>>[];
      for (final org in scopedOrganizations) {
        final events = _filtered
            .where((event) => event.organizationId == org.id)
            .toList();
        final recorded = events.fold<int>(
          0,
          (sum, e) => sum + e.attendanceCount,
        );
        records.add([
          org.name,
          org.category,
          'Not connected',
          org.status,
          org.adminEmail.isEmpty ? 'Unassigned' : org.adminEmail,
          'Not connected',
          'Not connected',
          '${events.length}',
          'Not connected',
          '$recorded',
          'Not connected',
        ]);
      }
      return (
        [
          'Organization Name',
          'Category',
          'Barangay',
          'Local Registry Status',
          'Assigned Representative',
          'Admins and Officers',
          'Active Members',
          'Events Hosted (filtered)',
          'Verified Attendees',
          'Recorded Attendance (not verified)',
          'Average Verified Turnout %',
        ],
        records,
      );
    }
    if (_reportTemplate == _templates[2]) {
      return (
        [
          'Event ID',
          'Event Title',
          'Host Organization',
          'Venue / Location',
          'Event Date',
          'Event Status',
          'Registrations',
          'Recorded Attendance',
          'Participant Name',
          'Verification Tier',
          'Check-In Timestamp',
          'Check-In Method',
        ],
        [
          for (final e in _filtered)
            [
              e.id,
              e.title,
              _orgName(e.organizationId),
              e.location,
              _date(e.startsAt),
              e.status.label,
              '${e.registrationCount}',
              '${e.attendanceCount}',
              'Not connected',
              'Not connected',
              'Not connected',
              'Not connected',
            ],
        ],
      );
    }
    return (<String>[], <List<String>>[]);
  }

  Future<void> _downloadTemplateCsv() async {
    if (!_templateAvailable || _exporting) return;
    setState(() => _exporting = true);
    try {
      final (headers, rows) = _generateTemplateRows();
      final csvText = [
        headers.map(_safeCsvCell).join(','),
        for (final row in rows) row.map(_safeCsvCell).join(','),
      ].join('\r\n');
      final bytes = Uint8List.fromList([
        0xEF,
        0xBB,
        0xBF,
        ...utf8.encode(csvText),
      ]);
      await _saveExport(
        'Template_${_templates.indexOf(_reportTemplate) + 1}',
        bytes,
        'csv',
        MimeType.csv,
      );
    } catch (_) {
      if (mounted)
        _snack('Could not export the selected CSV template.', error: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _downloadTemplatePdf() async {
    if (!_templateAvailable || _exporting) return;
    setState(() => _exporting = true);
    try {
      final (headers, rows) = _generateTemplateRows();
      final orgCount = organizationRepository.organizations
          .where((org) => _organization == 'All' || org.id == _organization)
          .length;
      final eventCount = _filtered.length;
      final attendance = _filtered.fold<int>(
        0,
        (sum, e) => sum + e.attendanceCount,
      );
      final registrations = _filtered.fold<int>(
        0,
        (sum, e) => sum + e.registrationCount,
      );
      final rate = registrations == 0
          ? 'N/A'
          : '${(attendance * 100 / registrations).toStringAsFixed(1)}% (recorded)';
      final pdf = pw.Document(
        title: 'KAISA ${_pdfText(_reportTemplate)} - Prototype',
      );
      final forest = PdfColor.fromHex('#00492C');
      final mint = PdfColor.fromHex('#F0F7F2');
      final gold = PdfColor.fromHex('#FBBA16');
      final printableHeaders = _reportTemplate == _templates[0]
          ? [
              headers[0],
              headers[1],
              headers[3],
              headers[4],
              headers[7],
              headers[9],
            ]
          : [
              headers[1],
              headers[2],
              headers[3],
              headers[4],
              headers[6],
              headers[7],
            ];
      final indices = _reportTemplate == _templates[0]
          ? [0, 1, 3, 4, 7, 9]
          : [1, 2, 3, 4, 6, 7];
      final allRows = [
        printableHeaders,
        for (final row in rows) [for (final i in indices) row[i]],
      ];
      final tableRows = <pw.TableRow>[];
      for (var index = 0; index < allRows.length; index++) {
        tableRows.add(
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: index == 0
                  ? forest
                  : (index.isEven ? mint : PdfColors.white),
            ),
            children: [
              for (final cell in allRows[index])
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 7,
                  ),
                  child: pw.Text(
                    _pdfText(cell),
                    style: pw.TextStyle(
                      color: index == 0 ? PdfColors.white : PdfColors.black,
                      fontWeight: index == 0
                          ? pw.FontWeight.bold
                          : pw.FontWeight.normal,
                      fontSize: index == 0 ? 7 : 7.5,
                    ),
                  ),
                ),
            ],
          ),
        );
      }
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          maxPages: 250,
          margin: const pw.EdgeInsets.all(28),
          header: (ctx) => pw.Container(
            padding: const pw.EdgeInsets.all(10),
            color: forest,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'CAVITE CITY LGU  /  KAISA - PROTOTYPE REPORT',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: gold,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  _pdfText(_reportTemplate),
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          footer: (ctx) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'PROTOTYPE - not an official LGU certification',
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.Text(
                'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],
          ),
          build: (_) => [
            pw.SizedBox(height: 10),
            pw.Text(
              'Scope: ${_range == null ? 'All dates' : '${_date(_range!.start)} to ${_date(_range!.end)}'}'
              ' | Organization: ${_organization == 'All' ? 'All' : _orgName(_organization)}'
              ' | Barangay: Not available (no source field)',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              'Generated: ${DateTime.now().toIso8601String()} | Prepared by: Operations Administrator (prototype)',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 9),
            pw.Container(
              padding: const pw.EdgeInsets.all(9),
              color: mint,
              child: pw.Text(
                'Organizations: $orgCount   |   Events: $eventCount   |   Members: N/A'
                '   |   Turnout: $rate',
                style: pw.TextStyle(
                  color: forest,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              _pdfText(_templateScopeNote),
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.SizedBox(height: 14),
            if (rows.isEmpty)
              pw.Text('No matching prototype records.')
            else
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColor.fromHex('#E2EBE4'),
                  width: .5,
                ),
                children: tableRows,
              ),
            pw.SizedBox(height: 28),
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Text(
                    'Prepared by: __________________________\nOperations Administrator',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    'Noted by: __________________________\nLGU Super Administrator (for future approval)',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
      await _saveExport(
        'Template_${_templates.indexOf(_reportTemplate) + 1}',
        await pdf.save(),
        'pdf',
        MimeType.pdf,
      );
    } catch (_) {
      if (mounted) _snack('Could not generate this PDF report.', error: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Widget _reportGenerator() {
    final (headers, rows) = _generateTemplateRows();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Standard LGU Report Generator',
            style: TextStyle(
              color: _forest,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Select a report template. Date and organization filters above apply to available data.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: ValueKey(_reportTemplate),
            initialValue: _reportTemplate,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Report template',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final item in _templates)
                DropdownMenuItem(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (value) =>
                setState(() => _reportTemplate = value ?? _templates.first),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: _soft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _templateScopeNote,
              style: const TextStyle(color: _ink, fontSize: 12, height: 1.45),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: _templateAvailable && !_exporting
                    ? _downloadTemplateCsv
                    : null,
                icon: const Icon(Icons.table_view_outlined, size: 18),
                label: const Text('Download template CSV'),
                style: FilledButton.styleFrom(backgroundColor: _forest),
              ),
              OutlinedButton.icon(
                onPressed: _templateAvailable && !_exporting
                    ? _downloadTemplatePdf
                    : null,
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('Download template PDF'),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            _templateAvailable
                ? '${rows.length} matching records - template preview'
                : 'Template unavailable until required records and permissions are connected',
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_templateAvailable && rows.isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  for (final h in headers.take(6))
                    DataColumn(
                      label: Text(
                        h,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
                rows: [
                  for (final row in rows.take(5))
                    DataRow(
                      cells: [
                        for (final v in row.take(6))
                          DataCell(
                            SizedBox(
                              width: 130,
                              child: Text(
                                v,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _importCsv() async {
    if (_importing) return;
    setState(() => _importing = true);
    try {
      // file_picker 12+/13+: pickFile replaces single-file pickFiles().
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (file == null) return; // User cancelled.

      const maxBytes = 2 * 1024 * 1024;
      final reportedSize = file.lengthSync() ?? await file.length();
      if (reportedSize != null && reportedSize > maxBytes) {
        throw const FormatException('CSV must be 2 MB or smaller.');
      }
      final bytes = await file.readAsBytes();
      if (bytes.length > maxBytes) {
        throw const FormatException('CSV must be 2 MB or smaller.');
      }
      final csvText = utf8
          .decode(bytes, allowMalformed: false)
          .replaceFirst('\uFEFF', '');
      // csv 7+/8+: the top-level csv codec replaces CsvToListConverter.
      final parsed = csv.decode(csvText);
      if (parsed.isEmpty) {
        throw const FormatException('The selected CSV is empty.');
      }
      final headers = parsed.first
          .map((cell) => cell.toString().trim())
          .toList();
      if (headers.isEmpty || headers.any((header) => header.isEmpty)) {
        throw const FormatException('Every CSV column must have a header.');
      }
      if (headers.length > 40) {
        throw const FormatException('Maximum of 40 CSV columns supported.');
      }
      if (headers.map((h) => h.toLowerCase()).toSet().length !=
          headers.length) {
        throw const FormatException('CSV column headers must be unique.');
      }
      if (parsed.length > 2001) {
        throw const FormatException('Maximum of 2,000 data rows supported.');
      }
      final rows = <List<String>>[];
      for (var i = 1; i < parsed.length; i++) {
        final values = parsed[i].map((cell) => cell.toString()).toList();
        if (values.every((cell) => cell.trim().isEmpty)) continue;
        if (values.length != headers.length) {
          throw FormatException(
            'Row ${i + 1} has ${values.length} values; expected ${headers.length}.',
          );
        }
        rows.add(values);
      }
      if (!mounted) return;
      _importSearchController.clear();
      setState(() {
        _importName = file.name;
        _importHeaders = headers;
        _importRows = rows;
        _importSearch = '';
        _importPage = 0;
      });
      _snack(
        'Imported ${rows.length} CSV rows for preview (no database changes).',
      );
    } on FormatException catch (e) {
      if (mounted) _snack(e.message, error: true);
    } catch (_) {
      if (mounted)
        _snack(
          'Could not open CSV. Check its encoding and structure.',
          error: true,
        );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error ? const Color(0xFF9A342B) : _forest,
        content: Text(message),
      ),
    );
  }

  List<List<String>> get _importFiltered {
    final query = _importSearch.trim().toLowerCase();
    if (query.isEmpty) return _importRows;
    return _importRows
        .where((row) => row.any((cell) => cell.toLowerCase().contains(query)))
        .toList();
  }

  // Escape for CSV and guard against spreadsheet formula injection on export.
  String _safeCsvCell(String cell) {
    final safe = RegExp(r'^\s*[=+@-]').hasMatch(cell) ? "'$cell" : cell;
    return '"${safe.replaceAll('"', '""')}"';
  }

  Future<void> _copyImportedCsv() async {
    final lines = <String>[
      _importHeaders.map(_safeCsvCell).join(','),
      for (final row in _importFiltered) row.map(_safeCsvCell).join(','),
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\r\n')));
    if (mounted) _snack('Copied ${_importFiltered.length} imported CSV rows.');
  }

  Widget _importedCsvPanel() {
    final rows = _importFiltered;
    final pages = rows.isEmpty
        ? 1
        : ((rows.length + _rowsPerPage - 1) ~/ _rowsPerPage);
    final page = _importPage < 0
        ? 0
        : (_importPage >= pages ? pages - 1 : _importPage);
    final visibleRows = rows
        .skip(page * _rowsPerPage)
        .take(_rowsPerPage)
        .toList();
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CSV import & review',
                    style: TextStyle(
                      color: _forest,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Preview an external report. Import does not modify KAISA records.',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _importing ? null : _importCsv,
                    icon: _importing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file_outlined, size: 18),
                    label: Text(
                      _importName == null ? 'Import CSV' : 'Replace CSV',
                    ),
                  ),
                  if (_importName != null) ...[
                    OutlinedButton.icon(
                      onPressed: _copyImportedCsv,
                      icon: const Icon(Icons.copy_outlined, size: 18),
                      label: const Text('Copy CSV'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _exporting
                          ? null
                          : () => _exportCsv(
                              organizations: false,
                              imported: true,
                            ),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Download CSV'),
                    ),
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _importName = null;
                        _importRows = [];
                        _importHeaders = [];
                        _importSearch = '';
                        _importPage = 0;
                        _importSearchController.clear();
                      }),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Clear'),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (_importName == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 18),
              decoration: BoxDecoration(
                color: _paper,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(Icons.upload_file_rounded, color: _green, size: 38),
                  SizedBox(height: 10),
                  Text(
                    'Upload a CSV report to preview its entire dataset',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'UTF-8 CSV · Header row required · Up to 2 MB, 2,000 rows and 40 columns',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
            )
          else ...[
            Text(
              '$_importName · ${_importRows.length} rows · ${_importHeaders.length} columns',
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _importSearchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search any imported CSV column',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => setState(() {
                _importSearch = value;
                _importPage = 0;
              }),
            ),
            const SizedBox(height: 12),
            if (visibleRows.isEmpty)
              const Padding(
                padding: EdgeInsets.all(22),
                child: Text(
                  'No matching CSV rows.',
                  style: TextStyle(color: _muted),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(_soft),
                      columnSpacing: 22,
                      columns: [
                        for (final header in _importHeaders)
                          DataColumn(
                            label: SizedBox(
                              width: 150,
                              child: Text(
                                header,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                      rows: [
                        for (final row in visibleRows)
                          DataRow(
                            cells: [
                              for (final cell in row)
                                DataCell(
                                  Tooltip(
                                    message: cell,
                                    child: SizedBox(
                                      width: 150,
                                      child: Text(
                                        cell,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(
                  '${rows.length} matching · page ${page + 1} of $pages',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
                IconButton(
                  tooltip: 'Previous CSV page',
                  onPressed: page == 0
                      ? null
                      : () => setState(() => _importPage = page - 1),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                IconButton(
                  tooltip: 'Next CSV page',
                  onPressed: page + 1 >= pages
                      ? null
                      : () => setState(() => _importPage = page + 1),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _copyOrganizationCsv() async {
    final lines = <String>[
      'Organization ID,Name,Category,Status,Registry Reference,Contact Email,Assigned Representative,Description',
      for (final org in organizationRepository.organizations)
        [
          org.id,
          org.name,
          org.category,
          org.status,
          org.registryReference,
          org.email,
          org.adminEmail,
          org.description,
        ].map(_csvCell).join(','),
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\r\n')));
    if (mounted)
      _snack(
        'Copied ${organizationRepository.organizations.length} organization records as CSV.',
      );
  }

  Widget _organizationRecords() {
    final organizations = organizationRepository.organizations.toList();
    organizations.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return Container(
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Complete organization registry',
                      style: TextStyle(
                        color: _forest,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${organizations.length} records',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: _copyOrganizationCsv,
                  icon: const Icon(Icons.copy_all_outlined, size: 17),
                  label: const Text('Copy organization CSV'),
                ),
                OutlinedButton.icon(
                  onPressed: _exporting
                      ? null
                      : () => _exportCsv(organizations: true),
                  icon: const Icon(Icons.download_outlined, size: 17),
                  label: const Text('Export CSV'),
                ),
                OutlinedButton.icon(
                  onPressed: _exporting
                      ? null
                      : () => _exportPdf(organizations: true),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 17),
                  label: const Text('Export PDF'),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _stroke),
          if (organizations.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Text(
                'No organization records available.',
                style: TextStyle(color: _muted),
              ),
            ),
          for (final org in organizations)
            ExpansionTile(
              title: Text(
                org.name,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                '${org.category} · ${org.status}',
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detail('Organization ID', org.id),
                _detail('Registry reference', org.registryReference),
                _detail('Category', org.category),
                _detail('Status', org.status),
                _detail('Contact email', org.email),
                _detail(
                  'Assigned representative',
                  org.adminEmail.isEmpty ? 'Not assigned' : org.adminEmail,
                ),
                _detail('Description', org.description),
              ],
            ),
        ],
      ),
    );
  }

  void _showDetails(CommunityEvent event) {
    final rate = event.registrationCount == 0
        ? null
        : event.attendanceCount / event.registrationCount * 100;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          event.title,
          style: const TextStyle(color: _forest, fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: 490,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detail('Organization', _orgName(event.organizationId)),
                _detail('Event ID', event.id),
                _detail('Status', event.status.label),
                _detail(
                  'Schedule',
                  '${_date(event.startsAt)} – ${_date(event.endsAt)}',
                ),
                _detail('Location', event.location),
                _detail('Capacity', '${event.capacity}'),
                _detail('Registrations', '${event.registrationCount}'),
                _detail('Recorded attendance', '${event.attendanceCount}'),
                _detail(
                  'Attendance / registration',
                  rate == null
                      ? 'Not available'
                      : '${rate.toStringAsFixed(1)}%',
                ),
                _detail('Description', event.description),
                const SizedBox(height: 8),
                const Text(
                  'Prototype records only. Attendance is recorded, not independently QR-verified.',
                  style: TextStyle(fontSize: 11, color: _muted),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
        const SizedBox(height: 3),
        Text(
          value.isEmpty ? 'Not provided' : value,
          style: const TextStyle(
            color: _ink,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  BoxDecoration _surface({double radius = 18}) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: _stroke),
  );

  @override
  Widget build(BuildContext context) {
    final events = _filtered;
    final registrations = events.fold<int>(
      0,
      (sum, e) => sum + e.registrationCount,
    );
    final attendance = events.fold<int>(0, (sum, e) => sum + e.attendanceCount);
    final completed = events
        .where((e) => e.status == CommunityEventStatus.completed)
        .toList();
    final completeReg = completed.fold<int>(
      0,
      (sum, e) => sum + e.registrationCount,
    );
    final completeAttendance = completed.fold<int>(
      0,
      (sum, e) => sum + e.attendanceCount,
    );
    final rate = completeReg == 0
        ? null
        : completeAttendance / completeReg * 100;
    final organizationAttendance = <String, int>{};
    final organizationEvents = <String, int>{};
    for (final e in completed) {
      organizationAttendance.update(
        e.organizationId,
        (value) => value + e.attendanceCount,
        ifAbsent: () => e.attendanceCount,
      );
      organizationEvents.update(
        e.organizationId,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    final topOrganizations = organizationAttendance.entries.toList()
      ..sort((a, b) {
        final attendanceOrder = b.value.compareTo(a.value);
        return attendanceOrder != 0
            ? attendanceOrder
            : (organizationEvents[b.key] ?? 0).compareTo(
                organizationEvents[a.key] ?? 0,
              );
      });
    final statusCounts = <String, int>{
      'Upcoming': events
          .where((e) => e.status == CommunityEventStatus.upcoming)
          .length,
      'Ongoing': events
          .where((e) => e.status == CommunityEventStatus.ongoing)
          .length,
      'Completed': completed.length,
      'Cancelled': events
          .where((e) => e.status == CommunityEventStatus.cancelled)
          .length,
    };
    return LayoutBuilder(
      builder: (context, bounds) {
        final compact = bounds.maxWidth < 680;
        return ColoredBox(
          color: _paper,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 28,
              24,
              compact ? 16 : 28,
              48,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1260),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(compact),
                      const SizedBox(height: 22),
                      _section(
                        'Report overview',
                        'Numbers update from the current local prototype repositories.',
                      ),
                      const SizedBox(height: 12),
                      _stats([
                        _ReportStat(
                          'Registered organizations',
                          '${organizationRepository.totalOrganizations}',
                          Icons.apartment_rounded,
                        ),
                        _ReportStat(
                          'Events in report',
                          '${events.length}',
                          Icons.event_note_rounded,
                        ),
                        _ReportStat(
                          'Registrations',
                          '$registrations',
                          Icons.groups_rounded,
                        ),
                        _ReportStat(
                          'Recorded attendance',
                          '$attendance',
                          Icons.fact_check_outlined,
                        ),
                      ]),
                      const SizedBox(height: 22),
                      _filters(events.length),
                      const SizedBox(height: 22),
                      _reportGenerator(),
                      const SizedBox(height: 22),
                      _spotlight(topOrganizations, organizationEvents, rate),
                      const SizedBox(height: 22),
                      _section(
                        'Participation & activity',
                        'Two focused breakdowns, based on the selected report filters.',
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, box) {
                          final sideBySide = box.maxWidth >= 840;
                          final width = sideBySide
                              ? (box.maxWidth - 14) / 2
                              : box.maxWidth;
                          return Wrap(
                            spacing: 14,
                            runSpacing: 14,
                            children: [
                              SizedBox(
                                width: width,
                                child: _panel(
                                  'Events by status',
                                  'Filtered event distribution',
                                  _bars(statusCounts, events.length),
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: _panel(
                                  'Top hosting organizations',
                                  'Recorded attendance from completed events',
                                  _organizationBars(topOrganizations),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 22),
                      _section(
                        'Full report records',
                        'Inspect every organization field and all matching event details.',
                      ),
                      const SizedBox(height: 12),
                      _organizationRecords(),
                      const SizedBox(height: 22),
                      _section(
                        'Event report',
                        'Open any event to view its complete description, schedule, capacity, registration and attendance.',
                      ),
                      const SizedBox(height: 12),
                      _eventList(events),
                      const SizedBox(height: 22),
                      _importedCsvPanel(),
                      const SizedBox(height: 14),
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: _muted, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Prototype report only. Figures come from in-app repositories; imported CSV remains a separate read-only preview. '
                              'Most Active uses recorded attendance from completed events, not a certified award or QR verification.',
                              style: TextStyle(
                                color: _muted,
                                fontSize: 11,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _header(bool compact) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(compact ? 22 : 30),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0B3024), Color(0xFF16593E), Color(0xFF288258)],
      ),
    ),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 16,
      spacing: 20,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'KAISA  /  LGU OPERATIONS  /  REPORTS',
                style: TextStyle(
                  color: _gold,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 13),
              Text(
                'Reports & Insights',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 27 : 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Explore community event activity, organizational participation, and practical reports.',
                style: TextStyle(
                  color: Color(0xFFE2F0E6),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white12,
            border: Border.all(color: Colors.white30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.science_outlined, color: _gold, size: 18),
              SizedBox(width: 8),
              Text(
                'PROTOTYPE DATA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _section(String title, String sub) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: _ink,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 5),
      Text(sub, style: const TextStyle(color: _muted, fontSize: 12)),
    ],
  );

  Widget _stats(List<_ReportStat> stats) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 960
          ? 4
          : constraints.maxWidth >= 540
          ? 2
          : 1;
      const gap = 12.0;
      final w = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final stat in stats)
            Container(
              width: w,
              padding: const EdgeInsets.all(17),
              decoration: _surface(),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _soft,
                    ),
                    child: Icon(stat.icon, color: _forest, size: 23),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stat.value,
                          style: const TextStyle(
                            color: _forest,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          stat.title,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    },
  );

  Widget _filters(int count) {
    final organizations = organizationRepository.organizations;
    final orgIds = <String>{
      ...organizations.map((org) => org.id),
      ...eventRepository.events.map((event) => event.organizationId),
    }.toList()..sort((a, b) => _orgName(a).compareTo(_orgName(b)));
    if (_organization != 'All' && !orgIds.contains(_organization))
      _organization = 'All';
    final search = TextField(
      controller: _search,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Search event, organization, ID or location',
        prefixIcon: const Icon(Icons.search_rounded, color: _green),
        suffixIcon: _search.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _search.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close_rounded),
              ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(11)),
        isDense: true,
      ),
    );
    final status = DropdownButtonFormField<String>(
      key: ValueKey('status-$_status'),
      initialValue: _status,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: ['All', 'Upcoming', 'Ongoing', 'Completed', 'Cancelled']
          .map(
            (value) => DropdownMenuItem(
              value: value,
              child: Text(value, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _status = v ?? 'All'),
    );
    final org = DropdownButtonFormField<String>(
      key: ValueKey('organization-$_organization'),
      initialValue: _organization,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Organization',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem(value: 'All', child: Text('All organizations')),
        for (final id in orgIds)
          DropdownMenuItem(
            value: id,
            child: Text(_orgName(id), overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) => setState(() => _organization = v ?? 'All'),
    );
    final sort = DropdownButtonFormField<String>(
      key: ValueKey('sort-$_sort'),
      initialValue: _sort,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Sort',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items:
          [
                'Newest first',
                'Oldest first',
                'Most attended',
                'Most registrations',
              ]
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(value, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
      onChanged: (v) => setState(() => _sort = v ?? 'Newest first'),
    );
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 10,
            spacing: 12,
            children: [
              const Text(
                'Report filters',
                style: TextStyle(
                  color: _forest,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                '$count matching event(s)',
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 800;
              final mid = c.maxWidth >= 520;
              final w = wide
                  ? (c.maxWidth - 36) / 4
                  : mid
                  ? (c.maxWidth - 12) / 2
                  : c.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 13,
                children: [
                  SizedBox(width: w, child: search),
                  SizedBox(width: w, child: status),
                  SizedBox(width: w, child: org),
                  SizedBox(width: w, child: sort),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _chooseDates,
                icon: const Icon(Icons.date_range_rounded, size: 17),
                label: Text(
                  _range == null
                      ? 'Select date range'
                      : '${_date(_range!.start)} – ${_date(_range!.end)}',
                ),
              ),
              if (_range != null)
                IconButton(
                  tooltip: 'Clear date range',
                  onPressed: () => setState(() => _range = null),
                  icon: const Icon(Icons.close_rounded),
                ),
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 17),
                label: const Text('Reset filters'),
              ),
              OutlinedButton.icon(
                onPressed: () => _copyCsv(_filtered),
                icon: const Icon(Icons.copy_all_rounded, size: 17),
                label: const Text('Copy CSV'),
              ),
              FilledButton.icon(
                onPressed: _exporting
                    ? null
                    : () => _exportCsv(organizations: false),
                style: FilledButton.styleFrom(
                  backgroundColor: _forest,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.download_outlined, size: 17),
                label: const Text('Export CSV'),
              ),
              FilledButton.icon(
                onPressed: _exporting
                    ? null
                    : () => _exportPdf(organizations: false),
                style: FilledButton.styleFrom(
                  backgroundColor: _forest,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 17),
                label: const Text('Export PDF'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _spotlight(
    List<MapEntry<String, int>> leaders,
    Map<String, int> organizationEvents,
    double? rate,
  ) {
    final hasLeader = leaders.isNotEmpty && leaders.first.value > 0;
    final lead = hasLeader ? leaders.first : null;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _surface(),
      child: LayoutBuilder(
        builder: (context, box) {
          return Wrap(
            spacing: 20,
            runSpacing: 16,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: box.maxWidth >= 650 ? box.maxWidth * .57 : box.maxWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.emoji_events_outlined,
                          color: Color(0xFFC38A0C),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'MOST ACTIVE · REPORT VIEW',
                          style: TextStyle(
                            color: _forest,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      lead == null
                          ? 'Not enough completed-event data yet'
                          : _orgName(lead.key),
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Ranked by recorded attendance across completed events in the current report filters. '
                      'This is a prototype indication, not an official recognition.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: _soft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead == null ? '—' : '${lead.value}',
                      style: const TextStyle(
                        color: _forest,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'Recorded attendance',
                      style: TextStyle(color: _muted, fontSize: 11),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      lead == null
                          ? 'No hosted events'
                          : '${organizationEvents[lead.key] ?? 0} completed events',
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      rate == null
                          ? 'Attendance rate: N/A'
                          : 'Completion attendance rate: ${rate.toStringAsFixed(1)}%',
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _panel(String title, String subtitle, Widget child) => Container(
    constraints: const BoxConstraints(minHeight: 275),
    padding: const EdgeInsets.all(19),
    decoration: _surface(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _forest,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
        const SizedBox(height: 20),
        child,
      ],
    ),
  );

  Widget _bars(Map<String, int> values, int total) {
    if (total == 0) return _empty('No matching events in this report.');
    const colors = [_green, _forest, Color(0xFF74B495), _gold];
    final entries = values.entries.toList();
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          Tooltip(
            message: '${entries[i].key}: ${entries[i].value} / $total events',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entries[i].key,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${entries[i].value} · ${(entries[i].value / total * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: entries[i].value / total,
                    minHeight: 12,
                    backgroundColor: _soft,
                    color: colors[i % colors.length],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
        ],
      ],
    );
  }

  Widget _organizationBars(List<MapEntry<String, int>> entries) {
    final top = entries.where((e) => e.value > 0).take(5).toList();
    if (top.isEmpty)
      return _empty('No recorded attendance for completed events.');
    final max = top.first.value;
    return Column(
      children: [
        for (var i = 0; i < top.length; i++) ...[
          Tooltip(
            message:
                '${_orgName(top[i].key)}: ${top[i].value} recorded attendees',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 25,
                      child: Text(
                        '#${i + 1}',
                        style: const TextStyle(
                          color: _green,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _orgName(top[i].key),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${top[i].value}',
                      style: const TextStyle(
                        color: _forest,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: max == 0 ? 0.0 : top[i].value / max,
                    minHeight: 12,
                    backgroundColor: _soft,
                    color: i == 0 ? _gold : _green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _empty(String title) => SizedBox(
    height: 145,
    child: Center(
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(color: _muted, fontSize: 12),
      ),
    ),
  );

  Widget _eventList(List<CommunityEvent> events) => Container(
    decoration: _surface(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(Icons.summarize_outlined, color: _green, size: 21),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Event records',
                  style: TextStyle(
                    color: _forest,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${events.length} results',
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: _stroke),
        if (events.isEmpty)
          Padding(
            padding: const EdgeInsets.all(40),
            child: _empty('No events match your current filters.'),
          )
        else
          for (final event in events) ...[
            _eventTile(event),
            const Divider(height: 1, color: _stroke),
          ],
      ],
    ),
  );

  Widget _eventTile(CommunityEvent event) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => _showDetails(event),
      hoverColor: _soft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _soft,
              ),
              child: const Icon(
                Icons.event_available_outlined,
                color: _forest,
                size: 21,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_orgName(event.organizationId)}  •  ${_date(event.startsAt)}',
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 9,
                    runSpacing: 5,
                    children: [
                      _tag(event.status.label),
                      _tag('${event.registrationCount} registered'),
                      _tag('${event.attendanceCount} attended'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.chevron_right_rounded, color: _muted),
          ],
        ),
      ),
    ),
  );

  Widget _tag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: _soft,
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: _forest,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _ReportStat {
  final String title;
  final String value;
  final IconData icon;
  const _ReportStat(this.title, this.value, this.icon);
}
