import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/repositories/verification_case_repository.dart';

// KAISA · Verification Superadmin · Reporting prototype.
// All figures are derived from the shared in-memory DEMO repository.
// This widget never fetches personal documents or changes account tiers.
const _forest = Color(0xFF00492C);
const _green = Color(0xFF237A50);
const _gold = Color(0xFFFBBA16);
const _ink = Color(0xFF173D2B);
const _muted = Color(0xFF687B70);
const _paper = Color(0xFFF7F9F6);
const _stroke = Color(0xFFE2EBE4);
const _mint = Color(0xFFEAF5EE);
const _amber = Color(0xFFAC7614);
const _red = Color(0xFFB74A43);
const _blue = Color(0xFF477DB0);

class VerificationReportsPage extends StatefulWidget {
  const VerificationReportsPage({super.key});

  @override
  State<VerificationReportsPage> createState() =>
      _VerificationReportsPageState();
}

class _VerificationReportsPageState extends State<VerificationReportsPage> {
  final _repository = VerificationCaseRepository.instance;
  String _month = 'All periods';
  String _type = 'All types';
  String _platform = 'All platforms';
  String _archive = 'All records';
  String _exportKind = 'Applications';
  bool _downloading = false;

  static const _statusOrder = <String>[
    'Pending',
    'Under Review',
    'Resubmission',
    'Approved',
    'Rejected',
  ];
  static const _statusColors = <Color>[_gold, _blue, _amber, _green, _red];

  @override
  void initState() {
    super.initState();
    _repository.addListener(_refresh);
  }

  @override
  void dispose() {
    _repository.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  String _period(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  String _date(DateTime? d) => d == null
      ? ''
      : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  List<String> get _months {
    final values =
        _repository.applications
            .map((a) => _period(a.submitted))
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));
    return ['All periods', ...values];
  }

  List<VerificationApplication> get _filtered {
    return _repository.applications.where((a) {
      return (_month == 'All periods' || _period(a.submitted) == _month) &&
          (_type == 'All types' || a.type == _type) &&
          (_platform == 'All platforms' || a.platform == _platform) &&
          (_archive == 'All records' ||
              (_archive == 'Archived only' ? a.archived : !a.archived));
    }).toList()..sort((a, b) => b.submitted.compareTo(a.submitted));
  }

  int _count(List<VerificationApplication> cases, String status) =>
      cases.where((a) => a.status == status).length;

  int _percent(int count, int total) =>
      total == 0 ? 0 : (100 * count / total).round();

  String _csvCell(String value) {
    final clean = value.replaceAll('\r', ' ').replaceAll('\n', ' ').trim();
    final escaped = RegExp(r'^[=+@\-]').hasMatch(clean) ? "'$clean" : clean;
    return '"${escaped.replaceAll('"', '""')}"';
  }

  String _csv(List<List<String>> rows) =>
      '\uFEFF${rows.map((row) => row.map(_csvCell).join(',')).join('\r\n')}\r\n';

  List<List<String>> _applicationRows(List<VerificationApplication> cases) => [
    [
      'Application ID',
      'Applicant (DEMO)',
      'Request Type',
      'Platform',
      'Submitted At',
      'Status',
      'Priority',
      'Archived',
      'Archived At',
      'Archive Reason',
      'Purpose',
    ],
    for (final a in cases)
      [
        a.id,
        a.name,
        a.type,
        a.platform,
        _date(a.submitted),
        a.status,
        a.priority,
        a.archived ? 'Yes' : 'No',
        _date(a.archivedAt),
        a.archiveReason ?? '',
        a.purpose,
      ],
  ];

  List<List<String>> _summaryRows(List<VerificationApplication> cases) {
    final approved = _count(cases, 'Approved');
    final rejected = _count(cases, 'Rejected');
    final finalDecisions = approved + rejected;
    final rows = <List<String>>[
      ['Metric', 'Value'],
      ['Data classification', 'FICTIONAL DEMONSTRATION DATA'],
      ['Report period', _month],
      ['Request type filter', _type],
      ['Platform filter', _platform],
      ['Archive filter', _archive],
      ['Applications', '${cases.length}'],
      [
        'Resident Tier 2',
        '${cases.where((a) => a.type == 'Resident Tier 2').length}',
      ],
      [
        'Organization Accreditation',
        '${cases.where((a) => a.type != 'Resident Tier 2').length}',
      ],
      ..._statusOrder.map((s) => [s, '${_count(cases, s)}']),
      ['Finalized Decisions', '$finalDecisions'],
      [
        'Approval Rate (finalized only)',
        finalDecisions == 0
            ? 'N/A'
            : '${(100 * approved / finalDecisions).toStringAsFixed(1)}%',
      ],
      ['Archived Applications', '${cases.where((a) => a.archived).length}'],
    ];
    for (final platform in ['Web', 'Mobile']) {
      rows.add([
        'Platform: $platform',
        '${cases.where((a) => a.platform == platform).length}',
      ]);
    }
    return rows;
  }

  List<List<String>> _historyRows(List<VerificationApplication> cases) {
    final ids = cases.map((a) => a.id).toSet();
    return [
      ['Application ID', 'Action', 'Recorded At', 'Reason (DEMO)'],
      for (final event in _repository.events)
        if (ids.contains(event.caseId))
          [event.caseId, event.action, _date(event.at), event.reason],
    ];
  }

  Future<void> _export() async {
    if (_downloading) return;
    final cases = _filtered;
    final rows = switch (_exportKind) {
      'Summary' => _summaryRows(cases),
      'Review Activity' => _historyRows(cases),
      'Approved Tier 2' => _applicationRows(
        cases
            .where((a) => a.type == 'Resident Tier 2' && a.status == 'Approved')
            .toList(),
      ),
      _ => _applicationRows(cases),
    };
    final base = _exportKind.toLowerCase().replaceAll(' ', '_');
    setState(() => _downloading = true);
    try {
      await FileSaver.instance.saveFile(
        name: 'kaisa_verification_${base}_demo',
        bytes: Uint8List.fromList(utf8.encode(_csv(rows))),
        fileExtension: 'csv',
        mimeType: MimeType.csv,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$_exportKind CSV exported (demo records).')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV export failed: $e')));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _copySummary() async {
    await Clipboard.setData(ClipboardData(text: _csv(_summaryRows(_filtered))));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Filtered report summary copied as CSV.')),
      );
    }
  }

  BoxDecoration _surface() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(19),
    border: Border.all(color: _stroke),
    boxShadow: const [
      BoxShadow(color: Color(0x0700492C), blurRadius: 20, offset: Offset(0, 6)),
    ],
  );

  Widget _card(Widget child) => Container(
    width: double.infinity,
    decoration: _surface(),
    padding: const EdgeInsets.all(19),
    child: child,
  );

  Widget _heading(String title, String caption) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: _ink,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 4),
      Text(caption, style: const TextStyle(color: _muted, fontSize: 12)),
    ],
  );

  Widget _metric(String name, String value, String detail, IconData icon) =>
      Tooltip(
        message: detail,
        child: _card(
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _mint,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: _forest),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: _forest,
                      ),
                    ),
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _ink,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: _muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _responsiveCards(List<Widget> cards) => LayoutBuilder(
    builder: (_, c) {
      final n = c.maxWidth >= 970 ? 4 : (c.maxWidth >= 520 ? 2 : 1);
      const gap = 12.0;
      final width = (c.maxWidth - (n - 1) * gap) / n;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final card in cards) SizedBox(width: width, child: card),
        ],
      );
    },
  );

  Widget _dropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> change, {
    double width = 175,
  }) => SizedBox(
    width: width,
    child: DropdownButtonFormField<String>(
      key: ValueKey('$label:$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: [
        for (final option in options)
          DropdownMenuItem(
            value: option,
            child: Text(option, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: change,
    ),
  );

  Widget _filters() => _card(
    Wrap(
      spacing: 10,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _dropdown(
          'Reporting month',
          _month,
          _months,
          (v) => setState(() => _month = v ?? 'All periods'),
          width: 175,
        ),
        _dropdown(
          'Request type',
          _type,
          ['All types', 'Resident Tier 2', 'Org Accreditation'],
          (v) => setState(() => _type = v ?? 'All types'),
          width: 195,
        ),
        _dropdown(
          'Platform',
          _platform,
          ['All platforms', 'Web', 'Mobile'],
          (v) => setState(() => _platform = v ?? 'All platforms'),
        ),
        _dropdown('Archive', _archive, [
          'All records',
          'Active only',
          'Archived only',
        ], (v) => setState(() => _archive = v ?? 'All records')),
        TextButton.icon(
          onPressed: () => setState(() {
            _month = 'All periods';
            _type = 'All types';
            _platform = 'All platforms';
            _archive = 'All records';
          }),
          icon: const Icon(Icons.restart_alt_rounded),
          label: const Text('Reset'),
        ),
      ],
    ),
  );

  Widget _statusChart(List<VerificationApplication> cases) => _card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          'Application outcomes',
          'Hover or tap a bar to inspect counts and percentages',
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < _statusOrder.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 17),
            child: Tooltip(
              message:
                  '${_statusOrder[i]}: ${_count(cases, _statusOrder[i])} of ${cases.length} '
                  '(${_percent(_count(cases, _statusOrder[i]), cases.length)}%)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _statusOrder[i],
                          style: const TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        '${_count(cases, _statusOrder[i])}  ·  ${_percent(_count(cases, _statusOrder[i]), cases.length)}%',
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: LinearProgressIndicator(
                      value: cases.isEmpty
                          ? 0
                          : _count(cases, _statusOrder[i]) / cases.length,
                      minHeight: 13,
                      backgroundColor: _mint,
                      color: _statusColors[i],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );

  Widget _donut(List<VerificationApplication> cases) {
    final resident = cases.where((a) => a.type == 'Resident Tier 2').length;
    final org = cases.length - resident;
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(
            'Application composition',
            'Resident Tier 2 vs organization accreditation',
          ),
          const SizedBox(height: 20),
          Center(
            child: Tooltip(
              message:
                  '$resident resident applications; $org organization applications',
              child: SizedBox(
                width: 185,
                height: 185,
                child: CustomPaint(
                  painter: _DonutPainter(
                    values: [resident.toDouble(), org.toDouble()],
                    colors: [_green, _gold],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${cases.length}',
                          style: const TextStyle(
                            fontSize: 27,
                            color: _forest,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'applications',
                          style: TextStyle(fontSize: 11, color: _muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          _legend(
            _green,
            'Resident Tier 2',
            '$resident · ${_percent(resident, cases.length)}%',
          ),
          const SizedBox(height: 7),
          _legend(
            _gold,
            'Organization Accreditation',
            '$org · ${_percent(org, cases.length)}%',
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String title, String result) => Row(
    children: [
      Container(
        width: 11,
        height: 11,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(title, style: const TextStyle(fontSize: 12, color: _ink)),
      ),
      Text(
        result,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _ink,
        ),
      ),
    ],
  );

  Widget _platformChart(List<VerificationApplication> cases) {
    final web = cases.where((a) => a.platform == 'Web').length;
    final mobile = cases.where((a) => a.platform == 'Mobile').length;
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(
            'Submission platform',
            'Works across locations; no barangay-based reporting',
          ),
          const SizedBox(height: 22),
          for (final pair in [('Web', web, _blue), ('Mobile', mobile, _green)])
            Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Tooltip(
                message:
                    '${pair.$1}: ${pair.$2} applications (${_percent(pair.$2, cases.length)}%)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          pair.$1 == 'Web' ? Icons.language : Icons.smartphone,
                          color: pair.$3,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            pair.$1,
                            style: const TextStyle(
                              color: _ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${pair.$2} (${_percent(pair.$2, cases.length)}%)',
                          style: const TextStyle(color: _muted, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: cases.isEmpty ? 0 : pair.$2 / cases.length,
                        minHeight: 16,
                        color: pair.$3,
                        backgroundColor: _mint,
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

  Widget _monthlyChart(List<VerificationApplication> cases) {
    final months = cases.map((a) => _period(a.submitted)).toSet().toList()
      ..sort();
    final highest = math.max(
      1,
      months.fold<int>(
        0,
        (n, m) =>
            math.max(n, cases.where((a) => _period(a.submitted) == m).length),
      ),
    );
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(
            'Monthly submission trend',
            'Based on application submission date',
          ),
          const SizedBox(height: 22),
          if (months.isEmpty)
            const Text(
              'No applications for the selected filters.',
              style: TextStyle(color: _muted),
            )
          else
            SizedBox(
              height: 176,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final month in months)
                    Expanded(
                      child: Tooltip(
                        message:
                            '$month: ${cases.where((a) => _period(a.submitted) == month).length} submissions',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${cases.where((a) => _period(a.submitted) == month).length}',
                                style: const TextStyle(
                                  color: _forest,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Flexible(
                                child: FractionallySizedBox(
                                  heightFactor:
                                      cases
                                          .where(
                                            (a) =>
                                                _period(a.submitted) == month,
                                          )
                                          .length /
                                      highest,
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _green,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                month.substring(5),
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                month.substring(0, 4),
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Fixed content widths keep DataTable's intrinsic layout from squeezing
  // longer values into narrow columns. The surrounding scroll view handles
  // smaller desktops and mobile displays without RenderFlex overflows.
  Widget _registerText(
    String text,
    double width, {
    bool strong = false,
    Color color = _ink,
    int maxLines = 1,
  }) => SizedBox(
    width: width,
    child: Tooltip(
      message: text,
      child: Text(
        text,
        maxLines: maxLines,
        softWrap: maxLines > 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12,
        ),
      ),
    ),
  );

  Widget _table(List<VerificationApplication> cases) => _card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          'Filtered application register',
          '${cases.length} matching demonstration records',
        ),
        const SizedBox(height: 8),
        const Text(
          'Scroll horizontally to inspect the full register on smaller screens.',
          style: TextStyle(fontSize: 11, color: _muted),
        ),
        const SizedBox(height: 15),
        if (cases.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text(
                'No applications match the selected filters.',
                style: TextStyle(color: _muted),
              ),
            ),
          )
        else
          Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: const WidgetStatePropertyAll(_mint),
                columnSpacing: 18,
                horizontalMargin: 14,
                dataRowMinHeight: 62,
                dataRowMaxHeight: 68,
                columns: [
                  DataColumn(
                    label: _registerText('APPLICATION', 210, strong: true),
                  ),
                  DataColumn(
                    label: _registerText('REQUEST', 160, strong: true),
                  ),
                  DataColumn(
                    label: _registerText('PLATFORM', 100, strong: true),
                  ),
                  DataColumn(
                    label: _registerText('SUBMITTED', 116, strong: true),
                  ),
                  DataColumn(label: _registerText('STATUS', 130, strong: true)),
                  DataColumn(
                    label: _registerText('ARCHIVED', 85, strong: true),
                  ),
                ],
                rows: [
                  for (final a in cases)
                    DataRow(
                      cells: [
                        DataCell(
                          Tooltip(
                            message: '${a.name}\n${a.id}',
                            child: SizedBox(
                              width: 210,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _ink,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    a.id,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: _muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        DataCell(_registerText(a.type, 160, maxLines: 2)),
                        DataCell(_registerText(a.platform, 100)),
                        DataCell(
                          _registerText(
                            _date(a.submitted).substring(0, 10),
                            116,
                          ),
                        ),
                        DataCell(_registerText(a.status, 130)),
                        DataCell(_registerText(a.archived ? 'Yes' : 'No', 85)),
                      ],
                    ),
                ],
              ),
            ),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _paper,
    child: LayoutBuilder(
      builder: (context, layout) {
        final compact = layout.maxWidth < 670;
        final cases = _filtered;
        final approved = _count(cases, 'Approved');
        final rejected = _count(cases, 'Rejected');
        final finalized = approved + rejected;
        final rate = finalized == 0 ? 0 : 100 * approved / finalized;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            compact ? 14 : 26,
            24,
            compact ? 14 : 26,
            45,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1260),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(compact ? 20 : 30),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF0A3225),
                            _forest,
                            Color(0xFF247B51),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(23),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 18,
                        runSpacing: 14,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 700),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'KAISA  /  LGU VERIFICATION  /  ANALYTICS',
                                  style: TextStyle(
                                    color: _gold,
                                    fontSize: 11,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Verification Reports',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: compact ? 25 : 32,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Monitor resident Tier 2 and organization-accreditation requests, decisions, and workload.',
                                  style: TextStyle(
                                    color: Color(0xFFE6F2E9),
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.query_stats_rounded,
                            size: 40,
                            color: _gold,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5DA),
                        border: Border.all(color: const Color(0xFFEFE0B7)),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: _amber),
                          SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              'DEVELOPMENT PREVIEW — Live values update with the shared in-memory demo repository. '
                              'No real Supabase profiles, identity documents, or biometric data are accessed.',
                              style: TextStyle(color: _ink, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _filters(),
                    const SizedBox(height: 20),
                    _responsiveCards([
                      _metric(
                        'Total applications',
                        '${cases.length}',
                        'All filtered resident and organization requests',
                        Icons.folder_open_outlined,
                      ),
                      _metric(
                        'Needs action',
                        '${cases.where((a) => a.needsAction).length}',
                        'Pending, under review, and resubmission',
                        Icons.pending_actions_rounded,
                      ),
                      _metric(
                        'Approved',
                        '$approved',
                        'Approved applications, including archived',
                        Icons.verified_outlined,
                      ),
                      _metric(
                        'Approval rate',
                        '${rate.toStringAsFixed(1)}%',
                        'Approved / (approved + rejected); unfinished excluded',
                        Icons.trending_up_rounded,
                      ),
                    ]),
                    const SizedBox(height: 19),
                    LayoutBuilder(
                      builder: (_, c) {
                        final wide = c.maxWidth >= 850;
                        return Wrap(
                          spacing: 15,
                          runSpacing: 15,
                          children: [
                            SizedBox(
                              width: wide ? (c.maxWidth - 15) / 2 : c.maxWidth,
                              child: _statusChart(cases),
                            ),
                            SizedBox(
                              width: wide ? (c.maxWidth - 15) / 2 : c.maxWidth,
                              child: _donut(cases),
                            ),
                            SizedBox(
                              width: wide ? (c.maxWidth - 15) / 2 : c.maxWidth,
                              child: _monthlyChart(cases),
                            ),
                            SizedBox(
                              width: wide ? (c.maxWidth - 15) / 2 : c.maxWidth,
                              child: _platformChart(cases),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 19),
                    _card(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _heading(
                            'Export verification reports',
                            'Download filtered CSV data; no sensitive ID or selfie contents',
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _dropdown(
                                'Report format',
                                _exportKind,
                                [
                                  'Applications',
                                  'Summary',
                                  'Review Activity',
                                  'Approved Tier 2',
                                ],
                                (v) => setState(
                                  () => _exportKind = v ?? 'Applications',
                                ),
                                width: 210,
                              ),
                              FilledButton.icon(
                                onPressed: _downloading ? null : _export,
                                style: FilledButton.styleFrom(
                                  backgroundColor: _forest,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 22,
                                    vertical: 17,
                                  ),
                                ),
                                icon: _downloading
                                    ? const SizedBox(
                                        width: 17,
                                        height: 17,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.download_rounded),
                                label: Text(
                                  _downloading ? 'Exporting...' : 'Export CSV',
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: _copySummary,
                                icon: const Icon(Icons.copy_all_outlined),
                                label: const Text('Copy summary'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Approval is a demonstration status only; this report does not certify any real Tier 2 resident.',
                            style: TextStyle(fontSize: 11, color: _muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 19),
                    _table(cases),
                    const SizedBox(height: 12),
                    const Text(
                      'Report records reset on full application restart. Production reporting requires secure Supabase queries and role-based export authorization.',
                      style: TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.values, required this.colors});
  final List<double> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 12;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 17
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final total = values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) {
      paint.color = _mint;
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, paint);
      return;
    }
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      if (values[i] == 0) continue;
      final sweep = values[i] / total * 2 * math.pi;
      paint.color = colors[i];
      canvas.drawArc(
        rect,
        start + .015,
        math.max(0, sweep - .03),
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.values.toString() != values.toString() ||
      oldDelegate.colors.toString() != colors.toString();
}
