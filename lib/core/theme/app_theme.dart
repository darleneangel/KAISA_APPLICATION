import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// One builder for both modes, so light and dark can never drift apart again.
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
          seedColor: dark ? AppColors.green : AppColors.forest,
          brightness: brightness,
        ).copyWith(
          primary: kc.brand,
          onPrimary: kc.onBrand,
          secondary: AppColors.yellow,
          onSecondary: AppColors.deepForest,
          surface: kc.card,
          onSurface: kc.ink,
          onSurfaceVariant: kc.inkSoft,
          surfaceContainerHighest: kc.tile,
          outline: kc.stroke,
          outlineVariant: kc.stroke,
          error: AppColors.error,
        );

    final body = GoogleFonts.montserratTextTheme(
      base.textTheme,
    ).apply(bodyColor: kc.ink, displayColor: kc.ink);

    final textTheme = body.copyWith(
      displayMedium: body.displayMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.5,
      ),
      headlineLarge: body.headlineLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
      ),
      headlineMedium: body.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
      headlineSmall: body.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      titleLarge: body.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      titleMedium: body.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      titleSmall: body.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      labelLarge: body.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      bodyMedium: body.bodyMedium?.copyWith(height: 1.5),
    );

    const pill = StadiumBorder();
    final buttonText = GoogleFonts.montserrat(
      fontSize: 15,
      fontWeight: FontWeight.w700,
    );

    OutlineInputBorder inputBorder(Color color, [double width = 1.2]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: color, width: width),
        );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: kc.page,
      canvasColor: kc.card,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: textTheme,
      primaryTextTheme: GoogleFonts.montserratTextTheme(
        base.primaryTextTheme,
      ).apply(bodyColor: kc.ink, displayColor: kc.ink),
      extensions: [kc],
      appBarTheme: AppBarTheme(
        backgroundColor: kc.page,
        foregroundColor: kc.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: kc.ink,
        ),
      ),
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
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: kc.brand,
          foregroundColor: kc.onBrand,
          elevation: 0,
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 26),
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
          padding: const EdgeInsets.symmetric(horizontal: 26),
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: kc.ink,
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 26),
          side: BorderSide(color: kc.stroke, width: 1.4),
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: kc.brand,
          textStyle: GoogleFonts.montserrat(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kc.tile,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        labelStyle: TextStyle(
          color: kc.inkSoft,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(color: kc.inkMuted, fontSize: 14),
        errorStyle: const TextStyle(fontWeight: FontWeight.w600),
        prefixIconColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.focused) ? kc.brand : kc.inkSoft,
        ),
        suffixIconColor: kc.inkSoft,
        border: inputBorder(kc.stroke),
        enabledBorder: inputBorder(kc.stroke),
        focusedBorder: inputBorder(kc.brand, 2),
        errorBorder: inputBorder(AppColors.error),
        focusedErrorBorder: inputBorder(AppColors.error, 2),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: kc.tile,
        selectedColor: dark ? const Color(0xFF3A5C46) : AppColors.yellow,
        side: BorderSide(color: kc.stroke),
        shape: pill,
        labelStyle: GoogleFonts.montserrat(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: kc.ink,
        ),
        checkmarkColor: dark ? AppColors.yellow : AppColors.deepForest,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        elevation: 0,
        backgroundColor: kc.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.yellow,
        indicatorShape: pill,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 24,
            color: s.contains(WidgetState.selected)
                ? AppColors.deepForest
                : kc.inkSoft,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          final selected = s.contains(WidgetState.selected);
          return GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? kc.ink : kc.inkSoft,
          );
        }),
      ),
      // Web uses a rail instead of the bottom bar.
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: kc.card,
        useIndicator: true,
        indicatorColor: AppColors.yellow,
        indicatorShape: pill,
        selectedIconTheme: const IconThemeData(color: AppColors.deepForest),
        unselectedIconTheme: IconThemeData(color: kc.inkSoft),
        selectedLabelTextStyle: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: kc.ink,
        ),
        unselectedLabelTextStyle: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: kc.inkSoft,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: kc.sheet,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: kc.sheet,
        modalBackgroundColor: kc.sheet,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? const Color(0xFF2A4538) : AppColors.deepForest,
        actionTextColor: AppColors.yellow,
        contentTextStyle: GoogleFonts.montserrat(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerTheme: DividerThemeData(color: kc.stroke, thickness: 1, space: 1),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? kc.brand : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(kc.onBrand),
        side: BorderSide(color: kc.inkSoft, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: kc.brand),
      popupMenuTheme: PopupMenuThemeData(
        color: kc.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: kc.sheet,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: dark ? kc.tile : AppColors.forest,
        headerForegroundColor: dark ? kc.ink : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    );
  }
}
