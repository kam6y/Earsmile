import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/app_settings.dart';
import 'local_storage_provider.dart';

part 'settings_provider.g.dart';

/// アプリ設定の状態管理 Provider
///
/// - build(): ObjectBox から設定を読み込んで初期状態を返す
/// - updateFontSize(): フォントサイズ変更 → ObjectBox 保存
/// - toggleHighContrast(): コントラスト切替 → ObjectBox 保存
@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  @override
  AppSettings build() {
    return ref.read(localStorageServiceProvider).loadSettings();
  }

  /// フォントサイズを変更して即座に保存する
  ///
  /// [scale]: 1.0(24pt) / 2.0(32pt) / 3.0(48pt)
  void updateFontSize(double scale) {
    final updated = AppSettings(
      id: state.id,
      fontSize: scale,
      isHighContrast: state.isHighContrast,
    );
    state = updated;
    ref.read(localStorageServiceProvider).saveSettings(updated);
  }

  /// 高コントラストモードを切り替えて即座に保存する
  void toggleHighContrast(bool enabled) {
    final updated = AppSettings(
      id: state.id,
      fontSize: state.fontSize,
      isHighContrast: enabled,
    );
    state = updated;
    ref.read(localStorageServiceProvider).saveSettings(updated);
  }
}
