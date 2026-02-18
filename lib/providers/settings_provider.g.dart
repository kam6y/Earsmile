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
    extends $AsyncNotifierProvider<SettingsNotifier, AppSettings> {
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
}

String _$settingsNotifierHash() => r'e6d925f7c9b78887a4b57c128c5b38c4e2b8cf1c';

/// アプリ設定の状態管理 Provider
///
/// - build(): ObjectBox から設定を読み込んで初期状態を返す
/// - updateFontSize(): フォントサイズ変更 → ObjectBox 保存
/// - toggleHighContrast(): コントラスト切替 → ObjectBox 保存

abstract class _$SettingsNotifier extends $AsyncNotifier<AppSettings> {
  FutureOr<AppSettings> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AppSettings>, AppSettings>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<AppSettings>, AppSettings>,
        AsyncValue<AppSettings>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
