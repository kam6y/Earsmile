import 'dart:async';

import 'package:flutter/services.dart';

/// 音声認識イベントの種別
enum SpeechEventType {
  partialResult,
  finalResult,
  error,
  silenceDetected,
}

/// 音声認識イベントデータ
class SpeechEvent {
  final SpeechEventType type;
  final String? text;
  final double? confidence;
  final String? errorCode;
  final String? errorMessage;

  const SpeechEvent({
    required this.type,
    this.text,
    this.confidence,
    this.errorCode,
    this.errorMessage,
  });

  factory SpeechEvent.fromMap(Map<dynamic, dynamic> map) {
    final typeValue = map['type'];
    if (typeValue is! String) {
      return const SpeechEvent(
        type: SpeechEventType.error,
        errorCode: 'INVALID_EVENT_PAYLOAD',
        errorMessage: 'Event type is missing or invalid',
      );
    }

    final typeStr = typeValue;
    switch (typeStr) {
      case 'onPartialResult':
        return SpeechEvent(
          type: SpeechEventType.partialResult,
          text: map['text'] as String?,
          confidence: (map['confidence'] as num?)?.toDouble(),
        );
      case 'onFinalResult':
        return SpeechEvent(
          type: SpeechEventType.finalResult,
          text: map['text'] as String?,
          confidence: (map['confidence'] as num?)?.toDouble(),
        );
      case 'onError':
        return SpeechEvent(
          type: SpeechEventType.error,
          errorCode: map['errorCode'] as String?,
          errorMessage: map['message'] as String?,
        );
      case 'onSilenceDetected':
        return const SpeechEvent(type: SpeechEventType.silenceDetected);
      default:
        return SpeechEvent(
          type: SpeechEventType.error,
          errorCode: 'UNKNOWN_EVENT',
          errorMessage: 'Unknown event: $typeStr',
        );
    }
  }
}

/// 音声認識 Platform Channel ラッパー
///
/// iOS ネイティブの SpeechRecognizerPlugin と通信する。
/// コンストラクタで MethodChannel / EventChannel を差し替え可能（テスト用）。
class SpeechService {
  SpeechService({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _methodChannel =
            methodChannel ?? const MethodChannel('com.app.speech/recognizer'),
        _eventChannel = eventChannel ??
            const EventChannel('com.app.speech/recognizer_events');

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  /// 音声認識を開始する
  Future<void> startListening() async {
    await _methodChannel.invokeMethod<void>('startListening');
  }

  /// 音声認識を停止する
  Future<void> stopListening() async {
    await _methodChannel.invokeMethod<void>('stopListening');
  }

  /// マイク・音声認識の権限をリクエストする
  ///
  /// 戻り値: true = 許可、false = 拒否
  Future<bool> requestPermission() async {
    final result = await _methodChannel.invokeMethod<bool>('requestPermission');
    return result ?? false;
  }

  /// 現在の権限状態を確認する
  ///
  /// 戻り値: "granted" / "denied" / "notDetermined"
  Future<String> checkPermission() async {
    final result = await _methodChannel.invokeMethod<String>('checkPermission');
    return result ?? 'notDetermined';
  }

  /// ネイティブからのイベントストリーム
  Stream<SpeechEvent> get eventStream {
    return _eventChannel.receiveBroadcastStream().map((dynamic event) {
      if (event is Map<dynamic, dynamic>) {
        return SpeechEvent.fromMap(event);
      }
      return const SpeechEvent(
        type: SpeechEventType.error,
        errorCode: 'INVALID_EVENT_PAYLOAD',
        errorMessage: 'Event payload is not a map',
      );
    });
  }
}
