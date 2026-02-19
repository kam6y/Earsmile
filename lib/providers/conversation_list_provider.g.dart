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
final class ConversationListNotifierProvider extends $AsyncNotifierProvider<
    ConversationListNotifier, List<Conversation>> {
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
}

String _$conversationListNotifierHash() =>
    r'fa07a4109d45dc5a25d7a7e7eb8a17ed2e6ac42d';

/// 会話一覧の状態管理 Provider（履歴画面用）
///
/// 生成されるプロバイダ名: conversationListProvider

abstract class _$ConversationListNotifier
    extends $AsyncNotifier<List<Conversation>> {
  FutureOr<List<Conversation>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<Conversation>>, List<Conversation>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<Conversation>>, List<Conversation>>,
        AsyncValue<List<Conversation>>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
