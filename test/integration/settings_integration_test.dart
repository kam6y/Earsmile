import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:earsmile/models/app_settings.dart';
import 'package:earsmile/providers/device_capability_provider.dart';
import 'package:earsmile/providers/local_storage_provider.dart';
import 'package:earsmile/providers/settings_provider.dart';
import 'package:earsmile/screens/settings_screen.dart';

import '../helpers/mocks.dart';

void main() {
  late MockLocalStorageService mockStorage;

  setUp(() {
    mockStorage = MockLocalStorageService();
  });

  group('設定画面 結合テスト', () {
    Widget buildSettingsScreen({
      AppSettings? initialSettings,
      bool supportsOnDevice = false,
    }) {
      return ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWithValue(mockStorage),
          settingsProvider.overrideWith(
            () => FakeSettingsNotifier(initialSettings),
          ),
          deviceCapabilityProvider.overrideWith(
            () => _FakeDeviceCapabilityNotifier(supportsOnDevice),
          ),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      );
    }

    testWidgets('文字サイズスライダーが表示される', (tester) async {
      await tester.pumpWidget(buildSettingsScreen());
      await tester.pumpAndSettle();

      expect(find.text('文字の大きさ'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('プレビューテキストが表示される', (tester) async {
      await tester.pumpWidget(buildSettingsScreen());
      await tester.pumpAndSettle();

      expect(find.text('この大きさで\n表示されます'), findsOneWidget);
    });

    testWidgets('コントラスト切替ラジオボタンが表示される', (tester) async {
      await tester.pumpWidget(buildSettingsScreen());
      await tester.pumpAndSettle();

      expect(find.text('画面の色'), findsOneWidget);
      expect(find.text('白い画面'), findsOneWidget);
      expect(find.text('黒い画面（見やすい）'), findsOneWidget);
    });

    testWidgets('フォントサイズラベル「大」「特大」「最大」が表示される', (tester) async {
      await tester.pumpWidget(buildSettingsScreen());
      await tester.pumpAndSettle();

      expect(find.text('大'), findsOneWidget);
      expect(find.text('特大'), findsOneWidget);
      expect(find.text('最大'), findsOneWidget);
    });

    testWidgets('タイトル「せってい」が表示される', (tester) async {
      await tester.pumpWidget(buildSettingsScreen());
      await tester.pumpAndSettle();

      expect(find.text('せってい'), findsOneWidget);
    });

    testWidgets('戻るボタンが表示される', (tester) async {
      await tester.pumpWidget(buildSettingsScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
    });

    testWidgets('高コントラスト設定で画面が表示される', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(
        initialSettings: AppSettings(isHighContrast: true),
      ));
      await tester.pumpAndSettle();

      // 画面が正常にレンダリングされる
      expect(find.text('せってい'), findsOneWidget);
      expect(find.text('文字の大きさ'), findsOneWidget);
    });

    testWidgets('フォントサイズ最大 (3.0) でも画面が正常に表示される', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(
        initialSettings: AppSettings(fontSize: 3.0),
      ));
      await tester.pumpAndSettle();

      // 画面が正常にレンダリングされる
      expect(find.text('せってい'), findsOneWidget);
      expect(find.text('この大きさで\n表示されます'), findsOneWidget);
    });

    testWidgets('オンデバイス非対応の場合、サーバー認識のみ表示されオンデバイス選択肢は表示されない',
        (tester) async {
      await tester.pumpWidget(buildSettingsScreen(supportsOnDevice: false));
      await tester.pumpAndSettle();

      expect(find.text('音声認識の方法'), findsOneWidget);
      expect(find.text('サーバーで認識（通常）'), findsOneWidget);
      expect(find.text('端末のみで認識（オフライン）'), findsNothing);
    });

    testWidgets('オンデバイス対応の場合、音声認識セクションが表示される', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(supportsOnDevice: true));
      await tester.pumpAndSettle();

      expect(find.text('音声認識の方法'), findsOneWidget);
      expect(find.text('サーバーで認識（通常）'), findsOneWidget);
      expect(find.text('端末のみで認識（オフライン）'), findsOneWidget);
    });
  });
}

class _FakeDeviceCapabilityNotifier extends DeviceCapabilityNotifier {
  final bool _value;

  _FakeDeviceCapabilityNotifier(this._value);

  @override
  Future<bool> build() async => _value;
}
