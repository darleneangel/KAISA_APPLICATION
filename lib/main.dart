import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (url.isEmpty || key.isEmpty) {
    throw StateError(
      'Missing SUPABASE_URL or SUPABASE_ANON_KEY dart defines. '
      'See README_SETUP.md.',
    );
  }

  debugPrint('KAISA: Starting Supabase initialization');

  try {
    await Supabase.initialize(url: url, publishableKey: key);

    debugPrint('KAISA: Supabase initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('KAISA: Supabase initialization failed: $e');
    debugPrintStack(stackTrace: stackTrace);
    rethrow;
  }

  debugPrint('KAISA: Starting Flutter UI');

  runApp(const ProviderScope(child: KaisaApp()));
}
