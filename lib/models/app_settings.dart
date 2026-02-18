import 'package:objectbox/objectbox.dart';

@Entity()
class AppSettings {
  int id;

  /// フォントサイズスケール: 1.0(24pt), 2.0(32pt), 3.0(48pt)
  double fontSize;

  /// true: 黒背景+黄文字, false: 白背景+黒文字
  bool isHighContrast;

  AppSettings({
    this.id = 0,
    this.fontSize = 1.0,
    this.isHighContrast = false,
  });
}
