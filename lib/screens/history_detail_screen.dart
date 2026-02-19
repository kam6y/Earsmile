import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/constants.dart';
import '../config/theme.dart';
import '../models/message.dart';
import '../providers/conversation_list_provider.dart';
import '../providers/message_list_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/accessibility_helpers.dart';
import '../utils/date_formatter.dart';
import '../widgets/confirmation_dialog.dart';

/// 履歴詳細画面
///
/// 特定の会話の全メッセージをタイムスタンプ付きで表示する。
/// 会話の削除機能を提供する。
class HistoryDetailScreen extends ConsumerWidget {
  final String conversationId;

  const HistoryDetailScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(messageListProvider(conversationId));
    final conversations = ref.watch(conversationListProvider);

    // 会話情報を取得してタイトル表示に使う
    String title = '会話の詳細';
    for (final c in conversations) {
      if (c.uuid == conversationId) {
        title = DateFormatter.toDetailTitleFormat(c.startedAt);
        break;
      }
    }

    return _buildContent(context, ref, messages, title);
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<Message> messages,
    String title,
  ) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final fontSize = resolveBodyFontSize(settings.fontSize);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 64,
        leading: Semantics(
          label: AccessibilityLabels.goBack,
          button: true,
          child: SizedBox(
            width: 64,
            height: 64,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              iconSize: 28,
              onPressed: () => context.pop(),
            ),
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // メッセージ一覧
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      'メッセージはありません',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontSize: fontSize),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _MessageItem(
                        message: message,
                        fontSize: fontSize,
                      );
                    },
                  ),
          ),
          // 削除ボタン
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: AppConstants.deleteButtonHeight,
                child: Semantics(
                  label: AccessibilityLabels.deleteConversation,
                  button: true,
                  child: ElevatedButton(
                    onPressed: () => _onDelete(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: Size.fromHeight(
                          AppConstants.deleteButtonHeight),
                    ),
                    child: Text(
                      'この会話を削除する',
                      style: TextStyle(fontSize: fontSize * 0.75),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmationDialog(
      context,
      message: '本当に消しますか？',
    );
    if (confirmed && context.mounted) {
      ref
          .read(conversationListProvider.notifier)
          .deleteConversation(conversationId);
      if (context.mounted) {
        context.pop();
      }
    }
  }
}

/// メッセージ1件の表示
class _MessageItem extends StatelessWidget {
  final Message message;
  final double fontSize;

  const _MessageItem({
    required this.message,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // タイムスタンプ
          Text(
            DateFormatter.toMessageTimestamp(message.timestamp),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: fontSize * 0.625,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 12),
          // メッセージテキスト
          Expanded(
            child: Text(
              message.text,
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: fontSize),
            ),
          ),
        ],
      ),
    );
  }
}
