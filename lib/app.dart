import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/routes.dart';
import 'config/theme.dart';
import 'providers/settings_provider.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isHighContrast = settings.isHighContrast;
    return MaterialApp.router(
      title: 'earsmile',
      theme: isHighContrast ? highContrastTheme : normalTheme,
      routerConfig: AppRouter.router,
    );
  }
}
