import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:earsmile/models/conversation.dart';
import 'package:earsmile/models/message.dart';
import 'package:earsmile/models/app_settings.dart';
import 'package:earsmile/providers/conversation_list_provider.dart';
import 'package:earsmile/providers/message_list_provider.dart';
import 'package:earsmile/providers/settings_provider.dart';
import 'package:earsmile/screens/history_detail_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja');
  });
  final testConversation = Conversation(
    uuid: 'conv-uuid-1',
    startedAt: DateTime(2025, 2, 18, 14, 30),
    title: '2025/02/18 14:30 の会話',
  );

  final testMessages = [
    Message(
      uuid: 'msg-1',
      conversationId: 'conv-uuid-1',
      timestamp: DateTime(2025, 2, 18, 14, 30, 5),
      text: 'こんにちは、今日はいい天気ですね',
      confidence: 0.95,
      isFinal: true,
    ),
    Message(
      uuid: 'msg-2',
      conversationId: 'conv-uuid-1',
      timestamp: DateTime(2025, 2, 18, 14, 30, 15),
      text: 'はい、お出かけ日和です',
      confidence: 0.90,
      isFinal: true,
    ),
  ];

  /// テスト用ヘルパー
  Widget buildTestWidget({
    required List<Conversation> conversations,
    required List<Message> messages,
    String conversationId = 'conv-uuid-1',
  }) {
    return ProviderScope(
      overrides: [
        conversationListProvider.overrideWith(
          () => _FakeConversationListNotifier(conversations),
        ),
        messageListProvider(conversationId).overrideWith(
          (ref) async => messages,
        ),
        settingsProvider.overrideWith(
          () => _FakeSettingsNotifier(),
        ),
      ],
      child: MaterialApp(
        home: HistoryDetailScreen(conversationId: conversationId),
      ),
    );
  }

  group('HistoryDetailScreen', () {
    testWidgets('メッセージ一覧がタイムスタンプ付きで表示される', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        conversations: [testConversation],
        messages: testMessages,
      ));
      await tester.pumpAndSettle();

      // タイムスタンプ
      expect(find.text('14:30:05'), findsOneWidget);
      expect(find.text('14:30:15'), findsOneWidget);

      // メッセージテキスト
      expect(find.text('こんにちは、今日はいい天気ですね'), findsOneWidget);
      expect(find.text('はい、お出かけ日和です'), findsOneWidget);
    });

    testWidgets('タイトルに日付が表示される', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        conversations: [testConversation],
        messages: testMessages,
      ));
      await tester.pumpAndSettle();

      expect(find.text('2月18日の会話'), findsOneWidget);
    });

    testWidgets('削除ボタンが表示される', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        conversations: [testConversation],
        messages: testMessages,
      ));
      await tester.pumpAndSettle();

      expect(find.text('この会話を削除する'), findsOneWidget);
    });

    testWidgets('削除ボタンタップで確認ダイアログが表示される', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        conversations: [testConversation],
        messages: testMessages,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('この会話を削除する'));
      await tester.pumpAndSettle();

      // 確認ダイアログ
      expect(find.text('確認'), findsOneWidget);
      expect(find.text('本当に消しますか？'), findsOneWidget);
      expect(find.text('はい'), findsOneWidget);
      expect(find.text('いいえ'), findsOneWidget);
    });

    testWidgets('確認ダイアログで「いいえ」を選択するとダイアログが閉じる', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        conversations: [testConversation],
        messages: testMessages,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('この会話を削除する'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('いいえ'));
      await tester.pumpAndSettle();

      // ダイアログが閉じ、元の画面に戻っている
      expect(find.text('本当に消しますか？'), findsNothing);
      expect(find.text('この会話を削除する'), findsOneWidget);
    });

    testWidgets('メッセージがない場合「メッセージはありません」が表示される',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        conversations: [testConversation],
        messages: [],
      ));
      await tester.pumpAndSettle();

      expect(find.text('メッセージはありません'), findsOneWidget);
    });
  });
}

/// テスト用 ConversationListNotifier
class _FakeConversationListNotifier extends ConversationListNotifier {
  final List<Conversation> _conversations;

  _FakeConversationListNotifier(this._conversations);

  @override
  Future<List<Conversation>> build() async => _conversations;

  @override
  Future<void> deleteConversation(String uuid) async {
    _conversations.removeWhere((c) => c.uuid == uuid);
    state = AsyncData(List.from(_conversations));
  }
}

/// テスト用 SettingsNotifier
class _FakeSettingsNotifier extends SettingsNotifier {
  @override
  Future<AppSettings> build() async => AppSettings();
}
