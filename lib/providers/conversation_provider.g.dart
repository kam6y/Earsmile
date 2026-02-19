// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 会話の開始・終了・削除を管理する Notifier
///
/// 生成されるプロバイダ名: conversationProvider

@ProviderFor(ConversationNotifier)
final conversationProvider = ConversationNotifierProvider._();

/// 会話の開始・終了・削除を管理する Notifier
///
/// 生成されるプロバイダ名: conversationProvider
final class ConversationNotifierProvider
    extends $NotifierProvider<ConversationNotifier, Conversation?> {
  /// 会話の開始・終了・削除を管理する Notifier
  ///
  /// 生成されるプロバイダ名: conversationProvider
  ConversationNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'conversationProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$conversationNotifierHash();

  @$internal
  @override
  ConversationNotifier create() => ConversationNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Conversation? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Conversation?>(value),
    );
  }
}

String _$conversationNotifierHash() =>
    r'3c6ecf0df9e8df8e6cd33723b9e2ddeb66a2e325';

/// 会話の開始・終了・削除を管理する Notifier
///
/// 生成されるプロバイダ名: conversationProvider

abstract class _$ConversationNotifier extends $Notifier<Conversation?> {
  Conversation? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Conversation?, Conversation?>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<Conversation?, Conversation?>,
        Conversation?,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
