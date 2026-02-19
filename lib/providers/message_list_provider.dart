import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/message.dart';
import 'local_storage_provider.dart';

part 'message_list_provider.g.dart';

/// 指定した会話のメッセージ一覧を取得する Provider
///
/// 生成されるプロバイダ名: messageListProvider
@riverpod
Future<List<Message>> messageList(
  Ref ref,
  String conversationId,
) async {
  return ref.read(localStorageServiceProvider).getMessages(conversationId);
}
