import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'providers/local_storage_provider.dart';
import 'providers/speech_provider.dart';
import 'services/local_storage_service.dart';
import 'services/speech_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final localStorageService = LocalStorageService();
  await localStorageService.initialize();
  await initializeDateFormatting('ja');

  final speechService = SpeechService();

  runApp(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(localStorageService),
        speechServiceProvider.overrideWithValue(speechService),
      ],
      child: const App(),
    ),
  );
}
