import 'package:flutter/material.dart';

/// KAISA Civic Dignity palette from the supplied Google Stitch export.
/// Legacy names are retained so older pages keep compiling.
class AppColors {
  AppColors._();

  static const Color deepForest = Color(0xFF00301B);
  static const Color forest = Color(0xFF00492C);
  static const Color mint = Color(0xFFEAF5EE);
  static const Color lime = Color(0xFFFBBA16);

  // Legacy 'blue' identifiers are green-mapped to unify existing resident UIs.
  static const Color blue = forest;
  static const Color blueDark = deepForest;
  static const Color blueLight = mint;

  static const Color green = Color(0xFF2C6A4A);
  static const Color greenDark = forest;
  static const Color greenLight = mint;

  static const Color yellow = Color(0xFFFBBA16);
  static const Color yellowDark = Color(0xFF946800);
  static const Color yellowLight = Color(0xFFFFF4DB);

  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color surfaceSoft = Color(0xFFF2F5F3);

  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF89948D);
  static const Color border = Color(0xFFE5E7EB);

  static const Color primary = forest;
  static const Color secondary = green;
  static const Color accent = yellow;
  static const Color success = green;
  static const Color warning = yellow;
  static const Color error = Color(0xFFBA1A1A);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [deepForest, forest],
  );
}
