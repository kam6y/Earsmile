// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'speech_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SpeechNotifier)
final speechProvider = SpeechNotifierProvider._();

final class SpeechNotifierProvider
    extends $NotifierProvider<SpeechNotifier, SpeechState> {
  SpeechNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'speechProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$speechNotifierHash();

  @$internal
  @override
  SpeechNotifier create() => SpeechNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SpeechState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SpeechState>(value),
    );
  }
}

String _$speechNotifierHash() => r'8281339e44ad5e924f8ec7d81ce21bce4b8eb38a';

abstract class _$SpeechNotifier extends $Notifier<SpeechState> {
  SpeechState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SpeechState, SpeechState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<SpeechState, SpeechState>, SpeechState, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
