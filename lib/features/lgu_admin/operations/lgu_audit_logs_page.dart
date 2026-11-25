import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_saver/file_saver.dart';

import '../../../shared/models/audit_log_model.dart';
import '../../../shared/repositories/audit_log_repository.dart';

// KAISA Operations visual system — consistent with Dashboard and Registry.
const _forest = Color(0xFF00492C);
const _green = Color(0xFF287D55);
const _gold = Color(0xFFFBBA16);
const _paper = Color(0xFFF6F8F5);
const _ink = Color(0xFF173D2B);
const _muted = Color(0xFF687B70);
const _stroke = Color(0xFFE2EBE4);
const _soft = Color(0xFFEAF5EE);

class LguAuditLogsPage extends StatefulWidget {
  const LguAuditLogsPage({super.key});

  @override
  State<LguAuditLogsPage> createState() => _LguAuditLogsPageState();
}

class _LguAuditLogsPageState extends State<LguAuditLogsPage> {
  final AuditLogRepository repository = AuditLogRepository.instance;
  final TextEditingController _search = TextEditingController();
  String _action = 'All';
  String _module = 'All';
  String _role = 'All';
  String _datePreset = 'All time';
  bool _newestFirst = true;
  int _visibleCount = 15;

  @override
  void initState() {
    super.initState();
    repository.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    repository.removeListener(_refresh);
    _search.dispose();
    super.dispose();
  }

  List<String> _options(Iterable<String> values) {
    final distinct =
        values.map((v) => v.trim()).where((v) => v.isNotEmpty).toSet().toList()
          ..sort();
    return ['All', ...distinct];
  }

  DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  // Prototype-only visibility filter. Production authorization MUST be enforced
  // by Supabase RLS / a trusted backend, not by this client-side condition.
  // Explicit operational modules are included rather than exposing all LGU logs.
  bool _isOperationsLog(AuditLog log) {
    final module = log.module.toLowerCase().trim();
    const keywords = [
      'organization',
      'registry',
      'assignment',
      'representative',
      'event',
      'attendance',
      'filing',
      'report',
      'announcement',
      'community feed',
      'moderation',
      'content',
      'certificate',
    ];
    if (!keywords.any(module.contains)) return false;
    // Authentication activity is maintained in the IT security workspace.
    if (log.action == AuditActionType.login) return false;
    return true;
  }

  List<AuditLog> get _operationsLogs =>
      repository.logs.where(_isOperationsLog).toList();

  List<AuditLog> get _filtered {
    final now = DateTime.now();
    final today = _startOfDay(now);
    final query = _search.text.trim().toLowerCase();
    final result = _operationsLogs.where((log) {
      if (_action != 'All' && log.action.label != _action) return false;
      if (_module != 'All' && log.module != _module) return false;
      if (_role != 'All' && log.actorRole != _role) return false;
      final day = _startOfDay(log.timestamp.toLocal());
      if (_datePreset == 'Today' && day != today) return false;
      if (_datePreset == 'Last 7 days' &&
          (day.isBefore(today.subtract(const Duration(days: 6))) ||
              day.isAfter(today))) {
        return false;
      }
      if (_datePreset == 'Last 30 days' &&
          (day.isBefore(today.subtract(const Duration(days: 29))) ||
              day.isAfter(today))) {
        return false;
      }
      if (query.isEmpty) return true;
      return [
        log.id,
        log.actorName,
        log.actorRole,
        log.action.label,
        log.module,
        log.targetId,
        log.description,
      ].any((field) => field.toLowerCase().contains(query));
    }).toList();
    result.sort(
      (a, b) => _newestFirst
          ? b.timestamp.compareTo(a.timestamp)
          : a.timestamp.compareTo(b.timestamp),
    );
    return result;
  }

  String _dateTime(DateTime date) {
    final local = date.toLocal();
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
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    return '${months[local.month - 1]} ${local.day}, ${local.year}  •  '
        '$hour:${local.minute.toString().padLeft(2, '0')} ${local.hour < 12 ? 'AM' : 'PM'}';
  }

  IconData _icon(AuditActionType action) {
    switch (action) {
      case AuditActionType.create:
        return Icons.add_circle_outline_rounded;
      case AuditActionType.update:
        return Icons.edit_note_rounded;
      case AuditActionType.assign:
        return Icons.person_add_alt_1_rounded;
      case AuditActionType.remove:
        return Icons.person_remove_outlined;
      case AuditActionType.statusChange:
        return Icons.sync_alt_rounded;
      case AuditActionType.login:
        return Icons.lock_outline_rounded;
      case AuditActionType.certificate:
        return Icons.workspace_premium_outlined;
    }
  }

  Color _color(AuditActionType action) {
    switch (action) {
      case AuditActionType.create:
      case AuditActionType.assign:
        return _green;
      case AuditActionType.update:
      case AuditActionType.statusChange:
        return const Color(0xFF2769A6);
      case AuditActionType.remove:
        return const Color(0xFFB7791F);
      case AuditActionType.login:
        return const Color(0xFF7956A6);
      case AuditActionType.certificate:
        return const Color(0xFF9C7400);
    }
  }

  BoxDecoration _surface({double radius = 18}) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: _stroke),
  );

  bool _exporting = false;

  // Write the current filtered register as a PDF (no CSV output).
  // The prototype repository contains no reliable outcome or actor UUID.
  Future<void> _exportPdf(List<AuditLog> records) async {
    if (_exporting || records.isEmpty) {
      if (records.isEmpty) _snack('No matching activities to export.');
      return;
    }
    setState(() => _exporting = true);
    try {
      final document = pw.Document();
      final forest = PdfColor.fromHex('#00492C');
      final mint = PdfColor.fromHex('#EAF5EE');
      // Core PDF fonts do not support every Unicode character.
      String safe(String input) =>
          input.replaceAll(RegExp(r'[^\x20-\x7e]'), '-');
      final rows = <List<String>>[
        [
          'Date & Time',
          'Actor',
          'Role',
          'Action',
          'Module',
          'Record ID',
          'Description',
        ],
        for (final log in records)
          [
            safe(_dateTime(log.timestamp)),
            safe(log.actorName),
            safe(log.actorRole),
            safe(log.action.label),
            safe(log.module),
            safe(log.targetId),
            safe(log.description),
          ],
      ];
      document.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          header: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(13),
                color: forest,
                child: pw.Text(
                  'KAISA  |  OPERATIONS ADMINISTRATOR',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Operations Audit Trail',
                style: pw.TextStyle(
                  color: forest,
                  fontSize: 17,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Generated: ${DateTime.now().toLocal().toIso8601String().substring(0, 16)}  |  Records: ${records.length}',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                'DEMONSTRATION REPORT - not independently verified system evidence',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.red700),
              ),
              pw.SizedBox(height: 10),
            ],
          ),
          footer: (context) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'KAISA | Operations audit (prototype)',
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],
          ),
          build: (_) => [
            pw.Table.fromTextArray(
              headers: rows.first,
              data: rows.skip(1).toList(),
              headerDecoration: pw.BoxDecoration(color: forest),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 8,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
              oddRowDecoration: pw.BoxDecoration(color: mint),
              cellPadding: const pw.EdgeInsets.all(6),
              border: pw.TableBorder.all(
                color: PdfColor.fromHex('#DEE8DF'),
                width: .5,
              ),
            ),
          ],
        ),
      );
      await FileSaver.instance.saveFile(
        name: 'kaisa_operations_audit_demo',
        bytes: Uint8List.fromList(await document.save()),
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
      if (mounted) {
        _snack('Exported ${records.length} filtered activities to PDF.');
      }
    } catch (error) {
      if (mounted) _snack('PDF export failed: $error');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _clear() => setState(() {
    _search.clear();
    _action = 'All';
    _module = 'All';
    _role = 'All';
    _datePreset = 'All time';
    _newestFirst = true;
    _visibleCount = 15;
  });

  void _details(AuditLog log) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.receipt_long_rounded, color: _forest),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Activity Details',
                style: TextStyle(color: _forest, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detail('Log ID', log.id),
                _detail('Date & time (local)', _dateTime(log.timestamp)),
                _detail('Recorded actor', log.actorName),
                _detail('Actor role', log.actorRole),
                _detail('Action', log.action.label),
                _detail('Module', log.module),
                _detail(
                  'Target record',
                  log.targetId.isEmpty ? 'Not specified' : log.targetId,
                ),
                _detail('Description', log.description),
                const SizedBox(height: 8),
                const Text(
                  'Prototype record only. This is not independently verified backend evidence.',
                  style: TextStyle(fontSize: 11, color: _muted),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: log.id));
              Navigator.pop(dialogContext);
              _snack('Log ID copied.');
            },
            child: const Text('Copy ID'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _forest),
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: const TextStyle(
            color: _ink,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final all = _operationsLogs;
    final filtered = _filtered;
    final moduleOptions = _options(all.map((log) => log.module));
    final roleOptions = _options(all.map((log) => log.actorRole));
    // A selected filter may disappear when repository records change.
    final moduleValue = moduleOptions.contains(_module) ? _module : 'All';
    final roleValue = roleOptions.contains(_role) ? _role : 'All';
    final today = _startOfDay(DateTime.now());
    final todayCount = all
        .where((log) => _startOfDay(log.timestamp.toLocal()) == today)
        .length;
    final actors = all
        .map((log) => log.actorName)
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .length;
    final modules = all
        .map((log) => log.module)
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .length;

    return LayoutBuilder(
      builder: (context, bounds) {
        final compact = bounds.maxWidth < 700;
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
                      const SizedBox(height: 24),
                      _summary([
                        ('Total activities', all.length, Icons.history_rounded),
                        ('Recorded today', todayCount, Icons.today_rounded),
                        (
                          'Operational actors',
                          actors,
                          Icons.people_outline_rounded,
                        ),
                        (
                          'Modules involved',
                          modules,
                          Icons.dashboard_customize_outlined,
                        ),
                      ]),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: _surface(radius: 14),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              color: _forest,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Operations scope: organization registry, assignments, events, attendance, filings, reports, announcements and content moderation. '
                                'Login security, MFA, policies, credentials, and infrastructure belong to IT Security Logs.',
                                style: TextStyle(
                                  color: _muted,
                                  height: 1.4,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _section(
                        'Operations audit trail',
                        'Registry, assignments, events, attendance, filings, announcements and moderation.',
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: _surface(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _search,
                              onChanged: (_) =>
                                  setState(() => _visibleCount = 15),
                              decoration: InputDecoration(
                                labelText: 'Search activities',
                                hintText:
                                    'Actor, action, module, record ID, or description',
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: _green,
                                ),
                                suffixIcon: _search.text.isEmpty
                                    ? null
                                    : IconButton(
                                        onPressed: () => setState(() {
                                          _search.clear();
                                          _visibleCount = 15;
                                        }),
                                        icon: const Icon(Icons.close_rounded),
                                        tooltip: 'Clear search',
                                      ),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 14),
                            LayoutBuilder(
                              builder: (context, width) {
                                final two = width.maxWidth >= 540;
                                final four = width.maxWidth >= 1080;
                                final cellWidth = four
                                    ? (width.maxWidth - 30) / 4
                                    : two
                                    ? (width.maxWidth - 10) / 2
                                    : width.maxWidth;
                                return Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    SizedBox(
                                      width: cellWidth,
                                      child: _select(
                                        'Action',
                                        _action,
                                        [
                                          'All',
                                          ...AuditActionType.values
                                              .where(
                                                (a) =>
                                                    a !=
                                                        AuditActionType.login &&
                                                    a !=
                                                        AuditActionType
                                                            .statusChange,
                                              )
                                              .map((a) => a.label),
                                        ],
                                        (value) => setState(() {
                                          _action = value;
                                          _visibleCount = 15;
                                        }),
                                      ),
                                    ),
                                    SizedBox(
                                      width: cellWidth,
                                      child: _select(
                                        'Module',
                                        moduleValue,
                                        moduleOptions,
                                        (value) => setState(() {
                                          _module = value;
                                          _visibleCount = 15;
                                        }),
                                      ),
                                    ),
                                    SizedBox(
                                      width: cellWidth,
                                      child: _select(
                                        'Actor role',
                                        roleValue,
                                        roleOptions,
                                        (value) => setState(() {
                                          _role = value;
                                          _visibleCount = 15;
                                        }),
                                      ),
                                    ),
                                    SizedBox(
                                      width: cellWidth,
                                      child: _select(
                                        'Date',
                                        _datePreset,
                                        const [
                                          'All time',
                                          'Today',
                                          'Last 7 days',
                                          'Last 30 days',
                                        ],
                                        (value) => setState(() {
                                          _datePreset = value;
                                          _visibleCount = 15;
                                        }),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => setState(
                                    () => _newestFirst = !_newestFirst,
                                  ),
                                  icon: const Icon(
                                    Icons.swap_vert_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    _newestFirst
                                        ? 'Newest first'
                                        : 'Oldest first',
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _clear,
                                  icon: const Icon(
                                    Icons.filter_alt_off_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Clear filters'),
                                ),
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _forest,
                                  ),
                                  onPressed: filtered.isEmpty || _exporting
                                      ? null
                                      : () => _exportPdf(filtered),
                                  icon: const Icon(
                                    Icons.picture_as_pdf_outlined,
                                    size: 18,
                                  ),
                                  label: Text(
                                    _exporting
                                        ? 'Exporting...'
                                        : 'Export filtered PDF',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 13),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          '${filtered.length} of ${all.length} operations activities  •  Prototype records',
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (filtered.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(44),
                          decoration: _surface(),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.manage_search_rounded,
                                color: _muted,
                                size: 36,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'No matching audit activities',
                                style: TextStyle(
                                  color: _ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Try a different search or clear filters.',
                                style: TextStyle(color: _muted),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        _activityTable(filtered.take(_visibleCount).toList()),
                        if (filtered.length > _visibleCount) ...[
                          const SizedBox(height: 12),
                          Center(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  setState(() => _visibleCount += 15),
                              icon: const Icon(Icons.expand_more_rounded),
                              label: Text(
                                'Load more (${filtered.length - _visibleCount} remaining)',
                              ),
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: _muted,
                            size: 17,
                          ),
                          const SizedBox(width: 9),
                          const Expanded(
                            child: Text(
                              'Prototype-only view: locally filters operational modules, but it does NOT provide secure access control. '
                              'Production must enforce row-level authorization, immutable server-side logging, and export auditing. '
                              'Verified actor IDs and independently confirmed outcomes are not recorded in the current model.',
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
      gradient: const LinearGradient(
        colors: [Color(0xFF0B3024), Color(0xFF15543A), Color(0xFF288258)],
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 14,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'KAISA  /  LGU OPERATIONS  /  AUDIT TRAIL',
                style: TextStyle(
                  color: _gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Operations Audit Trail',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 27 : 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Trace organization, event and community actions while keeping IT security investigations separate.',
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: Colors.white30),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_outlined, color: _gold, size: 18),
              SizedBox(width: 8),
              Text(
                'OPERATIONS ONLY  •  DEMO',
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

  Widget _section(String title, String subtitle) => Column(
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
      Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
    ],
  );

  Widget _summary(List<(String, int, IconData)> values) => LayoutBuilder(
    builder: (context, bounds) {
      final columns = bounds.maxWidth >= 970
          ? 4
          : bounds.maxWidth >= 520
          ? 2
          : 1;
      const gap = 12.0;
      final itemWidth = (bounds.maxWidth - (columns - 1) * gap) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final item in values)
            Container(
              width: itemWidth,
              padding: const EdgeInsets.all(18),
              decoration: _surface(),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: _soft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.$3, color: _forest, size: 22),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.$2}',
                          style: const TextStyle(
                            fontSize: 27,
                            color: _forest,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          item.$1,
                          style: const TextStyle(color: _muted, fontSize: 12),
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

  Widget _select(
    String title,
    String value,
    List<String> options,
    ValueChanged<String> changed,
  ) => DropdownButtonFormField<String>(
    key: ValueKey('$title:$value'),
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: title,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    ),
    items: [
      for (final option in options)
        DropdownMenuItem(
          value: option,
          child: Text(option, overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
    ],
    onChanged: (value) {
      if (value != null) changed(value);
    },
  );

  Widget _activityTable(List<AuditLog> records) => Container(
    decoration: _surface(),
    clipBehavior: Clip.antiAlias,
    child: LayoutBuilder(
      builder: (context, bounds) {
        return Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: bounds.maxWidth > 1280 ? bounds.maxWidth : 1280,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(_soft),
                dataRowMinHeight: 66,
                dataRowMaxHeight: 78,
                columnSpacing: 22,
                horizontalMargin: 18,
                dividerThickness: .5,
                showCheckboxColumn: false,
                columns: const [
                  DataColumn(label: Text('DATE & TIME')),
                  DataColumn(label: Text('ACTOR / ROLE')),
                  DataColumn(label: Text('ACTION')),
                  DataColumn(label: Text('MODULE')),
                  DataColumn(label: Text('DESCRIPTION')),
                  DataColumn(label: Text('RECORD ID')),
                  DataColumn(label: Text('DETAILS')),
                ],
                rows: [
                  for (final log in records)
                    DataRow(
                      onSelectChanged: (_) => _details(log),
                      color: WidgetStateProperty.resolveWith<Color?>((states) {
                        if (states.contains(WidgetState.hovered)) return _soft;
                        return null;
                      }),
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 147,
                            child: Text(
                              _dateTime(log.timestamp),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 148,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  log.actorName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _ink,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  log.actorRole,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(_actionTag(log.action)),
                        DataCell(
                          SizedBox(
                            width: 122,
                            child: Text(
                              log.module,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: _ink),
                            ),
                          ),
                        ),
                        DataCell(
                          Tooltip(
                            message: log.description,
                            child: SizedBox(
                              width: 252,
                              child: Text(
                                log.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _ink,
                                ),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 125,
                            child: SelectableText(
                              log.targetId.isEmpty ? '—' : log.targetId,
                              maxLines: 1,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          IconButton(
                            tooltip: 'View full activity details',
                            icon: const Icon(
                              Icons.open_in_new_rounded,
                              size: 19,
                            ),
                            color: _forest,
                            onPressed: () => _details(log),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget _actionTag(AuditActionType action) {
    final color = _color(action);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(action), color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            action.label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
