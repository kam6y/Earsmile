import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/constants.dart';
import '../config/theme.dart';
import '../models/conversation.dart';
import '../providers/conversation_list_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/accessibility_helpers.dart';
import '../utils/date_formatter.dart';

/// 履歴一覧画面
///
/// 過去の会話ログを日付降順で一覧表示する。
/// 各リストアイテムをタップすると履歴詳細画面へ遷移する。
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationListProvider);

    return conversationsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => Scaffold(
        body: Center(child: Text('エラーが発生しました: $e')),
      ),
      data: (conversations) => _buildContent(context, ref, conversations),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<Conversation> conversations,
  ) {
    final theme = Theme.of(context);
    final settingsAsync = ref.watch(settingsProvider);
    final fontSize = switch (settingsAsync) {
      AsyncData(:final value) => resolveBodyFontSize(value.fontSize),
      _ => resolveBodyFontSize(1.0),
    };

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
          '会話りれき',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: conversations.isEmpty
          ? Center(
              child: Text(
                'りれきはありません',
                style: theme.textTheme.bodyLarge?.copyWith(fontSize: fontSize),
              ),
            )
          : ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                return _ConversationListItem(
                  conversation: conversation,
                  fontSize: fontSize,
                  onTap: () =>
                      context.push('/history/${conversation.uuid}'),
                );
              },
            ),
    );
  }
}

/// 会話リストの1アイテム
class _ConversationListItem extends StatelessWidget {
  final Conversation conversation;
  final double fontSize;
  final VoidCallback onTap;

  const _ConversationListItem({
    required this.conversation,
    required this.fontSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: '${DateFormatter.toHistoryListFormat(conversation.startedAt)}の会話',
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppConstants.historyItemMinHeight,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor,
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 上段: 日時（太字）
              Text(
                DateFormatter.toHistoryListFormat(conversation.startedAt),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              // 下段: タイトル（最大2行、末尾省略）
              Text(
                conversation.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: fontSize * 0.75,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
