import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'operations_performance_service.dart';

const _forest = Color(0xFF00492C);
const _green = Color(0xFF287D55);
const _gold = Color(0xFFFBBA16);
const _ink = Color(0xFF173D2B);
const _muted = Color(0xFF687B70);
const _border = Color(0xFFE2EBE4);
const _mint = Color(0xFFEAF5EE);
const _dark = Color(0xFF092A21);

/// Interactive, fictional prototype analytics; no database queries or writes.
class OperationsInsightsSection extends StatefulWidget {
  const OperationsInsightsSection({super.key});

  @override
  State<OperationsInsightsSection> createState() =>
      _OperationsInsightsSectionState();
}

class _OperationsInsightsSectionState extends State<OperationsInsightsSection> {
  List<OrganizationPerformance>? _data;
  String? _error;
  bool _loading = true;
  String _metric = 'Demo attendance';
  String _category = 'All categories';
  String _search = '';
  String _trendMetric = 'Check-ins';
  int _trendMonths = 6;
  int? _hoveredTrendIndex;
  int? _hoveredBarIndex;
  int? _hoveredPieIndex;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await OperationsPerformanceService.instance.fetch();
      if (mounted) setState(() => _data = result);
    } catch (error) {
      if (mounted) {
        setState(() {
          _data = null;
          // Avoid surfacing internal database details to dashboard users.
          _error = 'Could not load the prototype sample data.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _value(OrganizationPerformance org) => switch (_metric) {
    'Events hosted' => org.events,
    'Active members' => org.members,
    _ => org.attendees,
  };

  List<OrganizationPerformance> get _filtered {
    final query = _search.toLowerCase().trim();
    final rows = (_data ?? []).where((o) {
      return (_category == 'All categories' || o.category == _category) &&
          (query.isEmpty ||
              o.name.toLowerCase().contains(query) ||
              o.barangay.toLowerCase().contains(query) ||
              o.category.toLowerCase().contains(query));
    }).toList();
    rows.sort((a, b) {
      final diff = _value(b).compareTo(_value(a));
      return diff != 0 ? diff : a.name.compareTo(b.name);
    });
    return rows;
  }

  Map<String, int> _groupBy(
    List<OrganizationPerformance> rows,
    String Function(OrganizationPerformance) name,
    int Function(OrganizationPerformance) amount,
  ) {
    final counts = <String, int>{};
    for (final row in rows) {
      final key = name(row);
      counts[key] = (counts[key] ?? 0) + amount(row);
    }
    return Map.fromEntries(
      counts.entries.toList()..sort((a, b) {
        final compare = b.value.compareTo(a.value);
        return compare != 0 ? compare : a.key.compareTo(b.key);
      }),
    );
  }

  void _showDetails(OrganizationPerformance org) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(org.name),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${org.category}  •  ${org.barangay}'),
              const SizedBox(height: 16),
              _fact('Accreditation', org.accreditationStatus),
              _fact('Demo check-ins', '${org.attendees}'),
              _fact('Events hosted', '${org.events}'),
              _fact('Active members', '${org.members}'),
              _fact('Admins and officers', '${org.adminsOfficers}'),
              const SizedBox(height: 12),
              const Text(
                'SIMULATED METRICS — no Supabase performance data. '
                'They are not a quality or compliance rating.',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _fact(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: _muted)),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, color: _ink),
          ),
        ),
      ],
    ),
  );

  static String _csv(String text) => '"${text.replaceAll('"', '""')}"';

  Future<void> _export() async {
    final rows = _filtered;
    final lines = <String>[
      'DEMO DATA ONLY - Organization,Category,Barangay,Accreditation,Active members,Admins and officers,Events hosted,Simulated check-ins',
      for (final org in rows)
        '${_csv(org.name)},${_csv(org.category)},${_csv(org.barangay)},'
            '${_csv(org.accreditationStatus)},${org.members},'
            '${org.adminsOfficers},${org.events},${org.attendees}',
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied ${rows.length} organization records as CSV.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(),
        const SizedBox(height: 14),
        if (_loading)
          _panel(
            'Loading civic performance',
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (_error != null)
          _panel(
            'Performance data not yet connected',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_error!, style: const TextStyle(color: _muted)),
                const SizedBox(height: 12),
                const Text(
                  'These charts use locally defined fictional sample data. '
                  'The rest of the dashboard uses existing local repositories.',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ],
            ),
          )
        else if (_data!.isEmpty)
          _panel(
            'No organization performance records',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No demo organization records are available.',
                  style: TextStyle(color: _muted),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          )
        else ...[
          _filters(),
          const SizedBox(height: 14),
          _insightContent(),
        ],
      ],
    );
  }

  Widget _heading() => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 12,
    runSpacing: 10,
    children: [
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Organization performance intelligence  •  DEMO',
            style: TextStyle(
              color: _ink,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'PROTOTYPE • Fictional organization data — not Supabase records',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ),
      OutlinedButton.icon(
        onPressed: _loading ? null : _refresh,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('Refresh metrics'),
      ),
    ],
  );

  Widget _filters() {
    final categories = (_data!.map((e) => e.category).toSet().toList()..sort());
    return _panel(
      'Explore the data',
      LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 800;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: wide ? 270 : c.maxWidth,
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: const InputDecoration(
                    labelText: 'Find organization / barangay',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(
                width: wide ? 210 : c.maxWidth,
                child: DropdownButtonFormField<String>(
                  key: ValueKey(_category),
                  initialValue: _category,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: ['All categories', ...categories]
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _category = v ?? 'All categories'),
                ),
              ),
              SizedBox(
                width: wide ? 210 : c.maxWidth,
                child: DropdownButtonFormField<String>(
                  key: ValueKey(_metric),
                  initialValue: _metric,
                  decoration: const InputDecoration(
                    labelText: 'Rank by',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: ['Demo attendance', 'Events hosted', 'Active members']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _metric = v ?? 'Demo attendance'),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _export,
                icon: const Icon(Icons.copy_all_rounded, size: 17),
                label: const Text('Copy CSV'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _insightContent() {
    final rows = _filtered;
    if (rows.isEmpty) {
      return _panel(
        'No matching records',
        const Text(
          'Try a different search or category.',
          style: TextStyle(color: _muted),
        ),
      );
    }
    final hasActivity = rows.any((e) => e.attendees > 0 || e.events > 0);
    final top = hasActivity
        ? (rows.toList()..sort((a, b) {
                final cmp = b.attendees.compareTo(a.attendees);
                if (cmp != 0) return cmp;
                final events = b.events.compareTo(a.events);
                return events != 0 ? events : a.name.compareTo(b.name);
              }))
              .first
        : null;
    // Three meaningful visualizations only. More charts would repeat the same totals.
    final charts = <Widget>[
      _panel('Monthly participation · simulated', _monthlyTrend(rows)),
      _panel('Top organizations · $_metric', _verticalOrgBars(rows)),
      _panel('Participation by category', _categoryPie(rows)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _spotlight(top),
        const SizedBox(height: 20),
        _sectionLabel(
          'Performance at a glance',
          'Three focused interactive prototype charts. Hover over data points or bars for details.',
        ),
        const SizedBox(height: 12),
        _chartGrid(charts),
        const SizedBox(height: 22),
        _leaderboard(rows),
      ],
    );
  }

  Widget _sectionLabel(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: _ink,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 4),
      Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
    ],
  );

  Widget _chartGrid(List<Widget> children) => LayoutBuilder(
    builder: (context, bounds) {
      final columns = bounds.maxWidth >= 900 ? 2 : 1;
      const gap = 14.0;
      final width = (bounds.maxWidth - (columns - 1) * gap) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );

  // The provider stores total counts only, not timestamped records.
  // These weights deliberately create a visible sample trend; never treat
  // their values as a monthly historical series.
  Widget _monthlyTrend(List<OrganizationPerformance> rows) {
    final total = switch (_trendMetric) {
      'Events' => rows.fold<int>(0, (sum, o) => sum + o.events),
      'Members' => rows.fold<int>(0, (sum, o) => sum + o.members),
      _ => rows.fold<int>(0, (sum, o) => sum + o.attendees),
    };
    const weights = <double>[
      0.55,
      0.72,
      0.63,
      0.81,
      0.76,
      0.95,
      0.84,
      1.02,
      0.89,
      1.15,
      1.04,
      1.29,
    ];
    final count = _trendMonths;
    final values = weights
        .take(count)
        .map((w) => (total / 12 * w).roundToDouble())
        .toList();
    final labels = List<String>.generate(count, (i) => 'M${i + 1}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, selectorBounds) {
            final available = selectorBounds.maxWidth;
            final fullRow = available >= 354;
            final selectorWidth = fullRow
                ? (available - 9) / 2 < 172.5
                      ? (available - 9) / 2
                      : 172.5
                : available.clamp(0.0, 175.0).toDouble();
            return Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                SizedBox(
                  width: selectorWidth,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(_trendMetric),
                    initialValue: _trendMetric,
                    isExpanded: true,
                    isDense: true,
                    decoration: const InputDecoration(
                      labelText: 'Metric',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    items: ['Check-ins', 'Events', 'Members']
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _trendMetric = v ?? 'Check-ins'),
                  ),
                ),
                SizedBox(
                  width: selectorWidth,
                  child: DropdownButtonFormField<int>(
                    key: ValueKey(_trendMonths),
                    initialValue: _trendMonths,
                    isExpanded: true,
                    isDense: true,
                    decoration: const InputDecoration(
                      labelText: 'Demo periods',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 6,
                        child: Text(
                          '6 months',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 12,
                        child: Text(
                          '12 months',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _trendMonths = v ?? 6),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, bounds) {
            const left = 43.0;
            const right = 10.0;
            final plotWidth = math.max(1.0, bounds.maxWidth - left - right);
            return MouseRegion(
              cursor: SystemMouseCursors.precise,
              onExit: (_) => setState(() => _hoveredTrendIndex = null),
              onHover: (event) {
                final fraction = ((event.localPosition.dx - left) / plotWidth)
                    .clamp(0.0, 1.0);
                final index = (fraction * (values.length - 1)).round();
                if (_hoveredTrendIndex != index) {
                  setState(() => _hoveredTrendIndex = index);
                }
              },
              child: GestureDetector(
                onTapDown: (details) {
                  final fraction =
                      ((details.localPosition.dx - left) / plotWidth).clamp(
                        0.0,
                        1.0,
                      );
                  setState(
                    () => _hoveredTrendIndex = (fraction * (values.length - 1))
                        .round(),
                  );
                },
                child: SizedBox(
                  height: 218,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _TrendPainter(
                      values,
                      labels,
                      hoveredIndex: _hoveredTrendIndex,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 7),
        Text(
          _hoveredTrendIndex == null || _hoveredTrendIndex! >= values.length
              ? 'Hover or tap a data point to inspect the simulated value.'
              : '${labels[_hoveredTrendIndex!]} · $_trendMetric: '
                    '${values[_hoveredTrendIndex!].round()} (demo)',
          style: const TextStyle(
            fontSize: 11,
            color: _forest,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Illustrative periods, not real calendar months.',
          style: TextStyle(fontSize: 11, color: _muted),
        ),
      ],
    );
  }

  Widget _verticalOrgBars(List<OrganizationPerformance> rows) {
    final top = rows.take(6).toList();
    if (top.isEmpty) return _empty('No organizations match the filter.');
    final maximum = math.max(1, top.map(_value).reduce(math.max));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ranking by $_metric · tap a bar to inspect',
          style: const TextStyle(color: _muted, fontSize: 11),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 207,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < top.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) => setState(() => _hoveredBarIndex = i),
                      onExit: (_) => setState(() => _hoveredBarIndex = null),
                      child: Tooltip(
                        message: '${top[i].name}\n$_metric: ${_value(top[i])}',
                        child: InkWell(
                          onTap: () => _showDetails(top[i]),
                          borderRadius: BorderRadius.circular(7),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${_value(top[i])}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _forest,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 7),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                height: 143 * _value(top[i]) / maximum,
                                constraints: const BoxConstraints(minHeight: 4),
                                decoration: BoxDecoration(
                                  color: _hoveredBarIndex == i
                                      ? _forest
                                      : (i == 0 ? _gold : _green),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(7),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '#${i + 1}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        const Text(
          'Gold = highest in current filtered ranking.',
          style: TextStyle(color: _muted, fontSize: 11),
        ),
      ],
    );
  }

  Widget _categoryPie(List<OrganizationPerformance> rows) {
    final categories = _groupBy(rows, (o) => o.category, (o) => o.attendees);
    final total = categories.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return _empty('No simulated check-ins to display.');
    const colors = <Color>[
      _forest,
      _gold,
      _green,
      Color(0xFF74B495),
      Color(0xFF2E6693),
      Color(0xFFA7C5B5),
    ];
    final entries = categories.entries.toList();
    return LayoutBuilder(
      builder: (context, bounds) => Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 17,
        runSpacing: 16,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.precise,
            onExit: (_) => setState(() => _hoveredPieIndex = null),
            onHover: (event) {
              final x = event.localPosition.dx - 89;
              final y = event.localPosition.dy - 89;
              if (math.sqrt(x * x + y * y) > 86) {
                if (_hoveredPieIndex != null) {
                  setState(() => _hoveredPieIndex = null);
                }
                return;
              }
              final angle =
                  (math.atan2(y, x) + math.pi / 2 + math.pi * 2) %
                  (math.pi * 2);
              var cursor = 0.0;
              int? selected;
              for (var i = 0; i < entries.length; i++) {
                cursor += entries[i].value / total * 2 * math.pi;
                if (angle <= cursor) {
                  selected = i;
                  break;
                }
              }
              if (selected != _hoveredPieIndex) {
                setState(() => _hoveredPieIndex = selected);
              }
            },
            child: SizedBox(
              width: 178,
              height: 178,
              child: CustomPaint(
                painter: _PiePainter(
                  entries.map((e) => e.value).toList(),
                  colors,
                  hoveredIndex: _hoveredPieIndex,
                ),
              ),
            ),
          ),
          SizedBox(
            width: math.min(280.0, math.max(180.0, bounds.maxWidth - 25)),
            child: Column(
              children: [
                for (var i = 0; i < entries.length; i++)
                  Tooltip(
                    message:
                        '${entries[i].key}: ${entries[i].value} demo check-ins',
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 11,
                            height: 11,
                            decoration: BoxDecoration(
                              color: colors[i % colors.length],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entries[i].key,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: _ink),
                            ),
                          ),
                          Text(
                            '${(entries[i].value * 100 / total).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _forest,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_hoveredPieIndex != null &&
                    _hoveredPieIndex! < entries.length)
                  Text(
                    '${entries[_hoveredPieIndex!].key}: '
                    '${entries[_hoveredPieIndex!].value} check-ins (demo)',
                    style: const TextStyle(
                      color: _forest,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _spotlight(OrganizationPerformance? top) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_dark, _forest, _green]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Wrap(
        spacing: 22,
        runSpacing: 14,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 610),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events_rounded, color: _gold),
                    SizedBox(width: 9),
                    Text(
                      'DEMO ACTIVITY SPOTLIGHT',
                      style: TextStyle(
                        color: _gold,
                        letterSpacing: 1.5,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  top?.name ?? 'No activity leader yet',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  top == null
                      ? 'No simulated attendance or hosted events are recorded for '
                            'these organizations yet.'
                      : '${top.barangay} • ${top.category}  ·  '
                            '${top.attendees} demo check-ins  ·  '
                            '${top.events} hosted events',
                  style: const TextStyle(
                    color: Color(0xFFE1F0E8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'DEMO RANKING: simulated check-ins first, hosted events second. '
                  'Not an official award or performance assessment.',
                  style: TextStyle(color: Color(0xFFBDD9C9), fontSize: 11),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: top == null ? null : () => _showDetails(top),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
            ),
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Inspect leader'),
          ),
        ],
      ),
    );
  }

  Widget _leaderboard(List<OrganizationPerformance> rows) {
    return _panel(
      'Organization leaderboard · $_metric',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select a row to inspect a fictional organization’s simulated results.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: math.max(800.0, c.maxWidth),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(_mint),
                  columns: const [
                    DataColumn(label: Text('RANK')),
                    DataColumn(label: Text('ORGANIZATION')),
                    DataColumn(label: Text('BARANGAY')),
                    DataColumn(label: Text('MEMBERS')),
                    DataColumn(label: Text('EVENTS')),
                    DataColumn(label: Text('CHECK-INS')),
                  ],
                  rows: [
                    for (var i = 0; i < rows.length; i++)
                      DataRow(
                        cells: [
                          DataCell(
                            Text('#${i + 1}'),
                            onTap: () => _showDetails(rows[i]),
                          ),
                          DataCell(
                            SizedBox(
                              width: 210,
                              child: Text(
                                rows[i].name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            onTap: () => _showDetails(rows[i]),
                          ),
                          DataCell(Text(rows[i].barangay)),
                          DataCell(Text('${rows[i].members}')),
                          DataCell(Text('${rows[i].events}')),
                          DataCell(Text('${rows[i].attendees}')),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel(String title, Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(19),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: const TextStyle(
              color: _forest,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 15),
        ],
        child,
      ],
    ),
  );

  Widget _empty(String text) => SizedBox(
    height: 130,
    child: Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: _muted),
      ),
    ),
  );
}

class _PiePainter extends CustomPainter {
  const _PiePainter(this.values, this.colors, {this.hoveredIndex});
  final List<int> values;
  final List<Color> colors;
  final int? hoveredIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<int>(0, (a, b) => a + b);
    if (total <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      if (values[i] <= 0) continue;
      final sweep = values[i] / total * 2 * math.pi;
      final offset = hoveredIndex == i
          ? Offset(
              math.cos(start + sweep / 2) * 5,
              math.sin(start + sweep / 2) * 5,
            )
          : Offset.zero;
      canvas.drawArc(
        rect.shift(offset),
        start,
        sweep,
        true,
        Paint()
          ..color = colors[i % colors.length]
          ..style = PaintingStyle.fill,
      );
      start += sweep;
    }
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _PiePainter old) =>
      old.values.toString() != values.toString() ||
      old.colors.toString() != colors.toString() ||
      old.hoveredIndex != hoveredIndex;
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter(this.values, this.labels, {this.hoveredIndex});
  final List<double> values;
  final List<String> labels;
  final int? hoveredIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const left = 43.0;
    const right = 10.0;
    const top = 12.0;
    const bottom = 30.0;
    final width = math.max(1.0, size.width - left - right);
    final height = math.max(1.0, size.height - top - bottom);
    final maximum = math.max(1.0, values.reduce(math.max) * 1.15);
    final axis = Paint()
      ..color = const Color(0xFFE4EAE4)
      ..strokeWidth = 1;
    final labelStyle = const TextStyle(color: _muted, fontSize: 10);

    void drawText(String text, Offset offset) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: labelStyle),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, offset);
    }

    for (var i = 0; i <= 4; i++) {
      final y = top + height * i / 4;
      canvas.drawLine(Offset(left, y), Offset(left + width, y), axis);
      drawText('${(maximum * (4 - i) / 4).round()}', Offset(2, y - 6));
    }
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x =
          left + width * (values.length == 1 ? 0 : i / (values.length - 1));
      final y = top + height * (1 - values[i] / maximum);
      points.add(Offset(x, y));
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, top + height + 8));
    }
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      linePath.lineTo(point.dx, point.dy);
    }
    final fill = Path.from(linePath)
      ..lineTo(points.last.dx, top + height)
      ..lineTo(points.first.dx, top + height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x553CB982), Color(0x003CB982)],
        ).createShader(Rect.fromLTWH(left, top, width, height)),
    );
    canvas.drawPath(
      linePath,
      Paint()
        ..color = _forest
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      if (i == hoveredIndex) {
        canvas.drawLine(
          Offset(point.dx, top),
          Offset(point.dx, top + height),
          Paint()
            ..color = _green.withValues(alpha: 0.55)
            ..strokeWidth = 1,
        );
      }
      canvas.drawCircle(
        point,
        i == hoveredIndex ? 7 : 4,
        Paint()..color = _gold,
      );
      canvas.drawCircle(
        point,
        i == hoveredIndex ? 3 : 2,
        Paint()..color = _forest,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.values.toString() != values.toString() ||
      old.labels.toString() != labels.toString() ||
      old.hoveredIndex != hoveredIndex;
}
