import 'package:objectbox/objectbox.dart';

@Entity()
class Message {
  int id;

  /// UUID v4 (外部連携用)
  @Index()
  @Unique()
  String uuid;

  /// 親ConversationのUUID
  @Index()
  String conversationId;

  @Index()
  @Property(type: PropertyType.date)
  DateTime timestamp;

  /// 認識テキスト内容
  String text;

  /// 認識信頼度 (0.0 ~ 1.0)
  double confidence;

  /// 確定済みテキストか (false = 認識中)
  bool isFinal;

  Message({
    this.id = 0,
    required this.uuid,
    required this.conversationId,
    required this.timestamp,
    required this.text,
    this.confidence = 0.0,
    this.isFinal = false,
  });
}
