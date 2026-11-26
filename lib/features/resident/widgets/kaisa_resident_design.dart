import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' show FontFeature;

/// One source of truth for shared resident-page styling.
abstract final class KaisaResidentDesign {
  static const forest = Color(0xFF00492C);
  static const green = Color(0xFF176B43);
  static const yellow = Color(0xFFFBBA16);
  static const paper = Color(0xFFF8F9FA);
  static const ink = Color(0xFF1F2937);
  static const muted = Color(0xFF6B7280);
  static const border = Color(0xFFE5E7EB);
  static const mint = Color(0xFFE7F2EC);
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00492C), Color(0xFF00301B)],
  );
  static const double desktopWidth = 1180;
  static const double cardRadius = 12;
  static const double cardPadding = 18;
  static const double iconSize = 22;

  static double pagePadding(double width) => width < 600 ? 18 : 32;

  static BoxDecoration cardDecoration() => BoxDecoration(
    color: Colors.white,
    border: Border.all(color: border),
    borderRadius: BorderRadius.circular(cardRadius),
    boxShadow: const [
      BoxShadow(color: Color(0x09000000), blurRadius: 8, offset: Offset(0, 2)),
    ],
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
        style: KaisaTypography.heading(
          TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -.4,
            color: KaisaResidentDesign.ink,
          ),
        ),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 4),
        Text(
          subtitle!,
          style: KaisaTypography.body(
            TextStyle(
              fontSize: 13,
              color: KaisaResidentDesign.muted,
              height: 1.4,
            ),
          ),
        ),
      ],
    ],
  );
}

abstract final class KaisaTypography {
  static TextStyle heading(TextStyle style) => style.copyWith(
    fontFamily: GoogleFonts.outfit(
      fontWeight: style.fontWeight ?? FontWeight.w600,
    ).fontFamily,
    fontWeight: style.fontWeight ?? FontWeight.w600,
  );
  static TextStyle body(TextStyle style) => style.copyWith(
    fontFamily: GoogleFonts.plusJakartaSans(
      fontWeight: style.fontWeight ?? FontWeight.w400,
    ).fontFamily,
    fontWeight: style.fontWeight ?? FontWeight.w400,
  );
  static TextStyle data(TextStyle style) => style.copyWith(
    fontFamily: GoogleFonts.inter(
      fontWeight: style.fontWeight ?? FontWeight.w400,
    ).fontFamily,
    fontWeight: style.fontWeight ?? FontWeight.w400,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  static ThemeData homeTheme(BuildContext context) {
    final base = Theme.of(context);
    final ui = base.textTheme.apply(
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    );
    TextStyle heading(TextStyle? original, double size, FontWeight weight) =>
        (original ?? const TextStyle()).copyWith(
          fontFamily: GoogleFonts.outfit(fontWeight: weight).fontFamily,
          fontSize: size,
          fontWeight: weight,
          height: 1.2,
          letterSpacing: -.25,
        );
    TextStyle body(TextStyle? original, double size, FontWeight weight) =>
        (original ?? const TextStyle()).copyWith(
          fontFamily: GoogleFonts.plusJakartaSans(
            fontWeight: weight,
          ).fontFamily,
          fontSize: size,
          fontWeight: weight,
          height: 1.5,
        );
    final residentText = ui.copyWith(
      displayLarge: heading(ui.displayLarge, 48, FontWeight.w700),
      displayMedium: heading(ui.displayMedium, 36, FontWeight.w700),
      displaySmall: heading(ui.displaySmall, 32, FontWeight.w600),
      headlineLarge: heading(ui.headlineLarge, 32, FontWeight.w600),
      headlineMedium: heading(ui.headlineMedium, 24, FontWeight.w600),
      headlineSmall: heading(ui.headlineSmall, 20, FontWeight.w600),
      titleLarge: heading(ui.titleLarge, 20, FontWeight.w600),
      titleMedium: heading(ui.titleMedium, 16, FontWeight.w600),
      titleSmall: heading(ui.titleSmall, 14, FontWeight.w600),
      bodyLarge: body(ui.bodyLarge, 16, FontWeight.w400),
      bodyMedium: body(ui.bodyMedium, 14, FontWeight.w400),
      bodySmall: body(ui.bodySmall, 12, FontWeight.w400),
      labelLarge: body(ui.labelLarge, 14, FontWeight.w600),
      labelMedium: body(ui.labelMedium, 12, FontWeight.w500),
      labelSmall: body(ui.labelSmall, 11, FontWeight.w600),
    );
    return base.copyWith(
      textTheme: residentText,
      primaryTextTheme: base.primaryTextTheme.apply(
        fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      ),
    );
  }

  static ThemeData theme(BuildContext context) {
    final base = Theme.of(context);
    final ui = base.textTheme.apply(
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    );
    TextStyle h(TextStyle? s) =>
        heading(s ?? const TextStyle(fontWeight: FontWeight.w600));
    TextStyle b(TextStyle? s) => body(s ?? const TextStyle());
    return base.copyWith(
      textTheme: ui.copyWith(
        displayLarge: h(ui.displayLarge),
        displayMedium: h(ui.displayMedium),
        displaySmall: h(ui.displaySmall),
        headlineLarge: h(ui.headlineLarge),
        headlineMedium: h(ui.headlineMedium),
        headlineSmall: h(ui.headlineSmall),
        titleLarge: h(ui.titleLarge),
        titleMedium: h(ui.titleMedium),
        titleSmall: h(ui.titleSmall),
        bodyLarge: b(ui.bodyLarge),
        bodyMedium: b(ui.bodyMedium),
        bodySmall: b(ui.bodySmall),
        labelLarge: b(ui.labelLarge),
        labelMedium: b(ui.labelMedium),
        labelSmall: b(ui.labelSmall),
      ),
      primaryTextTheme: base.primaryTextTheme.apply(
        fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      ),
    );
  }
}
