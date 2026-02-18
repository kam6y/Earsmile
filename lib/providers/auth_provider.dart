import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/auth_service.dart';

part 'auth_provider.g.dart';

/// 認証状態を管理する Provider
///
/// build() で匿名認証を実行し、UID（または null）を返す。
/// オフラインファースト: 認証失敗時も AsyncData(null) として正常完了扱い。
@riverpod
class AuthNotifier extends _$AuthNotifier {
  late final AuthService _authService;

  @override
  Future<String?> build() async {
    _authService = AuthService();
    return _authService.ensureAuthenticated();
  }

  /// 現在の UID を同期的に取得する
  String? get currentUserId => _authService.currentUserId;
}
