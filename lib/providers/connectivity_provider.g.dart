// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connectivity_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// ネットワーク接続状態を監視する Stream Provider
///
/// true = オンライン、false = オフライン

@ProviderFor(connectivity)
final connectivityProvider = ConnectivityProvider._();

/// ネットワーク接続状態を監視する Stream Provider
///
/// true = オンライン、false = オフライン

final class ConnectivityProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// ネットワーク接続状態を監視する Stream Provider
  ///
  /// true = オンライン、false = オフライン
  ConnectivityProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'connectivityProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$connectivityHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return connectivity(ref);
  }
}

String _$connectivityHash() => r'8b52bea4bc740971bfe657cb5203b079e42ad3e5';
