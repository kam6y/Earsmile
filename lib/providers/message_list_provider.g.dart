// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 指定した会話のメッセージ一覧を取得する Provider
///
/// 生成されるプロバイダ名: messageListProvider

@ProviderFor(messageList)
final messageListProvider = MessageListFamily._();

/// 指定した会話のメッセージ一覧を取得する Provider
///
/// 生成されるプロバイダ名: messageListProvider

final class MessageListProvider
    extends $FunctionalProvider<List<Message>, List<Message>, List<Message>>
    with $Provider<List<Message>> {
  /// 指定した会話のメッセージ一覧を取得する Provider
  ///
  /// 生成されるプロバイダ名: messageListProvider
  MessageListProvider._(
      {required MessageListFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'messageListProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$messageListHash();

  @override
  String toString() {
    return r'messageListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<Message>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Message> create(Ref ref) {
    final argument = this.argument as String;
    return messageList(
      ref,
      argument,
    );
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Message> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Message>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MessageListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$messageListHash() => r'b28147289a028084a99835ca996b5b0f26b41a3b';

/// 指定した会話のメッセージ一覧を取得する Provider
///
/// 生成されるプロバイダ名: messageListProvider

final class MessageListFamily extends $Family
    with $FunctionalFamilyOverride<List<Message>, String> {
  MessageListFamily._()
      : super(
          retry: null,
          name: r'messageListProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// 指定した会話のメッセージ一覧を取得する Provider
  ///
  /// 生成されるプロバイダ名: messageListProvider

  MessageListProvider call(
    String conversationId,
  ) =>
      MessageListProvider._(argument: conversationId, from: this);

  @override
  String toString() => r'messageListProvider';
}
