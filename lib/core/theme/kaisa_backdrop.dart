import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Misty green treatment shared by KAISA hero areas: deep gradient, a warm
/// sun glow, soft rings, layered ridges that fade into the mist, and a dot grid.
/// Modernized with glassy edges, ambient glows, and fading grid masks.
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
                // Warm sun glow, top right (Expanded for smoother ambient light)
                Positioned(
                  right: -w * .25,
                  top: -w * .30,
                  child: _Glow(size: math.max(380, w * 1.0)),
                ),
                // Modern ambient ring, bottom left
                Positioned(
                  left: -w * .25,
                  bottom: -w * .25,
                  child: _Ring(
                    size: math.max(280, w * .85),
                    color: AppColors.lime,
                  ),
                ),
                // Accent pills (Upgraded to floating gradient capsules)
                Positioned(
                  top: h * .16,
                  left: -60,
                  child: _Pill(
                    width: 190,
                    height: 24,
                    color1: AppColors.yellow.withValues(alpha: .25),
                    color2: AppColors.yellow.withValues(alpha: .05),
                  ),
                ),
                Positioned(
                  top: h * .3,
                  right: -50,
                  child: _Pill(
                    width: 150,
                    height: 18,
                    color1: AppColors.lime.withValues(alpha: .15),
                    color2: AppColors.lime.withValues(alpha: .0),
                  ),
                ),
                if (hills)
                  Positioned.fill(
                    child: CustomPaint(painter: _RidgePainter(hillsBase)),
                  ),
                // Fading dot grid overlay
                const Positioned.fill(child: CustomPaint(painter: _Dots())),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Upgraded Sun Glow: Uses more stops for a buttery-smooth light falloff.
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
          AppColors.yellow.withValues(alpha: .40),
          AppColors.yellow.withValues(alpha: .20),
          AppColors.yellow.withValues(alpha: .05),
          AppColors.yellow.withValues(alpha: 0),
        ],
        stops: const [0, 0.3, 0.6, 1],
      ),
    ),
  );
}

/// Upgraded Ring: Replaced thick chunky border with a sleek, thin border
/// and an outer blurred glow for a high-end ambient feel.
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
      border: Border.all(
        color: color.withValues(alpha: 0.15),
        width: 1.5, // Crisp thin edge
      ),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.05),
          blurRadius: 40,
          spreadRadius: 20,
        ),
      ],
    ),
  );
}

/// Upgraded Pill: Uses linear gradients to look like floating glass orbs
class _Pill extends StatelessWidget {
  const _Pill({
    required this.width,
    required this.height,
    required this.color1,
    required this.color2,
  });
  final double width, height;
  final Color color1, color2;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: -.25,
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: color1.withValues(alpha: 0.1),
            blurRadius: 16,
            spreadRadius: 4,
          ),
        ],
      ),
    ),
  );
}

class _Layer {
  const _Layer(this.offset, this.amp, this.freq, this.phase, this.color);
  final double offset, amp, freq, phase;
  final Color color;
}

/// Upgraded Ridge Painter: Adds a crisp, semi-transparent "glass" stroke
/// to the top edge of each wave, giving the mountains rich dimension and depth.
class _RidgePainter extends CustomPainter {
  _RidgePainter(this.base);
  final double base;

  @override
  void paint(Canvas canvas, Size size) {
    final layers = [
      _Layer(0, .035, 1.2, .6, AppColors.lime.withValues(alpha: .18)),
      _Layer(.07, .04, 1.0, 2.2, Colors.white.withValues(alpha: .12)),
      _Layer(.14, .04, 1.5, 4.1, AppColors.night.withValues(alpha: .55)),
    ];

    for (final l in layers) {
      final top = base + l.offset;
      final path = Path()..moveTo(0, size.height);

      // Build the wave
      for (double x = 0; x <= size.width + 6; x += 6) {
        final t = x / size.width * math.pi * 2;
        final y =
            size.height *
            (top +
                l.amp * math.sin(t * l.freq + l.phase) +
                l.amp * .45 * math.sin(t * l.freq * 2.3 + l.phase * 1.7));
        path.lineTo(x, y);
      }

      // Save the top edge for stroking later
      final topEdgePath = Path.from(path);

      // Close the path for the fill
      path
        ..lineTo(size.width, size.height)
        ..close();

      final rect = Rect.fromLTRB(0, size.height * top, size.width, size.height);

      // 1. Draw the fading fill
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [l.color, l.color.withValues(alpha: 0)],
        ).createShader(rect);
      canvas.drawPath(path, fillPaint);

      // 2. Draw the crisp top highlight (Glass edge effect)
      // This single addition makes it look 10x more modern
      final strokePaint = Paint()
        ..color = l.color.withValues(alpha: (l.color.a * 1.5).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawPath(topEdgePath, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RidgePainter old) => old.base != base;
}

/// Upgraded Dots: Applies a shader to the dots so they organically fade out
/// towards the bottom, reducing clutter while keeping the high-tech texture.
class _Dots extends CustomPainter {
  const _Dots();

  @override
  void paint(Canvas canvas, Size size) {
    // Gradient shader makes dots disappear gracefully down the screen
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.lime.withValues(alpha: .18),
          AppColors.lime.withValues(alpha: .0),
        ],
        stops: const [0.0, 0.7], // Fully faded out by 70% of the screen
      ).createShader(rect);

    // Slightly tightened the grid for a more refined tech-texture look
    for (double x = 24; x < size.width; x += 48) {
      for (double y = 32; y < size.height; y += 48) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
