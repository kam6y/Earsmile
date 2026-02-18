import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/speech_provider.dart';

/// スプラッシュ画面
///
/// 処理フロー:
/// 1. ロゴとアプリ名を中央に表示
/// 2. Firebase 匿名認証を実行
/// 3. 認証完了（成功・失敗問わず）または 3秒タイムアウトで Home へ遷移
///
/// マイク権限チェックは Step 6 で追加予定。
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timeoutTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    // 最初のフレーム描画後に初期化を開始
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startInitialization();
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _startInitialization() async {
    // タイムアウトタイマー: 3秒以内に初期化が終わらなければ強制遷移
    _timeoutTimer = Timer(AppConstants.splashTimeout, () {
      _navigateToHome();
    });

    // Firebase 匿名認証を実行
    try {
      await ref.read(authProvider.future);
    } catch (_) {
      // オフラインファースト: 認証失敗でもアプリ利用を許可
    }

    // マイク・音声認識の権限チェック
    try {
      final speechService = ref.read(speechServiceProvider);
      final permissionStatus = await speechService.checkPermission();
      if (permissionStatus == 'notDetermined') {
        await speechService.requestPermission();
      } else if (permissionStatus == 'denied' && mounted) {
        await _showPermissionDeniedDialog();
      }
    } catch (_) {
      // 権限チェック失敗でもアプリ利用を許可
    }

    _navigateToHome();
  }

  Future<void> _showPermissionDeniedDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('マイクの使用が必要です'),
        content: const Text(
          'お話しされた内容を文字にするには、マイクの使用を許可してください。\n\n'
          '「設定」アプリを開いて「earsmile」のマイクを有効にしてください。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('あとで'),
          ),
        ],
      ),
    );
  }

  void _navigateToHome() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _timeoutTimer?.cancel();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hearing,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Semantics(
              label: 'earsmile、起動中です',
              child: Text(
                'earsmile',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
