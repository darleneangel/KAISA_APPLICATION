import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../shared/repositories/verification_workflow_repository.dart';
import '../../../shared/repositories/verification_case_repository.dart';

const _forest = Color(0xFF00492C);
const _gold = Color(0xFFFBBA16);
const _mint = Color(0xFFE5F3EA);
const _ink = Color(0xFF18362A);
const _grey = Color(0xFF637468);
const _blue = Color(0xFF3679A7);
const _red = Color(0xFFC05245);

/// All visualizations are computed from the shared fictional repository.
/// No live identity documents or external services are queried.
class VerificationAnalyticsCharts extends StatelessWidget {
  const VerificationAnalyticsCharts({
    super.key,
    required this.cases,
    this.compact = false,
  });
  final List<dynamic> cases;
  final bool compact;

  Widget _panel(String title, String subtitle, Widget chart) => Container(
    padding: const EdgeInsets.all(19),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE1EAE3)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0900492C),
          blurRadius: 16,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: _grey)),
        const SizedBox(height: 20),
        chart,
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final status = <String, int>{
      'Pending': 0,
      'Under Review': 0,
      'Approved': 0,
      'Rejected': 0,
      'Resubmission': 0,
    };
    for (final item in cases) {
      final name = switch (item.status.name) {
        'pending' => 'Pending',
        'reviewing' => 'Under Review',
        'approved' => 'Approved',
        'rejected' => 'Rejected',
        'resubmission' => 'Resubmission',
        _ => 'Pending',
      };
      status[name] = (status[name] ?? 0) + 1;
    }
    final barangays = <String, int>{};
    for (final item in cases) {
      barangays.update(item.barangay, (n) => n + 1, ifAbsent: () => 1);
    }
    final ranked = barangays.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final daily = <DateTime, int>{};
    for (final item in cases) {
      final key = DateTime(
        item.submittedAt.year,
        item.submittedAt.month,
        item.submittedAt.day,
      );
      daily.update(key, (n) => n + 1, ifAbsent: () => 1);
    }
    final days = daily.keys.toList()..sort();
    final resident = cases.where((c) => c.kind.name == 'resident').length;
    final organization = cases.length - resident;
    final cards = <Widget>[
      _panel(
        'Application status',
        'All ${cases.length} matching applications',
        _StatusDonut(status: status, total: cases.length),
      ),
      _panel(
        'Submission trend',
        'Actual dates from the fictional application records',
        _DailyTrend(days: days, counts: daily),
      ),
      _panel(
        'Applications by barangay',
        'Counts based on selected filters',
        SizedBox(
          height: math.max(170, math.min(330, ranked.length * 32)).toDouble(),
          child: ListView(
            primary: false,
            children: [
              for (final e in ranked)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 105,
                        child: Text(
                          e.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: _grey),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: cases.isEmpty ? 0 : e.value / cases.length,
                            backgroundColor: _mint,
                            color: _forest,
                            minHeight: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${e.value}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      _panel(
        'Application type',
        'Resident Tier 2 and organization accreditation',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _typeBar('Resident Tier 2', resident, cases.length, _forest),
            const SizedBox(height: 20),
            _typeBar(
              'Organization accreditation',
              organization,
              cases.length,
              _gold,
            ),
            const SizedBox(height: 28),
            Text(
              'Total sample applications: ${cases.length}',
              style: const TextStyle(fontSize: 12, color: _grey),
            ),
          ],
        ),
      ),
    ];
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        final columns = width >= 780 ? 2 : 1;
        const gap = 14.0;
        final itemWidth = (width - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final c in cards) SizedBox(width: itemWidth, child: c),
          ],
        );
      },
    );
  }

  Widget _typeBar(String label, int value, int total, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
          ),
          Text(
            '$value / $total',
            style: const TextStyle(fontSize: 12, color: _grey),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: total == 0 ? 0 : value / total,
          color: color,
          backgroundColor: _mint,
          minHeight: 15,
        ),
      ),
    ],
  );
}

class _StatusDonut extends StatelessWidget {
  const _StatusDonut({required this.status, required this.total});
  final Map<String, int> status;
  final int total;
  static const colors = [_gold, _blue, _forest, _red, Color(0xFFAE7A2B)];
  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 155,
        child: Center(
          child: SizedBox(
            width: 155,
            height: 155,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(155, 155),
                  painter: _DonutPainter(status.values.toList(), colors),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$total',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: _forest,
                      ),
                    ),
                    const Text(
                      'applications',
                      style: TextStyle(fontSize: 11, color: _grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 15),
      Wrap(
        spacing: 12,
        runSpacing: 9,
        children: [
          for (var i = 0; i < status.length; i++)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: colors[i],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '${status.keys.elementAt(i)}: ${status.values.elementAt(i)}',
                  style: const TextStyle(fontSize: 11, color: _grey),
                ),
              ],
            ),
        ],
      ),
    ],
  );
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.values, this.colors);
  final List<int> values;
  final List<Color> colors;
  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<int>(0, (a, b) => a + b);
    final center = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - 12;
    final rect = Rect.fromCircle(center: center, radius: r);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 19
      ..strokeCap = StrokeCap.butt;
    paint.color = _mint;
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint);
    if (total == 0) return;
    var angle = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * 2 * math.pi;
      if (sweep <= 0) continue;
      paint.color = colors[i];
      canvas.drawArc(rect, angle, sweep, false, paint);
      angle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.values.toString() != values.toString();
}

class _DailyTrend extends StatelessWidget {
  const _DailyTrend({required this.days, required this.counts});
  final List<DateTime> days;
  final Map<DateTime, int> counts;
  @override
  Widget build(BuildContext context) {
    if (days.isEmpty)
      return const SizedBox(
        height: 155,
        child: Center(child: Text('No submissions in this selection')),
      );
    final start = days.first, end = days.last;
    final count = end.difference(start).inDays + 1;
    final values = [
      for (var i = 0; i < count; i++) counts[start.add(Duration(days: i))] ?? 0,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 165,
          width: double.infinity,
          child: CustomPaint(painter: _TrendPainter(values)),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${start.month}/${start.day}/${start.year}',
              style: const TextStyle(fontSize: 11, color: _grey),
            ),
            Text(
              '${end.month}/${end.day}/${end.year}',
              style: const TextStyle(fontSize: 11, color: _grey),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          'Peak: ${values.reduce(math.max)} cases/day · ${values.length} days',
          style: const TextStyle(color: _grey, fontSize: 11),
        ),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.values);
  final List<int> values;
  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = math.max(1, values.reduce(math.max));
    final left = 12.0,
        right = size.width - 12,
        top = 14.0,
        bottom = size.height - 14;
    final grid = Paint()
      ..color = _mint
      ..strokeWidth = 1;
    for (var n = 0; n <= 4; n++) {
      final y = top + (bottom - top) * n / 4;
      canvas.drawLine(Offset(left, y), Offset(right, y), grid);
    }
    Offset point(int i) => Offset(
      values.length == 1
          ? (left + right) / 2
          : left + (right - left) * i / (values.length - 1),
      bottom - (bottom - top) * values[i] / maxVal,
    );
    final path = Path()..moveTo(point(0).dx, point(0).dy);
    for (var i = 1; i < values.length; i++)
      path.lineTo(point(i).dx, point(i).dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = _forest
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    final dot = Paint()..color = _gold;
    for (var i = 0; i < values.length; i++)
      canvas.drawCircle(point(i), 3.2, dot);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.values.toString() != values.toString();
}
