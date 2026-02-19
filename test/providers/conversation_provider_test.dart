import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:earsmile/providers/conversation_provider.dart';
import 'package:earsmile/providers/local_storage_provider.dart';
import 'package:earsmile/services/local_storage_service.dart';
import 'package:earsmile/models/conversation.dart';

/// テスト用の LocalStorageService モック
class MockLocalStorageService extends LocalStorageService {
  final List<Conversation> savedConversations = [];
  final List<String> deletedConversationUuids = [];
  final List<String> deletedMessageConversationIds = [];

  @override
  void saveConversation(Conversation conversation) {
    final index =
        savedConversations.indexWhere((c) => c.uuid == conversation.uuid);
    if (index >= 0) {
      savedConversations[index] = conversation;
    } else {
      savedConversations.add(conversation);
    }
  }

  @override
  void deleteConversation(String uuid) {
    deletedConversationUuids.add(uuid);
    savedConversations.removeWhere((c) => c.uuid == uuid);
  }

  @override
  void deleteMessages(String conversationId) {
    deletedMessageConversationIds.add(conversationId);
  }
}

void main() {
  late MockLocalStorageService mockStorage;
  late ProviderContainer container;

  setUp(() {
    mockStorage = MockLocalStorageService();
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(mockStorage),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('ConversationNotifier', () {
    test('初期状態は null', () {
      final state = container.read(conversationProvider);
      expect(state, isNull);
    });

    test('startNewConversation で会話が生成・保存される', () {
      final notifier = container.read(conversationProvider.notifier);
      final conversation = notifier.startNewConversation();

      expect(conversation.uuid, isNotEmpty);
      expect(conversation.title, contains('の会話'));
      expect(conversation.startedAt, isNotNull);
      expect(conversation.endedAt, isNull);

      // ObjectBox に保存されたことを確認
      expect(mockStorage.savedConversations, hasLength(1));
      expect(mockStorage.savedConversations.first.uuid, conversation.uuid);

      // state が更新されたことを確認
      final state = container.read(conversationProvider);
      expect(state?.uuid, conversation.uuid);
    });

    test('endConversation で endedAt が設定される', () {
      final notifier = container.read(conversationProvider.notifier);
      notifier.startNewConversation();
      notifier.endConversation();

      final state = container.read(conversationProvider);
      expect(state?.endedAt, isNotNull);

      // ObjectBox に保存されたことを確認（save が2回呼ばれる）
      expect(mockStorage.savedConversations, hasLength(1));
      expect(mockStorage.savedConversations.first.endedAt, isNotNull);
    });

    test('アクティブ会話がない状態で endConversation を呼んでもエラーにならない',
        () {
      final notifier = container.read(conversationProvider.notifier);
      // 例外が発生しないことを確認
      notifier.endConversation();

      final state = container.read(conversationProvider);
      expect(state, isNull);
    });

    test('deleteConversation でメッセージと会話が削除される', () {
      final notifier = container.read(conversationProvider.notifier);
      final conversation = notifier.startNewConversation();

      notifier.deleteConversation(conversation.uuid);

      // メッセージと会話の削除が呼ばれたことを確認
      expect(mockStorage.deletedMessageConversationIds,
          contains(conversation.uuid));
      expect(mockStorage.deletedConversationUuids,
          contains(conversation.uuid));

      // state が null に戻ったことを確認
      final state = container.read(conversationProvider);
      expect(state, isNull);
    });

    test('別の会話を deleteConversation しても state は変わらない', () {
      final notifier = container.read(conversationProvider.notifier);
      final conversation = notifier.startNewConversation();

      notifier.deleteConversation('other-uuid');

      // アクティブ会話の state は変わらない
      final state = container.read(conversationProvider);
      expect(state?.uuid, conversation.uuid);
    });
  });
}
