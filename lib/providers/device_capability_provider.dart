import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers/speech_provider.dart';

part 'device_capability_provider.g.dart';

/// デバイスのオンデバイス音声認識対応可否を提供する Provider
///
/// iOS ネイティブの checkOnDeviceSupport を呼び出し、結果をキャッシュする。
/// 設定画面でオンデバイス選択肢の表示/非表示を制御するために使用する。
@riverpod
class DeviceCapabilityNotifier extends _$DeviceCapabilityNotifier {
  @override
  Future<bool> build() async {
    return ref.read(speechServiceProvider).checkOnDeviceSupport();
  }
}
