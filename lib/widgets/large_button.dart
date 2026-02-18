import 'package:flutter/material.dart';

import '../config/constants.dart';

/// 最小 64x64pt を保証するアクセシブルなボタン Widget
///
/// 詳細設計書 §9.1 に準拠
class LargeButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double minWidth;
  final double minHeight;

  /// VoiceOver 用のセマンティクスラベル（省略時は [label] を使用）
  final String? semanticsLabel;

  const LargeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.minWidth = AppConstants.minTouchTarget,
    this.minHeight = AppConstants.minTouchTarget,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel ?? label,
      button: true,
      enabled: onPressed != null,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minWidth,
          minHeight: minHeight,
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            minimumSize: Size(minWidth, minHeight),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
