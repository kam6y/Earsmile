import 'package:objectbox/objectbox.dart';

import 'speech_recognition_mode.dart';

@Entity()
class AppSettings {
  int id;

  /// フォントサイズスケール: 1.0(24pt), 2.0(32pt), 3.0(48pt)
  double fontSize;

  /// true: 黒背景+黄文字, false: 白背景+黒文字
  bool isHighContrast;

  /// 音声認識モード（ObjectBox保存用の String 表現）
  String speechRecognitionModeRaw;

  AppSettings({
    this.id = 0,
    this.fontSize = 1.0,
    this.isHighContrast = false,
    this.speechRecognitionModeRaw = 'server',
  });

  /// 音声認識モード（enum アクセサ）
  @Transient()
  SpeechRecognitionMode get speechRecognitionMode =>
      speechRecognitionModeFromString(speechRecognitionModeRaw);

  @Transient()
  set speechRecognitionMode(SpeechRecognitionMode mode) {
    speechRecognitionModeRaw = mode.toStorageString();
  }
}
