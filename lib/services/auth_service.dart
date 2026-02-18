import 'package:firebase_auth/firebase_auth.dart';

/// Firebase 匿名認証サービス
///
/// 詳細設計書 §4.2 に準拠。
/// オフラインファースト設計のため、認証失敗時もアプリ利用をブロックしない。
class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  /// 認証済みの UID を返す。未認証の場合は匿名サインインを実行する。
  /// ネットワークエラー等で認証に失敗した場合は null を返す。
  Future<String?> ensureAuthenticated() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        return currentUser.uid;
      }
      final credential = await _firebaseAuth.signInAnonymously();
      return credential.user?.uid;
    } on FirebaseAuthException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 現在の UID を同期的に取得する（未認証なら null）
  String? get currentUserId => _firebaseAuth.currentUser?.uid;
}
