import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Compatibility palette for existing KAISA Figma widget imports.
/// Shared brand values now follow Civic Dignity.
abstract final class KaisaFigmaPalette {
  static const Color green = AppColors.forest;
  static const Color yellow = AppColors.yellow;
  static const Color mint = AppColors.mint;
  static const Color ink = AppColors.textPrimary;
  static const Color muted = AppColors.textSecondary;
  static const Color outline = AppColors.border;
  static const Color paper = AppColors.background;
  static const LinearGradient hero = AppColors.heroGradient;
}
