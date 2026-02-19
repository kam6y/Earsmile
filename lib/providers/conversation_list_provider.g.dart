// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 会話一覧の状態管理 Provider（履歴画面用）
///
/// 生成されるプロバイダ名: conversationListProvider

@ProviderFor(ConversationListNotifier)
final conversationListProvider = ConversationListNotifierProvider._();

/// 会話一覧の状態管理 Provider（履歴画面用）
///
/// 生成されるプロバイダ名: conversationListProvider
final class ConversationListNotifierProvider
    extends $NotifierProvider<ConversationListNotifier, List<Conversation>> {
  /// 会話一覧の状態管理 Provider（履歴画面用）
  ///
  /// 生成されるプロバイダ名: conversationListProvider
  ConversationListNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'conversationListProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$conversationListNotifierHash();

  @$internal
  @override
  ConversationListNotifier create() => ConversationListNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Conversation> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Conversation>>(value),
    );
  }
}

String _$conversationListNotifierHash() =>
    r'a0212335dd5558ab24066502d25d7f659518c968';

/// 会話一覧の状態管理 Provider（履歴画面用）
///
/// 生成されるプロバイダ名: conversationListProvider

abstract class _$ConversationListNotifier
    extends $Notifier<List<Conversation>> {
  List<Conversation> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<Conversation>, List<Conversation>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<List<Conversation>, List<Conversation>>,
        List<Conversation>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
