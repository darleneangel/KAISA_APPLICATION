import 'dart:math' as math;
import 'kaisa_resident_design.dart';
import 'package:flutter/material.dart';

/// A reusable illustrated header for resident screens. All artwork is drawn
/// using Flutter widgets; no new image assets or dependencies are required.
class KaisaResidentHero extends StatefulWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final String? chip;
  const KaisaResidentHero({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.chip,
  });
  @override
  State<KaisaResidentHero> createState() => _KaisaResidentHeroState();
}

class _KaisaResidentHeroState extends State<KaisaResidentHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final t = MediaQuery.disableAnimationsOf(context)
            ? 0.0
            : Curves.easeInOut.transform(_animation.value);
        return Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF00492C), Color(0xFF00301B)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: .18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .07),
                blurRadius: 8,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -57,
                top: -67,
                child: Container(
                  width: 225,
                  height: 225,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      width: 34,
                      color: KaisaResidentDesign.yellow.withValues(alpha: .14),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -60,
                bottom: -28,
                child: Transform.rotate(
                  angle: -.34,
                  child: Container(
                    width: 220,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF286EAA).withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(60),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                top: 36 + 8 * math.sin(t * math.pi * 2),
                child: Transform.rotate(
                  angle: -.13 + .08 * t,
                  child: Container(
                    width: 87,
                    height: 87,
                    decoration: BoxDecoration(
                      color: KaisaResidentDesign.yellow,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: KaisaResidentDesign.yellow.withValues(
                            alpha: .22,
                          ),
                          blurRadius: 18,
                          offset: const Offset(0, 9),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon,
                      color: const Color(0xFF00301B),
                      size: 43,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 25, 116, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.circle,
                          color: KaisaResidentDesign.yellow,
                          size: 8,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.eyebrow.toUpperCase(),
                            maxLines: 2,
                            style: KaisaTypography.body(
                              TextStyle(
                                color: KaisaResidentDesign.yellow,
                                fontSize: 10,
                                letterSpacing: 1.3,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    Text(
                      widget.title,
                      style: KaisaTypography.heading(
                        TextStyle(
                          color: Colors.white,
                          fontSize: MediaQuery.sizeOf(context).width < 380
                              ? 23
                              : 28,
                          height: 1.13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 11),
                    Text(
                      widget.subtitle,
                      style: KaisaTypography.body(
                        TextStyle(
                          color: const Color(0xFFE7F2EC),
                          fontSize: 13,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (widget.chip != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .13),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .18),
                          ),
                        ),
                        child: Text(
                          widget.chip!,
                          style: KaisaTypography.body(
                            TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
