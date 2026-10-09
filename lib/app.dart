import 'package:flutter/material.dart';


import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class KaisaApp extends StatelessWidget {
  const KaisaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'KAISA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
