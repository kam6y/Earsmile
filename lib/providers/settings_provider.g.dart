// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// アプリ設定の状態管理 Provider
///
/// - build(): ObjectBox から設定を読み込んで初期状態を返す
/// - updateFontSize(): フォントサイズ変更 → ObjectBox 保存
/// - toggleHighContrast(): コントラスト切替 → ObjectBox 保存

@ProviderFor(SettingsNotifier)
final settingsProvider = SettingsNotifierProvider._();

/// アプリ設定の状態管理 Provider
///
/// - build(): ObjectBox から設定を読み込んで初期状態を返す
/// - updateFontSize(): フォントサイズ変更 → ObjectBox 保存
/// - toggleHighContrast(): コントラスト切替 → ObjectBox 保存
final class SettingsNotifierProvider
    extends $NotifierProvider<SettingsNotifier, AppSettings> {
  /// アプリ設定の状態管理 Provider
  ///
  /// - build(): ObjectBox から設定を読み込んで初期状態を返す
  /// - updateFontSize(): フォントサイズ変更 → ObjectBox 保存
  /// - toggleHighContrast(): コントラスト切替 → ObjectBox 保存
  SettingsNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'settingsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$settingsNotifierHash();

  @$internal
  @override
  SettingsNotifier create() => SettingsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppSettings>(value),
    );
  }
}

String _$settingsNotifierHash() => r'7a311132e25d4deab4eb8de573078e4cad5f5c8c';

/// アプリ設定の状態管理 Provider
///
/// - build(): ObjectBox から設定を読み込んで初期状態を返す
/// - updateFontSize(): フォントサイズ変更 → ObjectBox 保存
/// - toggleHighContrast(): コントラスト切替 → ObjectBox 保存

abstract class _$SettingsNotifier extends $Notifier<AppSettings> {
  AppSettings build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AppSettings, AppSettings>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AppSettings, AppSettings>, AppSettings, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
