import 'package:go_router/go_router.dart';

import '../screens/splash_screen.dart';
import '../screens/home_screen.dart';
import '../screens/history_screen.dart';
import '../screens/history_detail_screen.dart';
import '../screens/settings_screen.dart';

/// ルートパス定数
abstract class RoutePaths {
  static const String splash = '/splash';
  static const String home = '/';
  static const String history = '/history';
  static const String historyDetail = '/history/:id';
  static const String settings = '/settings';

  /// 履歴詳細のパスを生成する
  static String historyDetailOf(String id) => '/history/$id';
}

/// アプリケーションのルーティング設定
///
/// 詳細設計書 §7.2 に準拠
abstract class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: RoutePaths.splash,
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.history,
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: RoutePaths.historyDetail,
        builder: (context, state) => HistoryDetailScreen(
          conversationId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
