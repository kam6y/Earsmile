import 'package:flutter/material.dart';

/// 通常モード: 白背景 + 黒文字
final ThemeData normalTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFFFFFFF),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(
      fontFamily: 'HiraKakuProN-W3',
      color: Color(0xFF000000),
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'HiraKakuProN-W3',
      color: Color(0xFF000000),
      fontWeight: FontWeight.w400,
    ),
    bodySmall: TextStyle(
      fontFamily: 'HiraKakuProN-W3',
      color: Color(0xFF000000),
      fontWeight: FontWeight.w400,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(64, 64),
      textStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'HiraKakuProN-W3',
      ),
    ),
  ),
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.light,
  ),
  useMaterial3: true,
);

/// 高コントラストモード: 黒背景 + 黄文字、Bold固定
final ThemeData highContrastTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF000000),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(
      fontFamily: 'HiraKakuProN-W6',
      color: Color(0xFFFFFF00),
      fontWeight: FontWeight.w700,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'HiraKakuProN-W6',
      color: Color(0xFFFFFF00),
      fontWeight: FontWeight.w700,
    ),
    bodySmall: TextStyle(
      fontFamily: 'HiraKakuProN-W6',
      color: Color(0xFFFFFF00),
      fontWeight: FontWeight.w700,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFFFFF00),
      foregroundColor: const Color(0xFF000000),
      minimumSize: const Size(64, 64),
      textStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'HiraKakuProN-W6',
      ),
    ),
  ),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFFFFF00),
    onPrimary: Color(0xFF000000),
    surface: Color(0xFF000000),
    onSurface: Color(0xFFFFFF00),
  ),
  useMaterial3: true,
);

/// フォントサイズスケールを実際の pt 値に変換する
///
/// - 1.0 → 24pt（大）
/// - 2.0 → 32pt（特大）
/// - 3.0 → 48pt（最大・iPad推奨）
double resolveBodyFontSize(double scale) {
  switch (scale) {
    case 1.0:
      return 24.0;
    case 2.0:
      return 32.0;
    case 3.0:
      return 48.0;
    default:
      return 24.0;
  }
}
