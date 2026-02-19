import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:earsmile/models/conversation.dart';
import 'package:earsmile/models/app_settings.dart';
import 'package:earsmile/providers/conversation_list_provider.dart';
import 'package:earsmile/providers/settings_provider.dart';
import 'package:earsmile/screens/history_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja');
  });
  /// テスト用ヘルパー: HistoryScreen を ProviderScope + MaterialApp でラップ
  Widget buildTestWidget({
    required List<Conversation> conversations,
  }) {
    return ProviderScope(
      overrides: [
        conversationListProvider.overrideWith(
          () => _FakeConversationListNotifier(conversations),
        ),
        settingsProvider.overrideWith(
          () => _FakeSettingsNotifier(),
        ),
      ],
      child: const MaterialApp(
        home: HistoryScreen(),
      ),
    );
  }

  group('HistoryScreen', () {
    testWidgets('会話がない場合「りれきはありません」が表示される', (tester) async {
      await tester.pumpWidget(buildTestWidget(conversations: []));
      await tester.pumpAndSettle();

      expect(find.text('りれきはありません'), findsOneWidget);
    });

    testWidgets('会話一覧が日時とタイトルで表示される', (tester) async {
      final conversations = [
        Conversation(
          uuid: 'uuid-1',
          startedAt: DateTime(2025, 2, 18, 14, 30),
          title: '2025/02/18 14:30 の会話',
        ),
        Conversation(
          uuid: 'uuid-2',
          startedAt: DateTime(2025, 2, 17, 10, 0),
          title: '2025/02/17 10:00 の会話',
        ),
      ];

      await tester.pumpWidget(buildTestWidget(conversations: conversations));
      await tester.pumpAndSettle();

      // 日時が表示されること
      expect(find.text('2月18日 14:30'), findsOneWidget);
      expect(find.text('2月17日 10:00'), findsOneWidget);

      // タイトルが表示されること
      expect(find.text('2025/02/18 14:30 の会話'), findsOneWidget);
      expect(find.text('2025/02/17 10:00 の会話'), findsOneWidget);
    });

    testWidgets('戻るボタンが表示される', (tester) async {
      await tester.pumpWidget(buildTestWidget(conversations: []));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
    });

    testWidgets('タイトル「会話りれき」が表示される', (tester) async {
      await tester.pumpWidget(buildTestWidget(conversations: []));
      await tester.pumpAndSettle();

      expect(find.text('会話りれき'), findsOneWidget);
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
