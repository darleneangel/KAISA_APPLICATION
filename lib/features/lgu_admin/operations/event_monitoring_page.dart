import 'package:flutter/material.dart';
import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../shared/models/community_event_model.dart';
import '../../../shared/models/organization_model.dart';
import '../../../shared/repositories/community_event_repository.dart';
import '../../../shared/repositories/organization_repository.dart';

// KAISA Operations visual system: consistent with Dashboard and Registry.
const _forest = Color(0xFF00492C);
const _green = Color(0xFF287D55);
const _paper = Color(0xFFF6F8F5);
const _ink = Color(0xFF173D2B);
const _muted = Color(0xFF687B70);
const _gold = Color(0xFFFBBA16);
const _stroke = Color(0xFFE2EBE4);
const _soft = Color(0xFFEAF5EE);

class EventMonitoringPage extends StatefulWidget {
  const EventMonitoringPage({super.key});

  @override
  State<EventMonitoringPage> createState() => _EventMonitoringPageState();
}

class _EventMonitoringPageState extends State<EventMonitoringPage> {
  final CommunityEventRepository eventRepository =
      CommunityEventRepository.instance;
  final OrganizationRepository organizationRepository =
      OrganizationRepository.instance;
  final TextEditingController searchController = TextEditingController();

  String statusFilter = 'All';
  String organizationFilter = 'All';
  String periodFilter = 'All dates';
  String sortOrder = 'Soonest first';
  late DateTime _displayedMonth;
  late DateTime _selectedDay;
  DateTime? _hoveredDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Show the nearest sample event month when the current month is empty.
    final available = eventRepository.events.toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final currentMonthHasEvents = available.any(
      (e) => e.startsAt.year == now.year && e.startsAt.month == now.month,
    );
    final start = currentMonthHasEvents || available.isEmpty
        ? now
        : available
              .firstWhere(
                (e) => !e.startsAt.isBefore(now),
                orElse: () => available.last,
              )
              .startsAt;
    _displayedMonth = DateTime(start.year, start.month);
    _selectedDay = DateTime(start.year, start.month, start.day);
    eventRepository.addListener(_refresh);
    organizationRepository.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    eventRepository.removeListener(_refresh);
    organizationRepository.removeListener(_refresh);
    searchController.dispose();
    super.dispose();
  }

  RegistryOrganization? _findOrganization(String id) {
    for (final organization in organizationRepository.organizations) {
      if (organization.id == id) return organization;
    }
    return null;
  }

  String _organizationName(String id) =>
      _findOrganization(id)?.name ?? 'Unknown organization';

  List<CommunityEvent> get filteredEvents {
    final query = searchController.text.trim().toLowerCase();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    final results = eventRepository.events.where((event) {
      final matchesStatus =
          statusFilter == 'All' || event.status.label == statusFilter;
      final matchesOrg =
          organizationFilter == 'All' ||
          event.organizationId == organizationFilter;
      final date = event.startsAt;
      final matchesPeriod = switch (periodFilter) {
        'This month' =>
          !date.isBefore(DateTime(now.year, now.month)) &&
              date.isBefore(monthEnd),
        'Next 30 days' =>
          !date.isBefore(today) &&
              date.isBefore(today.add(const Duration(days: 30))),
        'Past 30 days' =>
          date.isBefore(today.add(const Duration(days: 1))) &&
              !date.isBefore(today.subtract(const Duration(days: 30))),
        _ => true,
      };
      final matchesSearch =
          event.title.toLowerCase().contains(query) ||
          event.location.toLowerCase().contains(query) ||
          event.id.toLowerCase().contains(query) ||
          event.description.toLowerCase().contains(query) ||
          _organizationName(event.organizationId).toLowerCase().contains(query);
      return matchesStatus && matchesOrg && matchesPeriod && matchesSearch;
    }).toList();

    results.sort((a, b) {
      switch (sortOrder) {
        case 'Latest first':
          return b.startsAt.compareTo(a.startsAt);
        case 'Most registrations':
          return b.registrationCount.compareTo(a.registrationCount);
        case 'Most attendance':
          return b.attendanceCount.compareTo(a.attendanceCount);
        default:
          return a.startsAt.compareTo(b.startsAt);
      }
    });
    return results;
  }

  String _date(DateTime date) {
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _time(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${date.hour < 12 ? 'AM' : 'PM'}';
  }

  Color _statusColor(CommunityEventStatus status) {
    switch (status) {
      case CommunityEventStatus.upcoming:
        return const Color(0xFF2563A5);
      case CommunityEventStatus.ongoing:
        return _green;
      case CommunityEventStatus.completed:
        return const Color(0xFF65768B);
      case CommunityEventStatus.cancelled:
        return const Color(0xFFB45309);
    }
  }

  double _attendanceRatio(CommunityEvent e) {
    if (e.registrationCount <= 0) return 0;
    return e.attendanceCount / e.registrationCount;
  }

  void _resetFilters() {
    searchController.clear();
    setState(() {
      statusFilter = 'All';
      organizationFilter = 'All';
      periodFilter = 'All dates';
      sortOrder = 'Soonest first';
    });
  }

  bool _exportingPdf = false;

  String _printable(Object? value) =>
      (value ?? '').toString().replaceAll(RegExp(r'[^\x20-\x7E\n\r\t]'), '?');

  Future<void> _exportEventsPdf(List<CommunityEvent> events) async {
    if (_exportingPdf) return;
    setState(() => _exportingPdf = true);
    try {
      final document = pw.Document(
        title: 'KAISA Operations Events Monitoring - Prototype',
      );
      final forest = PdfColor.fromHex('#00492C');
      final gold = PdfColor.fromHex('#FBBA16');
      document.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(28),
          maxPages: 250,
          header: (_) => pw.Container(
            padding: const pw.EdgeInsets.all(11),
            color: forest,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'KAISA  /  OPERATIONS  /  EVENT MONITORING',
                  style: pw.TextStyle(
                    color: gold,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Filtered Event Monitoring Report',
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
                'PROTOTYPE - not official attendance evidence',
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
              'Generated ${DateTime.now().toIso8601String()} | '
              '${events.length} filtered events',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 12),
            if (events.isEmpty)
              pw.Text('No matching events')
            else
              pw.TableHelper.fromTextArray(
                headers: const [
                  'Event ID',
                  'Title',
                  'Organization',
                  'Date',
                  'Status',
                  'Location',
                  'Registrations',
                  'Attendance',
                ],
                data: [
                  for (final e in events)
                    [
                      _printable(e.id),
                      _printable(e.title),
                      _printable(_organizationName(e.organizationId)),
                      _date(e.startsAt),
                      _printable(e.status.label),
                      _printable(e.location),
                      '${e.registrationCount}',
                      '${e.attendanceCount}',
                    ],
                ],
                headerDecoration: pw.BoxDecoration(color: forest),
                headerStyle: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                ),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellPadding: const pw.EdgeInsets.all(5),
                oddRowDecoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F0F7F2'),
                ),
              ),
          ],
        ),
      );
      final now = DateTime.now();
      final stamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}';
      await FileSaver.instance.saveFile(
        name: 'KAISA_Events_Monitoring_$stamp',
        bytes: await document.save(),
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event Monitoring PDF saved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('PDF export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  void _showEventDetails(CommunityEvent event) {
    final ratio = _attendanceRatio(event);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          event.title,
          style: const TextStyle(
            color: _ink,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _statusPill(event.status),
                const SizedBox(height: 16),
                _detail('Event ID', event.id),
                _detail(
                  'Organization',
                  _organizationName(event.organizationId),
                ),
                _detail('Date', _date(event.startsAt)),
                _detail(
                  'Schedule',
                  '${_time(event.startsAt)} – ${_time(event.endsAt)}',
                ),
                _detail('Location', event.location),
                _detail('Registrations', '${event.registrationCount}'),
                _detail('Recorded attendance', '${event.attendanceCount}'),
                _detail('Capacity', '${event.capacity}'),
                _detail(
                  'Attendance / registrations',
                  '${(ratio * 100).toStringAsFixed(1)}%',
                ),
                const SizedBox(height: 6),
                const Text(
                  'Attendance compared with registrations',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    minHeight: 9,
                    value: ratio.clamp(0.0, 1.0).toDouble(),
                    backgroundColor: _soft,
                    color: _green,
                  ),
                ),
                const Divider(height: 28, color: _stroke),
                const Text(
                  'Description',
                  style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  event.description.isEmpty
                      ? 'No description provided.'
                      : event.description,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Prototype repository records. Attendance is recorded data; '
                  'it has not been verified against QR check-in evidence.',
                  style: TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
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
    final events = filteredEvents;
    final all = eventRepository.events;
    final ongoing = all
        .where((e) => e.status == CommunityEventStatus.ongoing)
        .length;
    final attendance = all.fold<int>(0, (sum, e) => sum + e.attendanceCount);
    final registrations = all.fold<int>(
      0,
      (sum, e) => sum + e.registrationCount,
    );

    return ColoredBox(
      color: _paper,
      child: LayoutBuilder(
        builder: (context, bounds) {
          final narrow = bounds.maxWidth < 700;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              narrow ? 16 : 28,
              24,
              narrow ? 16 : 28,
              48,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1260),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _hero(narrow),
                      const SizedBox(height: 24),
                      _summaryStrip(
                        total: all.length,
                        upcoming: eventRepository.upcomingEvents,
                        completed: eventRepository.completedEvents,
                        ongoing: ongoing,
                      ),
                      const SizedBox(height: 22),
                      _participationSummary(registrations, attendance),
                      const SizedBox(height: 24),
                      _directory(events, bounds.maxWidth < 900),
                      const SizedBox(height: 14),
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: _muted,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Prototype Event Monitoring reads the shared local repositories. '
                              'Calendar navigation, filtering, inspection and PDF reporting work on these records. '
                              'No event is approved, cancelled, or updated in Supabase from this screen.',
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
          );
        },
      ),
    );
  }

  Widget _hero(bool compact) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(compact ? 22 : 30),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0B3024), Color(0xFF15543A), Color(0xFF288258)],
      ),
    ),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 18,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 630),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'KAISA  /  LGU OPERATIONS  /  EVENTS',
                style: TextStyle(
                  color: _gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Event Monitoring',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 27 : 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Track community activities, organization hosts, registrations, '
                'and recorded attendance in one clear workspace.',
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
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white30),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.visibility_outlined, color: _gold, size: 19),
              SizedBox(width: 9),
              Text(
                'MONITORING VIEW',
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

  Widget _summaryStrip({
    required int total,
    required int upcoming,
    required int completed,
    required int ongoing,
  }) {
    final entries = <(String, int, IconData)>[
      ('Total events', total, Icons.event_note_outlined),
      ('Upcoming', upcoming, Icons.event_available_outlined),
      ('Ongoing', ongoing, Icons.play_circle_outline_rounded),
      ('Completed', completed, Icons.task_alt_outlined),
    ];
    return LayoutBuilder(
      builder: (context, bounds) {
        final columns = bounds.maxWidth >= 900
            ? 4
            : bounds.maxWidth >= 490
            ? 2
            : 1;
        const gap = 12.0;
        final width = (bounds.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final entry in entries)
              SizedBox(
                width: width,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: _surface(),
                  child: Row(
                    children: [
                      _iconBox(entry.$3),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.$2}',
                              style: const TextStyle(
                                color: _forest,
                                fontSize: 27,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              entry.$1,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _iconBox(IconData icon) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: _soft,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: _forest, size: 23),
  );

  Widget _participationSummary(int registered, int attended) {
    final ratio = registered <= 0 ? 0.0 : attended / registered;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _surface(),
      child: LayoutBuilder(
        builder: (context, bounds) {
          final narrow = bounds.maxWidth < 520;
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Participation snapshot',
                style: TextStyle(
                  color: _ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Recorded attendance compared with event registrations.',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
              const SizedBox(height: 15),
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0).toDouble(),
                  minHeight: 12,
                  backgroundColor: _soft,
                  color: _green,
                ),
              ),
            ],
          );
          final totals = Wrap(
            spacing: 14,
            runSpacing: 7,
            children: [
              _miniCount('$registered', 'Registrations'),
              _miniCount('$attended', 'Recorded attendance'),
              _miniCount(
                registered == 0 ? '—' : '${(ratio * 100).toStringAsFixed(0)}%',
                'Attendance ratio',
              ),
            ],
          );
          return narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [details, const SizedBox(height: 15), totals],
                )
              : Row(
                  children: [
                    Expanded(child: details),
                    const SizedBox(width: 26),
                    Flexible(child: totals),
                  ],
                );
        },
      ),
    );
  }

  Widget _miniCount(String value, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        value,
        style: const TextStyle(
          color: _forest,
          fontSize: 19,
          fontWeight: FontWeight.w900,
        ),
      ),
      Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
    ],
  );

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _monthLabel(DateTime date) {
    const months = [
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
    return '${months[date.month - 1]} ${date.year}';
  }

  void _moveMonth(int offset) {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + offset,
      );
      _selectedDay = DateTime(_displayedMonth.year, _displayedMonth.month);
      _hoveredDay = null;
    });
  }

  void _goToday() {
    final today = DateTime.now();
    setState(() {
      _displayedMonth = DateTime(today.year, today.month);
      _selectedDay = DateTime(today.year, today.month, today.day);
    });
  }

  Widget _directory(List<CommunityEvent> events, bool compact) {
    final daily =
        events.where((e) => _sameDay(e.startsAt, _selectedDay)).toList()
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final monthly = events
        .where(
          (e) =>
              e.startsAt.year == _displayedMonth.year &&
              e.startsAt.month == _displayedMonth.month,
        )
        .toList();

    return Container(
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, bounds) {
                final heading = const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Community Events Calendar',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Select a date to inspect scheduled events. Event colors show status.',
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                );
                final export = OutlinedButton.icon(
                  onPressed: events.isEmpty || _exportingPdf
                      ? null
                      : () => _exportEventsPdf(events),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 17),
                  label: const Text('Export PDF'),
                  style: OutlinedButton.styleFrom(foregroundColor: _forest),
                );
                return bounds.maxWidth < 560
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [heading, const SizedBox(height: 12), export],
                      )
                    : Row(
                        children: [
                          Expanded(child: heading),
                          const SizedBox(width: 12),
                          export,
                        ],
                      );
              },
            ),
          ),
          const Divider(height: 1, color: _stroke),
          Padding(padding: const EdgeInsets.all(18), child: _filters()),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${events.length} matching event(s) · ${monthly.length} this month',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 17),
                  label: const Text('Clear filters'),
                  style: TextButton.styleFrom(foregroundColor: _green),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _stroke),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                Text(
                  _monthLabel(_displayedMonth),
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: _goToday,
                      style: OutlinedButton.styleFrom(foregroundColor: _forest),
                      child: const Text('Today'),
                    ),
                    const SizedBox(width: 7),
                    IconButton.outlined(
                      tooltip: 'Previous month',
                      onPressed: () => _moveMonth(-1),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    const SizedBox(width: 5),
                    IconButton.outlined(
                      tooltip: 'Next month',
                      onPressed: () => _moveMonth(1),
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _calendar(events),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 14,
              runSpacing: 7,
              children: [
                _legendDot(
                  'Upcoming',
                  _statusColor(CommunityEventStatus.upcoming),
                ),
                _legendDot(
                  'Ongoing',
                  _statusColor(CommunityEventStatus.ongoing),
                ),
                _legendDot(
                  'Completed',
                  _statusColor(CommunityEventStatus.completed),
                ),
                _legendDot(
                  'Cancelled',
                  _statusColor(CommunityEventStatus.cancelled),
                ),
              ],
            ),
          ),
          const Divider(height: 30, color: _stroke),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 13),
            child: Row(
              children: [
                const Icon(
                  Icons.event_available_outlined,
                  color: _forest,
                  size: 21,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${_date(_selectedDay)} · ${daily.length} event(s)',
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (daily.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 25),
              child: Text(
                'No matching events scheduled for this date. '
                'Choose another highlighted day or adjust the filters.',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            )
          else
            ...daily.map(_eventCard),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _legendDot(String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 11, color: _muted)),
    ],
  );

  Widget _calendar(List<CommunityEvent> events) {
    final first = DateTime(_displayedMonth.year, _displayedMonth.month);
    final mondayOffset = first.weekday - DateTime.monday;
    final gridStart = first.subtract(Duration(days: mondayOffset));
    final daysInMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + 1,
      0,
    ).day;
    final slots = ((mondayOffset + daysInMonth + 6) ~/ 7) * 7;
    final today = DateTime.now();

    // A minimum width keeps dates and event labels legible on phones.
    return LayoutBuilder(
      builder: (context, outer) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: SizedBox(
          width: outer.maxWidth < 700 ? 700 : outer.maxWidth - 28,
          child: Column(
            children: [
              Row(
                children: [
                  for (final name in [
                    'MON',
                    'TUE',
                    'WED',
                    'THU',
                    'FRI',
                    'SAT',
                    'SUN',
                  ])
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 11),
                        child: Text(
                          name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              for (int week = 0; week < slots ~/ 7; week++)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int dayIndex = 0; dayIndex < 7; dayIndex++)
                      Expanded(
                        child: _dayCell(
                          gridStart.add(Duration(days: week * 7 + dayIndex)),
                          events,
                          today,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dayCell(DateTime day, List<CommunityEvent> events, DateTime today) {
    final onMonth =
        day.month == _displayedMonth.month && day.year == _displayedMonth.year;
    final selected = _sameDay(day, _selectedDay);
    final hovered = _hoveredDay != null && _sameDay(day, _hoveredDay!);
    final isToday = _sameDay(day, today);
    final matches = events.where((e) => _sameDay(e.startsAt, day)).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredDay = day),
      onExit: (_) => setState(() => _hoveredDay = null),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: selected
              ? const Color(0xFFE1F1E6)
              : hovered
              ? const Color(0xFFF1F8F3)
              : onMonth
              ? Colors.white
              : const Color(0xFFF7F9F7),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() {
              _selectedDay = DateTime(day.year, day.month, day.day);
              if (!onMonth) {
                _displayedMonth = DateTime(day.year, day.month);
              }
            }),
            child: Container(
              height: 105,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? _green : _stroke,
                  width: selected ? 1.5 : 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 25,
                    height: 25,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isToday ? _forest : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: isToday
                            ? Colors.white
                            : onMonth
                            ? _ink
                            : _muted,
                        fontWeight: selected || isToday
                            ? FontWeight.w900
                            : FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  for (final event in matches.take(2))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Tooltip(
                        message:
                            '${_time(event.startsAt)} · ${event.title}\n'
                            '${_organizationName(event.organizationId)}',
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: _statusColor(
                              event.status,
                            ).withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(4),
                            border: Border(
                              left: BorderSide(
                                color: _statusColor(event.status),
                                width: 3,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 3,
                          ),
                          child: Text(
                            event.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: _statusColor(event.status),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (matches.length > 2)
                    Text(
                      '+${matches.length - 2} more',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _filters() {
    final orgs = organizationRepository.organizations.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final validIds = orgs.map((e) => e.id).toSet();
    final selectedOrg = validIds.contains(organizationFilter)
        ? organizationFilter
        : 'All';

    final search = TextField(
      controller: searchController,
      onChanged: (_) => setState(() {}),
      decoration: _input('Search event, host or location', Icons.search_rounded)
          .copyWith(
            suffixIcon: searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
          ),
    );
    final status = _dropdown(
      value: statusFilter,
      options: const ['All', 'Upcoming', 'Ongoing', 'Completed', 'Cancelled'],
      label: 'Status',
      onChanged: (value) => setState(() => statusFilter = value),
    );
    final org = DropdownButtonFormField<String>(
      key: ValueKey('org-$selectedOrg'),
      initialValue: selectedOrg,
      isExpanded: true,
      decoration: _input('Host organization', Icons.apartment_outlined),
      items: [
        const DropdownMenuItem<String>(value: 'All', child: Text('All hosts')),
        for (final item in orgs)
          DropdownMenuItem<String>(
            value: item.id,
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (value) => setState(() => organizationFilter = value ?? 'All'),
    );

    return LayoutBuilder(
      builder: (context, bounds) {
        final maxWidth = bounds.maxWidth;
        final cols = maxWidth >= 850
            ? 4
            : maxWidth >= 520
            ? 2
            : 1;
        const gap = 12.0;
        final colWidth = (maxWidth - (cols - 1) * gap) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: cols == 4
                  ? colWidth * 2 + gap
                  : cols == 2
                  ? maxWidth
                  : colWidth,
              child: search,
            ),
            SizedBox(width: colWidth, child: status),
            SizedBox(width: colWidth, child: org),
          ],
        );
      },
    );
  }

  InputDecoration _input(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: _green, size: 19),
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  );

  Widget _dropdown({
    required String value,
    required List<String> options,
    required String label,
    required ValueChanged<String> onChanged,
  }) => DropdownButtonFormField<String>(
    key: ValueKey('$label-$value'),
    initialValue: value,
    isExpanded: true,
    decoration: _input(label, Icons.filter_list_rounded),
    items: [
      for (final option in options)
        DropdownMenuItem(
          value: option,
          child: Text(option, overflow: TextOverflow.ellipsis),
        ),
    ],
    onChanged: (value) {
      if (value != null) onChanged(value);
    },
  );

  Widget _statusPill(CommunityEventStatus status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.1),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _attendanceCell(CommunityEvent event) {
    final ratio = _attendanceRatio(event);
    return SizedBox(
      width: 160,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${event.attendanceCount} / ${event.registrationCount}',
            style: const TextStyle(
              fontSize: 12,
              color: _ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0).toDouble(),
              minHeight: 6,
              color: _green,
              backgroundColor: _soft,
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventCard(CommunityEvent event) => InkWell(
    onTap: () => _showEventDetails(event),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _stroke)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _statusPill(event.status),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            _organizationName(event.organizationId),
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _meta(Icons.calendar_today_outlined, _date(event.startsAt)),
              _meta(Icons.access_time_rounded, _time(event.startsAt)),
              _meta(Icons.place_outlined, event.location),
            ],
          ),
          const SizedBox(height: 14),
          _attendanceCell(event),
          const SizedBox(height: 9),
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'View details',
                style: TextStyle(
                  color: _forest,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, color: _forest, size: 17),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _meta(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: _muted, size: 15),
      const SizedBox(width: 5),
      Text(text, style: const TextStyle(color: _muted, fontSize: 11)),
    ],
  );

  BoxDecoration _surface() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: _stroke),
  );
}
