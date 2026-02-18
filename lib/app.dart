import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/routes.dart';
import 'config/theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Step 4 で SettingsProvider を監視してテーマを動的切替する
    return MaterialApp.router(
      title: 'earsmile',
      theme: normalTheme,
      routerConfig: AppRouter.router,
    );
  }
}
