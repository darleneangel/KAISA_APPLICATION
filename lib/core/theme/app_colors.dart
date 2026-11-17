import 'package:flutter/material.dart';

/// KAISA palette: Premium emerald greens + vibrant sun yellows.
/// Modernized for high contrast, deep dark-mode layering, and punchy accents.
/// Legacy aliases (blue*, greenLight...) are kept so existing screens compile.
class AppColors {
  AppColors._();

  // Greens - Shifted to rich emerald and electric lime tones for a premium feel
  static const forest =
          Color(0xFF0A5C45), // Vibrant, clean emerald
      deepForest =
          Color(0xFF042B21), // Ultra-deep contrast
      green =
          Color(0xFF138A62), // Active, bright green
      greenDark = forest,
      lime =
          Color(0xFFC5F279), // Trendy electric chartreuse
      limeDark = Color(0xFF94C742),
      mint =
          Color(0xFFE6F7F1), // Crisper, cooler mint
      cream =
          Color(0xFFFDFBF7), // Warmer, elegant off-white
      navy = Color(0xFF0C2B29); // Deep slate/teal

  // Depth tones used by the misty hero backdrop
  static const night =
          Color(0xFF021C15), // Near-black pine
      canopy =
          Color(0xFF0B7555), // Rich mid-tone
      sage = Color(0xFF87BCA2); // Soft, modern sage

  // Sun yellows - Warmed up for better contrast and glow
  static const yellow =
          Color(0xFFFFC837), // Punchy, golden yellow
      yellowDark =
          Color(0xFFE6A700), // Rich amber
      yellowLight = Color(0xFFFFF6D6); // Soft pastel glow

  // Neutrals (light mode) - Cooler off-whites for a cleaner, spacious look
  static const background = Color(0xFFF4F7F5),
      surface = Colors.white,
      surfaceSoft = Color(0xFFEBF0EC),
      textPrimary =
          Color(0xFF0F1F18), // Deep green-tinted black (softer than pure black)
      textSecondary = Color(0xFF556B60),
      textMuted = Color(0xFF899E93),
      border = Color(0xFFD7E3DA);

  // Legacy aliases (Preserved)
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
      error = Color(0xFFFF4D4D); // Modern, slightly coral red

  // Gradients - Adjusted for smoother, richer transitions
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
    colors: [Color(0xFFFFDF70), yellow, Color(0xFFFFB000)],
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
    tile: Color(0xFFF7FAF8), // Airy, almost-white tile fill
    stroke: AppColors.border,
    ink: AppColors.textPrimary,
    inkSoft: AppColors.textSecondary,
    inkMuted: AppColors.textMuted,
    brand: AppColors.forest,
    onBrand: Colors.white,
    accentSoft: AppColors.yellowLight,
    accentInk: Color(0xFF755200), // Deep bronze for sharp readability
  );

  static const dark = KaisaColors(
    page: Color(0xFF07100D), // Ultra-deep midnight pine
    sheet: Color(0xFF0E1A16), // Slightly elevated
    card: Color(0xFF13241E), // Card elevation
    tile: Color(0xFF1A2F27), // Interactive elements
    stroke: Color(0xFF2A453A), // Subtle structural borders
    ink: Color(0xFFF0F5F2), // Soft off-white to prevent eye strain
    inkSoft: Color(0xFFA3BDAF), // Muted minty grey
    inkMuted: Color(0xFF6D8579),
    brand: AppColors.lime, // Electric neon pop in dark mode
    onBrand: AppColors.deepForest, // Striking dark text on neon button
    accentSoft: Color(0x26FFC837), // 15% opacity warm yellow
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
