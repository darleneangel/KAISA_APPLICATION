import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const forest = Color(0xFF115C43),
      deepForest = Color(0xFF083C32),
      green = Color(0xFF218957),
      greenDark = forest,
      lime = Color(0xFFB9DD65),
      limeDark = Color(0xFF83AB2E),
      mint = Color(0xFFE8F5E9),
      cream = Color(0xFFFFFCF5),
      navy = Color(0xFF17382F);
  static const yellow = Color(0xFFFFD34D),
      yellowDark = Color(0xFFE8AD20),
      yellowLight = Color(0xFFFFF4CC);
  static const background = Color(0xFFF6F8F5),
      surface = Colors.white,
      surfaceSoft = Color(0xFFEEF3EF),
      textPrimary = Color(0xFF172E26),
      textSecondary = Color(0xFF65776C),
      textMuted = Color(0xFF84968B),
      border = Color(0xFFE0E9E1);
  static const blue = forest,
      blueDark = deepForest,
      blueLight = mint,
      greenLight = mint;
  static const primary = forest,
      secondary = green,
      accent = yellow,
      success = green,
      warning = yellowDark,
      error = Color(0xFFD54848);
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [deepForest, forest, green],
  );
}
