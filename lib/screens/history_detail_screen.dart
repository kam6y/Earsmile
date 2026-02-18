import 'package:flutter/material.dart';

/// 履歴詳細画面（Step 8 で実装）
class HistoryDetailScreen extends StatelessWidget {
  final String conversationId;

  const HistoryDetailScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('履歴詳細: $conversationId')),
    );
  }
}
