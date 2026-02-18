import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:earsmile/providers/auth_provider.dart';

void main() {
  group('AuthProvider', () {
    test('認証成功時は UID を返す', () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => _MockAuthNotifier()),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(authProvider.future);
      expect(result, equals('mock-uid-12345'));
    });

    test('認証失敗時は null を返す', () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => _FailingAuthNotifier()),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(authProvider.future);
      expect(result, isNull);
    });
  });
}

class _MockAuthNotifier extends AuthNotifier {
  @override
  Future<String?> build() async => 'mock-uid-12345';
}

class _FailingAuthNotifier extends AuthNotifier {
  @override
  Future<String?> build() async => null;
}
