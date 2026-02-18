// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 認証状態を管理する Provider
///
/// build() で匿名認証を実行し、UID（または null）を返す。
/// オフラインファースト: 認証失敗時も AsyncData(null) として正常完了扱い。

@ProviderFor(AuthNotifier)
final authProvider = AuthNotifierProvider._();

/// 認証状態を管理する Provider
///
/// build() で匿名認証を実行し、UID（または null）を返す。
/// オフラインファースト: 認証失敗時も AsyncData(null) として正常完了扱い。
final class AuthNotifierProvider
    extends $AsyncNotifierProvider<AuthNotifier, String?> {
  /// 認証状態を管理する Provider
  ///
  /// build() で匿名認証を実行し、UID（または null）を返す。
  /// オフラインファースト: 認証失敗時も AsyncData(null) として正常完了扱い。
  AuthNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'authProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$authNotifierHash();

  @$internal
  @override
  AuthNotifier create() => AuthNotifier();
}

String _$authNotifierHash() => r'1f6bc6bcffddaa31541df79ecfef0e838854fb64';

/// 認証状態を管理する Provider
///
/// build() で匿名認証を実行し、UID（または null）を返す。
/// オフラインファースト: 認証失敗時も AsyncData(null) として正常完了扱い。

abstract class _$AuthNotifier extends $AsyncNotifier<String?> {
  FutureOr<String?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String?>, String?>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<String?>, String?>,
        AsyncValue<String?>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
