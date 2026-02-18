import 'package:flutter_test/flutter_test.dart';
import 'package:earsmile/models/app_settings.dart';
import 'package:earsmile/models/conversation.dart';
import 'package:earsmile/models/message.dart';

void main() {
  group('AppSettings', () {
    test('デフォルト値が正しい', () {
      final settings = AppSettings();
      expect(settings.id, equals(0));
      expect(settings.fontSize, equals(1.0));
      expect(settings.isHighContrast, isFalse);
    });

    test('指定値で生成できる', () {
      final settings = AppSettings(
        id: 1,
        fontSize: 3.0,
        isHighContrast: true,
      );
      expect(settings.id, equals(1));
      expect(settings.fontSize, equals(3.0));
      expect(settings.isHighContrast, isTrue);
    });

    test('有効なフォントサイズのスケール値を設定できる', () {
      final small = AppSettings(fontSize: 1.0);
      final medium = AppSettings(fontSize: 2.0);
      final large = AppSettings(fontSize: 3.0);
      expect(small.fontSize, equals(1.0));
      expect(medium.fontSize, equals(2.0));
      expect(large.fontSize, equals(3.0));
    });
  });

  group('Conversation', () {
    late DateTime now;

    setUp(() {
      now = DateTime.now();
    });

    test('必須フィールドで生成できる', () {
      final conv = Conversation(
        uuid: 'test-uuid-1234',
        startedAt: now,
        title: '2024/01/01 12:00 の会話',
      );
      expect(conv.id, equals(0));
      expect(conv.uuid, equals('test-uuid-1234'));
      expect(conv.startedAt, equals(now));
      expect(conv.endedAt, isNull);
      expect(conv.title, equals('2024/01/01 12:00 の会話'));
      expect(conv.isFavorite, isFalse);
      expect(conv.isSyncedToCloud, isFalse);
    });

    test('全フィールドで生成できる', () {
      final endTime = now.add(const Duration(minutes: 30));
      final conv = Conversation(
        id: 1,
        uuid: 'test-uuid-5678',
        startedAt: now,
        endedAt: endTime,
        title: '2024/01/01 12:00 の会話',
        isFavorite: true,
        isSyncedToCloud: true,
      );
      expect(conv.id, equals(1));
      expect(conv.endedAt, equals(endTime));
      expect(conv.isFavorite, isTrue);
      expect(conv.isSyncedToCloud, isTrue);
    });
  });

  group('Message', () {
    late DateTime now;

    setUp(() {
      now = DateTime.now();
    });

    test('必須フィールドで生成できる', () {
      final msg = Message(
        uuid: 'msg-uuid-1234',
        conversationId: 'conv-uuid-1234',
        timestamp: now,
        text: 'こんにちは',
      );
      expect(msg.id, equals(0));
      expect(msg.uuid, equals('msg-uuid-1234'));
      expect(msg.conversationId, equals('conv-uuid-1234'));
      expect(msg.timestamp, equals(now));
      expect(msg.text, equals('こんにちは'));
      expect(msg.confidence, equals(0.0));
      expect(msg.isFinal, isFalse);
    });

    test('全フィールドで生成できる', () {
      final msg = Message(
        id: 1,
        uuid: 'msg-uuid-5678',
        conversationId: 'conv-uuid-5678',
        timestamp: now,
        text: '音声認識テスト',
        confidence: 0.95,
        isFinal: true,
      );
      expect(msg.id, equals(1));
      expect(msg.confidence, equals(0.95));
      expect(msg.isFinal, isTrue);
    });

    test('confidenceは0.0〜1.0の範囲で設定できる', () {
      final low = Message(
        uuid: 'u1',
        conversationId: 'c1',
        timestamp: now,
        text: 'test',
        confidence: 0.0,
      );
      final high = Message(
        uuid: 'u2',
        conversationId: 'c1',
        timestamp: now,
        text: 'test',
        confidence: 1.0,
      );
      expect(low.confidence, equals(0.0));
      expect(high.confidence, equals(1.0));
    });
  });
}
