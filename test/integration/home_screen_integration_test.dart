import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:earsmile/providers/connectivity_provider.dart';
import 'package:earsmile/providers/local_storage_provider.dart';
import 'package:earsmile/providers/settings_provider.dart';
import 'package:earsmile/providers/speech_provider.dart';
import 'package:earsmile/screens/home_screen.dart';
import 'package:earsmile/services/speech_service.dart';

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

  Widget buildTestWidget({
    bool isOffline = false,
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('History Route'))),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Settings Route'))),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        speechServiceProvider.overrideWithValue(mockSpeechService),
        localStorageServiceProvider.overrideWithValue(mockStorage),
        settingsProvider.overrideWith(() => FakeSettingsNotifier()),
        connectivityProvider.overrideWith(
          (ref) => Stream.value(!isOffline),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('Home Screen 結合テスト', () {
    testWidgets('画面表示時に会話が開始され音声認識がスタートする', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // 会話が作成されたことを確認
      expect(mockStorage.conversations, hasLength(1));
      // 音声認識が開始されたことを確認
      expect(mockSpeechService.startCalled, isTrue);
    });

    testWidgets('別画面から戻ると新しい会話が自動で開始される', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(mockStorage.conversations, hasLength(1));
      expect(mockSpeechService.startCallCount, 1);

      mockSpeechService.emitEvent(const SpeechEvent(
        type: SpeechEventType.finalResult,
        text: '前回会話のテキスト',
        confidence: 0.9,
      ));
      await tester.pump();
      expect(find.text('前回会話のテキスト'), findsOneWidget);

      await tester.tap(find.text('りれき'));
      await tester.pumpAndSettle();

      expect(find.text('History Route'), findsOneWidget);
      expect(mockSpeechService.stopCallCount, 1);
      expect(mockStorage.conversations.first.endedAt, isNotNull);

      final pushedContext = tester.element(find.text('History Route'));
      Navigator.of(pushedContext).pop();
      await tester.pumpAndSettle();

      expect(mockSpeechService.startCallCount, 2);
      expect(mockStorage.conversations, hasLength(2));
      expect(mockStorage.conversations.last.endedAt, isNull);
      expect(find.text('前回会話のテキスト'), findsNothing);
    });

    testWidgets('partialResult でグレーのテキストが表示される', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      mockSpeechService.emitEvent(const SpeechEvent(
        type: SpeechEventType.partialResult,
        text: '認識中のテキスト',
        confidence: 0.7,
      ));
      await tester.pump();

      expect(find.text('認識中のテキスト'), findsOneWidget);
    });

    testWidgets('finalResult でテキストが確定表示され LocalStorage に保存される', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      mockSpeechService.emitEvent(const SpeechEvent(
        type: SpeechEventType.finalResult,
        text: '確定テキスト',
        confidence: 0.95,
      ));
      await tester.pump();

      expect(find.text('確定テキスト'), findsOneWidget);
      // LocalStorage に保存されたことを確認
      expect(mockStorage.messages, hasLength(1));
      expect(mockStorage.messages.first.text, '確定テキスト');
      expect(mockStorage.messages.first.isFinal, isTrue);
    });

    testWidgets('silenceDetected で partial text が確定される', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // partial result を送信
      mockSpeechService.emitEvent(const SpeechEvent(
        type: SpeechEventType.partialResult,
        text: '無音前テキスト',
        confidence: 0.6,
      ));
      await tester.pump();

      // silence detected を送信
      mockSpeechService.emitEvent(
        const SpeechEvent(type: SpeechEventType.silenceDetected),
      );
      await tester.pump();

      // テキストが確定され、保存されたことを確認
      expect(mockStorage.messages, hasLength(1));
      expect(mockStorage.messages.first.text, '無音前テキスト');
    });

    testWidgets('停止ボタンタップで paused に遷移しボタンが「再開」に変化する', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // listening 状態なので「停止」ボタンが表示される
      expect(find.text('停止'), findsOneWidget);

      await tester.tap(find.text('停止'));
      await tester.pumpAndSettle();

      // 「再開」ボタンに変化
      expect(find.text('再開'), findsOneWidget);
      expect(find.text('停止'), findsNothing);
    });

    testWidgets('再開ボタンタップで listening に戻る', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // 一度停止
      await tester.tap(find.text('停止'));
      await tester.pumpAndSettle();

      // 再開
      await tester.tap(find.text('再開'));
      await tester.pumpAndSettle();

      // 「停止」ボタンに戻る
      expect(find.text('停止'), findsOneWidget);
    });

    testWidgets('エラー状態でエラーバナーが表示される', (tester) async {
      mockSpeechService.shouldThrowOnStart = true;

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // エラーメッセージが表示される
      expect(find.textContaining('音声認識エラー'), findsOneWidget);
    });

    testWidgets('オフライン時にオフラインバナーが表示される', (tester) async {
      await tester.pumpWidget(buildTestWidget(isOffline: true));
      await tester.pumpAndSettle();

      expect(find.text('オフライン（オンデバイス認識中）'), findsOneWidget);
    });

    testWidgets('オンライン時にオフラインバナーが表示されない', (tester) async {
      await tester.pumpWidget(buildTestWidget(isOffline: false));
      await tester.pumpAndSettle();

      expect(find.text('オフライン（オンデバイス認識中）'), findsNothing);
    });

    testWidgets('りれきボタンが表示される', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('りれき'), findsOneWidget);
    });

    testWidgets('せっていボタンが表示される', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('せってい'), findsOneWidget);
    });
  });
}
