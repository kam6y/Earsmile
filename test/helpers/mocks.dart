import 'dart:async';

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
  int startCallCount = 0;
  int stopCallCount = 0;
  bool shouldThrowOnStart = false;
  String permissionStatus = 'granted';

  MockSpeechService() : super();

  @override
  Future<void> startListening() async {
    if (shouldThrowOnStart) {
      throw Exception('Start failed');
    }
    startCalled = true;
    startCallCount += 1;
  }

  @override
  Future<void> stopListening() async {
    stopCalled = true;
    stopCallCount += 1;
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
  AppSettings loadSettings() => _settings;

  @override
  void saveSettings(AppSettings settings) {
    _settings = settings;
  }

  @override
  void saveConversation(Conversation conversation) {
    final index = conversations.indexWhere((c) => c.uuid == conversation.uuid);
    if (index >= 0) {
      conversations[index] = conversation;
    } else {
      conversations.add(conversation);
    }
  }

  @override
  List<Conversation> getAllConversations() {
    final sorted = List<Conversation>.from(conversations)
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return sorted;
  }

  @override
  void deleteConversation(String uuid) {
    conversations.removeWhere((c) => c.uuid == uuid);
  }

  @override
  void addMessage(Message message) {
    messages.add(message);
  }

  @override
  List<Message> getMessages(String conversationId) {
    return messages.where((m) => m.conversationId == conversationId).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  @override
  void deleteMessages(String conversationId) {
    messages.removeWhere((m) => m.conversationId == conversationId);
  }
}

/// テスト用 SettingsNotifier
class FakeSettingsNotifier extends SettingsNotifier {
  final AppSettings _initial;

  FakeSettingsNotifier([AppSettings? settings])
      : _initial = settings ?? AppSettings();

  @override
  AppSettings build() => _initial;
}

/// テスト用 ConversationListNotifier
class FakeConversationListNotifier extends ConversationListNotifier {
  final List<Conversation> _conversations;

  FakeConversationListNotifier(this._conversations);

  @override
  List<Conversation> build() => _conversations;

  @override
  void deleteConversation(String uuid) {
    _conversations.removeWhere((c) => c.uuid == uuid);
    state = List.from(_conversations);
  }
}
