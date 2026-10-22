import 'package:flutter/material.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/kaisa_theme_controller.dart';

class KaisaApp extends StatelessWidget {
  const KaisaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: KaisaThemeController.instance.mode,
      builder: (context, mode, _) => MaterialApp.router(
        title: 'KAISA',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: mode,
        routerConfig: appRouter,
      ),
    );
  }
}
