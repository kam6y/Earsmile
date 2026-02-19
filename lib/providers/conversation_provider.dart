import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../models/conversation.dart';
import 'local_storage_provider.dart';

part 'conversation_provider.g.dart';

/// 会話の開始・終了・削除を管理する Notifier
///
/// 生成されるプロバイダ名: conversationProvider
@riverpod
class ConversationNotifier extends _$ConversationNotifier {
  final _uuid = const Uuid();

  @override
  Conversation? build() {
    return null;
  }

  /// 新しい会話を開始し、ObjectBox に保存して返す
  Future<Conversation> startNewConversation() async {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy/MM/dd HH:mm');
    final conversation = Conversation(
      uuid: _uuid.v4(),
      startedAt: now,
      title: '${formatter.format(now)} の会話',
    );
    await ref.read(localStorageServiceProvider).saveConversation(conversation);
    state = conversation;
    return conversation;
  }

  /// 現在の会話を終了する（endedAt を設定して保存）
  Future<void> endConversation() async {
    if (state == null) return;
    final conversation = state!;
    conversation.endedAt = DateTime.now();
    await ref.read(localStorageServiceProvider).saveConversation(conversation);
    state = conversation;
  }

  /// 会話とそのメッセージを削除する
  Future<void> deleteConversation(String uuid) async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.deleteMessages(uuid);
    await storage.deleteConversation(uuid);
    if (state?.uuid == uuid) {
      state = null;
    }
  }
}
