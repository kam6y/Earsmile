import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:earsmile/services/speech_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SpeechService speechService;

  setUp(() {
    speechService = SpeechService();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.app.speech/recognizer'),
      (MethodCall call) async {
        switch (call.method) {
          case 'checkPermission':
            return 'granted';
          case 'requestPermission':
            return true;
          case 'startListening':
            return null;
          case 'stopListening':
            return null;
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.app.speech/recognizer'),
      null,
    );
  });

  group('SpeechService', () {
    test('checkPermission は権限状態を返す', () async {
      final result = await speechService.checkPermission();
      expect(result, 'granted');
    });

    test('requestPermission は bool を返す', () async {
      final result = await speechService.requestPermission();
      expect(result, true);
    });

    test('startListening は例外なく完了する', () async {
      await expectLater(speechService.startListening(), completes);
    });

    test('stopListening は例外なく完了する', () async {
      await expectLater(speechService.stopListening(), completes);
    });
  });

  group('SpeechEvent.fromMap', () {
    test('onPartialResult を正しくパースする', () {
      final event = SpeechEvent.fromMap({
        'type': 'onPartialResult',
        'text': 'こんにちは',
        'confidence': 0.85,
      });
      expect(event.type, SpeechEventType.partialResult);
      expect(event.text, 'こんにちは');
      expect(event.confidence, 0.85);
    });

    test('onFinalResult を正しくパースする', () {
      final event = SpeechEvent.fromMap({
        'type': 'onFinalResult',
        'text': 'お元気ですか',
        'confidence': 0.95,
      });
      expect(event.type, SpeechEventType.finalResult);
      expect(event.text, 'お元気ですか');
      expect(event.confidence, 0.95);
    });

    test('onError を正しくパースする', () {
      final event = SpeechEvent.fromMap({
        'type': 'onError',
        'errorCode': 'RECOGNITION_ERROR',
        'message': '認識に失敗しました',
      });
      expect(event.type, SpeechEventType.error);
      expect(event.errorCode, 'RECOGNITION_ERROR');
      expect(event.errorMessage, '認識に失敗しました');
    });

    test('onSilenceDetected を正しくパースする', () {
      final event = SpeechEvent.fromMap({
        'type': 'onSilenceDetected',
      });
      expect(event.type, SpeechEventType.silenceDetected);
    });

    test('未知のイベントタイプは error として返す', () {
      final event = SpeechEvent.fromMap({
        'type': 'unknownEvent',
      });
      expect(event.type, SpeechEventType.error);
      expect(event.errorCode, 'UNKNOWN_EVENT');
    });

    test('confidence が int で渡されても double に変換する', () {
      final event = SpeechEvent.fromMap({
        'type': 'onPartialResult',
        'text': 'テスト',
        'confidence': 1,
      });
      expect(event.confidence, 1.0);
      expect(event.confidence, isA<double>());
    });
  });
}
