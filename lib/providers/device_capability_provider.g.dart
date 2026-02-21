// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_capability_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// デバイスのオンデバイス音声認識対応可否を提供する Provider
///
/// iOS ネイティブの checkOnDeviceSupport を呼び出し、結果をキャッシュする。
/// 設定画面でオンデバイス選択肢の表示/非表示を制御するために使用する。

@ProviderFor(DeviceCapabilityNotifier)
final deviceCapabilityProvider = DeviceCapabilityNotifierProvider._();

/// デバイスのオンデバイス音声認識対応可否を提供する Provider
///
/// iOS ネイティブの checkOnDeviceSupport を呼び出し、結果をキャッシュする。
/// 設定画面でオンデバイス選択肢の表示/非表示を制御するために使用する。
final class DeviceCapabilityNotifierProvider
    extends $AsyncNotifierProvider<DeviceCapabilityNotifier, bool> {
  /// デバイスのオンデバイス音声認識対応可否を提供する Provider
  ///
  /// iOS ネイティブの checkOnDeviceSupport を呼び出し、結果をキャッシュする。
  /// 設定画面でオンデバイス選択肢の表示/非表示を制御するために使用する。
  DeviceCapabilityNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'deviceCapabilityProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$deviceCapabilityNotifierHash();

  @$internal
  @override
  DeviceCapabilityNotifier create() => DeviceCapabilityNotifier();
}

String _$deviceCapabilityNotifierHash() =>
    r'feae302e6ce3a789884ceda72881b0d65cda794f';

/// デバイスのオンデバイス音声認識対応可否を提供する Provider
///
/// iOS ネイティブの checkOnDeviceSupport を呼び出し、結果をキャッシュする。
/// 設定画面でオンデバイス選択肢の表示/非表示を制御するために使用する。

abstract class _$DeviceCapabilityNotifier extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<bool>, bool>,
        AsyncValue<bool>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
