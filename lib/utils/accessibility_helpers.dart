/// VoiceOver / アクセシビリティ用セマンティクスラベル定数
///
/// 詳細設計書 §9.2 に準拠
abstract class AccessibilityLabels {
  /// 音声認識停止ボタン
  static const String stopListening = '音声の聞き取りを停止';

  /// 音声認識再開ボタン
  static const String resumeListening = '音声の聞き取りを再開';

  /// 履歴画面へ遷移するボタン
  static const String openHistory = '会話のりれきを見る';

  /// 設定画面へ遷移するボタン
  static const String openSettings = 'せっていを開く';

  /// 会話削除ボタン
  static const String deleteConversation = 'この会話を削除する';

  /// 前の画面へ戻るボタン
  static const String goBack = '前の画面にもどる';
}
