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

    // Modern Typography: Switched to Inter (or keep Montserrat but tweaked weights).
    // Inter is standard for high-end SaaS/Fintech apps, but keeping Montserrat here
    // with adjusted tracking (letterSpacing) makes it feel instantly more expensive.
    final body = GoogleFonts.montserratTextTheme(
      base.textTheme,
    ).apply(bodyColor: kc.ink, displayColor: kc.ink);

    final textTheme = body.copyWith(
      displayMedium: body.displayMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2, // Slightly relaxed from -1.5 for better legibility
        height: 1.1,
      ),
      headlineLarge: body.headlineLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        height: 1.15,
      ),
      headlineMedium: body.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      headlineSmall: body.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.25,
      ),
      titleLarge: body.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: body.titleMedium?.copyWith(
        fontWeight: FontWeight.w600, // Reduced from 700 to look cleaner
        letterSpacing: -0.1,
      ),
      titleSmall: body.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: body.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1, // Added tiny tracking for all-caps/button labels
      ),
      bodyLarge: body.bodyLarge?.copyWith(
        height: 1.6,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: body.bodyMedium?.copyWith(
        height: 1.6,
        fontWeight: FontWeight.w400,
      ),
    );

    // Squircle/continuous curve look. A slightly softer radius looks more modern than raw circles.
    final pill = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );

    final buttonText = GoogleFonts.montserrat(
      fontSize: 15,
      fontWeight:
          FontWeight.w600, // Dropped from w700 to look sleeker, less chunky
      letterSpacing: 0.2,
    );

    // Modern inputs use subtle fills with soft borders, getting bolder only on focus.
    OutlineInputBorder inputBorder(Color color, [double width = 1.0]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
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

      // App Bar: Clean, flat, seamlessly blending with the page
      appBarTheme: AppBarTheme(
        backgroundColor: kc.page,
        foregroundColor: kc.ink,
        elevation: 0,
        scrolledUnderElevation:
            0, // Prevents muddy Material 3 tinting on scroll
        surfaceTintColor: Colors.transparent,
        centerTitle: true, // Center titles feel more app-like (iOS style)
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 17, // Standardized app bar size
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: kc.ink,
        ),
        iconTheme: IconThemeData(color: kc.ink, size: 22),
      ),

      // Cards: Glassier/Softer look
      cardTheme: CardThemeData(
        color: kc.card,
        elevation: dark
            ? 0
            : 2, // Tiny shadow in light mode for floating effect
        shadowColor: dark ? Colors.transparent : kc.stroke.withOpacity(0.3),
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: kc.stroke,
            width: dark ? 1 : 0.5,
          ), // Thinner borders
        ),
      ),

      // Buttons: Replaced pill with continuous curve "Squircle" look
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: kc.brand,
          foregroundColor: kc.onBrand,
          elevation: 0,
          minimumSize: const Size(
            0,
            56,
          ), // Standardized Apple/Google tap target
          padding: const EdgeInsets.symmetric(horizontal: 28),
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kc.brand,
          foregroundColor: kc.onBrand,
          elevation: dark ? 0 : 4,
          shadowColor: kc.brand.withOpacity(
            0.3,
          ), // Glow effect instead of hard shadow
          minimumSize: const Size(0, 56),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: kc.ink,
          minimumSize: const Size(0, 56),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          side: BorderSide(color: kc.stroke, width: 1.5),
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: kc.brand,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Inputs: Softer default state, crisp focus state
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kc.tile,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        labelStyle: TextStyle(
          color: kc.inkSoft,
          fontSize: 14,
          fontWeight: FontWeight.w500, // Reduced weight for cleaner look
        ),
        floatingLabelStyle: TextStyle(
          color: kc.brand,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(
          color: kc.inkMuted,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        errorStyle: TextStyle(
          color: AppColors.error,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        prefixIconColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.focused) ? kc.brand : kc.inkSoft,
        ),
        suffixIconColor: kc.inkSoft,
        border: inputBorder(Colors.transparent), // Borderless look by default
        enabledBorder: inputBorder(
          dark ? kc.stroke.withOpacity(0.5) : Colors.transparent,
        ),
        focusedBorder: inputBorder(kc.brand, 1.5), // Subtle focus ring
        errorBorder: inputBorder(AppColors.error.withOpacity(0.5)),
        focusedErrorBorder: inputBorder(AppColors.error, 1.5),
      ),

      // Chips: Modern toggle style
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: kc.tile,
        selectedColor: dark ? const Color(0xFF224233) : AppColors.yellowLight,
        side: BorderSide(color: dark ? kc.stroke : Colors.transparent),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ), // Moved away from stadium
        labelStyle: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: kc.ink,
        ),
        checkmarkColor: dark ? AppColors.yellow : kc.brand,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // Navigation: Floating dynamic island style / Glassy bottom bar look
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: kc.sheet.withOpacity(
          0.95,
        ), // Slight transparency hint if you use blur behind it
        surfaceTintColor: Colors.transparent,
        indicatorColor: dark ? kc.tile : AppColors.yellowLight,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 24,
            color: s.contains(WidgetState.selected)
                ? (dark ? kc.brand : kc.brand)
                : kc.inkMuted, // Push unselected further back
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          final selected = s.contains(WidgetState.selected);
          return GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? kc.ink : kc.inkMuted,
          );
        }),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: kc.card,
        useIndicator: true,
        indicatorColor: dark ? kc.tile : AppColors.yellowLight,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        selectedIconTheme: IconThemeData(color: kc.brand),
        unselectedIconTheme: IconThemeData(color: kc.inkMuted),
        selectedLabelTextStyle: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: kc.ink,
        ),
        unselectedLabelTextStyle: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: kc.inkMuted,
        ),
      ),

      // Dialogs & Sheets: Flatter, wider radii, smoother easing
      dialogTheme: DialogThemeData(
        backgroundColor: kc.sheet,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 10,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: kc.sheet,
        modalBackgroundColor: kc.sheet,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        dragHandleColor: kc.stroke, // Added a hint for the drag handle
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),

      // Snackbars: Floating pill
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? kc.card : AppColors.textPrimary,
        actionTextColor: kc.brand,
        contentTextStyle: GoogleFonts.montserrat(
          color: dark ? kc.ink : Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      ),

      dividerTheme: DividerThemeData(color: kc.stroke, thickness: 1, space: 24),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? kc.brand : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(kc.onBrand),
        side: BorderSide(color: kc.inkSoft, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: kc.brand,
        circularTrackColor: kc.stroke,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: kc.sheet,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: kc.stroke, width: 0.5),
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
