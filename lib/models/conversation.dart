import 'package:objectbox/objectbox.dart';

@Entity()
class Conversation {
  int id;

  /// UUID v4 (外部連携用)
  @Index()
  @Unique()
  String uuid;

  /// 会話開始時刻
  @Index()
  @Property(type: PropertyType.date)
  DateTime startedAt;

  /// 会話終了時刻（オプション）
  @Property(type: PropertyType.date)
  DateTime? endedAt;

  /// タイトル: "YYYY/MM/DD HH:mm の会話"
  String title;

  bool isFavorite;

  /// Firestore同期済みフラグ
  bool isSyncedToCloud;

  Conversation({
    this.id = 0,
    required this.uuid,
    required this.startedAt,
    this.endedAt,
    required this.title,
    this.isFavorite = false,
    this.isSyncedToCloud = false,
  });
}
