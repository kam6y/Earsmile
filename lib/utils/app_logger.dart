import 'package:flutter/foundation.dart';

/// 本番環境での情報漏えいを避けるための最小ログヘルパー。
abstract final class AppLogger {
  static void warn(
    String context, {
    Object? error,
  }) {
    if (!kDebugMode) return;

    final errorType = error == null ? '' : ' (${error.runtimeType})';
    debugPrint('[warn] $context$errorType');
  }
}
