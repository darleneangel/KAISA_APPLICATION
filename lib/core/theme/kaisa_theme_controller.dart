import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One shared theme selection across mobile and web.
class KaisaThemeController {
  KaisaThemeController._();
  static final instance = KaisaThemeController._();
  static const _key = 'kaisa_theme_mode';
  final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    mode.value = switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> change(ThemeMode selection) async {
    mode.value = selection;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, selection.name);
  }
}
