import 'package:flutter/material.dart';

import 'features/ecertificate/views/ecertificate_studio_page.dart';

/// Standalone, local UI preview: does not initialize Supabase or change app_router.dart.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _CertificatePreviewApp());
}

class _CertificatePreviewApp extends StatelessWidget {
  const _CertificatePreviewApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'KAISA Certificate Studio · Preview',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176B43)),
          scaffoldBackgroundColor: const Color(0xFFF5F9F6),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        home: const EcertificateStudioPage(),
      );
}
