import 'package:flutter/foundation.dart';

/// Notify shared resident chrome immediately after a successful profile save.
/// No personal information is stored here; the top bar reloads from Supabase.
final ValueNotifier<int> kaisaAccountRefresh = ValueNotifier<int>(0);

void notifyKaisaAccountChanged() => kaisaAccountRefresh.value++;
