# 詳細設計書：聴覚障害・難聴の高齢者向け音声テキスト化アプリ

## 1. システム構成

### 1.1 技術スタック

| レイヤー | 技術 | バージョン |
|---------|------|-----------|
| Frontend | Flutter | 3.x (最新安定版) |
| 状態管理 | Riverpod | 2.x |
| ローカルDB | ObjectBox | 5.x |
| 音声認識 | Apple Speech Framework (SFSpeechRecognizer) | iOS 16+ |
| 認証 | Firebase Authentication | - |
| クラウドDB | Cloud Firestore | - |
| サーバーレス | Cloud Functions for Firebase | Node.js 18 |
| AI変換 (Ver 2.0) | OpenAI Whisper API | - |

### 1.2 ディレクトリ構成

```
lib/
├── main.dart
├── app.dart
├── config/
│   ├── theme.dart              # テーマ定義（通常/高コントラスト）
│   ├── constants.dart           # 定数定義
│   └── routes.dart              # ルーティング定義
├── models/
│   ├── conversation.dart        # 会話モデル
│   ├── message.dart             # メッセージモデル
│   └── app_settings.dart        # 設定モデル
├── providers/
│   ├── speech_provider.dart     # 音声認識状態管理
│   ├── settings_provider.dart   # 設定状態管理
│   ├── conversation_provider.dart # 会話データ管理
│   └── auth_provider.dart       # 認証状態管理
├── services/
│   ├── speech_service.dart      # 音声認識サービス
│   ├── audio_level_service.dart # 音声レベル取得
│   ├── local_storage_service.dart # ローカル保存
│   ├── firestore_service.dart   # Firestore操作
│   └── auth_service.dart        # Firebase Auth操作
├── screens/
│   ├── splash_screen.dart       # スプラッシュ画面
│   ├── home_screen.dart         # ホーム（聴取）画面
│   ├── history_screen.dart      # 履歴一覧画面
│   ├── history_detail_screen.dart # 履歴詳細画面
│   └── settings_screen.dart     # 設定画面
├── widgets/
│   ├── transcript_view.dart     # テキスト表示エリア
│   ├── control_panel.dart       # 操作パネル
│   ├── waveform_indicator.dart  # 波形アニメーション
│   ├── phrase_buttons.dart      # 定型文ボタン
│   ├── large_button.dart        # 大型ボタン共通Widget
│   ├── confirmation_dialog.dart # 確認ダイアログ
│   └── offline_banner.dart      # オフライン表示バナー
└── utils/
    ├── date_formatter.dart      # 日付フォーマット
    └── accessibility_helpers.dart # アクセシビリティ補助
```

---

## 2. データモデル詳細設計

### 2.1 ローカルモデル (Dart クラス)

#### AppSettings

```dart
@Entity()
class AppSettings {
  int id = 0; // ObjectBoxではIDはint型、初期値0で自動採番

  double fontSize;       // 1.0(大/24pt), 2.0(特大/32pt), 3.0(最大/48pt)

  bool isHighContrast;   // true: 黒背景+黄文字, false: 白背景+黒文字
}
```

| フィールド | 型 | デフォルト値 | 説明 |
|-----------|-----|------------|------|
| fontSize | double | 1.0 | フォントサイズスケール |
| isHighContrast | bool | false | 高コントラストモード |

#### Conversation

```dart
@Entity()
class Conversation {
  int id = 0;

  @Index()
  @Unique()
  String uuid;           // UUID v4 (外部連携用)

  @Index()
  DateTime startedAt;

  DateTime? endedAt;

  String title;          // "YYYY/MM/DD HH:mm の会話"

  bool isFavorite;

  bool isSyncedToCloud;  // Firestore同期済みフラグ
}
```

#### Message

```dart
@Entity()
class Message {
  int id = 0;

  @Index()
  @Unique()
  String uuid;           // UUID v4 (外部連携用)

  @Index()
  String conversationId; // 親ConversationのUUID

  @Index()
  DateTime timestamp;

  String text;

  double confidence;     // 0.0 ~ 1.0

  bool isFinal;          // 確定済みテキストか
}
```

### 2.2 Firestore スキーマ

```
users/
  {userId}/
    - createdAt: Timestamp
    - lastLogin: Timestamp
    - platform: String ("ios" | "ipados")
    - appVersion: String
    - settings:
        - fontSize: Number
        - isHighContrast: Boolean
    conversations/
      {conversationId}/
        - startedAt: Timestamp
        - endedAt: Timestamp
        - title: String
        - isFavorite: Boolean
        messages/
          {messageId}/
            - timestamp: Timestamp
            - text: String
            - confidence: Number
            - isFinal: Boolean
```

### 2.3 ObjectBox Box 構成

| Box名 | クラス | 用途 |
|-------|-----|------|
| `Box<AppSettings>` | `AppSettings` | アプリ設定（1レコード） |
| `Box<Conversation>` | `Conversation` | 会話一覧 |
| `Box<Message>` | `Message` | 全メッセージ |

---

## 3. 画面設計

### 3.1 Splash Screen

**目的**: 初期化処理の実行とユーザー待機

**処理フロー**:
1. ロゴ表示（アプリアイコン中央配置）
2. Firebase匿名認証実行（初回のみ）
3. マイク権限チェック
   - 未許可 → 権限リクエストダイアログ表示
   - 拒否済み → 設定誘導画面へ遷移
4. ObjectBox初期化・設定読み込み
5. Home Screen へ遷移

**画面レイアウト**:
```
┌─────────────────────────┐
│                         │
│                         │
│        [App Logo]       │
│                         │
│     アプリ名テキスト      │
│                         │
│      [ローディング]       │
│                         │
└─────────────────────────┘
```

**遷移条件**: 全初期化完了後、自動遷移（最大3秒タイムアウト）

---

### 3.2 Home Screen（聴取画面）

**目的**: メイン機能。音声のリアルタイムテキスト化と表示

**画面レイアウト**:
```
┌─────────────────────────────┐
│ [オフラインバナー]  ← 必要時のみ │
├─────────────────────────────┤
│                             │
│   認識テキスト表示エリア       │
│   (ListView - 自動スクロール)  │
│                             │
│   「こんにちは、今日は        │
│     天気がいいですね」        │
│                             │
│   「はい、散歩日和です」      │
│                             │
│   「午後から...」 ← 認識中     │
│                             │
├─────────────────────────────┤
│  [波形インジケーター]          │
├─────────────────────────────┤
│                             │
│  [ ⏸ 停止 ]    [履歴] [設定] │
│  (64x64pt↑)                 │
└─────────────────────────────┘
```

**Widget構成**:

| Widget | 説明 |
|--------|------|
| `OfflineBanner` | ネットワーク未接続時に表示。高さ40pt、黄色背景 |
| `TranscriptView` | テキスト表示。ListView.builder + 自動スクロール |
| `WaveformIndicator` | 音声入力レベルの可視化（Ver 1.5） |
| `ControlPanel` | 操作ボタン群 |

**TranscriptView 仕様**:
- 新しい発話は下部に追加（チャット形式）
- 確定テキスト(`isFinal: true`): 通常色で表示
- 認識中テキスト(`isFinal: false`): グレー色で表示、確定時に色変更
- 無音1.5秒検知で改行挿入
- `ScrollController`で常に最新テキストが見える位置にスクロール
- フォントサイズは`settings.fontSize`に基づき動的変更:
  - 1.0 → 24pt
  - 2.0 → 32pt
  - 3.0 → 48pt

**ControlPanel ボタン仕様**:

| ボタン | サイズ | 色 | アクション |
|--------|-------|-----|----------|
| 停止/再開 | 80x80pt | 赤(停止)/緑(再開) | 音声認識の一時停止/再開 |
| 履歴 | 64x64pt | グレー | History Screen へ遷移 |
| 設定 | 64x64pt | グレー | Settings Screen へ遷移 |

---

### 3.3 History Screen（履歴一覧）

**目的**: 過去の会話ログの閲覧

**画面レイアウト**:
```
┌─────────────────────────────┐
│  [← 戻る]       会話りれき    │
│  (64x64pt)                   │
├─────────────────────────────┤
│                             │
│  ┌─────────────────────┐    │
│  │ 2月18日 14:30        │    │
│  │ こんにちは、今日は... │    │ ← 高さ80pt以上
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │ 2月17日 10:15        │    │
│  │ お薬の時間です...    │    │
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │ 2月16日 09:00        │    │
│  │ おはようございます... │    │
│  └─────────────────────┘    │
│                             │
└─────────────────────────────┘
```

**リストアイテム仕様**:
- 最小高さ: 80pt
- 上段: 日時表示（"M月D日 HH:mm" 形式、太字）
- 下段: テキストプレビュー（最大2行、末尾省略）
- タップ → History Detail Screen へ遷移
- 日付降順ソート

---

### 3.4 History Detail Screen（履歴詳細）

**目的**: 特定の会話ログの全文閲覧と削除

**画面レイアウト**:
```
┌─────────────────────────────┐
│  [← 戻る]    2月18日の会話    │
├─────────────────────────────┤
│                             │
│  14:30:05                   │
│  こんにちは、今日は天気が     │
│  いいですね                  │
│                             │
│  14:30:12                   │
│  はい、散歩日和です          │
│                             │
│  14:31:00                   │
│  午後から病院に行きましょう   │
│                             │
├─────────────────────────────┤
│                             │
│  [  この会話を削除する  ]     │
│  (赤背景・白文字・64pt高)     │
│                             │
└─────────────────────────────┘
```

**削除フロー**:
1. 「この会話を削除する」ボタンタップ
2. 確認ダイアログ表示:
   - タイトル: 「確認」
   - メッセージ: 「本当に消しますか？」
   - ボタン:
     - 「はい」（赤背景、64x48pt以上） → 削除実行 → 履歴一覧へ戻る
     - 「いいえ」（グレー背景、64x48pt以上） → ダイアログ閉じる

---

### 3.5 Settings Screen（設定）

**目的**: 文字サイズとコントラストの変更

**画面レイアウト**:
```
┌──────────────────────────────┐
│  [← 戻る]         せってい    │
├──────────────────────────────┤
│                              │
│  文字の大きさ                  │
│  ──────────────────────       │
│  大  ────●──── 最大           │
│        [スライダー]            │
│                              │
│  プレビュー:                   │
│  ┌────────────────────┐      │
│  │ この大きさで表示    │      │
│  │ されます           │      │
│  └────────────────────┘      │
│                              │
│  ──────────────────────       │
│                              │
│  画面の色                      │
│  [ ○ 白い画面 ]               │
│  [ ● 黒い画面（見やすい）]     │
│                              │
└──────────────────────────────┘
```

**文字サイズスライダー**:
- 3段階の離散値: 大(1.0) / 特大(2.0) / 最大(3.0)
- スライダー操作時にプレビューテキストがリアルタイムで変化
- 値変更は即座にObjectBoxに保存、UIに即反映

**コントラスト切替**:
- ラジオボタン形式（2択）
- 選択時に即座にテーマ全体が切り替わる
- 通常モード: 白背景(#FFFFFF) + 黒文字(#000000)
- 高コントラストモード: 黒背景(#000000) + 黄文字(#FFFF00)、フォントウェイトBold固定

---

## 4. サービス層詳細設計

### 4.1 SpeechService

**責務**: Apple Speech Framework (SFSpeechRecognizer) との連携

**Platform Channel 定義** (MethodChannel):

```
Channel名: "com.app.speech/recognizer"

Flutter → Native:
  - startListening()        → void
  - stopListening()         → void
  - requestPermission()     → bool (許可されたか)
  - checkPermission()       → String ("granted"|"denied"|"notDetermined")

Native → Flutter (EventChannel):
  - onPartialResult(String text, double confidence)
  - onFinalResult(String text, double confidence)
  - onError(String errorCode, String message)
  - onSilenceDetected()
```

**SFSpeechRecognizer 設定**:
```swift
recognizer.locale = Locale(identifier: "ja-JP")
request.shouldReportPartialResults = true
request.requiresOnDeviceRecognition = true  // オフライン対応
```

**状態管理 (SpeechState)**:
```dart
enum SpeechStatus {
  idle,           // 初期状態
  listening,      // 認識中
  paused,         // 一時停止中
  error,          // エラー発生
}

class SpeechState {
  final SpeechStatus status;
  final String currentPartialText;   // 認識途中テキスト
  final List<Message> confirmedMessages; // 確定済みメッセージ
  final String? errorMessage;
}
```

**無音検知ロジック**:
```
Timer _silenceTimer;

onAudioLevel(double level):
  if level < SILENCE_THRESHOLD (0.05):
    _silenceTimer を開始 (1.5秒)
  else:
    _silenceTimer をキャンセル

onSilenceTimerFired():
  現在のPartial Resultを確定(isFinal: true)扱いとする
  改行を挿入
  新しい認識セッションを開始
```

### 4.2 AuthService

**責務**: Firebase匿名認証の管理

```dart
class AuthService {
  /// 初回起動時に呼び出し。既にログイン済みならスキップ
  Future<String> ensureAuthenticated() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      return currentUser.uid;
    }
    final credential = await FirebaseAuth.instance.signInAnonymously();
    return credential.user!.uid;
  }

  /// 現在のUID取得
  String? get currentUserId =>
      FirebaseAuth.instance.currentUser?.uid;
}
```

### 4.3 LocalStorageService

**責務**: ObjectBox を使ったローカルデータの永続化

```dart
class LocalStorageService {
  late Store store;
  late Box<AppSettings> settingsBox;
  late Box<Conversation> conversationBox;
  late Box<Message> messageBox;

  // 設定
  Future<void> saveSettings(AppSettings settings);
  Future<AppSettings> loadSettings();

  // 会話
  Future<void> saveConversation(Conversation conversation);
  Future<List<Conversation>> getAllConversations(); // 日付降順
  Future<void> deleteConversation(String uuid);

  // メッセージ
  Future<void> addMessage(Message message);
  Future<List<Message>> getMessages(String conversationId);
  Future<void> deleteMessages(String conversationId);
}
```

**初期化処理**:
```dart
Future<void> initialize() async {
  final dir = await getApplicationDocumentsDirectory();
  store = await openStore(directory: p.join(dir.path, 'objectbox'));
  settingsBox = store.box<AppSettings>();
  conversationBox = store.box<Conversation>();
  messageBox = store.box<Message>();
}
```

### 4.4 FirestoreService (Ver 1.5)

**責務**: Firestore へのデータ同期

```dart
class FirestoreService {
  /// 会話データをFirestoreに同期
  Future<void> syncConversation({
    required String userId,
    required Conversation conversation,
    required List<Message> messages,
  }) async {
    final convRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('conversations')
        .doc(conversation.uuid);

    final batch = FirebaseFirestore.instance.batch();

    batch.set(convRef, {
      'startedAt': conversation.startedAt,
      'endedAt': conversation.endedAt,
      'title': conversation.title,
      'isFavorite': conversation.isFavorite,
    });

    for (final msg in messages) {
      final msgRef = convRef.collection('messages').doc(msg.uuid);
      batch.set(msgRef, {
        'timestamp': msg.timestamp,
        'text': msg.text,
        'confidence': msg.confidence,
        'isFinal': msg.isFinal,
      });
    }

    await batch.commit();
  }
}
```

---

## 5. Provider（状態管理）詳細設計

### 5.1 SettingsProvider

```dart
@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  @override
  AppSettings build() {
    return ref.read(localStorageServiceProvider).loadSettings();
  }

  void updateFontSize(double scale) {
    state = state.copyWith(fontSize: scale);
    ref.read(localStorageServiceProvider).saveSettings(state);
  }

  void toggleHighContrast(bool enabled) {
    state = state.copyWith(isHighContrast: enabled);
    ref.read(localStorageServiceProvider).saveSettings(state);
  }
}
```

### 5.2 SpeechProvider

```dart
@riverpod
class SpeechNotifier extends _$SpeechNotifier {
  @override
  SpeechState build() => SpeechState.idle();

  /// 音声認識を開始
  Future<void> startListening() async {
    state = state.copyWith(status: SpeechStatus.listening);
    ref.read(speechServiceProvider).startListening(
      onPartialResult: (text, confidence) {
        state = state.copyWith(currentPartialText: text);
      },
      onFinalResult: (text, confidence) {
        final message = Message(
          uuid: uuid.v4(),
          conversationId: _currentConversationId,
          timestamp: DateTime.now(),
          text: text,
          confidence: confidence,
          isFinal: true,
        );
        state = state.copyWith(
          confirmedMessages: [...state.confirmedMessages, message],
          currentPartialText: '',
        );
        ref.read(localStorageServiceProvider).addMessage(message);
      },
      onError: (code, message) {
        state = state.copyWith(
          status: SpeechStatus.error,
          errorMessage: message,
        );
      },
    );
  }

  /// 音声認識を一時停止
  void pause() {
    ref.read(speechServiceProvider).stopListening();
    state = state.copyWith(status: SpeechStatus.paused);
  }

  /// 音声認識を再開
  Future<void> resume() async => startListening();
}
```

### 5.3 ConversationProvider

```dart
@riverpod
class ConversationNotifier extends _$ConversationNotifier {
  @override
  Future<List<Conversation>> build() async {
    return ref.read(localStorageServiceProvider).getAllConversations();
  }

  /// 新規会話を開始
  Future<Conversation> startNewConversation() async {
    final conv = Conversation(
    final conv = Conversation(
      uuid: uuid.v4(),
      startedAt: DateTime.now(),
      title: DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now()) + ' の会話',
      isFavorite: false,
      isSyncedToCloud: false,
    );
    await ref.read(localStorageServiceProvider).saveConversation(conv);
    ref.invalidateSelf();
    return conv;
  }

  /// 会話を削除
  Future<void> deleteConversation(String conversationId) async {
    await ref.read(localStorageServiceProvider).deleteMessages(conversationId);
    await ref.read(localStorageServiceProvider).deleteConversation(conversationId);
    ref.invalidateSelf();
  }
}
```

---

## 6. テーマ設計

### 6.1 通常モード

```dart
ThemeData normalTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: Color(0xFFFFFFFF),
  textTheme: TextTheme(
    bodyLarge: TextStyle(
      fontFamily: 'HiraginoSans',
      color: Color(0xFF000000),
      fontWeight: FontWeight.w400,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: Size(64, 64),
      textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
  ),
);
```

### 6.2 高コントラストモード

```dart
ThemeData highContrastTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Color(0xFF000000),
  textTheme: TextTheme(
    bodyLarge: TextStyle(
      fontFamily: 'HiraginoSans',
      color: Color(0xFFFFFF00),
      fontWeight: FontWeight.w700, // Bold固定
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: Size(64, 64),
      backgroundColor: Color(0xFFFFFF00),
      foregroundColor: Color(0xFF000000),
      textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
  ),
);
```

### 6.3 フォントサイズマッピング

```dart
double resolveBodyFontSize(double scale) {
  switch (scale) {
    case 1.0: return 24.0;  // 大
    case 2.0: return 32.0;  // 特大
    case 3.0: return 48.0;  // 最大（iPad推奨）
    default:  return 24.0;
  }
}
```

---

## 7. 画面遷移とルーティング

### 7.1 遷移図

```
Splash Screen
    │
    ▼
Home Screen (聴取画面) ──── 常に音声認識可能状態
    │           │
    ▼           ▼
History      Settings
Screen       Screen
    │
    ▼
History Detail
Screen
```

### 7.2 ルート定義

```dart
final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/history/:id',
      builder: (context, state) =>
          HistoryDetailScreen(conversationId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
```

---

## 8. エラーハンドリング設計

### 8.1 エラー種別と対応

| エラー種別 | 検知方法 | ユーザー通知 | アプリ動作 |
|-----------|---------|------------|-----------|
| マイク権限未許可 | `AVAudioSession.recordPermission` | 図解付き設定誘導画面 | 音声認識停止、設定アプリへのリンク表示 |
| マイク権限拒否済み | Permission check結果 | 「設定」アプリへの遷移ボタン付き画面 | テキスト入力のみ利用可能 |
| ネットワーク未接続 | `Connectivity` パッケージ | 画面上部に「オフライン」バナー | オンデバイス認識で継続動作 |
| 音声認識エラー | SFSpeechRecognizer エラーコールバック | 「音声の認識に失敗しました」トースト | 3秒後に自動再試行（最大3回） |
| Firestore書き込み失敗 | try-catch | 表示なし（バックグラウンド） | ローカルに保持、次回接続時に再同期 |

### 8.2 音声認識エラーリカバリ

```
認識エラー発生
    │
    ├── エラー回数 < 3 → 3秒待機 → 認識セッション再開
    │
    └── エラー回数 >= 3 → 停止状態へ遷移
                          「再開」ボタン表示
                          エラーカウントリセット
```

---

## 9. アクセシビリティ対応

### 9.1 タッチターゲット

全てのインタラクティブ要素は最低 **64x64pt** を確保する。

```dart
class LargeButton extends StatelessWidget {
  // 最小サイズを64x64ptに強制
  static const double minSize = 64.0;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minSize,
        minHeight: minSize,
      ),
      child: ElevatedButton(...),
    );
  }
}
```

### 9.2 VoiceOver / アクセシビリティラベル

| 要素 | Semantics Label |
|------|-----------------|
| 停止ボタン | 「音声の聞き取りを停止」 |
| 再開ボタン | 「音声の聞き取りを再開」 |
| 履歴ボタン | 「会話のりれきを見る」 |
| 設定ボタン | 「せっていを開く」 |
| 削除ボタン | 「この会話を削除する」 |
| 戻るボタン | 「前の画面にもどる」 |

---

## 10. パフォーマンス要件と対策

| 要件 | 目標値 | 対策 |
|------|-------|------|
| 起動速度 | 2秒以内 | Splash画面での並列初期化（Auth + ObjectBox + 権限チェック） |
| 発話→表示 | 0.5秒以内 | オンデバイス認識 (`requiresOnDeviceRecognition: true`) |
| メモリ使用量 | 100MB以下 | ListView.builderによる遅延描画、古いメッセージの段階的解放 |
| 履歴表示 | 1秒以内 | ObjectBox Query のインデックス活用、ページング（50件単位） |

---

## 11. セキュリティ設計

### 11.1 データ保護

| 対象 | 方針 |
|------|------|
| 音声データ | デバイス内で処理。永続保存しない（Whisper利用時を除く） |
| テキストデータ | ObjectBox（暗号化サポート検討）に保存 |
| 通信 | HTTPS のみ（Firebase SDKがデフォルトで対応） |
| 認証 | Firebase匿名認証。個人情報の入力不要 |

### 11.2 Firestore セキュリティルール

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;

      match /conversations/{conversationId} {
        allow read, write: if request.auth != null
                           && request.auth.uid == userId;

        match /messages/{messageId} {
          allow read, write: if request.auth != null
                             && request.auth.uid == userId;
        }
      }
    }
  }
}
```

---

## 12. テスト計画

### 12.1 単体テスト

| 対象 | テスト内容 |
|------|----------|
| `AppSettings` モデル | シリアライズ/デシリアライズ、デフォルト値 |
| `LocalStorageService` | CRUD操作、データ整合性 |
| `ConversationNotifier` | 会話作成・削除・一覧取得 |
| `SettingsNotifier` | フォントサイズ変更、コントラスト切替 |
| `date_formatter` | 各種日付フォーマット変換 |

### 12.2 Widget テスト

| 対象 | テスト内容 |
|------|----------|
| `TranscriptView` | テキスト表示、自動スクロール、フォントサイズ反映 |
| `ControlPanel` | ボタンタップイベント、状態に応じた表示切替 |
| `ConfirmationDialog` | 「はい」「いいえ」の動作確認 |
| `SettingsScreen` | スライダー操作、プレビュー反映 |

### 12.3 結合テスト

| シナリオ | テスト内容 |
|---------|----------|
| 起動→認識→保存 | Splash → Home → 音声認識 → メッセージ保存の一連フロー |
| 履歴操作 | 履歴一覧→詳細→削除の一連フロー |
| オフライン | ネットワーク切断時のオンデバイス認識動作確認 |
| 設定反映 | 設定変更→Home画面への即時反映 |

---

## 13. リリース計画

### MVP (Ver 1.0)
- リアルタイム音声文字変換（オンデバイス）
- 超・視認性UI（フォントサイズ3段階、高コントラストモード）
- 会話履歴の表示と削除（ローカル保存）
- 匿名認証

### Ver 1.5
- 波形アニメーション（聞いていますフィードバック）
- 定型文表示（発話補助）
- Firestoreクラウド同期

### Ver 2.0
- 高精度AI変換モード（Whisper）
- 機種変更時のデータ移行
