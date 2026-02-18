import 'package:flutter/material.dart';

import '../config/constants.dart';

/// 確認ダイアログを表示し、ユーザーの選択（true/false）を返す
///
/// - [message]: ダイアログ本文
/// - [confirmLabel]: 確認ボタンのラベル（デフォルト: 「はい」）
/// - [cancelLabel]: キャンセルボタンのラベル（デフォルト: 「いいえ」）
///
/// 返り値: はい → true, いいえ または ダイアログ外タップ → false
Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String message,
  String confirmLabel = 'はい',
  String cancelLabel = 'いいえ',
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _ConfirmationDialog(
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
    ),
  );
  return result ?? false;
}

class _ConfirmationDialog extends StatelessWidget {
  final String message;
  final String confirmLabel;
  final String cancelLabel;

  const _ConfirmationDialog({
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('確認'),
      content: Text(message),
      actions: [
        // いいえボタン（グレー）
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppConstants.dialogButtonMinWidth,
            minHeight: AppConstants.dialogButtonMinHeight,
          ),
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
              minimumSize: const Size(
                AppConstants.dialogButtonMinWidth,
                AppConstants.dialogButtonMinHeight,
              ),
            ),
            child: Text(cancelLabel),
          ),
        ),
        // はいボタン（赤）
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppConstants.dialogButtonMinWidth,
            minHeight: AppConstants.dialogButtonMinHeight,
          ),
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(
                AppConstants.dialogButtonMinWidth,
                AppConstants.dialogButtonMinHeight,
              ),
            ),
            child: Text(confirmLabel),
          ),
        ),
      ],
    );
  }
}
