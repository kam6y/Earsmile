/// 音声認識モードの定義
///
/// ObjectBox は enum を直接保存できないため、String での変換を提供する。
enum SpeechRecognitionMode {
  /// サーバーサイド認識（デフォルト・全端末対応）
  server,

  /// オンデバイス認識（iOS 13+ 対応端末のみ）
  onDevice,
}

extension SpeechRecognitionModeX on SpeechRecognitionMode {
  String toStorageString() => name;
}

/// SpeechRecognitionMode の String → enum 変換
///
/// extension の static メソッドはオーバーライドできないため、
/// トップレベル関数として定義する。
SpeechRecognitionMode speechRecognitionModeFromString(String? value) {
  return switch (value) {
    'onDevice' => SpeechRecognitionMode.onDevice,
    _ => SpeechRecognitionMode.server,
  };
}
