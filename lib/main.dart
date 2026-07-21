import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: MemocardApp()));
}

/// The Memocard app root widget.
///
/// Wave 1 scope only: theme + 5-tab router shell. No Firebase, no
/// SharedPreferences, no async main() — those land in Waves 2-3.
class MemocardApp extends ConsumerWidget {
  const MemocardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      title: 'Memocard',
      debugShowCheckedModeBanner: false,
    );
  }
}
