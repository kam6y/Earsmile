/// アプリ全体で使用する定数
abstract class AppConstants {
  // -------------------------
  // タッチターゲット
  // -------------------------

  /// 全インタラクティブ要素の最小タッチターゲットサイズ (pt)
  static const double minTouchTarget = 64.0;

  /// 停止/再開ボタンのサイズ (pt)
  static const double mainButtonSize = 80.0;

  // -------------------------
  // 音声認識
  // -------------------------

  /// 無音検知の音声レベル閾値（0.0〜1.0）
  static const double silenceThreshold = 0.05;

  /// 無音と判定するまでの継続時間
  static const Duration silenceDuration = Duration(milliseconds: 1500);

  /// エラー発生時の自動再試行最大回数
  static const int maxRetryCount = 3;

  /// 再試行前の待機時間
  static const Duration retryDelay = Duration(seconds: 3);

  // -------------------------
  // UI サイズ
  // -------------------------

  /// 履歴リストアイテムの最小高さ (pt)
  static const double historyItemMinHeight = 80.0;

  /// オフラインバナーの高さ (pt)
  static const double offlineBannerHeight = 40.0;

  /// 削除ボタンの高さ (pt)
  static const double deleteButtonHeight = 64.0;

  /// ダイアログボタンの最小サイズ (pt)
  static const double dialogButtonMinWidth = 64.0;
  static const double dialogButtonMinHeight = 48.0;

  // -------------------------
  // Splash
  // -------------------------

  /// Splash 画面の最大表示時間
  static const Duration splashTimeout = Duration(seconds: 3);

  // -------------------------
  // メッセージ
  // -------------------------

  /// 音声認識に必要な権限がない場合の案内文言
  static const String speechPermissionDeniedMessage = 'マイクまたは音声認識の権限がありません。\n'
      '「設定」アプリで「earsmile」のマイクと音声認識を許可してください。';
}
