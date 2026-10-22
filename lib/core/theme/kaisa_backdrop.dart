import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Full-screen decorative green treatment shared by KAISA pages.
/// IgnorePointer ensures it never blocks forms, scrolling or navigation.
class KaisaBackdrop extends StatelessWidget {
  const KaisaBackdrop({super.key});
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, size) {
            final w = size.maxWidth;
            final h = size.maxHeight;
            return Stack(
              children: [
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF06392F),
                          Color(0xFF084B3B),
                          Color(0xFF0B7153),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -w * .22,
                  top: -w * .25,
                  child: _Ring(
                    size: math.max(280, w * .78),
                    color: const Color(0xFFC5ED89).withValues(alpha: .13),
                  ),
                ),
                Positioned(
                  left: -w * .33,
                  bottom: -w * .34,
                  child: _Ring(
                    size: math.max(290, w * .95),
                    color: const Color(0xFF61CBA1).withValues(alpha: .10),
                  ),
                ),
                Positioned(
                  top: h * .17,
                  left: -85,
                  child: Transform.rotate(
                    angle: -.25,
                    child: Container(
                      width: 190,
                      height: 27,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC5ED89).withValues(alpha: .13),
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: h * .22,
                  right: -95,
                  child: Transform.rotate(
                    angle: -.25,
                    child: Container(
                      width: 220,
                      height: 35,
                      decoration: BoxDecoration(
                        color: const Color(0xFF123C6A).withValues(alpha: .22),
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(child: CustomPaint(painter: _DotPattern())),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  final double size;
  final Color color;
  const _Ring({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: color, width: 42),
    ),
  );
}

class _DotPattern extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC5ED89).withValues(alpha: .12);
    for (double x = 28; x < size.width; x += 58) {
      for (double y = 36; y < size.height; y += 72) {
        canvas.drawCircle(Offset(x, y), 1.3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
