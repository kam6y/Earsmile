import 'package:intl/intl.dart';

/// 日付フォーマットユーティリティ
///
/// アプリ全体で使用する日付・時刻の表示形式を統一する。
abstract class DateFormatter {
  /// 履歴一覧表示用フォーマット
  ///
  /// 例: "2月18日 14:30"
  static String toHistoryListFormat(DateTime dt) {
    return DateFormat('M月d日 HH:mm', 'ja').format(dt);
  }

  /// 履歴詳細タイトル用フォーマット
  ///
  /// 例: "2月18日の会話"
  static String toDetailTitleFormat(DateTime dt) {
    return '${DateFormat('M月d日', 'ja').format(dt)}の会話';
  }

  /// 会話タイトル保存用フォーマット
  ///
  /// 例: "2024/02/18 14:30 の会話"
  static String toConversationTitle(DateTime dt) {
    return '${DateFormat('yyyy/MM/dd HH:mm').format(dt)} の会話';
  }

  /// メッセージタイムスタンプ表示用フォーマット
  ///
  /// 例: "14:30:05"
  static String toMessageTimestamp(DateTime dt) {
    return DateFormat('HH:mm:ss').format(dt);
  }
}
