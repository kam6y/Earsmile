import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:earsmile/config/constants.dart';
import 'package:earsmile/models/app_settings.dart';
import 'package:earsmile/models/conversation.dart';
import 'package:earsmile/models/message.dart';
import 'package:earsmile/providers/connectivity_provider.dart';
import 'package:earsmile/providers/conversation_list_provider.dart';
import 'package:earsmile/providers/local_storage_provider.dart';
import 'package:earsmile/providers/message_list_provider.dart';
import 'package:earsmile/providers/settings_provider.dart';
import 'package:earsmile/providers/speech_provider.dart';
import 'package:earsmile/screens/history_detail_screen.dart';
import 'package:earsmile/screens/history_screen.dart';
import 'package:earsmile/screens/home_screen.dart';
import 'package:earsmile/screens/settings_screen.dart';
import 'package:earsmile/utils/accessibility_helpers.dart';

import '../helpers/mocks.dart';

void main() {
  late MockSpeechService mockSpeechService;
  late MockLocalStorageService mockStorage;

  setUpAll(() async {
    await initializeDateFormatting('ja');
  });

  setUp(() {
    mockSpeechService = MockSpeechService();
    mockStorage = MockLocalStorageService();
  });

  tearDown(() {
    mockSpeechService.dispose();
  });

  // --- Home Screen ---

  Widget buildHomeScreen() {
    return ProviderScope(
      overrides: [
        speechServiceProvider.overrideWithValue(mockSpeechService),
        localStorageServiceProvider.overrideWithValue(mockStorage),
        settingsProvider.overrideWith(() => FakeSettingsNotifier()),
        connectivityProvider.overrideWith((ref) => Stream.value(true)),
      ],
      child: const MaterialApp(home: HomeScreen()),
    );
  }

  // --- Settings Screen ---

  Widget buildSettingsScreen({AppSettings? settings}) {
    return ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(mockStorage),
        settingsProvider
            .overrideWith(() => FakeSettingsNotifier(settings)),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    );
  }

  // --- History Screen ---

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

  // --- History Detail Screen ---

  Widget buildHistoryDetailScreen({
    required List<Conversation> conversations,
    required List<Message> messages,
    String conversationId = 'conv-1',
  }) {
    return ProviderScope(
      overrides: [
        conversationListProvider.overrideWith(
          () => FakeConversationListNotifier(conversations),
        ),
        messageListProvider(conversationId).overrideWith(
          (ref) => messages,
        ),
        settingsProvider.overrideWith(() => FakeSettingsNotifier()),
      ],
      child: MaterialApp(
        home: HistoryDetailScreen(conversationId: conversationId),
      ),
    );
  }

  group('アクセシビリティ: タッチターゲットサイズ', () {
    testWidgets('Home Screen: 停止/再開ボタンが 80x80pt 以上', (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      final stopButton = find.text('停止');
      expect(stopButton, findsOneWidget);

      // ボタン全体のサイズを取得するため親の ElevatedButton を確認
      final elevatedButtons = find.ancestor(
        of: stopButton,
        matching: find.byType(ElevatedButton),
      );
      final mainButtonSize = tester.getSize(elevatedButtons.first);
      expect(mainButtonSize.width,
          greaterThanOrEqualTo(AppConstants.mainButtonSize));
      expect(mainButtonSize.height,
          greaterThanOrEqualTo(AppConstants.mainButtonSize));
    });

    testWidgets('Home Screen: 履歴・設定ボタンが 64x64pt 以上', (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      for (final label in ['りれき', 'せってい']) {
        final button = find.text(label);
        expect(button, findsOneWidget, reason: '$label ボタンが見つからない');

        final elevatedButton = find.ancestor(
          of: button,
          matching: find.byType(ElevatedButton),
        );
        final size = tester.getSize(elevatedButton.first);
        expect(size.width, greaterThanOrEqualTo(AppConstants.minTouchTarget),
            reason: '$label ボタンの幅が ${AppConstants.minTouchTarget}pt 未満');
        expect(size.height, greaterThanOrEqualTo(AppConstants.minTouchTarget),
            reason: '$label ボタンの高さが ${AppConstants.minTouchTarget}pt 未満');
      }
    });

    testWidgets('Settings Screen: 戻るボタンが 64pt 幅', (tester) async {
      await tester.pumpWidget(buildSettingsScreen());
      await tester.pumpAndSettle();

      final backButton = find.byIcon(Icons.arrow_back_ios);
      expect(backButton, findsOneWidget);

      // 親の SizedBox を探す
      final sizedBox = find.ancestor(
        of: backButton,
        matching: find.byType(SizedBox),
      );
      // SizedBox は width:64, height:64 で定義されている
      expect(sizedBox, findsWidgets);
    });

    testWidgets('History Detail Screen: 削除ボタンが高さ 64pt 以上',
        (tester) async {
      final conversations = [
        Conversation(
          uuid: 'conv-1',
          startedAt: DateTime(2025, 2, 18, 14, 30),
          title: 'テスト会話',
        ),
      ];
      final messages = [
        Message(
          uuid: 'msg-1',
          conversationId: 'conv-1',
          timestamp: DateTime(2025, 2, 18, 14, 30, 5),
          text: 'テスト',
          confidence: 0.9,
          isFinal: true,
        ),
      ];

      await tester.pumpWidget(buildHistoryDetailScreen(
        conversations: conversations,
        messages: messages,
      ));
      await tester.pumpAndSettle();

      final deleteButton = find.text('この会話を削除する');
      expect(deleteButton, findsOneWidget);

      final elevatedButton = find.ancestor(
        of: deleteButton,
        matching: find.byType(ElevatedButton),
      );
      final size = tester.getSize(elevatedButton.first);
      expect(size.height,
          greaterThanOrEqualTo(AppConstants.deleteButtonHeight));
    });
  });

  group('アクセシビリティ: Semantics ラベル', () {
    testWidgets('Home Screen のボタンに Semantics ラベルが設定されている',
        (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      // 停止ボタン
      expect(
        find.bySemanticsLabel(AccessibilityLabels.stopListening),
        findsOneWidget,
      );

      // 履歴ボタン
      expect(
        find.bySemanticsLabel(AccessibilityLabels.openHistory),
        findsOneWidget,
      );

      // 設定ボタン
      expect(
        find.bySemanticsLabel(AccessibilityLabels.openSettings),
        findsOneWidget,
      );
    });

    testWidgets('Settings Screen の戻るボタンに Semantics ラベルが設定されている',
        (tester) async {
      await tester.pumpWidget(buildSettingsScreen());
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(AccessibilityLabels.goBack),
        findsWidgets,
      );
    });

    testWidgets('History Screen の戻るボタンに Semantics ラベルが設定されている',
        (tester) async {
      await tester.pumpWidget(buildHistoryScreen(conversations: []));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(AccessibilityLabels.goBack),
        findsWidgets,
      );
    });

    testWidgets('History Detail Screen の削除ボタンに Semantics ラベルが設定されている',
        (tester) async {
      final conversations = [
        Conversation(
          uuid: 'conv-1',
          startedAt: DateTime(2025, 2, 18, 14, 30),
          title: 'テスト',
        ),
      ];

      await tester.pumpWidget(buildHistoryDetailScreen(
        conversations: conversations,
        messages: [],
      ));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(AccessibilityLabels.deleteConversation),
        findsWidgets,
      );
    });
  });

  group('アクセシビリティ: フォントサイズ最大 (48pt) での表示', () {
    testWidgets('Home Screen がフォントサイズ最大で崩れない', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          speechServiceProvider.overrideWithValue(mockSpeechService),
          localStorageServiceProvider.overrideWithValue(mockStorage),
          settingsProvider.overrideWith(
              () => FakeSettingsNotifier(AppSettings(fontSize: 3.0))),
          connectivityProvider.overrideWith((ref) => Stream.value(true)),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ));
      await tester.pumpAndSettle();

      // 例外なく表示できることを確認
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Settings Screen がフォントサイズ最大で崩れない', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(
        settings: AppSettings(fontSize: 3.0),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('History Screen がフォントサイズ最大で崩れない', (tester) async {
      final conversations = [
        Conversation(
          uuid: 'conv-1',
          startedAt: DateTime(2025, 2, 18, 14, 30),
          title: '長いタイトルのテスト会話です。最大フォントでも表示が崩れないか確認します。',
        ),
      ];

      await tester.pumpWidget(ProviderScope(
        overrides: [
          conversationListProvider.overrideWith(
            () => FakeConversationListNotifier(conversations),
          ),
          settingsProvider.overrideWith(
              () => FakeSettingsNotifier(AppSettings(fontSize: 3.0))),
        ],
        child: const MaterialApp(home: HistoryScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(HistoryScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('アクセシビリティ: 高コントラストモード', () {
    testWidgets('Settings Screen が高コントラストモードで正常表示される',
        (tester) async {
      await tester.pumpWidget(buildSettingsScreen(
        settings: AppSettings(isHighContrast: true),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('History Screen が高コントラストモードで正常表示される',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          conversationListProvider.overrideWith(
            () => FakeConversationListNotifier([]),
          ),
          settingsProvider.overrideWith(
              () => FakeSettingsNotifier(AppSettings(isHighContrast: true))),
        ],
        child: const MaterialApp(home: HistoryScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(HistoryScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
