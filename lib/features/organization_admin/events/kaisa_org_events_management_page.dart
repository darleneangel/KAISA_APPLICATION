import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// KAISA Organization Admin Events: secure RPC writes + scoped reads.
/// SQL prerequisite: 20261118_kaisa_org_events_management.sql.
/// Add packages: flutter pub add pdf printing
class KaisaOrgEventsManagementPage extends StatefulWidget {
  const KaisaOrgEventsManagementPage({super.key});

  @override
  State<KaisaOrgEventsManagementPage> createState() =>
      _KaisaOrgEventsManagementPageState();
}

class _KaisaOrgEventsManagementPageState
    extends State<KaisaOrgEventsManagementPage> {
  static const _forest = Color(0xFF14532D);

  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;
  bool _busy = false;
  bool _initialized = false;
  int _loadVersion = 0;
  String? _error;
  String? _organizationId;
  String? _dateFilter;
  String? _eventIdFilter;
  String _statusFilter = 'all';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final query = GoRouterState.of(context).uri.queryParameters;
    final nextOrgId = query['organizationId'];
    final reload = !_initialized || nextOrgId != _organizationId;
    _initialized = true;
    _organizationId = nextOrgId;
    _dateFilter = query['date'];
    _eventIdFilter = query['eventId'];
    if (reload) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _organizationId == nextOrgId) _load();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final organizationId = _organizationId;
    final version = ++_loadVersion;
    if (organizationId == null || organizationId.isEmpty) {
      setState(() {
        _loading = false;
        _events = [];
        _error =
            'No organization selected. Open your organization portal first.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _supabase.rpc(
        'kaisa_admin_event_schedule',
        params: {'p_organization_id': organizationId},
      );
      if (!mounted ||
          version != _loadVersion ||
          _organizationId != organizationId) {
        return;
      }
      if (data is! List) throw const FormatException('Invalid event response');
      setState(() {
        _events = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted ||
          version != _loadVersion ||
          _organizationId != organizationId) {
        return;
      }
      setState(() {
        _loading = false;
        _error = _friendlyError(e);
      });
    }
  }

  String _friendlyError(Object error) {
    if (error is PostgrestException) {
      if (error.code == 'PGRST202') {
        return 'A required KAISA RPC is missing. Run the new Events Management SQL migration in Supabase.';
      }
      if (error.code == '42501' ||
          error.message.contains('KAISA_ORG_ADMIN_NOT_AUTHORIZED') ||
          error.message.contains('KAISA_EVENT_NOT_ASSIGNED')) {
        return 'You do not have permission to manage this organization’s events.';
      }
      if (error.message.contains('KAISA_ONLY_DRAFT')) {
        return 'Only draft events can be edited or published.';
      }
      if (error.message.contains('KAISA_EVENT_ALREADY_STARTED') ||
          error.message.contains('KAISA_CANNOT_CANCEL_STARTED_EVENT')) {
        return 'This action is unavailable after an event has started.';
      }
      if (error.message.contains('KAISA_INVALID')) {
        return 'Some event information is invalid. Check the fields and dates.';
      }
      return 'Database error: ${error.message}';
    }
    return 'Unable to complete this action. Please retry. ($error)';
  }

  void _notify(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : _forest,
      ),
    );
  }

  Future<void> _runAction(
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    if (_busy || _organizationId == null) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      _notify(successMessage);
      await _load();
    } catch (error) {
      _notify(_friendlyError(error), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openEditor([Map<String, dynamic>? event]) async {
    if (_busy || _organizationId == null) return;
    final fields = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _KaisaEventEditor(initialEvent: event),
    );
    if (!mounted || fields == null || _organizationId == null) return;
    await _runAction(
      () async {
        await _supabase.rpc(
          'kaisa_admin_save_event',
          params: {
            'p_organization_id': _organizationId,
            'p_event_id': event?['event_id'],
            'p_event': fields,
          },
        );
      },
      successMessage: event == null
          ? 'Event saved as draft.'
          : 'Draft updated.',
    );
  }

  Future<bool> _confirm(
    String title,
    String description, {
    String approveLabel = 'Confirm',
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(description),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Go back'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(approveLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _publish(Map<String, dynamic> event) async {
    final ok = await _confirm(
      'Publish this event?',
      '“${event['title']}” will appear in the resident event catalog and residents can register. '
          'Published events cannot be edited in this workflow.',
      approveLabel: 'Publish event',
    );
    if (!ok || !mounted) return;
    await _runAction(() async {
      await _supabase.rpc(
        'kaisa_admin_publish_event',
        params: {
          'p_organization_id': _organizationId,
          'p_event_id': event['event_id'],
        },
      );
    }, successMessage: 'Event published successfully.');
  }

  Future<void> _cancel(Map<String, dynamic> event) async {
    final ok = await _confirm(
      'Cancel this event?',
      '“${event['title']}” will be marked cancelled and its attendance scanner disabled. '
          'This action cannot be undone here. Registered residents are NOT automatically notified; '
          'please send an announcement separately.',
      approveLabel: 'Cancel event',
    );
    if (!ok || !mounted) return;
    await _runAction(() async {
      await _supabase.rpc(
        'kaisa_admin_cancel_event',
        params: {
          'p_organization_id': _organizationId,
          'p_event_id': event['event_id'],
        },
      );
    }, successMessage: 'Event cancelled. Send a notice to affected residents.');
  }

  DateTime? _date(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString())?.toLocal();

  String _stamp(Object? value) {
    final valueDate = _date(value);
    if (valueDate == null) return 'TBA';
    final h = valueDate.hour % 12 == 0 ? 12 : valueDate.hour % 12;
    final minute = valueDate.minute.toString().padLeft(2, '0');
    final month = valueDate.month.toString().padLeft(2, '0');
    final day = valueDate.day.toString().padLeft(2, '0');
    return '${valueDate.year}-$month-$day  $h:$minute ${valueDate.hour < 12 ? 'AM' : 'PM'}';
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _clearRouteFilters() {
    final id = _organizationId;
    if (id == null) return;
    context.go(
      Uri(
        path: '/organization-admin/events',
        queryParameters: {'organizationId': id},
      ).toString(),
    );
  }

  List<Map<String, dynamic>> get _visibleEvents {
    final search = _searchController.text.trim().toLowerCase();
    return _events.where((e) {
      final start = _date(e['starts_at']);
      if (_dateFilter != null &&
          (start == null || _dateKey(start) != _dateFilter))
        return false;
      if (_eventIdFilter != null &&
          e['event_id'].toString() != _eventIdFilter) {
        return false;
      }
      if (_statusFilter != 'all' && e['status']?.toString() != _statusFilter) {
        return false;
      }
      if (search.isNotEmpty &&
          !('${e['title'] ?? ''} ${e['category'] ?? ''} ${e['location'] ?? ''}')
              .toLowerCase()
              .contains(search))
        return false;
      return true;
    }).toList();
  }

  String get _organizationName {
    if (_events.isNotEmpty) {
      return (_events.first['organization_name'] ?? 'Organization').toString();
    }
    return 'Organization';
  }

  // PDF uses built-in base fonts; replace unsupported Unicode characters with
  // ASCII equivalents to avoid font encoding errors. For full Unicode support,
  // bundle a TTF font and use pw.Font.ttf(...).
  String _pdfText(Object? input) {
    return (input ?? '—')
        .toString()
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll('•', '-')
        .replaceAll('’', "'")
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll(RegExp(r'[^\x09\x0A\x0D\x20-\x7E\xA0-\xFF]'), '?');
  }

  pw.Widget _pdfHeading(String title, String subtitle) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'KAISA  |  ORGANIZATION ADMINISTRATION',
        style: pw.TextStyle(
          color: PdfColor.fromHex('#14532D'),
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      pw.SizedBox(height: 12),
      pw.Text(
        _pdfText(title),
        style: pw.TextStyle(fontSize: 21, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 4),
      pw.Text(_pdfText(subtitle), style: const pw.TextStyle(fontSize: 10)),
      pw.SizedBox(height: 18),
    ],
  );

  pw.Widget _pdfPair(String label, Object? value) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 7),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 115,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            _pdfText(value),
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
      ],
    ),
  );

  pw.Widget _pdfLongText(String label, Object? value) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        label,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 3),
      pw.Text(_pdfText(value), style: const pw.TextStyle(fontSize: 10)),
      pw.SizedBox(height: 9),
    ],
  );

  pw.Widget _pdfTable(List<String> headers, List<List<String>> rows) =>
      pw.TableHelper.fromTextArray(
        headers: headers,
        data: rows.map((row) => row.map(_pdfText).toList()).toList(),
        border: pw.TableBorder.all(color: PdfColors.grey300, width: .5),
        headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#E8F3EC')),
        headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        cellStyle: const pw.TextStyle(fontSize: 8),
        cellPadding: const pw.EdgeInsets.all(6),
        cellAlignment: pw.Alignment.centerLeft,
      );

  Future<void> _sharePdf(pw.Document doc, String fileName) async {
    try {
      final bytes = await doc.save();
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (error) {
      _notify('PDF export failed: $error', error: true);
    }
  }

  pw.Widget _pdfFooter(pw.Context context) => pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(
        'KAISA  |  Generated ${_stamp(DateTime.now().toIso8601String())}',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
      ),
      pw.Text(
        'Page ${context.pageNumber} / ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
      ),
    ],
  );

  Future<void> _exportSchedule() async {
    final rows = _visibleEvents;
    if (rows.isEmpty) {
      _notify('No events to export.', error: true);
      return;
    }
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        maxPages: 200,
        footer: _pdfFooter,
        build: (_) => [
          _pdfHeading(
            'Events schedule',
            '$_organizationName  |  ${rows.length} visible event(s)',
          ),
          _pdfTable(
            ['Event', 'Starts', 'Venue', 'Status', 'Registered', 'Capacity'],
            rows
                .map(
                  (e) => [
                    (e['title'] ?? 'Event').toString(),
                    _stamp(e['starts_at']),
                    (e['location'] ?? 'TBA').toString(),
                    (e['status'] ?? 'draft').toString().toUpperCase(),
                    '${e['registered'] ?? 0}',
                    '${e['capacity'] ?? 0}',
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );
    await _sharePdf(doc, 'kaisa_events_schedule.pdf');
  }

  Future<void> _exportEvent(Map<String, dynamic> e) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        maxPages: 30,
        footer: _pdfFooter,
        build: (_) => [
          _pdfHeading('Event information', _organizationName),
          _pdfPair('Title', e['title']),
          _pdfPair('Status', (e['status'] ?? 'draft').toString().toUpperCase()),
          _pdfPair('Category', e['category']),
          _pdfLongText('Description', e['description']),
          _pdfPair('Venue', e['location']),
          _pdfPair('Starts', _stamp(e['starts_at'])),
          _pdfPair('Ends', _stamp(e['ends_at'])),
          _pdfPair('Check-in opens', _stamp(e['opens_at'])),
          _pdfPair('Check-in closes', _stamp(e['closes_at'])),
          _pdfPair('Capacity', e['capacity']),
          _pdfPair('Registered', e['registered']),
          _pdfPair('Checked in', e['present']),
          _pdfPair('Checked out', e['checked_out']),
          _pdfPair('Contact person', e['contact_name']),
          _pdfPair('Contact email', e['contact_email']),
          _pdfLongText('Participant instructions', e['instructions']),
        ],
      ),
    );
    final id = (e['event_id'] ?? 'event').toString();
    await _sharePdf(
      doc,
      'kaisa_event_${id.substring(0, id.length < 8 ? id.length : 8)}.pdf',
    );
  }

  Future<void> _exportAttendance(Map<String, dynamic> e) async {
    if (_busy || _organizationId == null) return;
    setState(() => _busy = true);
    try {
      final data = await _supabase.rpc(
        'kaisa_admin_attendance_report',
        params: {
          'p_organization_id': _organizationId,
          'p_event_id': e['event_id'],
        },
      );
      if (data is! List)
        throw const FormatException('Invalid attendance response');
      final attendees = data
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList();
      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(35),
          maxPages: 200,
          footer: _pdfFooter,
          build: (_) => [
            _pdfHeading(
              'Attendance report',
              '${e['title']}  |  ${attendees.length} registered attendee(s)',
            ),
            pw.Text(
              'CONFIDENTIAL - For authorized organization use only.',
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.red700,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            if (attendees.isEmpty)
              pw.Text('No registered attendees found.')
            else
              _pdfTable(
                ['#', 'Name', 'Registration', 'Check-in', 'Check-out'],
                attendees.asMap().entries.map((entry) {
                  final a = entry.value;
                  return [
                    '${entry.key + 1}',
                    (a['name'] ?? 'Resident').toString(),
                    (a['registration_status'] ?? '—').toString(),
                    a['checked_in_at'] == null
                        ? '—'
                        : _stamp(a['checked_in_at']),
                    a['checked_out_at'] == null
                        ? '—'
                        : _stamp(a['checked_out_at']),
                  ];
                }).toList(),
              ),
          ],
        ),
      );
      final id = (e['event_id'] ?? 'event').toString();
      await _sharePdf(
        doc,
        'kaisa_attendance_${id.substring(0, id.length < 8 ? id.length : 8)}.pdf',
      );
    } catch (error) {
      _notify(_friendlyError(error), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showEventDetails(Map<String, dynamic> e) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text((e['title'] ?? 'Event').toString()),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detail('Status', e['status']),
                _detail('Category', e['category']),
                _detail('Description', e['description']),
                _detail('Venue', e['location']),
                _detail('Starts', _stamp(e['starts_at'])),
                _detail('Ends', _stamp(e['ends_at'])),
                _detail('QR check-in opens', _stamp(e['opens_at'])),
                _detail('QR check-in closes', _stamp(e['closes_at'])),
                _detail(
                  'Registration / capacity',
                  '${e['registered'] ?? 0} / ${e['capacity'] ?? 0}',
                ),
                _detail(
                  'Checked in / out',
                  '${e['present'] ?? 0} / ${e['checked_out'] ?? 0}',
                ),
                _detail('Contact person', e['contact_name']),
                _detail('Contact email', e['contact_email']),
                _detail('Instructions', e['instructions']),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _exportEvent(e);
            },
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Export PDF'),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, Object? value) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _forest,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          (value == null || value.toString().trim().isEmpty)
              ? '—'
              : value.toString(),
        ),
      ],
    ),
  );

  Widget _stat(String title, String value, IconData icon) => Container(
    width: 190,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2EAE3)),
    ),
    child: Row(
      children: [
        Icon(icon, color: _forest, size: 22),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 23,
                color: _forest,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _eventCard(Map<String, dynamic> event) {
    final status = (event['status'] ?? 'draft').toString();
    final isDraft = status == 'draft';
    final isActive = status == 'published';
    final start = _date(event['starts_at']);
    final upcoming = start != null && start.isAfter(DateTime.now());
    final registrations = (event['registered'] as num?)?.toInt() ?? 0;
    final capacity = (event['capacity'] as num?)?.toInt() ?? 0;
    final double percent = capacity > 0
        ? (registrations / capacity).clamp(0.0, 1.0).toDouble()
        : 0.0;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFE2EAE3)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${event['title'] ?? 'Event'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _forest,
                  ),
                ),
                Chip(
                  label: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: isActive
                      ? const Color(0xFFD8F4E3)
                      : isDraft
                      ? const Color(0xFFFFF3CB)
                      : const Color(0xFFF1E2E2),
                ),
                Chip(
                  label: Text('${event['category'] ?? 'Community'}'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 7),
            if ((event['description'] ?? '').toString().isNotEmpty)
              Text(
                '${event['description']}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black87),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 18,
              runSpacing: 10,
              children: [
                _meta(Icons.event_outlined, _stamp(event['starts_at'])),
                _meta(Icons.place_outlined, '${event['location'] ?? 'TBA'}'),
                _meta(
                  Icons.people_outline,
                  'Registered $registrations / $capacity',
                ),
                _meta(
                  Icons.how_to_reg_outlined,
                  'Checked in ${event['present'] ?? 0}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: percent,
              minHeight: 5,
              backgroundColor: const Color(0xFFF0F4F0),
              color: _forest,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _showEventDetails(event),
                  icon: const Icon(Icons.visibility_outlined, size: 17),
                  label: const Text('Details'),
                ),
                if (isDraft)
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _openEditor(event),
                    icon: const Icon(Icons.edit_outlined, size: 17),
                    label: const Text('Edit draft'),
                  ),
                if (isDraft)
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _publish(event),
                    icon: const Icon(Icons.publish_outlined, size: 17),
                    label: const Text('Publish'),
                  ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _exportEvent(event),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 17),
                  label: const Text('Event PDF'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _exportAttendance(event),
                  icon: const Icon(Icons.download_outlined, size: 17),
                  label: const Text('Attendance PDF'),
                ),
                if ((isDraft || isActive) && upcoming)
                  TextButton.icon(
                    onPressed: _busy ? null : () => _cancel(event),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade800,
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 17),
                    label: const Text('Cancel event'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: _forest),
      const SizedBox(width: 5),
      Text(text, style: const TextStyle(color: Colors.black87, fontSize: 12)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final visible = _visibleEvents;
    final published = _events.where((e) => e['status'] == 'published').length;
    final drafts = _events.where((e) => e['status'] == 'draft').length;
    final upcoming = _events
        .where(
          (e) =>
              e['status'] == 'published' &&
              (_date(e['starts_at'])?.isAfter(DateTime.now()) ?? false),
        )
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ORGANIZATION MANAGEMENT',
                style: TextStyle(
                  color: Color(0xFF237A50),
                  fontSize: 11,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Events Management',
                style: TextStyle(
                  color: _forest,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Create and manage organization events, schedules, participation and PDF reports.',
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: _forest),
                    onPressed: _busy || _organizationId == null
                        ? null
                        : () => _openEditor(),
                    icon: const Icon(Icons.add),
                    label: const Text('Create event'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy || _loading ? null : _load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy || _loading || visible.isEmpty
                        ? null
                        : _exportSchedule,
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Export schedule PDF'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _stat(
                    'Total events',
                    '${_events.length}',
                    Icons.event_note_outlined,
                  ),
                  _stat('Published', '$published', Icons.public),
                  _stat('Drafts', '$drafts', Icons.edit_note_outlined),
                  _stat('Upcoming', '$upcoming', Icons.calendar_month_outlined),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 290,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search title, category, venue',
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  DropdownButton<String>(
                    value: _statusFilter,
                    items: const [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('All statuses'),
                      ),
                      DropdownMenuItem(value: 'draft', child: Text('Drafts')),
                      DropdownMenuItem(
                        value: 'published',
                        child: Text('Published'),
                      ),
                      DropdownMenuItem(
                        value: 'cancelled',
                        child: Text('Cancelled'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _statusFilter = value ?? 'all'),
                  ),
                  if (_dateFilter != null || _eventIdFilter != null)
                    Chip(
                      label: Text(
                        _dateFilter == null
                            ? 'Selected event'
                            : 'Date: $_dateFilter',
                      ),
                    ),
                  if (_dateFilter != null || _eventIdFilter != null)
                    TextButton.icon(
                      onPressed: _clearRouteFilters,
                      icon: const Icon(Icons.close),
                      label: const Text('Show all dates'),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error != null)
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                        TextButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (visible.isEmpty)
                const Card(
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.all(22),
                    child: Text(
                      'No events match these filters. Create a new event or adjust your search.',
                    ),
                  ),
                )
              else
                for (final event in visible) _eventCard(event),
              const SizedBox(height: 10),
              const Text(
                'Only approved organization admins can manage these events. '
                'Drafts are editable; published events cannot be edited in this workflow. '
                'Cancelling an event does not automatically notify registrants.',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog returns only data accepted by the whitelisted SQL RPC.
class _KaisaEventEditor extends StatefulWidget {
  final Map<String, dynamic>? initialEvent;
  const _KaisaEventEditor({this.initialEvent});

  @override
  State<_KaisaEventEditor> createState() => _KaisaEventEditorState();
}

class _KaisaEventEditorState extends State<_KaisaEventEditor> {
  static const _forest = Color(0xFF14532D);
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _category;
  late final TextEditingController _description;
  late final TextEditingController _location;
  late final TextEditingController _capacity;
  late final TextEditingController _contactName;
  late final TextEditingController _contactEmail;
  late final TextEditingController _instructions;
  late DateTime _starts;
  late DateTime _ends;
  late DateTime _opens;
  late DateTime _closes;

  @override
  void initState() {
    super.initState();
    final event = widget.initialEvent;
    String val(String key, String fallback) =>
        (event?[key] ?? fallback).toString();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final base = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9);
    _starts = DateTime.tryParse(val('starts_at', ''))?.toLocal() ?? base;
    _ends =
        DateTime.tryParse(val('ends_at', ''))?.toLocal() ??
        _starts.add(const Duration(hours: 2));
    _opens =
        DateTime.tryParse(val('opens_at', ''))?.toLocal() ??
        _starts.subtract(const Duration(minutes: 30));
    _closes =
        DateTime.tryParse(val('closes_at', ''))?.toLocal() ??
        _ends.add(const Duration(minutes: 30));
    _title = TextEditingController(text: val('title', ''));
    _category = TextEditingController(text: val('category', 'Community'));
    _description = TextEditingController(text: val('description', ''));
    _location = TextEditingController(text: val('location', ''));
    _capacity = TextEditingController(text: val('capacity', '100'));
    _contactName = TextEditingController(text: val('contact_name', ''));
    _contactEmail = TextEditingController(text: val('contact_email', ''));
    _instructions = TextEditingController(text: val('instructions', ''));
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _category,
      _description,
      _location,
      _capacity,
      _contactName,
      _contactEmail,
      _instructions,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String _stamp(DateTime d) {
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '${d.year}-$month-$day • $hour:$minute ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  Future<void> _pickDateTime(
    DateTime current,
    ValueChanged<DateTime> apply,
  ) async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 8),
      initialDate: current,
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !mounted) return;
    setState(
      () =>
          apply(DateTime(day.year, day.month, day.day, time.hour, time.minute)),
    );
  }

  Widget _dateTile(
    String label,
    DateTime value,
    ValueChanged<DateTime> apply,
  ) => OutlinedButton.icon(
    onPressed: () => _pickDateTime(value, apply),
    icon: const Icon(Icons.calendar_month_outlined, size: 18),
    label: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11)),
        Text(
          _stamp(value),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    int lines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    maxLines: lines,
    maxLength: maxLength,
    keyboardType: keyboardType,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      isDense: true,
    ),
  );

  String? _required(String? value, {int min = 1}) {
    if ((value ?? '').trim().length < min)
      return 'Enter at least $min characters';
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (!_ends.isAfter(_starts)) {
      _showError('Event end time must be after its start time.');
      return;
    }
    if (!_closes.isAfter(_opens)) {
      _showError('QR check-in closing must be after opening.');
      return;
    }
    final email = _contactEmail.text.trim();
    if (email.isNotEmpty &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      _showError('Enter a valid organizer contact email.');
      return;
    }
    Navigator.pop(context, <String, dynamic>{
      'title': _title.text.trim(),
      'category': _category.text.trim(),
      'description': _description.text.trim(),
      'location': _location.text.trim(),
      'capacity': int.parse(_capacity.text.trim()),
      'starts_at': _starts.toUtc().toIso8601String(),
      'ends_at': _ends.toUtc().toIso8601String(),
      'opens_at': _opens.toUtc().toIso8601String(),
      'closes_at': _closes.toUtc().toIso8601String(),
      'contact_name': _contactName.text.trim(),
      'contact_email': email,
      'instructions': _instructions.text.trim(),
    });
  }

  void _showError(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final editing = widget.initialEvent != null;
    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 790),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      editing ? 'Edit event draft' : 'Create event',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _forest,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Text(
                'Save your information as a draft, then publish when approved.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 560;
                        final colWidth = wide
                            ? (constraints.maxWidth - 14) / 2
                            : constraints.maxWidth;
                        return Wrap(
                          spacing: 14,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: constraints.maxWidth,
                              child: _field(
                                _title,
                                'Event title *',
                                maxLength: 150,
                                validator: (s) => _required(s, min: 3),
                              ),
                            ),
                            SizedBox(
                              width: colWidth,
                              child: _field(
                                _category,
                                'Category *',
                                maxLength: 60,
                                validator: (s) => _required(s),
                              ),
                            ),
                            SizedBox(
                              width: colWidth,
                              child: _field(
                                _capacity,
                                'Maximum participants *',
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  final n = int.tryParse((value ?? '').trim());
                                  if (n == null || n < 1 || n > 100000) {
                                    return 'Enter a number between 1 and 100,000';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(
                              width: constraints.maxWidth,
                              child: _field(
                                _location,
                                'Venue / location *',
                                maxLength: 250,
                                validator: (s) => _required(s),
                              ),
                            ),
                            SizedBox(
                              width: constraints.maxWidth,
                              child: _field(
                                _description,
                                'Event description',
                                lines: 3,
                                maxLength: 5000,
                              ),
                            ),
                            SizedBox(
                              width: constraints.maxWidth,
                              child: const Text(
                                'Event schedule',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: _forest,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: colWidth,
                              child: _dateTile(
                                'Starts',
                                _starts,
                                (d) => _starts = d,
                              ),
                            ),
                            SizedBox(
                              width: colWidth,
                              child: _dateTile('Ends', _ends, (d) => _ends = d),
                            ),
                            SizedBox(
                              width: constraints.maxWidth,
                              child: const Text(
                                'Attendance QR scanning window',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: _forest,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: colWidth,
                              child: _dateTile(
                                'QR opens',
                                _opens,
                                (d) => _opens = d,
                              ),
                            ),
                            SizedBox(
                              width: colWidth,
                              child: _dateTile(
                                'QR closes',
                                _closes,
                                (d) => _closes = d,
                              ),
                            ),
                            SizedBox(
                              width: constraints.maxWidth,
                              child: const Text(
                                'Additional details (optional)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: _forest,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: colWidth,
                              child: _field(
                                _contactName,
                                'Contact person',
                                maxLength: 120,
                              ),
                            ),
                            SizedBox(
                              width: colWidth,
                              child: _field(
                                _contactEmail,
                                'Contact email',
                                maxLength: 254,
                                keyboardType: TextInputType.emailAddress,
                              ),
                            ),
                            SizedBox(
                              width: constraints.maxWidth,
                              child: _field(
                                _instructions,
                                'Participant instructions / what to bring',
                                lines: 3,
                                maxLength: 2000,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Discard'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: _forest),
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save draft'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
