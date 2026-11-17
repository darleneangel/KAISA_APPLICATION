import 'package:flutter/material.dart';

/// KAISA palette — Cavite City LGU identity.
/// Forest Depth (#00492C) for structure + Golden Pulse (#FBBA16) for action.
/// Warm stone canvas (#F4F4F0) instead of stark white.
/// Legacy aliases (blue*, greenLight, lime...) are kept so existing screens compile.
class AppColors {
  AppColors._();

  // ── Core brand ──────────────────────────────────────────────
  static const forest = Color(0xFF00492C); // Forest Depth
  static const deepForest = Color(0xFF00331F);
  static const green = Color(0xFF1F8A5B); // success / positive
  static const greenDark = forest;
  static const sage = Color(0xFF7AA895); // chart secondary stroke
  static const sageTrack = Color(0xFFE3EDE7); // pale ring / bar track
  static const mint = Color(0xFFE8F1EC);
  static const cream = Color(0xFFF4F4F0); // warm stone canvas
  static const lime = Color(0xFFD9EBB5); // legacy: soft sage-lime
  static const limeDark = Color(0xFF9CC25A);
  static const navy = Color(0xFF0C2B20);
  static const night = Color(0xFF00251A);
  static const canopy = Color(0xFF0B6B45);

  // ── Golden Pulse ────────────────────────────────────────────
  static const yellow = Color(0xFFFBBA16);
  static const yellowDark = Color(0xFFD99A00);
  static const yellowLight = Color(0xFFFFF3CF);

  // ── Neutrals (light) ────────────────────────────────────────
  static const background = Color(0xFFF4F4F0);
  static const surface = Colors.white;
  static const surfaceSoft = Color(0xFFF4F4F0);
  static const textPrimary = Color(0xFF0E3A27);
  static const textSecondary = Color(0xFF6E7773);
  static const textMuted = Color(0xFF9AA19D);
  static const border = Color(0xFFECECE6); // hairline

  // ── Legacy aliases ──────────────────────────────────────────
  static const blue = forest,
      blueDark = deepForest,
      blueLight = mint,
      greenLight = mint;

  // ── Semantic ────────────────────────────────────────────────
  static const primary = forest,
      secondary = green,
      accent = yellow,
      success = green,
      warning = yellowDark,
      error = Color(0xFFE5484D);

  // ── Pastel status tints (pills, icon badges) ────────────────
  static const tintGreen = Color(0xFFE3F1E9);
  static const tintYellow = Color(0xFFFFF3CF);
  static const tintBlue = Color(0xFFE4ECF8);
  static const tintRed = Color(0xFFFBE4E4);

  // ── Gradients ───────────────────────────────────────────────
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [deepForest, forest, Color(0xFF0A5C3B)],
  );

  static const mistGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [night, deepForest, forest],
  );

  static const sunGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD461), yellow, Color(0xFFF0A500)],
  );

  /// Auth backdrop: warm cream → pale sage.
  static const authGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF7F4EA), Color(0xFFE3EDE7)],
  );
}

/// Theme-aware colors. Read with `context.kc`.
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
    this.accent = AppColors.yellow,
    this.onAccent = AppColors.forest,
    this.deep = AppColors.forest,
  });

  final Color page; // scaffold background (warm stone)
  final Color sheet; // bottom sheets, sidebar, dialogs
  final Color card; // raised cards
  final Color tile; // input fills, soft tiles
  final Color stroke; // hairline borders
  final Color ink; // primary text
  final Color inkSoft; // secondary text
  final Color inkMuted; // hints
  final Color brand; // primary action (forest in light)
  final Color onBrand;
  final Color accentSoft; // soft yellow surface
  final Color accentInk; // text on accentSoft
  final Color accent; // Golden Pulse — CTAs, stars, highlights
  final Color onAccent; // text on accent
  final Color deep; // solid dark feature cards

  static const light = KaisaColors(
    page: AppColors.background,
    sheet: Colors.white,
    card: Colors.white,
    tile: Color(0xFFF4F4F0),
    stroke: AppColors.border,
    ink: AppColors.textPrimary,
    inkSoft: AppColors.textSecondary,
    inkMuted: AppColors.textMuted,
    brand: AppColors.forest,
    onBrand: Colors.white,
    accentSoft: AppColors.yellowLight,
    accentInk: Color(0xFF7A5600),
    accent: AppColors.yellow,
    onAccent: AppColors.forest,
    deep: AppColors.forest,
  );

  static const dark = KaisaColors(
    page: Color(0xFF0A1511),
    sheet: Color(0xFF0F1D17),
    card: Color(0xFF13241C),
    tile: Color(0xFF1B2F26),
    stroke: Color(0xFF28443A),
    ink: Color(0xFFF0F4F1),
    inkSoft: Color(0xFFA3B8AD),
    inkMuted: Color(0xFF6F867A),
    brand: AppColors.yellow, // golden pulse carries actions in dark mode
    onBrand: AppColors.deepForest,
    accentSoft: Color(0x26FBBA16),
    accentInk: AppColors.yellow,
    accent: AppColors.yellow,
    onAccent: AppColors.deepForest,
    deep: Color(0xFF0A4A30),
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
    Color? accent,
    Color? onAccent,
    Color? deep,
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
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      deep: deep ?? this.deep,
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
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      deep: l(deep, other.deep),
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
