# Earsmile (イヤースマイル)

聴覚障害・難聴の高齢者向け音声テキスト化アプリです。
完全オンデバイス処理により、プライバシーを保護しながらリアルタイムに音声を文字に変換します。

## 📱 動作環境

本アプリは現在 **iOS (主要ターゲット)** および macOS での動作を想定しています。
Web版は一部ネイティブ機能（ObjectBox等）の制約により、現在完全には動作しません。

*   **Flutter**: 3.x (Latest Stable)
*   **Xcode**: 15.0以上 (iOS 15.0以上をターゲット)
*   **CocoaPods**: 必要

## 🛠️ セットアップ

### 1. リポジトリのクローン
```bash
git clone <repository-url>
cd earsmile
```

### 2. 依存関係のインストール
```bash
flutter pub get
```

### 3. iOSシミュレータの準備
Xcodeをインストール後、以下のコマンドでiOSシミュレータランタイムがインストールされているか確認してください。
```bash
xcrun simctl list runtimes
```
もし一覧に「iOS ...」がない場合は、Xcodeの設定 (`Settings > Platforms`) からダウンロードするか、以下のコマンドを実行してください（時間がかかります）。
```bash
xcodebuild -downloadPlatform iOS
```

## 🚀 アプリの実行方法

### iOSシミュレータで実行 （推奨）
1.  シミュレータを起動します。
    ```bash
    open -a Simulator
    ```
    ※ シミュレータが起動してもデバイスが表示されない場合は、以下のコマンドで利用可能なデバイスを確認し、起動してください。
    ```bash
    xcrun simctl list devices
    # 例: iPhone 15 Pro (UUID) を起動
    xcrun simctl boot <UUID>
    ```

2.  シミュレータが起動したら、`flutter devices` で認識されているか確認します。
    ```bash
    flutter devices
    ```

3.  アプリを実行します。
    ```bash
    flutter run
    ```
    ※ 複数のデバイスが接続されている場合は `flutter devices` でIDを確認し、`-d <device-id>` を指定してください。

### macOSで実行
```bash
flutter run -d macos
```

## 🧪 テストの実行

```bash
flutter test
```

## ⚠️ トラブルシューティング

### ビルドエラーが発生する場合
キャッシュや依存関係の問題でビルドに失敗する場合は、以下のクリーニングコマンドを試してください。

```bash
flutter clean
flutter pub get
cd ios
rm -rf Pods
rm Podfile.lock
pod install --repo-update
cd ..
flutter run
```

### iOSのデプロイメントターゲットエラー
`Podfile` は `platform :ios, '15.0'` に設定されています。もし `deployment target` 関連のエラーが出た場合は `ios/Podfile` を確認し、その後に `pod install` を再実行してください。

## 🔒 プライバシーについて
本アプリはマイク入力および音声認識をデバイス内でのみ処理します。外部サーバーへの音声データの送信は行いません。
`Info.plist` には以下の権限設定が含まれています：
*   `NSMicrophoneUsageDescription`: マイク使用の許可
*   `NSSpeechRecognitionUsageDescription`: 音声認識機能使用の許可
