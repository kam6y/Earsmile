import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:earsmile/providers/speech_provider.dart';
import 'package:earsmile/providers/local_storage_provider.dart';
import 'package:earsmile/services/speech_service.dart';
import 'package:earsmile/services/local_storage_service.dart';
import 'package:earsmile/models/message.dart';

/// テスト用の SpeechService モック
///
/// sync: true により、emitEvent で追加したイベントは即座にリスナーに届く。
class MockSpeechService extends SpeechService {
  final StreamController<SpeechEvent> _controller =
      StreamController<SpeechEvent>.broadcast(sync: true);
  bool startCalled = false;
  bool stopCalled = false;
  bool shouldThrowOnStart = false;

  MockSpeechService() : super();

  @override
  Future<void> startListening() async {
    if (shouldThrowOnStart) {
      throw Exception('Start failed');
    }
    startCalled = true;
  }

  @override
  Future<void> stopListening() async {
    stopCalled = true;
  }

  @override
  Stream<SpeechEvent> get eventStream => _controller.stream;

  void emitEvent(SpeechEvent event) {
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}

/// テスト用の LocalStorageService モック
class MockLocalStorageService extends LocalStorageService {
  final List<Message> savedMessages = [];

  @override
  Future<void> addMessage(Message message) async {
    savedMessages.add(message);
  }
}

void main() {
  late MockSpeechService mockSpeechService;
  late MockLocalStorageService mockLocalStorageService;
  late ProviderContainer container;

  setUp(() {
    mockSpeechService = MockSpeechService();
    mockLocalStorageService = MockLocalStorageService();
    container = ProviderContainer(
      overrides: [
        speechServiceProvider.overrideWithValue(mockSpeechService),
        localStorageServiceProvider.overrideWithValue(mockLocalStorageService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    mockSpeechService.dispose();
  });

  group('SpeechNotifier', () {
    test('初期状態は idle', () {
      final state = container.read(speechProvider);
      expect(state.status, SpeechStatus.idle);
      expect(state.currentPartialText, '');
      expect(state.confirmedMessages, isEmpty);
    });

    test('conversationId 未設定時は startListening が何もしない', () async {
      final notifier = container.read(speechProvider.notifier);
      await notifier.startListening();

      final state = container.read(speechProvider);
      expect(state.status, SpeechStatus.idle);
      expect(mockSpeechService.startCalled, false);
    });

    test('startListening で status が listening に遷移する', () async {
      final notifier = container.read(speechProvider.notifier);
      notifier.setConversationId('test-conversation-id');
      await notifier.startListening();

      final state = container.read(speechProvider);
      expect(state.status, SpeechStatus.listening);
      expect(mockSpeechService.startCalled, true);
    });

    test('startListening 失敗時は status が error に遷移する', () async {
      mockSpeechService.shouldThrowOnStart = true;

      final notifier = container.read(speechProvider.notifier);
      notifier.setConversationId('test-conversation-id');
      await notifier.startListening();

      final state = container.read(speechProvider);
      expect(state.status, SpeechStatus.error);
    });

    test('pause で status が paused に遷移する', () async {
      final notifier = container.read(speechProvider.notifier);
      notifier.setConversationId('test-conversation-id');
      await notifier.startListening();
      await notifier.pause();

      final state = container.read(speechProvider);
      expect(state.status, SpeechStatus.paused);
      expect(mockSpeechService.stopCalled, true);
    });

    test('resume で status が listening に戻る', () async {
      final notifier = container.read(speechProvider.notifier);
      notifier.setConversationId('test-conversation-id');
      await notifier.startListening();
      await notifier.pause();
      await notifier.resume();

      final state = container.read(speechProvider);
      expect(state.status, SpeechStatus.listening);
    });

    test('stop で status が idle に遷移する', () async {
      final notifier = container.read(speechProvider.notifier);
      notifier.setConversationId('test-conversation-id');
      await notifier.startListening();
      await notifier.stop();

      final state = container.read(speechProvider);
      expect(state.status, SpeechStatus.idle);
    });

    test('partialResult イベントで currentPartialText が更新される', () async {
      final notifier = container.read(speechProvider.notifier);
      notifier.setConversationId('test-conversation-id');
      await notifier.startListening();

      mockSpeechService.emitEvent(const SpeechEvent(
        type: SpeechEventType.partialResult,
        text: 'こんにち',
        confidence: 0.7,
      ));


      final state = container.read(speechProvider);
      expect(state.currentPartialText, 'こんにち');
      expect(state.currentConfidence, 0.7);
    });

    test('finalResult イベントで confirmedMessages に追加される', () async {
      final notifier = container.read(speechProvider.notifier);
      notifier.setConversationId('test-conversation-id');
      await notifier.startListening();

      mockSpeechService.emitEvent(const SpeechEvent(
        type: SpeechEventType.finalResult,
        text: 'こんにちは',
        confidence: 0.95,
      ));



      final state = container.read(speechProvider);
      expect(state.confirmedMessages, hasLength(1));
      expect(state.confirmedMessages.first.text, 'こんにちは');
      expect(state.confirmedMessages.first.isFinal, true);
      expect(state.confirmedMessages.first.conversationId,
          'test-conversation-id');
      expect(state.currentPartialText, '');
    });

    test('finalResult で LocalStorageService に保存される', () async {
      final notifier = container.read(speechProvider.notifier);
      notifier.setConversationId('test-conversation-id');
      await notifier.startListening();

      mockSpeechService.emitEvent(const SpeechEvent(
        type: SpeechEventType.finalResult,
        text: 'テスト保存',
        confidence: 0.9,
      ));



      expect(mockLocalStorageService.savedMessages, hasLength(1));
      expect(mockLocalStorageService.savedMessages.first.text, 'テスト保存');
    });

    test('silenceDetected で partial text が確定される', () async {
      final notifier = container.read(speechProvider.notifier);
      notifier.setConversationId('test-conversation-id');
      await notifier.startListening();

      // まず partial result を送信
      mockSpeechService.emitEvent(const SpeechEvent(
        type: SpeechEventType.partialResult,
        text: '認識中テキスト',
        confidence: 0.6,
      ));


      // 次に silence detected を送信
      mockSpeechService.emitEvent(
          const SpeechEvent(type: SpeechEventType.silenceDetected));


      final state = container.read(speechProvider);
      expect(state.confirmedMessages, hasLength(1));
      expect(state.confirmedMessages.first.text, '認識中テキスト');
      expect(state.currentPartialText, '');
    });

    test('silenceDetected で partial text が空の場合は何もしない', () async {
      final notifier = container.read(speechProvider.notifier);
      notifier.setConversationId('test-conversation-id');
      await notifier.startListening();

      mockSpeechService.emitEvent(
          const SpeechEvent(type: SpeechEventType.silenceDetected));


      final state = container.read(speechProvider);
      expect(state.confirmedMessages, isEmpty);
    });

    test('エラー3回で status が error に遷移する', () async {
      final notifier = container.read(speechProvider.notifier);
      notifier.setConversationId('test-conversation-id');
      await notifier.startListening();

      for (var i = 0; i < 3; i++) {
        mockSpeechService.emitEvent(const SpeechEvent(
          type: SpeechEventType.error,
          errorCode: 'RECOGNITION_ERROR',
          errorMessage: '認識エラー',
        ));
  
      }

      final state = container.read(speechProvider);
      expect(state.status, SpeechStatus.error);
      expect(state.errorMessage, '認識エラー');
    });
  });

  group('SpeechState', () {
    test('copyWith でフィールドを部分更新できる', () {
      const original = SpeechState();
      final updated = original.copyWith(
        status: SpeechStatus.listening,
        currentPartialText: 'テスト',
      );

      expect(updated.status, SpeechStatus.listening);
      expect(updated.currentPartialText, 'テスト');
      expect(updated.confirmedMessages, isEmpty);
      expect(updated.retryCount, 0);
    });

    test('copyWith で errorMessage を null にクリアできる', () {
      final withError = const SpeechState().copyWith(
        errorMessage: 'エラー',
      );
      expect(withError.errorMessage, 'エラー');

      final cleared = withError.copyWith(errorMessage: null);
      expect(cleared.errorMessage, isNull);
    });
  });
}
