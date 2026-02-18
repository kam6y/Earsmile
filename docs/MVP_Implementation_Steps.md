# MVP実装ステップ：聴覚障害・難聴の高齢者向け音声テキスト化アプリ

## 対象スコープ (MVP = Ver 1.0)

- リアルタイム音声文字変換（オンデバイス）
- 超・視認性UI（フォントサイズ3段階、高コントラストモード）
- 会話履歴の表示と削除（ローカル保存）
- Firebase匿名認証

---

## Step 1: プロジェクト初期セットアップ

### 1.1 Flutter プロジェクト作成

- `flutter create` で iOS/iPadOS 向けプロジェクトを作成
- 最小対応バージョンを iOS 16 に設定
- `analysis_options.yaml` で Lint ルール設定

### 1.2 依存パッケージ導入

```yaml
dependencies:
  flutter_riverpod: ^3.2.1 # 状態管理
  riverpod_annotation: ^4.0.2 # Riverpod コード生成
  objectbox: ^5.2.0 # ローカルDB
  objectbox_flutter_libs: ^5.2.0 # ObjectBox Flutter統合
  path_provider: ^2.1.5 # パス取得
  go_router: ^17.1.0 # ルーティング
  firebase_core: ^4.4.0 # Firebase初期化
  firebase_auth: ^6.1.4 # 匿名認証
  uuid: ^4.5.2 # ID生成
  connectivity_plus: ^7.0.0 # ネットワーク状態検知
  intl: ^0.20.2 # 日付フォーマット

dev_dependencies:
  build_runner: ^2.11.1
  riverpod_generator: ^4.0.3
  objectbox_generator: ^5.2.0 # ObjectBox コード生成
  flutter_lints: ^6.0.0
```

### 1.3 ディレクトリ構成の作成

詳細設計書 §1.2 に基づき、以下のディレクトリを作成する。

```
lib/
├── main.dart
├── app.dart
├── config/
├── models/
├── providers/
├── services/
├── screens/
├── widgets/
└── utils/
```

### 1.4 Firebase プロジェクト設定

- Firebase Console でプロジェクト作成
- iOS アプリ登録、`GoogleService-Info.plist` 配置
- 匿名認証を有効化

**成果物**: ビルド・実行可能な空の Flutter プロジェクト

---

## Step 2: データモデルとローカルストレージ

### 2.1 ObjectBox Entity 定義

以下の3つのモデルクラスを作成し、`build_runner` でコードを生成する。

| ファイル | クラス |
|---------|--------|
| `models/app_settings.dart` | `AppSettings` (`@Entity`) |
| `models/conversation.dart` | `Conversation` (`@Entity`) |
| `models/message.dart` | `Message` (`@Entity`) |

各モデルのフィールドは詳細設計書 §2.1 に準拠する（`int id = 0;` を含む）。

### 2.2 LocalStorageService 実装

`services/local_storage_service.dart` に以下を実装する。

- `initialize()`: ObjectBox初期化 (`openStore()`)
- `saveSettings()` / `loadSettings()`: 設定の保存・読み込み
- `saveConversation()` / `getAllConversations()` / `deleteConversation()`: 会話CRUD
- `addMessage()` / `getMessages()` / `deleteMessages()`: メッセージCRUD
- `getAllConversations()` は日付降順で返す（Queryを使用）
- 各書き込み操作は `store.runInTransaction()` または同期メソッドで行う

### 2.3 単体テスト

- モデルのシリアライズ/デシリアライズテスト
- LocalStorageService の CRUD テスト

**成果物**: ローカルにデータを永続化できるストレージ層

---

## Step 3: テーマとUI基盤

### 3.1 テーマ定義

`config/theme.dart` に以下を実装する。

- 通常モード (`normalTheme`): 白背景 + 黒文字
- 高コントラストモード (`highContrastTheme`): 黒背景 + 黄文字、Bold固定
- フォントサイズマッピング関数 `resolveBodyFontSize(double scale)`
  - 1.0 → 24pt、2.0 → 32pt、3.0 → 48pt
- フォント: ヒラギノ角ゴシック

### 3.2 定数・ルーティング定義

- `config/constants.dart`: タッチターゲット最小サイズ (64pt)、無音閾値等
- `config/routes.dart`: GoRouter によるルート定義（詳細設計書 §7.2 準拠）

### 3.3 共通 Widget

- `widgets/large_button.dart`: 最小 64x64pt を保証するボタン Widget
- `widgets/confirmation_dialog.dart`: 大きなボタンの確認ダイアログ
- `widgets/offline_banner.dart`: オフライン表示バナー

### 3.4 ユーティリティ

- `utils/date_formatter.dart`: 日付フォーマット（「M月D日 HH:mm」等）
- `utils/accessibility_helpers.dart`: アクセシビリティ補助

**成果物**: テーマ切替・共通Widget が使える UI 基盤

---

## Step 4: 設定機能 (Settings)

### 4.1 SettingsProvider

`providers/settings_provider.dart` に Riverpod Notifier を実装する。

- `build()`: ObjectBox から設定を読み込んで初期状態を返す
- `updateFontSize(double scale)`: フォントサイズ変更 → ObjectBox 保存
- `toggleHighContrast(bool enabled)`: コントラスト切替 → ObjectBox 保存

### 4.2 Settings Screen

`screens/settings_screen.dart` に以下を実装する。

- 文字サイズスライダー（3段階の離散値）
- プレビューテキスト（スライダー操作でリアルタイム変化）
- コントラスト切替（ラジオボタン2択）
- 戻るボタン（64x64pt 以上）
- 変更は即座に ObjectBox 保存、UI に即反映

### 4.3 app.dart へのテーマ統合

- `SettingsProvider` を監視し、`MaterialApp` の `theme` を動的切替
- フォントサイズの変更が全画面に反映されることを確認

**成果物**: 文字サイズ・コントラストを変更でき、即座に反映される設定画面

---

## Step 5: Firebase 匿名認証

### 5.1 AuthService

`services/auth_service.dart` に以下を実装する。

- `ensureAuthenticated()`: 既存ユーザーがいればスキップ、いなければ匿名サインイン
- `currentUserId` getter

### 5.2 AuthProvider

`providers/auth_provider.dart` に認証状態の Provider を実装する。

### 5.3 Splash Screen

`screens/splash_screen.dart` に以下を実装する。

1. ロゴ表示（中央配置）
2. 並列で初期化実行:
   - Firebase 匿名認証
   - ObjectBox 初期化・設定読み込み
   - マイク権限チェック
3. 権限未許可 → リクエストダイアログ、拒否済み → 設定誘導
4. 全初期化完了後、Home Screen へ自動遷移（最大3秒タイムアウト）

**成果物**: アプリ起動時に認証・初期化を完了し、Home 画面へ遷移する Splash 画面

---

## Step 6: 音声認識（コア機能）

### 6.1 iOS ネイティブ側 (Swift)

Platform Channel (`com.app.speech/recognizer`) を実装する。

- MethodChannel:
  - `startListening()` / `stopListening()`
  - `requestPermission()` / `checkPermission()`
- EventChannel:
  - `onPartialResult(text, confidence)`
  - `onFinalResult(text, confidence)`
  - `onError(errorCode, message)`
  - `onSilenceDetected()`

SFSpeechRecognizer 設定:
- `locale`: `ja-JP`
- `shouldReportPartialResults`: `true`
- `requiresOnDeviceRecognition`: `true`（オフライン対応）

### 6.2 SpeechService (Flutter 側)

`services/speech_service.dart` に Platform Channel のラッパーを実装する。

- ネイティブ側とのメッセージ送受信
- コールバックの Flutter 側への変換

### 6.3 SpeechProvider

`providers/speech_provider.dart` に以下を実装する。

- 状態: `idle` / `listening` / `paused` / `error`
- `startListening()`: 認識開始、Partial/Final Result の処理
- `pause()` / `resume()`: 一時停止・再開
- Final Result 受信時に `LocalStorageService.addMessage()` で保存

### 6.4 無音検知ロジック

- 音声レベルが閾値 (0.05) 未満で 1.5秒経過 → 現在の Partial Result を確定扱い
- 改行を挿入し、新しい認識セッションを開始

### 6.5 エラーリカバリ

- エラー発生時、3秒待機後に自動再試行（最大3回）
- 3回失敗 → 停止状態へ遷移、「再開」ボタン表示

**成果物**: 日本語音声をリアルタイムでテキスト化し、ローカルに保存できる音声認識機能

---

## Step 7: Home Screen（聴取画面）

### 7.1 TranscriptView

`widgets/transcript_view.dart` に以下を実装する。

- `ListView.builder` による会話テキスト表示
- 確定テキスト (`isFinal: true`): 通常色表示
- 認識中テキスト (`isFinal: false`): グレー色表示
- `ScrollController` で常に最新テキストへ自動スクロール
- フォントサイズは `settings.fontSize` に連動

### 7.2 ControlPanel

`widgets/control_panel.dart` に以下を実装する。

| ボタン | サイズ | 色 | アクション |
|--------|-------|-----|----------|
| 停止/再開 | 80x80pt | 赤/緑 | 音声認識の一時停止/再開 |
| 履歴 | 64x64pt | グレー | History Screen へ遷移 |
| 設定 | 64x64pt | グレー | Settings Screen へ遷移 |

### 7.3 OfflineBanner 統合

- `connectivity_plus` でネットワーク状態を監視
- 未接続時に画面上部に黄色バナーを表示

### 7.4 ConversationProvider

`providers/conversation_provider.dart` に以下を実装する。

- `startNewConversation()`: アプリ起動時（またはHome表示時）に新規会話を作成
- `deleteConversation()`: 会話とメッセージの削除

### 7.5 Home Screen 組み立て

`screens/home_screen.dart` で上記 Widget を組み合わせ、画面レイアウトを構築する。

### 7.6 アクセシビリティラベル

全ボタンに Semantics Label を設定する（詳細設計書 §9.2 準拠）。

**成果物**: 音声をリアルタイムでテキスト表示し、停止/再開できるメイン画面

---

## Step 8: 履歴機能

### 8.1 History Screen

`screens/history_screen.dart` に以下を実装する。

- 会話一覧を日付降順で表示
- 各リストアイテム:
  - 最小高さ 80pt
  - 上段: 日時（「M月D日 HH:mm」形式、太字）
  - 下段: テキストプレビュー（最大2行、末尾省略）
- タップで History Detail Screen へ遷移
- 戻るボタン（64x64pt）

### 8.2 History Detail Screen

`screens/history_detail_screen.dart` に以下を実装する。

- 会話の全メッセージを時刻付きで表示
- 「この会話を削除する」ボタン（赤背景、白文字、64pt高）
- 削除確認ダイアログ:
  - メッセージ: 「本当に消しますか？」
  - 「はい」（赤、64x48pt以上）→ 削除実行 → 履歴一覧へ戻る
  - 「いいえ」（グレー、64x48pt以上）→ ダイアログ閉じる

### 8.3 Widget テスト

- 履歴一覧の表示テスト
- 削除確認ダイアログの動作テスト

**成果物**: 過去の会話ログを閲覧・削除できる履歴画面

---

## Step 9: 結合テストと品質確認

### 9.1 結合テスト

| シナリオ | 確認内容 |
|---------|---------|
| 起動→認識→保存 | Splash → Home → 音声認識 → メッセージ保存の一連フロー |
| 履歴操作 | 履歴一覧 → 詳細 → 削除の一連フロー |
| オフライン動作 | ネットワーク切断時のオンデバイス認識動作 |
| 設定反映 | 設定変更 → Home 画面への即時反映 |

### 9.2 パフォーマンス確認

| 項目 | 目標値 |
|------|-------|
| 起動速度 | 2秒以内 |
| 発話→表示 | 0.5秒以内 |
| メモリ使用量 | 100MB以下 |
| 履歴表示 | 1秒以内 |

### 9.3 アクセシビリティ確認

- 全タッチターゲットが 64x64pt 以上であること
- VoiceOver で全操作が可能であること
- 高コントラストモードで全画面の視認性が確保されていること
- フォントサイズ最大 (48pt) で UI が崩れないこと

### 9.4 セキュリティ確認

- 音声データがデバイス外に送信されていないこと
- Firestore セキュリティルールが正しく適用されていること（MVP では Firestore 同期は未実装だが、ルールは先に設定）

**成果物**: MVP 品質基準を満たした動作確認済みアプリ

---

## 実装順序の依存関係

```
Step 1 (プロジェクトセットアップ)
  │
  ├── Step 2 (データモデル・ストレージ)
  │     │
  │     ├── Step 4 (設定機能)
  │     │     │
  │     │     └──┐
  │     │        │
  │     └── Step 6 (音声認識)
  │           │
  │           └──┐
  │              │
  ├── Step 3 (テーマ・UI基盤) ──┐
  │                             │
  ├── Step 5 (認証・Splash) ────┤
  │                             │
  │                             ▼
  │                      Step 7 (Home Screen)
  │                             │
  │                             ▼
  │                      Step 8 (履歴機能)
  │                             │
  │                             ▼
  └──────────────────── Step 9 (結合テスト)
```

- Step 2, 3, 5 は Step 1 完了後に並行着手可能
- Step 4 は Step 2 + 3 に依存
- Step 6 は Step 2 に依存
- Step 7 は Step 3, 4, 5, 6 の全完了が必要
- Step 8 は Step 7 に依存
- Step 9 は全ステップ完了後
