import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/constants.dart';
import '../config/routes.dart';
import '../providers/speech_provider.dart';
import '../utils/accessibility_helpers.dart';
import 'large_button.dart';

/// 操作パネル Widget
///
/// - 停止/再開ボタン（80x80pt、赤/緑）
/// - 履歴ボタン（64x64pt、グレー）
/// - 設定ボタン（64x64pt、グレー）
class ControlPanel extends ConsumerWidget {
  final Future<void> Function()? onBeforeRouteChange;
  final Future<void> Function()? onAfterRouteReturn;

  const ControlPanel({
    super.key,
    this.onBeforeRouteChange,
    this.onAfterRouteReturn,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speechState = ref.watch(speechProvider);
    final isListening = speechState.status == SpeechStatus.listening;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 停止/再開 メインボタン
          LargeButton(
            label: isListening ? '停止' : '再開',
            semanticsLabel: isListening
                ? AccessibilityLabels.stopListening
                : AccessibilityLabels.resumeListening,
            backgroundColor: isListening ? Colors.red : Colors.green,
            foregroundColor: Colors.white,
            minWidth: AppConstants.mainButtonSize,
            minHeight: AppConstants.mainButtonSize,
            onPressed: () {
              final notifier = ref.read(speechProvider.notifier);
              if (isListening) {
                notifier.pause();
              } else {
                notifier.resume();
              }
            },
          ),
          // 履歴ボタン
          LargeButton(
            label: 'りれき',
            semanticsLabel: AccessibilityLabels.openHistory,
            backgroundColor: Colors.grey.shade600,
            foregroundColor: Colors.white,
            onPressed: () async {
              final beforeRouteChange = onBeforeRouteChange;
              if (beforeRouteChange != null) {
                await beforeRouteChange();
              }
              if (!context.mounted) return;
              await context.push(RoutePaths.history);
              if (!context.mounted) return;
              final afterRouteReturn = onAfterRouteReturn;
              if (afterRouteReturn != null) {
                await afterRouteReturn();
              }
            },
          ),
          // 設定ボタン
          LargeButton(
            label: 'せってい',
            semanticsLabel: AccessibilityLabels.openSettings,
            backgroundColor: Colors.grey.shade600,
            foregroundColor: Colors.white,
            onPressed: () async {
              final beforeRouteChange = onBeforeRouteChange;
              if (beforeRouteChange != null) {
                await beforeRouteChange();
              }
              if (!context.mounted) return;
              await context.push(RoutePaths.settings);
              if (!context.mounted) return;
              final afterRouteReturn = onAfterRouteReturn;
              if (afterRouteReturn != null) {
                await afterRouteReturn();
              }
            },
          ),
        ],
      ),
    );
  }
}
