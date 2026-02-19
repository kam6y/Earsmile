import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../config/constants.dart';
import '../models/message.dart';
import '../services/speech_service.dart';
import 'local_storage_provider.dart';

part 'speech_provider.g.dart';

// ---------------------------------------------------------------------------
// SpeechState
// ---------------------------------------------------------------------------

enum SpeechStatus { idle, listening, paused, error }

class SpeechState {
  final SpeechStatus status;
  final String currentPartialText;
  final double currentConfidence;
  final List<Message> confirmedMessages;
  final String? errorMessage;
  final int retryCount;

  const SpeechState({
    this.status = SpeechStatus.idle,
    this.currentPartialText = '',
    this.currentConfidence = 0.0,
    this.confirmedMessages = const [],
    this.errorMessage,
    this.retryCount = 0,
  });

  SpeechState copyWith({
    SpeechStatus? status,
    String? currentPartialText,
    double? currentConfidence,
    List<Message>? confirmedMessages,
    String? errorMessage,
    int? retryCount,
  }) {
    return SpeechState(
      status: status ?? this.status,
      currentPartialText: currentPartialText ?? this.currentPartialText,
      currentConfidence: currentConfidence ?? this.currentConfidence,
      confirmedMessages: confirmedMessages ?? this.confirmedMessages,
      errorMessage: errorMessage,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

// ---------------------------------------------------------------------------
// SpeechService Provider（override 必須パターン）
// ---------------------------------------------------------------------------

final speechServiceProvider = Provider<SpeechService>((ref) {
  throw UnimplementedError(
    'speechServiceProvider を ProviderScope で override してください',
  );
});

// ---------------------------------------------------------------------------
// SpeechNotifier
// ---------------------------------------------------------------------------

@riverpod
class SpeechNotifier extends _$SpeechNotifier {
  StreamSubscription<SpeechEvent>? _eventSubscription;
  final _uuid = const Uuid();
  String? _currentConversationId;

  @override
  SpeechState build() {
    ref.onDispose(() {
      _eventSubscription?.cancel();
    });
    return const SpeechState();
  }

  /// 現在の会話IDを設定する
  void setConversationId(String conversationId) {
    _currentConversationId = conversationId;
  }

  /// 音声認識を開始する
  Future<void> startListening() async {
    if (_currentConversationId == null) return;

    final speechService = ref.read(speechServiceProvider);

    _eventSubscription?.cancel();
    _eventSubscription = speechService.eventStream.listen(_handleEvent);

    try {
      await speechService.startListening();
      state = state.copyWith(
        status: SpeechStatus.listening,
        errorMessage: null,
        retryCount: 0,
      );
    } catch (e) {
      debugPrint('SpeechNotifier.startListening error: $e');
      state = state.copyWith(
        status: SpeechStatus.error,
        errorMessage: '音声認識の開始に失敗しました',
      );
    }
  }

  /// 音声認識を一時停止する
  Future<void> pause() async {
    final speechService = ref.read(speechServiceProvider);
    try {
      await speechService.stopListening();
    } catch (e) {
      debugPrint('SpeechNotifier.pause error: $e');
    }
    _eventSubscription?.cancel();
    state = state.copyWith(status: SpeechStatus.paused);
  }

  /// 音声認識を再開する
  Future<void> resume() async {
    await startListening();
  }

  /// 音声認識を完全停止する
  Future<void> stop() async {
    _eventSubscription?.cancel();
    try {
      final speechService = ref.read(speechServiceProvider);
      await speechService.stopListening();
    } catch (e) {
      debugPrint('SpeechNotifier.stop error: $e');
    }
    // async 待機後に Provider が破棄されている場合があるため確認
    if (!ref.mounted) return;
    state = state.copyWith(status: SpeechStatus.idle);
  }

  /// EventChannel からのイベントを処理する
  void _handleEvent(SpeechEvent event) {
    switch (event.type) {
      case SpeechEventType.partialResult:
        state = state.copyWith(
          currentPartialText: event.text ?? '',
          currentConfidence: event.confidence ?? 0.0,
        );

      case SpeechEventType.finalResult:
        _finalizeResult(event.text ?? '', event.confidence ?? 0.0);

      case SpeechEventType.silenceDetected:
        if (state.currentPartialText.isNotEmpty) {
          _finalizeResult(state.currentPartialText, state.currentConfidence);
        }

      case SpeechEventType.error:
        _handleError(event.errorCode ?? 'UNKNOWN', event.errorMessage ?? '');
    }
  }

  /// 認識結果を確定し、ObjectBox に保存する
  void _finalizeResult(String text, double confidence) {
    if (text.isEmpty || _currentConversationId == null) return;

    final message = Message(
      uuid: _uuid.v4(),
      conversationId: _currentConversationId!,
      timestamp: DateTime.now(),
      text: text,
      confidence: confidence,
      isFinal: true,
    );

    state = state.copyWith(
      confirmedMessages: [...state.confirmedMessages, message],
      currentPartialText: '',
      currentConfidence: 0.0,
    );

    ref.read(localStorageServiceProvider).addMessage(message);
  }

  /// エラー発生時の自動リトライ処理
  void _handleError(String code, String message) {
    debugPrint('SpeechNotifier._handleError: code=$code, message=$message');
    final newRetryCount = state.retryCount + 1;

    if (newRetryCount >= AppConstants.maxRetryCount) {
      state = state.copyWith(
        status: SpeechStatus.error,
        errorMessage: '音声認識でエラーが発生しました。再度お試しください',
        retryCount: 0,
      );
      _eventSubscription?.cancel();
    } else {
      state = state.copyWith(retryCount: newRetryCount);
      Future.delayed(AppConstants.retryDelay, () {
        if (!ref.mounted) return;
        if (state.status != SpeechStatus.idle &&
            state.status != SpeechStatus.paused) {
          startListening();
        }
      });
    }
  }
}
