import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';
import '../providers/settings_provider.dart';
import '../providers/speech_provider.dart';

/// 認識テキスト表示 Widget
///
/// - 確定テキスト（isFinal: true）: テーマ通常色
/// - 認識中テキスト（isFinal: false）: グレー色（高コントラスト時は薄黄色）
/// - 最新テキストへ自動スクロール
/// - フォントサイズは設定に連動
class TranscriptView extends ConsumerStatefulWidget {
  const TranscriptView({super.key});

  @override
  ConsumerState<TranscriptView> createState() => _TranscriptViewState();
}

class _TranscriptViewState extends ConsumerState<TranscriptView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final speechState = ref.watch(speechProvider);
    final settingsAsync = ref.watch(settingsProvider);

    final fontSize = switch (settingsAsync) {
      AsyncData(:final value) => resolveBodyFontSize(value.fontSize),
      _ => 24.0,
    };
    final isHighContrast = switch (settingsAsync) {
      AsyncData(:final value) => value.isHighContrast,
      _ => false,
    };

    final theme = Theme.of(context);
    final confirmedMessages = speechState.confirmedMessages;
    final hasPartial = speechState.currentPartialText.isNotEmpty;
    final itemCount = confirmedMessages.length + (hasPartial ? 1 : 0);

    // 認識中テキストの色: 高コントラスト時は薄黄色、通常は灰色
    final partialColor =
        isHighContrast ? const Color(0xFF999900) : Colors.grey;

    // テキスト変化時に自動スクロール
    _scrollToBottom();

    return Semantics(
      label: '認識されたテキストの表示エリア',
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index < confirmedMessages.length) {
            final message = confirmedMessages[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                message.text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: fontSize,
                ),
              ),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                speechState.currentPartialText,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: fontSize,
                  color: partialColor,
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
