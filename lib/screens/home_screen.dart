import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/connectivity_provider.dart';
import '../providers/conversation_provider.dart';
import '../providers/speech_provider.dart';
import '../widgets/control_panel.dart';
import '../widgets/offline_banner.dart';
import '../widgets/transcript_view.dart';

/// ホーム画面 - 音声聴取画面
///
/// - アプリ表示時に新規会話を開始し、音声認識を自動スタート
/// - リアルタイムでテキストを表示
/// - 停止/再開・履歴・設定への操作パネル
/// - オフライン時にバナー表示
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeConversation();
    });
  }

  Future<void> _initializeConversation() async {
    if (_initialized || !mounted) return;
    _initialized = true;

    final speechNotifier = ref.read(speechProvider.notifier);
    speechNotifier.resetDisplayState();

    final conversationNotifier = ref.read(conversationProvider.notifier);
    final conversation = conversationNotifier.startNewConversation();

    speechNotifier.setConversationId(conversation.uuid);
    await speechNotifier.startListening();

    if (!mounted) return;
    final started = ref.read(speechProvider).status == SpeechStatus.listening;
    if (!started) {
      speechNotifier.clearConversationId();
      conversationNotifier.endConversation();
      _initialized = false;
    }
  }

  Future<void> _closeSessionForNavigation() async {
    if (!_initialized) return;
    final speechNotifier = ref.read(speechProvider.notifier);
    await speechNotifier.stop();
    speechNotifier.clearConversationId();
    speechNotifier.resetDisplayState();
    ref.read(conversationProvider.notifier).endConversation();
    _initialized = false;
  }

  void _closeSessionWithoutAwait() {
    if (!_initialized) return;
    // stop() は async だが、dispose() 内では await できない。
    // EventChannel の購読解除とネイティブ側の停止を発火する。
    final speechNotifier = ref.read(speechProvider.notifier);
    speechNotifier.stop();
    speechNotifier.clearConversationId();
    ref.read(conversationProvider.notifier).endConversation();
    _initialized = false;
  }

  @override
  void dispose() {
    _closeSessionWithoutAwait();
    super.dispose();
  }

  @override
  void deactivate() {
    // replace/破棄時の取りこぼしを防ぐための保険
    if (_initialized) {
      _closeSessionWithoutAwait();
    }
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final connectivityAsync = ref.watch(connectivityProvider);
    final isOffline = switch (connectivityAsync) {
      AsyncData(:final value) => !value,
      _ => false,
    };

    final speechState = ref.watch(speechProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // オフラインバナー（必要時のみ）
            if (isOffline) const OfflineBanner(),

            // エラー表示（必要時のみ）
            if (speechState.status == SpeechStatus.error &&
                speechState.errorMessage != null)
              Semantics(
                liveRegion: true,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.red.shade100,
                  child: Text(
                    '音声認識エラー: ${speechState.errorMessage}',
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              ),

            // テキスト表示エリア
            const Expanded(
              child: TranscriptView(),
            ),

            // 操作パネル
            ControlPanel(
              onBeforeRouteChange: _closeSessionForNavigation,
              onAfterRouteReturn: _initializeConversation,
            ),
          ],
        ),
      ),
    );
  }
}
