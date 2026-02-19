This file defines operating instructions for coding agents in this repository.

## 目的
- このプロジェクトは `earsmile` (イヤースマイル) です。
- 主機能は「聴覚障害・難聴の高齢者向け音声テキスト化アプリ (iOS/iPadOS 16+ only)」です。
- 本ドキュメントの目的は、実装現状に一致した最小限かつ実用的な作業規約を提供することです。
- 仕様の一次情報は実装コードです。古い文書よりコードを優先します。

## 適用範囲と優先順位
- `AGENTS.md` は実装・仕様に関する共通規約の正本です。
- `CLAUDE.md` は Claude Code の司令塔運用（委譲・レビュー手順）の正本です。
- 実装判断で矛盾した場合は、`実装コード` → `AGENTS.md` の順で優先します。
- Claude専用の運用手順は `CLAUDE.md` を参照します。

## 会話ルール
- 返信・進捗報告・最終報告は常に日本語で行います。
- 変更前に「何を直すか」を短く共有し、変更後に結果と検証内容を明示します。
- 推測が含まれる場合は仮定として明示し、確認した事実と分けて記述します。
- 実行できなかった検証（時間不足、環境不足など）は必ず理由付きで報告します。

## アーキテクチャ (Architecture)
### State Management: Riverpod
- `flutter_riverpod` with code generation (`riverpod_annotation` + `riverpod_generator`) を使用。
- Providers live in `lib/providers/`.
- `@riverpod` annotation を使用して定義し、 `build_runner` で `.g.dart` を生成する。

### Data Layer: Two-Tier Storage
1. **Local (ObjectBox)**: Embedded NoSQL database at `{DocumentsDirectory}/objectbox`.
   - Initialized in `LocalStorageService` (`lib/services/local_storage_service.dart`).
   - Models in `lib/models/` using `@Entity()`.
2. **Cloud (Firebase Firestore)**: Optional sync.
   - Sync state tracked via `isSyncedToCloud`.
   - Config in `lib/firebase_options.dart`.

### Authentication
- Anonymous Firebase Auth only. No user registration. UID persists across restarts.

### Firebase設定ファイル運用
- `lib/firebase_options.dart` と `ios/Runner/GoogleService-Info.plist` は **リポジトリで管理する**（GitHub へコミット可）。
- 上記2ファイルはクライアント設定情報であり、アクセス制御は Firebase Security Rules / App Check / Auth 設定で担保する。
- 以下は **コミット禁止**: Firebase Admin SDK のサービスアカウント鍵（`serviceAccountKey.json` など）、秘密鍵、`.env` に入るシークレット値。

### Routing
- `go_router` ^17.1.0 configured in `lib/config/routes.dart`.
- Routes: `/splash`, `/`, `/history`, `/history/:id`, `/settings`.

### Core Entities
- **AppSettings**: singleton (id=1); `fontSize` (1.0/2.0/3.0 -> 24/32/48pt), `isHighContrast`.
- **Conversation**: UUID for sync, `isFavorite`, `isSyncedToCloud`.
- **Message**: `conversationId` (UUID), `text`, `confidence`, `isFinal`.

## 開発原則・制約 (Key Design Constraints)
- **Accessibility first**: Minimum font 24pt, touch targets ≥80pt, high-contrast color mode support.
- **Offline-first**: All features must work without network. Cloud sync is optional.
- **iOS only**: No Android or web targets.
- **Breaking changes**: 許容します。旧実装への過剰な互換レイヤーは追加しません。
- **不要コード削除**: 複雑なフォールバックや使われていないコードは積極的に削除します。

## コーディング規約
### Provider 命名規則（Riverpod 3.x）
- `@riverpod class FooNotifier` -> `fooProvider` (`Notifier` suffix removed).
- Example: `SettingsNotifier` -> `settingsProvider`.

### LocalStorageService の初期化
- `main.dart` で `await service.initialize()` を呼び出し、`ProviderScope` の `overrides` で注入する。

### AsyncValue のアンラップ（Riverpod 3.x）
- `valueOrNull` は廃止。Dart 3.x パターンマッチングを使用する:
  ```dart
  final value = switch (asyncValue) {
    AsyncData(:final value) => value,
    _ => defaultValue,
  };
  ```

## 関連ドキュメント (Documentation)
`docs/` ディレクトリ内の設計書:
- `RDD.md`: 要件定義 (Functional requirements)
- `DetailedDesign.md`: 詳細設計 (Directory structure, Riverpod providers, Firestore schema)

## 変更フロー
1. 対象機能の実装箇所・型・API定義を確認する。
2. 変更設計を最小単位に分割し、影響範囲（UI/Backend/API/設定）を明確化する。
3. 実装を変更する。
4. 必要な生成・検証コマンドを実行する。
5. 変更差分を自己レビューし、古い説明・未使用コード・不要分岐を除去する。
6. 最終報告では「変更ファイル」「挙動への影響」「実行した検証」「未実施項目」を示す。

## 最小コマンド
日常開発で使う最小セット:

```bash
# 依存関係インストール
~/flutter/bin/flutter pub get

# コード生成 (ObjectBox entities / Riverpod providers)
~/flutter/bin/flutter pub run build_runner build --delete-conflicting-outputs

# 静的解析
~/flutter/bin/flutter analyze

# iOSシミュレータで実行
~/flutter/bin/flutter run
```

## テスト実行規約
推奨手順:
```bash
# 全テスト実行
~/flutter/bin/flutter test

# 単一ファイル実行
~/flutter/bin/flutter test test/models/models_test.dart
```

実務ルール:
- 変更に近いテストを優先し、必要に応じて対象を絞る（`-k`, 単一ファイル, 単一テスト）。
- テスト未実行で提出する場合は、未実行理由と想定リスクを報告する。

## 外部ライブラリ調査規約
- 外部ライブラリを使う実装前に、最新APIを確認してからコードを書く。
- 特に更新頻度が高い領域は毎回確認する。

必須確認項目:
1. APIシグネチャ（引数名・戻り値・型）
2. 非推奨/削除済みAPI
3. 現行の推奨実装パターン
4. 直近バージョンの破壊的変更

調査方針:
- 一次情報（公式ドキュメント、公式リポジトリ、公式リリースノート）を優先する。
- 参考記事は補助扱いにし、公式情報で再確認する。

## 更新時チェックリスト
- [ ] 返信を日本語で統一した。
- [ ] 変更内容が「単純化優先・breaking change許容」の方針に沿っている。
- [ ] すでに存在するコードと生成物の整合を取った。
- [ ] 実行した検証コマンドと未実施項目を最終報告に記載した。
