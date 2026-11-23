import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../shared/models/community_event_model.dart';
import '../../../shared/models/organization_model.dart';
import '../../../shared/repositories/community_event_repository.dart';
import '../../../shared/repositories/organization_repository.dart';

// KAISA Operations: PDF-only reporting from the shared in-memory prototype.
// No Supabase queries, member verification, or official attendance certification.
const _forest = Color(0xFF00492C);
const _green = Color(0xFF287D55);
const _gold = Color(0xFFFBBA16);
const _paper = Color(0xFFF6F8F5);
const _ink = Color(0xFF173D2B);
const _muted = Color(0xFF687B70);
const _mint = Color(0xFFEAF5EE);
const _border = Color(0xFFE2EBE4);

class LguReportsPage extends StatefulWidget {
  const LguReportsPage({super.key});

  @override
  State<LguReportsPage> createState() => _LguReportsPageState();
}

class _LguReportsPageState extends State<LguReportsPage> {
  final _organizations = OrganizationRepository.instance;
  final _events = CommunityEventRepository.instance;
  final _search = TextEditingController();
  String _organizationId = 'All';
  String _eventStatus = 'All';
  String _report = 'Organizations & Performance';
  DateTimeRange? _dates;
  bool _exporting = false;

  static const _reportOptions = [
    'Organizations & Performance',
    'Event Activity & Attendance',
  ];

  @override
  void initState() {
    super.initState();
    _organizations.addListener(_refresh);
    _events.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _organizations.removeListener(_refresh);
    _events.removeListener(_refresh);
    _search.dispose();
    super.dispose();
  }

  String _orgName(String id) {
    for (final org in _organizations.organizations) {
      if (org.id == id) return org.name;
    }
    return 'Unknown organization';
  }

  String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<CommunityEvent> get _matchingEvents {
    final query = _search.text.trim().toLowerCase();
    final list = _events.events.where((e) {
      if (_organizationId != 'All' && e.organizationId != _organizationId) {
        return false;
      }
      if (_eventStatus != 'All' && e.status.label != _eventStatus) return false;
      if (_dates != null) {
        final day = DateUtils.dateOnly(e.startsAt);
        if (day.isBefore(DateUtils.dateOnly(_dates!.start)) ||
            day.isAfter(DateUtils.dateOnly(_dates!.end)))
          return false;
      }
      return query.isEmpty ||
          e.title.toLowerCase().contains(query) ||
          e.id.toLowerCase().contains(query) ||
          _orgName(e.organizationId).toLowerCase().contains(query) ||
          e.location.toLowerCase().contains(query);
    }).toList();
    list.sort((a, b) => b.startsAt.compareTo(a.startsAt));
    return list;
  }

  List<RegistryOrganization> get _matchingOrganizations {
    final query = _search.text.trim().toLowerCase();
    final list = _organizations.organizations.where((o) {
      if (_organizationId != 'All' && o.id != _organizationId) return false;
      return query.isEmpty ||
          o.name.toLowerCase().contains(query) ||
          o.id.toLowerCase().contains(query) ||
          o.category.toLowerCase().contains(query);
    }).toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  BoxDecoration _surface() => BoxDecoration(
    color: Colors.white,
    border: Border.all(color: _border),
    borderRadius: BorderRadius.circular(18),
  );

  Widget _card(Widget child) => Container(
    decoration: _surface(),
    padding: const EdgeInsets.all(18),
    child: child,
  );

  Widget _stat(String label, String value, IconData icon) => _card(
    Row(
      children: [
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: _mint,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: _forest),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: _forest,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _dropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChange, {
    double width = 220,
  }) => SizedBox(
    width: width,
    child: DropdownButtonFormField<String>(
      key: ValueKey('$label-$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: [
        for (final option in options)
          DropdownMenuItem(
            value: option,
            child: Text(
              label == 'Organization' && option != 'All'
                  ? _orgName(option)
                  : option,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onChange,
    ),
  );

  Widget _filters() {
    final orgList = _organizations.organizations.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final knownIds = orgList.map((o) => o.id).toSet();
    final selectedId = knownIds.contains(_organizationId)
        ? _organizationId
        : 'All';
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Report filters',
            style: TextStyle(
              color: _ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 10,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 230,
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Search records',
                    prefixIcon: Icon(Icons.search_rounded),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              _dropdown(
                'Organization',
                selectedId,
                ['All', ...orgList.map((o) => o.id)],
                (v) => setState(() => _organizationId = v ?? 'All'),
                width: 210,
              ),
              _dropdown(
                'Event status',
                _eventStatus,
                const ['All', 'Upcoming', 'Ongoing', 'Completed', 'Cancelled'],
                (v) => setState(() => _eventStatus = v ?? 'All'),
                width: 165,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.date_range_rounded),
                label: Text(
                  _dates == null
                      ? 'All dates'
                      : '${_date(_dates!.start)} – ${_date(_dates!.end)}',
                ),
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    initialDateRange: _dates,
                  );
                  if (picked != null && mounted)
                    setState(() => _dates = picked);
                },
              ),
              TextButton.icon(
                onPressed: () => setState(() {
                  _search.clear();
                  _organizationId = 'All';
                  _eventStatus = 'All';
                  _dates = null;
                }),
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Date and event-status filters apply to event figures. '
            'Organization totals are registry records, not Active/Inactive statuses.',
            style: TextStyle(color: _muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _bar(String label, int value, int maxValue) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Tooltip(
      message: '$label: $value',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$value',
                style: const TextStyle(
                  color: _forest,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: LinearProgressIndicator(
              value: maxValue == 0 ? 0 : value / maxValue,
              minHeight: 12,
              backgroundColor: _mint,
              color: _green,
            ),
          ),
        ],
      ),
    ),
  );

  String _pdfText(Object? raw) =>
      (raw ?? '').toString().replaceAll(RegExp(r'[^\x20-\x7E\n\r\t]'), '?');

  Future<void> _exportPdf() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final events = _matchingEvents;
      final orgs = _matchingOrganizations;
      final isOrg = _report == _reportOptions[0];
      final attendance = events.fold<int>(
        0,
        (sum, e) => sum + e.attendanceCount,
      );
      final registrations = events.fold<int>(
        0,
        (sum, e) => sum + e.registrationCount,
      );
      final pdf = pw.Document(
        title: 'KAISA Operations ${_pdfText(_report)}',
        author: 'KAISA Operations Administrator',
      );
      final forest = PdfColor.fromHex('#00492C');
      final gold = PdfColor.fromHex('#FBBA16');
      final header = isOrg
          ? [
              'Organization',
              'Category',
              'Representative',
              'Events',
              'Recorded attendance',
            ]
          : ['Event', 'Host', 'Date', 'Status', 'Registrations', 'Attendance'];
      final data = isOrg
          ? [
              for (final org in orgs)
                [
                  _pdfText(org.name),
                  _pdfText(org.category),
                  _pdfText(
                    org.adminEmail.isEmpty ? 'Unassigned' : org.adminEmail,
                  ),
                  '${events.where((e) => e.organizationId == org.id).length}',
                  '${events.where((e) => e.organizationId == org.id).fold<int>(0, (n, e) => n + e.attendanceCount)}',
                ],
            ]
          : [
              for (final e in events)
                [
                  _pdfText(e.title),
                  _pdfText(_orgName(e.organizationId)),
                  _date(e.startsAt),
                  _pdfText(e.status.label),
                  '${e.registrationCount}',
                  '${e.attendanceCount}',
                ],
            ];
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(28),
          maxPages: 250,
          header: (_) => pw.Container(
            padding: const pw.EdgeInsets.all(12),
            color: forest,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'KAISA  /  LGU OPERATIONS  /  PROTOTYPE REPORT',
                  style: pw.TextStyle(
                    color: gold,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  _pdfText(_report),
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 17,
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
                'PROTOTYPE DATA - not an official LGU report',
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
              'Generated: ${DateTime.now().toIso8601String()}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              'Organization: ${_pdfText(_organizationId == 'All' ? 'All' : _orgName(_organizationId))}  |  '
              'Date range: ${_dates == null ? 'All' : '${_date(_dates!.start)} to ${_date(_dates!.end)}'}  |  '
              'Event status: $_eventStatus',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Organization records: ${orgs.length}     Filtered events: ${events.length}     '
              'Registrations: $registrations     Recorded attendance: $attendance',
              style: pw.TextStyle(
                color: forest,
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
            ),
            pw.SizedBox(height: 12),
            if (data.isEmpty)
              pw.Text('No records match the selected filters.')
            else
              pw.TableHelper.fromTextArray(
                headers: header,
                data: data,
                headerStyle: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                ),
                headerDecoration: pw.BoxDecoration(color: forest),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellPadding: const pw.EdgeInsets.all(6),
                oddRowDecoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F0F7F2'),
                ),
              ),
            pw.SizedBox(height: 28),
            pw.Text(
              'Prepared by: __________________________    Operations Administrator',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
      );
      final date = DateTime.now();
      final stamp =
          '${date.year}${date.month.toString().padLeft(2, '0')}'
          '${date.day.toString().padLeft(2, '0')}_${date.hour.toString().padLeft(2, '0')}'
          '${date.minute.toString().padLeft(2, '0')}';
      await FileSaver.instance.saveFile(
        name: 'KAISA_Operations_${isOrg ? 'Organizations' : 'Events'}_$stamp',
        bytes: await pdf.save(),
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF report generated. Check your downloads.'),
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not export PDF: $e')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgs = _matchingOrganizations;
    final events = _matchingEvents;
    final registrations = events.fold<int>(
      0,
      (n, e) => n + e.registrationCount,
    );
    final attendance = events.fold<int>(0, (n, e) => n + e.attendanceCount);
    final categoryCounts = <String, int>{};
    for (final org in orgs) {
      categoryCounts.update(org.category, (v) => v + 1, ifAbsent: () => 1);
    }
    final eventStatusCounts = <String, int>{};
    for (final e in events) {
      eventStatusCounts.update(e.status.label, (v) => v + 1, ifAbsent: () => 1);
    }
    final compact = MediaQuery.sizeOf(context).width < 680;
    return ColoredBox(
      color: _paper,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          compact ? 14 : 26,
          24,
          compact ? 14 : 26,
          45,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1250),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(27),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0B3024), _forest, _green],
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KAISA  /  OPERATIONS ADMINISTRATION',
                          style: TextStyle(
                            color: _gold,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Operations Reports',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 30,
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          'Organization activity and event participation in one reporting workspace.',
                          style: TextStyle(color: Color(0xFFE2F0E6)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 13),
                  _card(
                    const Text(
                      'PROTOTYPE DATA — figures come from local repositories. '
                      'PDF exports are not official LGU documents or verified attendance records.',
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _filters(),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (_, c) {
                      final columns = c.maxWidth >= 950
                          ? 4
                          : c.maxWidth >= 510
                          ? 2
                          : 1;
                      const gap = 12.0;
                      final width =
                          (c.maxWidth - gap * (columns - 1)) / columns;
                      final widgets = [
                        _stat(
                          'Organization records',
                          '${orgs.length}',
                          Icons.apartment_outlined,
                        ),
                        _stat(
                          'Events',
                          '${events.length}',
                          Icons.event_outlined,
                        ),
                        _stat(
                          'Registrations',
                          '$registrations',
                          Icons.groups_outlined,
                        ),
                        _stat(
                          'Recorded attendance',
                          '$attendance',
                          Icons.fact_check_outlined,
                        ),
                      ];
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (final child in widgets)
                            SizedBox(width: width, child: child),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  _card(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PDF report generator',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Choose a report. PDF includes only fields available in KAISA repositories.',
                          style: TextStyle(color: _muted, fontSize: 12),
                        ),
                        const SizedBox(height: 13),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _dropdown(
                              'Report template',
                              _report,
                              _reportOptions,
                              (v) => setState(
                                () => _report = v ?? _reportOptions[0],
                              ),
                              width: 290,
                            ),
                            FilledButton.icon(
                              onPressed: _exporting ? null : _exportPdf,
                              style: FilledButton.styleFrom(
                                backgroundColor: _forest,
                              ),
                              icon: const Icon(Icons.picture_as_pdf_rounded),
                              label: Text(
                                _exporting ? 'Generating...' : 'Export PDF',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (_, c) {
                      final wide = c.maxWidth >= 850;
                      final width = wide ? (c.maxWidth - 12) / 2 : c.maxWidth;
                      final categories = categoryCounts.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value));
                      final statuses = eventStatusCounts.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value));
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: width,
                            child: _card(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Organizations by category',
                                    style: TextStyle(
                                      color: _ink,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 13),
                                  if (categories.isEmpty)
                                    const Text('No organization data.')
                                  else
                                    for (final e in categories.take(6))
                                      _bar(e.key, e.value, orgs.length),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: _card(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Events by status',
                                    style: TextStyle(
                                      color: _ink,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 13),
                                  if (statuses.isEmpty)
                                    const Text('No matching event data.')
                                  else
                                    for (final e in statuses)
                                      _bar(e.key, e.value, events.length),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  _card(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Matching event records',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (events.isEmpty)
                          const Text(
                            'No events match the filters.',
                            style: TextStyle(color: _muted),
                          )
                        else
                          for (final e in events.take(20)) ...[
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.event_available_outlined,
                                color: _forest,
                              ),
                              title: Text(
                                e.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${_orgName(e.organizationId)} · ${_date(e.startsAt)} · ${e.status.label}',
                              ),
                              trailing: Text(
                                '${e.attendanceCount} attended',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _forest,
                                ),
                              ),
                            ),
                            const Divider(color: _border, height: 1),
                          ],
                        if (events.length > 20)
                          Text(
                            'Showing 20 of ${events.length} events. Export PDF for the full filtered set.',
                            style: const TextStyle(fontSize: 11, color: _muted),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
