import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:earsmile/config/theme.dart';

void main() {
  group('normalTheme', () {
    test('白背景が設定されている', () {
      expect(normalTheme.scaffoldBackgroundColor, const Color(0xFFFFFFFF));
    });

    test('黒文字が設定されている', () {
      expect(normalTheme.textTheme.bodyLarge?.color, const Color(0xFF000000));
      expect(normalTheme.textTheme.bodyMedium?.color, const Color(0xFF000000));
    });

    test('ヒラギノ角ゴ W3 フォントが設定されている', () {
      expect(normalTheme.textTheme.bodyLarge?.fontFamily, 'HiraKakuProN-W3');
    });

    test('ボタンの最小サイズが 64x64pt', () {
      final buttonStyle = normalTheme.elevatedButtonTheme.style;
      final minSize = buttonStyle?.minimumSize?.resolve({});
      expect(minSize?.width, 64.0);
      expect(minSize?.height, 64.0);
    });
  });

  group('highContrastTheme', () {
    test('黒背景が設定されている', () {
      expect(
          highContrastTheme.scaffoldBackgroundColor, const Color(0xFF000000));
    });

    test('黄文字 (#FFFF00) が設定されている', () {
      expect(highContrastTheme.textTheme.bodyLarge?.color,
          const Color(0xFFFFFF00));
      expect(highContrastTheme.textTheme.bodyMedium?.color,
          const Color(0xFFFFFF00));
    });

    test('ヒラギノ角ゴ W6 フォントが設定されている', () {
      expect(
          highContrastTheme.textTheme.bodyLarge?.fontFamily, 'HiraKakuProN-W6');
    });

    test('Bold (W700) が固定されている', () {
      expect(highContrastTheme.textTheme.bodyLarge?.fontWeight, FontWeight.w700);
    });

    test('ボタンの最小サイズが 64x64pt', () {
      final buttonStyle = highContrastTheme.elevatedButtonTheme.style;
      final minSize = buttonStyle?.minimumSize?.resolve({});
      expect(minSize?.width, 64.0);
      expect(minSize?.height, 64.0);
    });
  });

  group('resolveBodyFontSize', () {
    test('1.0 → 24pt', () {
      expect(resolveBodyFontSize(1.0), 24.0);
    });

    test('2.0 → 32pt', () {
      expect(resolveBodyFontSize(2.0), 32.0);
    });

    test('3.0 → 48pt', () {
      expect(resolveBodyFontSize(3.0), 48.0);
    });

    test('不正な値はデフォルト 24pt', () {
      expect(resolveBodyFontSize(0.5), 24.0);
      expect(resolveBodyFontSize(4.0), 24.0);
    });
  });
}
