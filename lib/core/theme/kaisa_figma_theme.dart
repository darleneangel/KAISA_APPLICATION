import 'package:flutter/material.dart';

/// Visual tokens adapted from the provided Figma React reference.
/// Only colors, typography, shape and Material component styling live here.
/// No authentication, Supabase, role or navigation code is changed.
abstract final class KaisaFigmaPalette {
  static const forest = Color(0xFF184F30);
  static const green = Color(0xFF2E7D32);
  static const leaf = Color(0xFF43A047);
  static const mint = Color(0xFFE8F5E9);
  static const yellow = Color(0xFFFBC02D);
  static const blue = Color(0xFF1565C0);
  static const paper = Color(0xFFF7FAF7);
  static const ink = Color(0xFF1F2937);
  static const muted = Color(0xFF6B7280);
  static const outline = Color(0xFFE3ECE5);
  static const white = Colors.white;

  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF153F27), green, leaf],
  );
  static const LinearGradient action = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[green, leaf],
  );
}

class KaisaFigmaTheme {
  static ThemeData get light {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    final scheme = ColorScheme.fromSeed(
      seedColor: KaisaFigmaPalette.green,
      primary: KaisaFigmaPalette.green,
      secondary: KaisaFigmaPalette.yellow,
      surface: KaisaFigmaPalette.white,
      brightness: Brightness.light,
    );
    final text = base.textTheme.apply(
      fontFamily: 'Montserrat',
      bodyColor: KaisaFigmaPalette.ink,
      displayColor: KaisaFigmaPalette.ink,
    );
    final radius = BorderRadius.circular(18);
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: KaisaFigmaPalette.paper,
      textTheme: text,
      primaryTextTheme: text,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: KaisaFigmaPalette.white,
        foregroundColor: KaisaFigmaPalette.ink,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 21,
          fontWeight: FontWeight.w800,
          color: KaisaFigmaPalette.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: KaisaFigmaPalette.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          color: KaisaFigmaPalette.muted,
        ),
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        prefixIconColor: KaisaFigmaPalette.green,
        suffixIconColor: KaisaFigmaPalette.green,
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: KaisaFigmaPalette.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: KaisaFigmaPalette.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(
            color: KaisaFigmaPalette.green,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: Color(0xFFDC5549)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: KaisaFigmaPalette.green,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 54),
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KaisaFigmaPalette.green,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KaisaFigmaPalette.green,
          side: const BorderSide(color: KaisaFigmaPalette.outline),
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: KaisaFigmaPalette.green,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: KaisaFigmaPalette.mint,
        side: const BorderSide(color: KaisaFigmaPalette.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        labelStyle: const TextStyle(
          color: KaisaFigmaPalette.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        height: 72,
        indicatorColor: KaisaFigmaPalette.mint,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: states.contains(WidgetState.selected)
                ? KaisaFigmaPalette.green
                : KaisaFigmaPalette.muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 23,
            color: states.contains(WidgetState.selected)
                ? KaisaFigmaPalette.green
                : KaisaFigmaPalette.muted,
          ),
        ),
      ),
      dividerColor: KaisaFigmaPalette.outline,
      listTileTheme: ListTileThemeData(
        iconColor: KaisaFigmaPalette.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: KaisaFigmaPalette.forest,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: KaisaFigmaPalette.green,
        linearTrackColor: KaisaFigmaPalette.mint,
      ),
    );
  }
}
