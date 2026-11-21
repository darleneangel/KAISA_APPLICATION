import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Forest Depth hero treatment: a deep green gradient, a soft golden glow,
/// and Golden Pulse light streaks rising from the bottom edge.
/// Same constructor as before, so existing screens keep working:
///  - [hills] now toggles the golden light streaks
///  - [hillsBase] controls how tall they rise (lower value = taller)
/// IgnorePointer ensures it never blocks forms, scrolling or navigation.
class KaisaBackdrop extends StatelessWidget {
  const KaisaBackdrop({super.key, this.hillsBase = .78, this.hills = true});

  final double hillsBase;
  final bool hills;

  // x position (fraction of width), height (fraction of height), width (px)
  static const _streaks = <List<double>>[
    [.10, .30, 10],
    [.28, .46, 18],
    [.50, .36, 8],
    [.68, .56, 20],
    [.88, .32, 12],
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, c) {
            final screen = MediaQuery.sizeOf(context);
            final w = c.hasBoundedWidth ? c.maxWidth : screen.width;
            final h = c.hasBoundedHeight ? c.maxHeight : screen.height;
            final rise = ((1 - hillsBase) / .22).clamp(.4, 2.0);

            return Stack(
              children: [
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: AppColors.heroGradient),
                  ),
                ),
                // Soft sage ring, top right
                Positioned(
                  right: -w * .35,
                  top: -w * .35,
                  child: _Ring(size: math.max(320, w * 1.0)),
                ),
                // Golden glow rising from the bottom
                Positioned(
                  left: -w * .2,
                  right: -w * .2,
                  bottom: -h * .25,
                  child: _Glow(size: math.max(360, w * 1.2)),
                ),
                if (hills)
                  for (final s in _streaks)
                    Positioned(
                      left: w * s[0] - s[2] / 2,
                      bottom: 0,
                      child: _Streak(
                        width: s[2],
                        height: (h * s[1] * rise).clamp(40.0, h * .8),
                      ),
                    ),
                const Positioned.fill(child: CustomPaint(painter: _Dots())),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: size,
      height: size * .6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.yellow.withValues(alpha: .28),
            AppColors.yellow.withValues(alpha: .10),
            AppColors.yellow.withValues(alpha: 0),
          ],
          stops: const [0, .45, 1],
        ),
      ),
    ),
  );
}

class _Ring extends StatelessWidget {
  const _Ring({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.white.withValues(alpha: .18),
        width: 1.2,
      ),
    ),
  );
}

/// A single vertical golden light streak with a soft glow.
class _Streak extends StatelessWidget {
  const _Streak({required this.width, required this.height});
  final double width, height;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.vertical(top: Radius.circular(width)),
      gradient: LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          AppColors.yellow.withValues(alpha: .55),
          AppColors.yellow.withValues(alpha: .18),
          AppColors.yellow.withValues(alpha: 0),
        ],
        stops: const [0, .55, 1],
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.yellow.withValues(alpha: .18),
          blurRadius: 28,
          spreadRadius: 2,
        ),
      ],
    ),
  );
}

/// Fading dot grid, so the texture disappears towards the bottom.
class _Dots extends CustomPainter {
  const _Dots();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: .22),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0, .6],
      ).createShader(rect);

    for (double x = 24; x < size.width; x += 48) {
      for (double y = 32; y < size.height; y += 48) {
        canvas.drawCircle(Offset(x, y), 1.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
