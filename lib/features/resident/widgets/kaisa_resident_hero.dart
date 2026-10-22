import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

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
        final t = Curves.easeInOut.transform(_animation.value);
        return Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F7555), Color(0xFF074634), Color(0xFF053A30)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: .18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .17),
                blurRadius: 22,
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
                      color: AppColors.lime.withValues(alpha: .14),
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
                      color: const Color(0xFF286EAA).withValues(alpha: .30),
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
                      color: AppColors.lime,
                      borderRadius: BorderRadius.circular(27),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.lime.withValues(alpha: .22),
                          blurRadius: 18,
                          offset: const Offset(0, 9),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon,
                      color: AppColors.deepForest,
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
                          color: AppColors.lime,
                          size: 8,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.eyebrow.toUpperCase(),
                            maxLines: 2,
                            style: const TextStyle(
                              color: AppColors.lime,
                              fontSize: 10,
                              letterSpacing: 1.3,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        height: 1.13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.6,
                      ),
                    ),
                    const SizedBox(height: 11),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        color: AppColors.mint,
                        fontSize: 12,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
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
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .18),
                          ),
                        ),
                        child: Text(
                          widget.chip!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
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
