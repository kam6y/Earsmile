import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../models/conversation.dart';
import '../utils/date_formatter.dart';
import 'local_storage_provider.dart';

part 'conversation_provider.g.dart';

/// 会話の開始・終了・削除を管理する Notifier
///
/// 生成されるプロバイダ名: conversationProvider
@Riverpod(keepAlive: true)
class ConversationNotifier extends _$ConversationNotifier {
  final _uuid = const Uuid();

  @override
  Conversation? build() {
    return null;
  }

  /// 新しい会話を開始し、ObjectBox に保存して返す
  Conversation startNewConversation() {
    final now = DateTime.now();
    final conversation = Conversation(
      uuid: _uuid.v4(),
      startedAt: now,
      title: DateFormatter.toConversationTitle(now),
    );
    ref.read(localStorageServiceProvider).saveConversation(conversation);
    state = conversation;
    return conversation;
  }

  /// 現在の会話を終了する（endedAt を設定して保存）
  void endConversation() {
    if (state == null) return;
    final conversation = state!;
    conversation.endedAt = DateTime.now();
    ref.read(localStorageServiceProvider).saveConversation(conversation);
    state = conversation;
  }

  /// 会話とそのメッセージを削除する
  void deleteConversation(String uuid) {
    final storage = ref.read(localStorageServiceProvider);
    storage.deleteMessages(uuid);
    storage.deleteConversation(uuid);
    if (state?.uuid == uuid) {
      state = null;
    }
  }
}
