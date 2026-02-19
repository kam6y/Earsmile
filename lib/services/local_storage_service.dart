import 'package:path_provider/path_provider.dart';

import '../models/app_settings.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../objectbox.g.dart';

class LocalStorageService {
  late Store _store;
  late Box<AppSettings> _settingsBox;
  late Box<Conversation> _conversationBox;
  late Box<Message> _messageBox;

  Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    _store = await openStore(directory: '${dir.path}/objectbox');
    _settingsBox = _store.box<AppSettings>();
    _conversationBox = _store.box<Conversation>();
    _messageBox = _store.box<Message>();
  }

  void close() {
    _store.close();
  }

  // -------------------------
  // 設定 (AppSettings)
  // -------------------------

  /// 設定を保存する（常に id=1 の1レコードのみ維持）
  void saveSettings(AppSettings settings) {
    settings.id = 1;
    _settingsBox.put(settings);
  }

  /// 設定を読み込む（未保存の場合はデフォルト値を返す）
  AppSettings loadSettings() {
    return _settingsBox.get(1) ?? AppSettings();
  }

  // -------------------------
  // 会話 (Conversation)
  // -------------------------

  /// 会話を保存する（新規作成・更新ともに使用）
  void saveConversation(Conversation conversation) {
    _conversationBox.put(conversation);
  }

  /// 全会話を開始日時の降順で返す
  List<Conversation> getAllConversations() {
    final query = _conversationBox
        .query()
        .order(Conversation_.startedAt, flags: Order.descending)
        .build();
    final results = query.find();
    query.close();
    return results;
  }

  /// UUIDで指定した会話を削除する
  void deleteConversation(String uuid) {
    final query = _conversationBox
        .query(Conversation_.uuid.equals(uuid))
        .build();
    final conversations = query.find();
    query.close();
    for (final conversation in conversations) {
      _conversationBox.remove(conversation.id);
    }
  }

  // -------------------------
  // メッセージ (Message)
  // -------------------------

  /// メッセージを追加する
  void addMessage(Message message) {
    _messageBox.put(message);
  }

  /// 指定した会話のメッセージをタイムスタンプ昇順で返す
  List<Message> getMessages(String conversationId) {
    final query = _messageBox
        .query(Message_.conversationId.equals(conversationId))
        .order(Message_.timestamp)
        .build();
    final results = query.find();
    query.close();
    return results;
  }

  /// 指定した会話のメッセージを全て削除する
  void deleteMessages(String conversationId) {
    final query = _messageBox
        .query(Message_.conversationId.equals(conversationId))
        .build();
    final messages = query.find();
    query.close();
    final ids = messages.map((m) => m.id).toList();
    _messageBox.removeMany(ids);
  }
}
