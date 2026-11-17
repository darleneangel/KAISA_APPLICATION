import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../shared/repositories/verification_case_repository.dart';

/// CSV/PDF reports based on KAISA's shared in-memory verification prototype.
/// These exports contain FICTIONAL test cases, not verified identities or AI results.
/// Never export raw IDs, selfies, signed URLs, or sensitive evidence in production.
class VerificationAnalyticsExport {
  static final VerificationCaseRepository _repository =
      VerificationCaseRepository.instance;

  static String _date(DateTime? value) => value == null
      ? 'Not recorded'
      : '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  static String _dateTime(DateTime value) => value.toIso8601String();

  /// Protect CSVs opened by spreadsheet software from formula injection.
  static String _csvCell(String value) {
    final sanitized = value.replaceAll('\r', ' ').replaceAll('\n', ' ');
    final guarded = RegExp(r'^\s*[=+@\-]').hasMatch(sanitized)
        ? "'$sanitized"
        : sanitized;
    return '"${guarded.replaceAll('"', '""')}"';
  }

  static String _csvRows(List<List<String>> rows) =>
      '\uFEFF${rows.map((r) => r.map(_csvCell).join(',')).join('\r\n')}\r\n';

  static List<List<String>> _applicationRows(
    List<VerificationApplication> items,
  ) => [
    [
      'Application ID',
      'Applicant (fictional)',
      'Request Type',
      'Submission Platform',
      'Submitted At',
      'Status',
      'Priority',
      'Purpose',
      'Archived',
      'Archived At',
      'Archive Reason',
    ],
    for (final c in items)
      [
        c.id,
        c.name,
        c.type,
        c.platform,
        _dateTime(c.submitted),
        c.status,
        c.priority,
        c.purpose,
        c.archived ? 'Yes' : 'No',
        _date(c.archivedAt),
        c.archiveReason ?? 'Not recorded',
      ],
  ];

  static List<List<String>> _summaryRows(List<VerificationApplication> items) {
    final finalized = items
        .where((c) => c.status == 'Approved' || c.status == 'Rejected')
        .toList();
    final approved = finalized.where((c) => c.status == 'Approved').length;
    final resident = items.where((c) => c.type == 'Resident Tier 2').length;
    final organization = items
        .where((c) => c.type == 'Org Accreditation')
        .length;
    final archived = items.where((c) => c.archived).length;
    final highPriority = items
        .where((c) => !c.archived && c.needsAction && c.priority == 'High')
        .length;
    final web = items.where((c) => c.platform == 'Web').length;
    final mobile = items.where((c) => c.platform == 'Mobile').length;
    return [
      ['Metric', 'Value'],
      [
        'Data Notice',
        'FICTIONAL DEMO DATA — NOT OFFICIAL VERIFICATION RECORDS',
      ],
      ['Total Applications', '${items.length}'],
      ['Resident Tier 2', '$resident'],
      ['Organization Accreditation', '$organization'],
      ['Pending', '${items.where((c) => c.status == 'Pending').length}'],
      [
        'Under Review',
        '${items.where((c) => c.status == 'Under Review').length}',
      ],
      [
        'Resubmission',
        '${items.where((c) => c.status == 'Resubmission').length}',
      ],
      ['Approved', '$approved'],
      ['Rejected', '${finalized.length - approved}'],
      [
        'Needs Action (active)',
        '${items.where((c) => !c.archived && c.needsAction).length}',
      ],
      ['High Priority (active)', '$highPriority'],
      ['Archived', '$archived'],
      [
        'Approval Rate (finalized only)',
        finalized.isEmpty
            ? 'N/A'
            : '${(approved * 100 / finalized.length).toStringAsFixed(1)}%',
      ],
      ['Web Submissions', '$web'],
      ['Mobile Submissions', '$mobile'],
      [
        'Average Review Turnaround',
        'Unavailable (current repository does not store per-case decision timestamps)',
      ],
      ['AI Screening Outcomes', 'Not connected; no model results available'],
    ];
  }

  static List<List<String>> _historyRows(
    List<VerificationCaseEvent> history,
  ) => [
    ['Application ID', 'Action', 'Recorded At (local demo time)', 'Reason'],
    for (final e in history) [e.caseId, e.action, _dateTime(e.at), e.reason],
  ];

  /// The current repository has no credential expiry or reminder fields.
  /// Preserve the export buttons while explicitly indicating that there are
  /// no available renewal records, rather than fabricating expiry dates.
  static List<List<String>> _renewalRows(
    List<VerificationApplication> items,
  ) => [
    ['Metric', 'Value'],
    ['Notice', 'DEMONSTRATION ONLY — renewal tracking is not connected'],
    ['Applications in provided scope', '${items.length}'],
    ['Credential expiry data', 'Not available in VerificationApplication'],
    ['Reminder delivery data', 'Not available in VerificationCaseRepository'],
  ];

  static Future<String?> _saveCsv(String name, List<List<String>> rows) =>
      FileSaver.instance.saveFile(
        name: name,
        bytes: Uint8List.fromList(utf8.encode(_csvRows(rows))),
        fileExtension: 'csv',
        mimeType: MimeType.csv,
      );

  static String _filePart(String value) {
    final cleaned = value.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9_-]+'),
      '_',
    );
    return cleaned.isEmpty ? 'all' : cleaned;
  }

  static Future<String?> exportRenewalsCsv(
    List<VerificationApplication> items,
  ) => _saveCsv('kaisa_verification_renewals_demo', _renewalRows(items));

  static Future<String?> exportRenewalsPdf(
    List<VerificationApplication> items,
  ) => _savePdf(
    _renewalRows(items),
    'Credential Renewal Watchlist',
    scope: 'No expiry information available in the current repository',
  );

  static Future<String?> exportCsv({
    required List<VerificationApplication> cases,
    required String scope,
    required bool summary,
  }) => _saveCsv(
    'kaisa_verification_${summary ? 'analytics' : 'applications'}_${_filePart(scope)}_demo',
    summary ? _summaryRows(cases) : _applicationRows(cases),
  );

  static Future<String?> exportPdf({
    required List<VerificationApplication> cases,
    required String scope,
    required bool summary,
  }) => _savePdf(
    summary ? _summaryRows(cases) : _applicationRows(cases),
    summary ? 'Verification Analytics' : 'Verification Application Register',
    scope: scope,
  );

  static Future<String?> exportHistoryCsv(
    List<VerificationCaseEvent> history,
  ) => _saveCsv(
    'kaisa_verification_decision_history_demo',
    _historyRows(history),
  );

  static Future<String?> exportHistoryPdf(
    List<VerificationCaseEvent> history,
  ) => _savePdf(
    _historyRows(history),
    'Verification Decision / Archive History',
    scope: 'Recorded prototype actions',
  );

  /// Helpers for pages that want the freshest shared demo records.
  static List<VerificationApplication> get currentApplications =>
      _repository.applications;
  static List<VerificationCaseEvent> get currentHistory => _repository.events;

  static String _pdfSafe(String text) =>
      text.replaceAll(RegExp(r'[^\x20-\x7E]'), '-');

  static Future<String?> _savePdf(
    List<List<String>> rows,
    String title, {
    required String scope,
  }) async {
    final document = pw.Document();
    final green = PdfColor.fromHex('#00492C');
    final mint = PdfColor.fromHex('#E8F4EC');
    final gold = PdfColor.fromHex('#FBBA16');
    final headings = rows.first;
    final entries = rows.skip(1).toList();
    // Keep each PDF table reasonably small and repeat the column headings.
    const rowsPerPage = 18;
    final pageCount = entries.isEmpty
        ? 1
        : (entries.length / rowsPerPage).ceil();
    for (var page = 0; page < pageCount; page++) {
      final pageRows = entries
          .skip(page * rowsPerPage)
          .take(rowsPerPage)
          .toList();
      document.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(26),
          header: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                color: green,
                padding: const pw.EdgeInsets.all(12),
                child: pw.Row(
                  children: [
                    pw.Text(
                      'KAISA  /  VERIFICATION',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    pw.Spacer(),
                    pw.Text(
                      'DEMONSTRATION ONLY',
                      style: pw.TextStyle(
                        color: gold,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                _pdfSafe(title),
                style: pw.TextStyle(
                  color: green,
                  fontSize: 17,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                _pdfSafe(
                  'Scope: $scope | Generated: ${DateTime.now().toIso8601String().substring(0, 16)}',
                ),
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'FICTIONAL DATA - NOT REAL ID DOCUMENTS, AI RESULTS, OR OFFICIAL DECISIONS',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.red700),
              ),
              pw.SizedBox(height: 10),
            ],
          ),
          footer: (ctx) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'KAISA Verification Administrator (demo) | Unofficial / unsigned',
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.Text(
                'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],
          ),
          build: (ctx) => [
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColor.fromHex('#D5E2D9'),
                width: .5,
              ),
              columnWidths: {
                for (var i = 0; i < headings.length; i++)
                  i: const pw.FlexColumnWidth(),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: green),
                  children: [
                    for (final heading in headings)
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          _pdfSafe(heading),
                          style: pw.TextStyle(
                            fontSize: headings.length > 7 ? 6 : 8,
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                for (var row = 0; row < pageRows.length; row++)
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: row.isEven ? mint : PdfColors.white,
                    ),
                    children: [
                      for (final cell in pageRows[row])
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            _pdfSafe(cell),
                            style: pw.TextStyle(
                              fontSize: headings.length > 7 ? 6 : 8,
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      );
    }
    return FileSaver.instance.saveFile(
      name: 'kaisa_verification_${_filePart(title)}_demo',
      bytes: Uint8List.fromList(await document.save()),
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }
}
