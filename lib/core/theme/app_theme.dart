import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// One builder for both modes.
/// Typography: Poppins (headings, numerals) + Inter (body, labels, tables).
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final kc = dark ? KaisaColors.dark : KaisaColors.light;
    final base = ThemeData(useMaterial3: true, brightness: brightness);

    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.forest,
          brightness: brightness,
        ).copyWith(
          primary: kc.brand,
          onPrimary: kc.onBrand,
          secondary: AppColors.yellow,
          onSecondary: AppColors.forest,
          surface: kc.card,
          onSurface: kc.ink,
          onSurfaceVariant: kc.inkSoft,
          surfaceContainerHighest: kc.tile,
          outline: kc.stroke,
          outlineVariant: kc.stroke,
          error: AppColors.error,
        );

    // Headings are Forest Depth in light mode, soft white in dark.
    final headColor = dark ? kc.ink : AppColors.forest;

    TextStyle poppins(TextStyle? s, FontWeight w, {double ls = 0, double? h}) =>
        GoogleFonts.poppins(
          textStyle: s,
          fontWeight: w,
          letterSpacing: ls,
          height: h,
          color: headColor,
        );

    final inter = GoogleFonts.interTextTheme(
      base.textTheme,
    ).apply(bodyColor: kc.ink, displayColor: kc.ink);

    final textTheme = inter.copyWith(
      displayLarge: poppins(
        inter.displayLarge,
        FontWeight.w700,
        ls: -1.2,
        h: 1.1,
      ),
      displayMedium: poppins(
        inter.displayMedium,
        FontWeight.w700,
        ls: -1.0,
        h: 1.1,
      ),
      displaySmall: poppins(
        inter.displaySmall,
        FontWeight.w700,
        ls: -0.8,
        h: 1.15,
      ),
      headlineLarge: poppins(
        inter.headlineLarge,
        FontWeight.w700,
        ls: -0.6,
        h: 1.15,
      ),
      headlineMedium: poppins(
        inter.headlineMedium,
        FontWeight.w600,
        ls: -0.4,
        h: 1.2,
      ),
      headlineSmall: poppins(
        inter.headlineSmall,
        FontWeight.w600,
        ls: -0.3,
        h: 1.25,
      ),
      titleLarge: poppins(inter.titleLarge, FontWeight.w600, ls: -0.2),
      titleMedium: poppins(inter.titleMedium, FontWeight.w600, ls: -0.1),
      titleSmall: inter.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: inter.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: inter.labelMedium?.copyWith(fontWeight: FontWeight.w500),
      bodyLarge: inter.bodyLarge?.copyWith(height: 1.55),
      bodyMedium: inter.bodyMedium?.copyWith(height: 1.5),
      bodySmall: inter.bodySmall?.copyWith(color: kc.inkSoft, height: 1.45),
    );

    const pill = StadiumBorder();

    final buttonText = GoogleFonts.poppins(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    );

    OutlineInputBorder inputBorder(Color color, [double width = 1.0]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: kc.page,
      canvasColor: kc.card,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: textTheme,
      primaryTextTheme: GoogleFonts.interTextTheme(
        base.primaryTextTheme,
      ).apply(bodyColor: kc.ink, displayColor: kc.ink),
      extensions: [kc],

      // App bar: borderless, blends with the stone canvas
      appBarTheme: AppBarTheme(
        backgroundColor: kc.page,
        foregroundColor: kc.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: headColor,
        ),
        iconTheme: IconThemeData(color: kc.ink, size: 22),
      ),

      // Cards: white, 24px radius, hairline border (soft shadow lives in KaisaCard)
      cardTheme: CardThemeData(
        color: kc.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: kc.stroke),
        ),
      ),

      // Buttons: stadium pills
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: kc.brand,
          foregroundColor: kc.onBrand,
          elevation: 0,
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kc.brand,
          foregroundColor: kc.onBrand,
          elevation: 0,
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: kc.ink,
          backgroundColor: kc.card,
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          side: BorderSide(color: kc.stroke, width: 1.2),
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: dark ? kc.brand : AppColors.forest,
          shape: pill,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Inputs: soft stone fill, 12px radius, crisp focus ring
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kc.tile,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        labelStyle: TextStyle(
          color: kc.inkSoft,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          color: dark ? kc.brand : AppColors.forest,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(color: kc.inkMuted, fontSize: 14),
        errorStyle: const TextStyle(
          color: AppColors.error,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        prefixIconColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.focused)
              ? (dark ? kc.brand : AppColors.forest)
              : kc.inkSoft,
        ),
        suffixIconColor: kc.inkSoft,
        border: inputBorder(Colors.transparent),
        enabledBorder: inputBorder(dark ? kc.stroke : Colors.transparent),
        focusedBorder: inputBorder(dark ? kc.brand : AppColors.forest, 1.5),
        errorBorder: inputBorder(AppColors.error.withValues(alpha: .5)),
        focusedErrorBorder: inputBorder(AppColors.error, 1.5),
      ),

      // Chips: stadium; selected = solid forest
      chipTheme: ChipThemeData(
        backgroundColor: kc.card,
        selectedColor: dark ? kc.brand : AppColors.forest,
        side: BorderSide(color: kc.stroke),
        shape: const StadiumBorder(),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: kc.inkSoft,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: dark ? kc.onBrand : Colors.white,
        ),
        checkmarkColor: dark ? kc.onBrand : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // Material nav bar (KaisaBottomBar in kaisa_widgets.dart is the spec'd one)
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        elevation: 0,
        backgroundColor: kc.sheet,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 24,
            color: s.contains(WidgetState.selected)
                ? (dark ? kc.brand : AppColors.forest)
                : kc.inkMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          final selected = s.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected
                ? (dark ? kc.brand : AppColors.forest)
                : kc.inkMuted,
          );
        }),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: kc.sheet,
        useIndicator: true,
        indicatorColor: dark ? kc.brand : AppColors.forest,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        selectedIconTheme: IconThemeData(
          color: dark ? kc.onBrand : Colors.white,
        ),
        unselectedIconTheme: IconThemeData(color: kc.inkSoft),
        selectedLabelTextStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: kc.ink,
        ),
        unselectedLabelTextStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: kc.inkSoft,
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: kc.sheet,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: kc.sheet,
        modalBackgroundColor: kc.sheet,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        dragHandleColor: kc.stroke,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? kc.card : AppColors.forest,
        actionTextColor: AppColors.yellow,
        contentTextStyle: GoogleFonts.inter(
          color: dark ? kc.ink : Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      ),

      dividerTheme: DividerThemeData(color: kc.stroke, thickness: 1, space: 24),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? (dark ? kc.brand : AppColors.forest)
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(kc.onBrand),
        side: BorderSide(color: kc.inkMuted, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: dark ? kc.brand : AppColors.forest,
        linearTrackColor: AppColors.sageTrack,
        circularTrackColor: kc.stroke,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: kc.sheet,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: .06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: kc.stroke),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: kc.sheet,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: kc.card,
        headerForegroundColor: kc.ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: kc.stroke),
        ),
      ),
    );
  }
}
