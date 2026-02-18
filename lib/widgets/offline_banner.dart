import 'package:flutter/material.dart';

import '../config/constants.dart';

/// オフライン状態を示すバナー Widget
///
/// ネットワーク未接続時に画面上部に表示する。
/// オンデバイス認識で継続動作していることをユーザーに通知する。
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppConstants.offlineBannerHeight,
      width: double.infinity,
      color: const Color(0xFFFFC107), // アンバー/黄色
      child: const Center(
        child: Text(
          'オフライン（オンデバイス認識中）',
          style: TextStyle(
            color: Color(0xFF000000),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
