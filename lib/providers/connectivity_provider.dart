import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

/// ネットワーク接続状態を監視する Stream Provider
///
/// true = オンライン、false = オフライン
@riverpod
Stream<bool> connectivity(Ref ref) {
  return Connectivity().onConnectivityChanged.map((results) {
    return results.any((r) => r != ConnectivityResult.none);
  });
}
