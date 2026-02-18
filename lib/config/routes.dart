import 'package:go_router/go_router.dart';

import '../screens/splash_screen.dart';
import '../screens/home_screen.dart';
import '../screens/history_screen.dart';
import '../screens/history_detail_screen.dart';
import '../screens/settings_screen.dart';

/// アプリケーションのルーティング設定
///
/// 詳細設計書 §7.2 に準拠
abstract class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/history/:id',
        builder: (context, state) => HistoryDetailScreen(
          conversationId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
