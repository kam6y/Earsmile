import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/conversation.dart';
import 'local_storage_provider.dart';

part 'conversation_list_provider.g.dart';

/// 会話一覧の状態管理 Provider（履歴画面用）
///
/// 生成されるプロバイダ名: conversationListProvider
@riverpod
class ConversationListNotifier extends _$ConversationListNotifier {
  @override
  Future<List<Conversation>> build() async {
    return ref.read(localStorageServiceProvider).getAllConversations();
  }

  /// 会話とそのメッセージを削除し、一覧を更新する
  Future<void> deleteConversation(String uuid) async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.deleteMessages(uuid);
    await storage.deleteConversation(uuid);
    ref.invalidateSelf();
  }
}
