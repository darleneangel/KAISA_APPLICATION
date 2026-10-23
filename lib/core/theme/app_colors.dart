import 'package:flutter/material.dart';

/// KAISA palette: forest greens + sun yellow.
/// Legacy aliases (blue*, greenLight...) are kept so existing screens compile.
class AppColors {
  AppColors._();

  // Greens
  static const forest = Color(0xFF115C43),
      deepForest = Color(0xFF083C32),
      green = Color(0xFF218957),
      greenDark = forest,
      lime = Color(0xFFB9DD65),
      limeDark = Color(0xFF83AB2E),
      mint = Color(0xFFE8F5E9),
      cream = Color(0xFFFFFCF5),
      navy = Color(0xFF17382F);

  // Depth tones used by the misty hero backdrop
  static const night = Color(0xFF052A22),
      canopy = Color(0xFF0B6B4D),
      sage = Color(0xFF9CC5A9);

  // Sun yellows
  static const yellow = Color(0xFFFFD34D),
      yellowDark = Color(0xFFE8AD20),
      yellowLight = Color(0xFFFFF4CC);

  // Neutrals (light mode)
  static const background = Color(0xFFF6F8F5),
      surface = Colors.white,
      surfaceSoft = Color(0xFFEEF3EF),
      textPrimary = Color(0xFF172E26),
      textSecondary = Color(0xFF65776C),
      textMuted = Color(0xFF84968B),
      border = Color(0xFFE0E9E1);

  // Legacy aliases
  static const blue = forest,
      blueDark = deepForest,
      blueLight = mint,
      greenLight = mint;

  // Semantic
  static const primary = forest,
      secondary = green,
      accent = yellow,
      success = green,
      warning = yellowDark,
      error = Color(0xFFD54848);

  // Gradients
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [deepForest, forest, green],
  );

  static const mistGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [night, deepForest, canopy],
  );

  static const sunGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE787), yellow, Color(0xFFFFC21F)],
  );
}

/// Theme-aware colors so every screen looks right in light AND dark mode.
/// Read with `context.kc`.
@immutable
class KaisaColors extends ThemeExtension<KaisaColors> {
  const KaisaColors({
    required this.page,
    required this.sheet,
    required this.card,
    required this.tile,
    required this.stroke,
    required this.ink,
    required this.inkSoft,
    required this.inkMuted,
    required this.brand,
    required this.onBrand,
    required this.accentSoft,
    required this.accentInk,
  });

  final Color page; // scaffold background
  final Color sheet; // white bottom-sheet / web panel
  final Color card; // raised cards
  final Color tile; // input fills, soft tiles
  final Color stroke; // borders and dividers
  final Color ink; // primary text
  final Color inkSoft; // secondary text
  final Color inkMuted; // hints
  final Color brand; // primary action colour
  final Color onBrand; // text/icons on brand
  final Color accentSoft; // soft yellow surface
  final Color accentInk; // text on accentSoft

  static const light = KaisaColors(
    page: AppColors.background,
    sheet: Colors.white,
    card: Colors.white,
    tile: Color(0xFFF1F6F2),
    stroke: AppColors.border,
    ink: AppColors.textPrimary,
    inkSoft: AppColors.textSecondary,
    inkMuted: AppColors.textMuted,
    brand: AppColors.forest,
    onBrand: Colors.white,
    accentSoft: AppColors.yellowLight,
    accentInk: Color(0xFF7A5600),
  );

  static const dark = KaisaColors(
    page: Color(0xFF111C19),
    sheet: Color(0xFF16241F),
    card: Color(0xFF1D3029),
    tile: Color(0xFF223A31),
    stroke: Color(0xFF3A574A),
    ink: Color(0xFFF2F8F2),
    inkSoft: Color(0xFFB5CBBE),
    inkMuted: Color(0xFF8CA397),
    brand: AppColors.lime,
    onBrand: AppColors.deepForest,
    accentSoft: Color(0x33FFD34D),
    accentInk: AppColors.yellow,
  );

  @override
  KaisaColors copyWith({
    Color? page,
    Color? sheet,
    Color? card,
    Color? tile,
    Color? stroke,
    Color? ink,
    Color? inkSoft,
    Color? inkMuted,
    Color? brand,
    Color? onBrand,
    Color? accentSoft,
    Color? accentInk,
  }) {
    return KaisaColors(
      page: page ?? this.page,
      sheet: sheet ?? this.sheet,
      card: card ?? this.card,
      tile: tile ?? this.tile,
      stroke: stroke ?? this.stroke,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      inkMuted: inkMuted ?? this.inkMuted,
      brand: brand ?? this.brand,
      onBrand: onBrand ?? this.onBrand,
      accentSoft: accentSoft ?? this.accentSoft,
      accentInk: accentInk ?? this.accentInk,
    );
  }

  @override
  KaisaColors lerp(ThemeExtension<KaisaColors>? other, double t) {
    if (other is! KaisaColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return KaisaColors(
      page: l(page, other.page),
      sheet: l(sheet, other.sheet),
      card: l(card, other.card),
      tile: l(tile, other.tile),
      stroke: l(stroke, other.stroke),
      ink: l(ink, other.ink),
      inkSoft: l(inkSoft, other.inkSoft),
      inkMuted: l(inkMuted, other.inkMuted),
      brand: l(brand, other.brand),
      onBrand: l(onBrand, other.onBrand),
      accentSoft: l(accentSoft, other.accentSoft),
      accentInk: l(accentInk, other.accentInk),
    );
  }
}

extension KaisaThemeContext on BuildContext {
  KaisaColors get kc {
    final theme = Theme.of(this);
    return theme.extension<KaisaColors>() ??
        (theme.brightness == Brightness.dark
            ? KaisaColors.dark
            : KaisaColors.light);
  }
}
