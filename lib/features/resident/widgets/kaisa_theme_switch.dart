import 'package:flutter/material.dart';
import 'kaisa_resident_design.dart';
import '../../../core/theme/kaisa_theme_controller.dart';

class KaisaThemeSwitch extends StatelessWidget {
  const KaisaThemeSwitch({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
    valueListenable: KaisaThemeController.instance.mode,
    builder: (context, value, _) => PopupMenuButton<ThemeMode>(
      tooltip: 'Appearance',
      initialValue: value,
      onSelected: KaisaThemeController.instance.change,
      icon: Icon(
        value == ThemeMode.dark
            ? Icons.dark_mode_rounded
            : value == ThemeMode.light
            ? Icons.light_mode_rounded
            : Icons.brightness_auto_rounded,
        color: compact
            ? const Color(0xFFD6E4DD)
            : Theme.of(context).colorScheme.onSurface,
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: ThemeMode.system,
          child: ListTile(
            leading: Icon(Icons.brightness_auto_rounded),
            title: Text(
              'System',
              style: KaisaTypography.body(const TextStyle(fontSize: 14)),
            ),
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.light,
          child: ListTile(
            leading: Icon(Icons.light_mode_rounded),
            title: Text(
              'Light',
              style: KaisaTypography.body(const TextStyle(fontSize: 14)),
            ),
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.dark,
          child: ListTile(
            leading: Icon(Icons.dark_mode_rounded),
            title: Text(
              'Dark',
              style: KaisaTypography.body(const TextStyle(fontSize: 14)),
            ),
          ),
        ),
      ],
    ),
  );
}
