import 'package:flutter/material.dart';

/// Minimal controller, only use when the project does not already provide one.
/// If your existing controller persists choices, keep your existing file instead.
class KaisaThemeController {
  KaisaThemeController._();
  static final KaisaThemeController instance = KaisaThemeController._();
  final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);
  void change(ThemeMode next) => mode.value = next;
}
