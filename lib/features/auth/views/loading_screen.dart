import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Intro animation shown once when the KAISA app starts.
/// Set both image paths to match the files under assets/images/.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  static const Color _green = Color(0xFF087E58);
  static const Color _deepGreen = Color(0xFF03553E);
  static const Color _blue = Color(0xFF102F71);
  static const Color _yellow = Color(0xFFFFD642);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _continueToWelcome();
  }

  Future<void> _continueToWelcome() async {
    await Future<void>.delayed(const Duration(milliseconds: 2900));
    if (mounted) context.go('/welcome');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final narrow = size.width < 600;
    final logoSize = narrow ? 91.0 : 126.0;

    return Scaffold(
      backgroundColor: _green,
      body: SizedBox.expand(
        child: ClipRect(
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_deepGreen, _green, Color(0xFF0EA879)],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -size.width * .38,
                right: -size.width * .36,
                child: _GlowCircle(
                  diameter: math.max(size.width * .92, 300),
                  color: _yellow.withValues(alpha: .20),
                ),
              ),
              Positioned(
                bottom: -size.width * .52,
                left: -size.width * .3,
                child: _GlowCircle(
                  diameter: math.max(size.width, 400),
                  color: _blue.withValues(alpha: .60),
                ),
              ),
              Positioned(
                top: size.height * .14,
                left: -90,
                child: Transform.rotate(
                  angle: -.24,
                  child: Container(
                    width: narrow ? 170 : 280,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color: _yellow.withValues(alpha: .80),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -100,
                bottom: size.height * .17,
                child: Transform.rotate(
                  angle: -.24,
                  child: Container(
                    width: narrow ? 195 : 300,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color: _blue.withValues(alpha: .78),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _DotsPainter()),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 25,
                  ),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: _yellow,
                              ),
                            ),
                            const SizedBox(width: 9),
                            const Text(
                              'CAVITE CITY  •  KAISA',
                              style: TextStyle(
                                fontFamily: '',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          final phase = _controller.value;
                          return Transform.translate(
                            offset: Offset(0, -7 * math.sin(phase * math.pi)),
                            child: Transform.scale(
                              scale: .98 + .035 * phase,
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 21,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(35),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .35),
                                  width: 1.3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _deepGreen.withValues(alpha: .35),
                                    blurRadius: 35,
                                    offset: const Offset(0, 16),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _LogoTile(
                                    size: logoSize,
                                    assetPath: 'assets/images/lgu_seal.png',
                                    fallbackLabel: 'LGU\nSEAL',
                                  ),
                                  Container(
                                    width: 1,
                                    height: logoSize * .7,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    color: Colors.white.withValues(alpha: .35),
                                  ),
                                  _LogoTile(
                                    size: logoSize,
                                    assetPath: 'assets/images/kaisa_logo.png',
                                    fallbackLabel: 'KAISA\nLOGO',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 34),
                            Text(
                              'KAISA',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white,
                                fontSize: narrow ? 55 : 76,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 7,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 9),
                            const Text(
                              'CONNECT  •  PARTICIPATE  •  IMPACT',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: _yellow,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.6,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'One city. One community.\nStronger together.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white,
                                fontSize: 15,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: narrow ? 172 : 230,
                        child: Column(
                          children: [
                            AnimatedBuilder(
                              animation: _controller,
                              builder: (context, _) => LinearProgressIndicator(
                                value: .1 + .85 * _controller.value,
                                minHeight: 5,
                                borderRadius: BorderRadius.circular(20),
                                backgroundColor: Colors.white.withValues(
                                  alpha: .2,
                                ),
                                valueColor: const AlwaysStoppedAnimation(
                                  _yellow,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Bringing communities together',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoTile extends StatelessWidget {
  const _LogoTile({
    required this.size,
    required this.assetPath,
    required this.fallbackLabel,
  });

  final double size;
  final String assetPath;
  final String fallbackLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Center(
          child: Text(
            fallbackLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF102F71),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.diameter, required this.color});
  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: diameter,
    height: diameter,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class _DotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: .13);
    for (var row = 0; row < 11; row++) {
      for (var col = 0; col < 6; col++) {
        canvas.drawCircle(
          Offset(size.width - 23 - col * 21, 38 + row * 21),
          1.65,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
