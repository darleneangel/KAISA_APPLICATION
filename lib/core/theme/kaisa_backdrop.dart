import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Misty green treatment shared by KAISA hero areas: deep gradient, a warm
/// sun glow, soft rings, layered ridges that fade into the mist, and a dot grid.
/// IgnorePointer ensures it never blocks forms, scrolling or navigation.
class KaisaBackdrop extends StatelessWidget {
  const KaisaBackdrop({super.key, this.hillsBase = .78, this.hills = true});

  /// Where the first ridge starts, as a fraction of the height (0 = top).
  final double hillsBase;
  final bool hills;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, c) {
            final screen = MediaQuery.sizeOf(context);
            final w = c.hasBoundedWidth ? c.maxWidth : screen.width;
            final h = c.hasBoundedHeight ? c.maxHeight : screen.height;
            return Stack(
              children: [
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: AppColors.mistGradient),
                  ),
                ),
                // Warm sun glow, top right
                Positioned(
                  right: -w * .22,
                  top: -w * .26,
                  child: _Glow(size: math.max(320, w * .85)),
                ),
                // Soft ring, bottom left
                Positioned(
                  left: -w * .3,
                  bottom: -w * .34,
                  child: _Ring(
                    size: math.max(280, w * .9),
                    color: AppColors.lime.withValues(alpha: .08),
                  ),
                ),
                // Accent pills
                Positioned(
                  top: h * .16,
                  left: -80,
                  child: _Pill(
                    width: 190,
                    height: 26,
                    color: AppColors.yellow.withValues(alpha: .16),
                  ),
                ),
                Positioned(
                  top: h * .3,
                  right: -70,
                  child: _Pill(
                    width: 150,
                    height: 20,
                    color: AppColors.lime.withValues(alpha: .10),
                  ),
                ),
                if (hills)
                  Positioned.fill(
                    child: CustomPaint(painter: _RidgePainter(hillsBase)),
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
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          AppColors.yellow.withValues(alpha: .30),
          AppColors.yellow.withValues(alpha: .08),
          AppColors.yellow.withValues(alpha: 0),
        ],
        stops: const [0, .45, 1],
      ),
    ),
  );
}

class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.color});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: color, width: 38),
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.width, required this.height, required this.color});
  final double width, height;
  final Color color;
  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: -.25,
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(50),
      ),
    ),
  );
}

class _Layer {
  const _Layer(this.offset, this.amp, this.freq, this.phase, this.color);
  final double offset, amp, freq, phase;
  final Color color;
}

/// Layered ridges that fade into the mist, like the misty mountains in the
/// reference, but in KAISA greens.
class _RidgePainter extends CustomPainter {
  _RidgePainter(this.base);
  final double base;

  @override
  void paint(Canvas canvas, Size size) {
    final layers = [
      _Layer(0, .035, 1.2, .6, AppColors.lime.withValues(alpha: .13)),
      _Layer(.07, .04, 1.0, 2.2, Colors.white.withValues(alpha: .08)),
      _Layer(.14, .04, 1.5, 4.1, AppColors.night.withValues(alpha: .45)),
    ];
    for (final l in layers) {
      final top = base + l.offset;
      final path = Path()..moveTo(0, size.height);
      for (double x = 0; x <= size.width + 6; x += 6) {
        final t = x / size.width * math.pi * 2;
        final y =
            size.height *
            (top +
                l.amp * math.sin(t * l.freq + l.phase) +
                l.amp * .45 * math.sin(t * l.freq * 2.3 + l.phase * 1.7));
        path.lineTo(x, y);
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      final rect = Rect.fromLTRB(0, size.height * top, size.width, size.height);
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [l.color, l.color.withValues(alpha: 0)],
        ).createShader(rect);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RidgePainter old) => old.base != base;
}

class _Dots extends CustomPainter {
  const _Dots();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.lime.withValues(alpha: .12);
    for (double x = 28; x < size.width; x += 58) {
      for (double y = 36; y < size.height; y += 72) {
        canvas.drawCircle(Offset(x, y), 1.3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
