import 'package:flutter/material.dart';

/// One source of truth for shared resident-page styling.
abstract final class KaisaResidentDesign {
  static const forest = Color(0xFF14532D);
  static const green = Color(0xFF237A50);
  static const yellow = Color(0xFFFBC02D);
  static const paper = Color(0xFFF8FAF8);
  static const ink = Color(0xFF173D2B);
  static const muted = Color(0xFF687B70);
  static const border = Color(0xFFE2EBE4);
  static const double desktopWidth = 1180;
  static const double cardRadius = 20;
  static const double cardPadding = 18;
  static const double iconSize = 22;

  static double pagePadding(double width) => width < 600 ? 18 : 32;

  static BoxDecoration cardDecoration() => BoxDecoration(
    color: Colors.white,
    border: Border.all(color: border),
    borderRadius: BorderRadius.circular(cardRadius),
  );
}

class KaisaResidentCard extends StatelessWidget {
  const KaisaResidentCard({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? const EdgeInsets.all(KaisaResidentDesign.cardPadding),
    decoration: KaisaResidentDesign.cardDecoration(),
    child: child,
  );
}

class KaisaResidentSectionHeading extends StatelessWidget {
  const KaisaResidentSectionHeading({
    super.key,
    required this.title,
    this.subtitle,
  });
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -.4,
          color: KaisaResidentDesign.ink,
        ),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 4),
        Text(
          subtitle!,
          style: const TextStyle(
            fontSize: 13,
            color: KaisaResidentDesign.muted,
            height: 1.4,
          ),
        ),
      ],
    ],
  );
}
