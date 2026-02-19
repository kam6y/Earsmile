import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:earsmile/models/conversation.dart';
import 'package:earsmile/models/message.dart';
import 'package:earsmile/providers/conversation_list_provider.dart';
import 'package:earsmile/providers/message_list_provider.dart';
import 'package:earsmile/providers/settings_provider.dart';
import 'package:earsmile/screens/history_screen.dart';
import 'package:earsmile/screens/history_detail_screen.dart';

import '../helpers/mocks.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja');
  });

  final testConversations = [
    Conversation(
      uuid: 'conv-1',
      startedAt: DateTime(2025, 2, 18, 14, 30),
      title: '2025/02/18 14:30 の会話',
    ),
    Conversation(
      uuid: 'conv-2',
      startedAt: DateTime(2025, 2, 17, 10, 0),
      title: '2025/02/17 10:00 の会話',
    ),
  ];

  final testMessages = [
    Message(
      uuid: 'msg-1',
      conversationId: 'conv-1',
      timestamp: DateTime(2025, 2, 18, 14, 30, 5),
      text: 'こんにちは、今日はいい天気ですね',
      confidence: 0.95,
      isFinal: true,
    ),
    Message(
      uuid: 'msg-2',
      conversationId: 'conv-1',
      timestamp: DateTime(2025, 2, 18, 14, 30, 15),
      text: 'はい、お出かけ日和です',
      confidence: 0.90,
      isFinal: true,
    ),
  ];

  group('履歴一覧画面 結合テスト', () {
    Widget buildHistoryScreen({required List<Conversation> conversations}) {
      return ProviderScope(
        overrides: [
          conversationListProvider.overrideWith(
            () => FakeConversationListNotifier(conversations),
          ),
          settingsProvider.overrideWith(() => FakeSettingsNotifier()),
        ],
        child: const MaterialApp(home: HistoryScreen()),
      );
    }

    testWidgets('会話一覧が日付降順で表示される', (tester) async {
      await tester.pumpWidget(
          buildHistoryScreen(conversations: List.from(testConversations)));
      await tester.pumpAndSettle();

      // 両方の日時が表示される
      expect(find.text('2月18日 14:30'), findsOneWidget);
      expect(find.text('2月17日 10:00'), findsOneWidget);

      // タイトルが表示される
      expect(find.text('2025/02/18 14:30 の会話'), findsOneWidget);
      expect(find.text('2025/02/17 10:00 の会話'), findsOneWidget);
    });

    testWidgets('空の履歴で「りれきはありません」が表示される', (tester) async {
      await tester.pumpWidget(buildHistoryScreen(conversations: []));
      await tester.pumpAndSettle();

      expect(find.text('りれきはありません'), findsOneWidget);
    });
  });

  group('履歴詳細画面 結合テスト', () {
    Widget buildDetailScreen({
      required List<Conversation> conversations,
      required List<Message> messages,
      String conversationId = 'conv-1',
    }) {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const Scaffold(body: Text('一覧画面')),
            routes: [
              GoRoute(
                path: 'detail',
                builder: (_, __) =>
                    HistoryDetailScreen(conversationId: conversationId),
              ),
            ],
          ),
        ],
      );
      // /detail へ遷移してスタックを作る
      router.go('/detail');

      return ProviderScope(
        overrides: [
          conversationListProvider.overrideWith(
            () => FakeConversationListNotifier(conversations),
          ),
          messageListProvider(conversationId).overrideWith(
            (ref) async => messages,
          ),
          settingsProvider.overrideWith(() => FakeSettingsNotifier()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    testWidgets('メッセージがタイムスタンプ付きで表示される', (tester) async {
      await tester.pumpWidget(buildDetailScreen(
        conversations: List.from(testConversations),
        messages: testMessages,
      ));
      await tester.pumpAndSettle();

      expect(find.text('14:30:05'), findsOneWidget);
      expect(find.text('14:30:15'), findsOneWidget);
      expect(find.text('こんにちは、今日はいい天気ですね'), findsOneWidget);
      expect(find.text('はい、お出かけ日和です'), findsOneWidget);
    });

    testWidgets('タイトルに日付が表示される', (tester) async {
      await tester.pumpWidget(buildDetailScreen(
        conversations: List.from(testConversations),
        messages: testMessages,
      ));
      await tester.pumpAndSettle();

      expect(find.text('2月18日の会話'), findsOneWidget);
    });

    testWidgets('削除→確認「はい」で会話が削除される', (tester) async {
      final conversations = List<Conversation>.from(testConversations);
      await tester.pumpWidget(buildDetailScreen(
        conversations: conversations,
        messages: testMessages,
      ));
      await tester.pumpAndSettle();

      // 削除ボタンをタップ
      await tester.tap(find.text('この会話を削除する'));
      await tester.pumpAndSettle();

      // 確認ダイアログが表示される
      expect(find.text('本当に消しますか？'), findsOneWidget);

      // 「はい」をタップ
      await tester.tap(find.text('はい'));
      await tester.pumpAndSettle();

      // 会話が削除された（conversationsリストから除去された）
      expect(conversations.any((c) => c.uuid == 'conv-1'), isFalse);
    });

    testWidgets('削除→確認「いいえ」でダイアログが閉じ会話は残る', (tester) async {
      final conversations = List<Conversation>.from(testConversations);
      await tester.pumpWidget(buildDetailScreen(
        conversations: conversations,
        messages: testMessages,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('この会話を削除する'));
      await tester.pumpAndSettle();

      // 「いいえ」をタップ
      await tester.tap(find.text('いいえ'));
      await tester.pumpAndSettle();

      // ダイアログが閉じている
      expect(find.text('本当に消しますか？'), findsNothing);
      // 会話は残っている
      expect(conversations.any((c) => c.uuid == 'conv-1'), isTrue);
      // 元の画面が表示されている
      expect(find.text('この会話を削除する'), findsOneWidget);
    });

    testWidgets('メッセージがない場合「メッセージはありません」が表示される',
        (tester) async {
      await tester.pumpWidget(buildDetailScreen(
        conversations: List.from(testConversations),
        messages: [],
      ));
      await tester.pumpAndSettle();

      expect(find.text('メッセージはありません'), findsOneWidget);
    });
  });
}
