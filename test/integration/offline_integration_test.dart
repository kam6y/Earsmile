import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:earsmile/providers/connectivity_provider.dart';
import 'package:earsmile/providers/local_storage_provider.dart';
import 'package:earsmile/providers/settings_provider.dart';
import 'package:earsmile/providers/speech_provider.dart';
import 'package:earsmile/screens/home_screen.dart';

import '../helpers/mocks.dart';

void main() {
  late MockSpeechService mockSpeechService;
  late MockLocalStorageService mockStorage;

  setUp(() {
    mockSpeechService = MockSpeechService();
    mockStorage = MockLocalStorageService();
  });

  tearDown(() {
    mockSpeechService.dispose();
  });

  Widget buildHomeWidget({
    required Stream<bool> connectivityStream,
  }) {
    return ProviderScope(
      overrides: [
        speechServiceProvider.overrideWithValue(mockSpeechService),
        localStorageServiceProvider.overrideWithValue(mockStorage),
        settingsProvider.overrideWith(() => FakeSettingsNotifier()),
        connectivityProvider.overrideWith((ref) => connectivityStream),
      ],
      child: const MaterialApp(home: HomeScreen()),
    );
  }

  group('オフライン動作 結合テスト', () {
    testWidgets('オフライン時にバナーが表示される', (tester) async {
      await tester.pumpWidget(
        buildHomeWidget(connectivityStream: Stream.value(false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('オフライン（オンデバイス認識中）'), findsOneWidget);
    });

    testWidgets('オンライン時にバナーが表示されない', (tester) async {
      await tester.pumpWidget(
        buildHomeWidget(connectivityStream: Stream.value(true)),
      );
      await tester.pumpAndSettle();

      expect(find.text('オフライン（オンデバイス認識中）'), findsNothing);
    });

    testWidgets('オフライン→オンライン遷移でバナーが消える', (tester) async {
      final controller = StreamController<bool>.broadcast();

      await tester.pumpWidget(
        buildHomeWidget(connectivityStream: controller.stream),
      );

      // オフライン値を送信してウィジェットを更新
      controller.add(false);
      await tester.pumpAndSettle();

      expect(find.text('オフライン（オンデバイス認識中）'), findsOneWidget);

      // オンラインに遷移
      controller.add(true);
      await tester.pumpAndSettle();

      expect(find.text('オフライン（オンデバイス認識中）'), findsNothing);

      controller.close();
    });

    testWidgets('オンライン→オフライン遷移でバナーが表示される', (tester) async {
      final controller = StreamController<bool>.broadcast();

      await tester.pumpWidget(
        buildHomeWidget(connectivityStream: controller.stream),
      );

      // オンライン値を送信
      controller.add(true);
      await tester.pumpAndSettle();

      expect(find.text('オフライン（オンデバイス認識中）'), findsNothing);

      // オフラインに遷移
      controller.add(false);
      await tester.pumpAndSettle();

      expect(find.text('オフライン（オンデバイス認識中）'), findsOneWidget);

      controller.close();
    });
  });
}
