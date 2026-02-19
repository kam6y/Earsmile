import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/auth_service.dart';

part 'auth_provider.g.dart';

/// AuthService の Provider（override 必須パターン）
final authServiceProvider = Provider<AuthService>((ref) {
  throw UnimplementedError(
    'authServiceProvider を ProviderScope で override してください',
  );
});

/// 認証状態を管理する Provider
///
/// build() で匿名認証を実行し、UID（または null）を返す。
/// オフラインファースト: 認証失敗時も AsyncData(null) として正常完了扱い。
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<String?> build() async {
    final authService = ref.read(authServiceProvider);
    return authService.ensureAuthenticated();
  }

  /// 現在の UID を同期的に取得する
  String? get currentUserId =>
      ref.read(authServiceProvider).currentUserId;
}
