import 'dart:async';

import 'package:earsmile/providers/auth_provider.dart';
import 'package:earsmile/providers/speech_provider.dart';
import 'package:earsmile/screens/splash_screen.dart';
import 'package:earsmile/services/speech_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  late _MockSpeechService speechService;

  setUp(() {
    speechService = _MockSpeechService();
  });

  Widget buildTestWidget() {
    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Home Route'))),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        speechServiceProvider.overrideWithValue(speechService),
        authProvider.overrideWith(() => _MockAuthNotifier()),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('SplashScreen', () {
    testWidgets('requestPermission 応答待機中は3秒を超えても遷移しない', (tester) async {
      final completer = Completer<bool>();
      speechService.permissionStatus = 'notDetermined';
      speechService.requestPermissionHandler = () => completer.future;

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Home Route'), findsNothing);
      expect(speechService.requestPermissionCallCount, 1);
    });

    testWidgets('requestPermission が許可されたら Home へ遷移する', (tester) async {
      final completer = Completer<bool>();
      speechService.permissionStatus = 'notDetermined';
      speechService.requestPermissionHandler = () => completer.future;

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));

      expect(find.text('Home Route'), findsNothing);

      completer.complete(true);
      await tester.pumpAndSettle();

      expect(find.text('Home Route'), findsOneWidget);
    });

    testWidgets('requestPermission が拒否された場合は案内ダイアログを表示する', (tester) async {
      speechService.permissionStatus = 'notDetermined';
      speechService.requestPermissionHandler = () async => false;

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump();

      expect(find.text('マイクの使用が必要です'), findsOneWidget);
      expect(find.text('Home Route'), findsNothing);

      await tester.tap(find.text('あとで'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Home Route'), findsOneWidget);
    });
  });
}

class _MockSpeechService extends SpeechService {
  String permissionStatus = 'granted';
  Future<bool> Function()? requestPermissionHandler;
  int requestPermissionCallCount = 0;

  @override
  Future<String> checkPermission() async => permissionStatus;

  @override
  Future<bool> requestPermission() async {
    requestPermissionCallCount += 1;
    final handler = requestPermissionHandler;
    if (handler != null) {
      return handler();
    }
    return true;
  }
}

class _MockAuthNotifier extends AuthNotifier {
  @override
  Future<String?> build() async => 'mock-uid';
}
