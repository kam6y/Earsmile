import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:earsmile/app.dart';
import 'package:earsmile/providers/local_storage_provider.dart';
import 'package:earsmile/providers/settings_provider.dart';

import 'helpers/mocks.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final mockStorage = MockLocalStorageService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWithValue(mockStorage),
          settingsProvider.overrideWith(() => FakeSettingsNotifier()),
        ],
        child: const App(),
      ),
    );
    expect(find.text('earsmile'), findsWidgets);
  });
}
