import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:earsmile/models/app_settings.dart';
import 'package:earsmile/models/conversation.dart';
import 'package:earsmile/models/message.dart';
import 'package:earsmile/providers/conversation_list_provider.dart';
import 'package:earsmile/providers/settings_provider.dart';
import 'package:earsmile/services/local_storage_service.dart';
import 'package:earsmile/services/speech_service.dart';

/// テスト用 SpeechService モック
class MockSpeechService extends SpeechService {
  final StreamController<SpeechEvent> _controller =
      StreamController<SpeechEvent>.broadcast(sync: true);
  bool startCalled = false;
  bool stopCalled = false;
  bool shouldThrowOnStart = false;
  String permissionStatus = 'granted';

  MockSpeechService() : super();

  @override
  Future<void> startListening() async {
    if (shouldThrowOnStart) {
      throw Exception('Start failed');
    }
    startCalled = true;
  }

  @override
  Future<void> stopListening() async {
    stopCalled = true;
  }

  @override
  Stream<SpeechEvent> get eventStream => _controller.stream;

  @override
  Future<String> checkPermission() async => permissionStatus;

  @override
  Future<bool> requestPermission() async => true;

  void emitEvent(SpeechEvent event) {
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}

/// テスト用 LocalStorageService モック
class MockLocalStorageService extends LocalStorageService {
  final List<Conversation> conversations = [];
  final List<Message> messages = [];
  AppSettings _settings = AppSettings();

  @override
  Future<void> initialize() async {}

  @override
  Future<AppSettings> loadSettings() async => _settings;

  @override
  Future<void> saveSettings(AppSettings settings) async {
    _settings = settings;
  }

  @override
  Future<void> saveConversation(Conversation conversation) async {
    final index = conversations.indexWhere((c) => c.uuid == conversation.uuid);
    if (index >= 0) {
      conversations[index] = conversation;
    } else {
      conversations.add(conversation);
    }
  }

  @override
  Future<List<Conversation>> getAllConversations() async {
    final sorted = List<Conversation>.from(conversations)
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return sorted;
  }

  @override
  Future<void> deleteConversation(String uuid) async {
    conversations.removeWhere((c) => c.uuid == uuid);
  }

  @override
  Future<void> addMessage(Message message) async {
    messages.add(message);
  }

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    return messages
        .where((m) => m.conversationId == conversationId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  @override
  Future<void> deleteMessages(String conversationId) async {
    messages.removeWhere((m) => m.conversationId == conversationId);
  }
}

/// テスト用 SettingsNotifier
class FakeSettingsNotifier extends SettingsNotifier {
  final AppSettings _initial;

  FakeSettingsNotifier([AppSettings? settings])
      : _initial = settings ?? AppSettings();

  @override
  Future<AppSettings> build() async => _initial;
}

/// テスト用 ConversationListNotifier
class FakeConversationListNotifier extends ConversationListNotifier {
  final List<Conversation> _conversations;

  FakeConversationListNotifier(this._conversations);

  @override
  Future<List<Conversation>> build() async => _conversations;

  @override
  Future<void> deleteConversation(String uuid) async {
    _conversations.removeWhere((c) => c.uuid == uuid);
    state = AsyncData(List.from(_conversations));
  }
}
