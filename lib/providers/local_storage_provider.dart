import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/local_storage_service.dart';

/// LocalStorageService の Provider
///
/// main.dart の ProviderScope で overrideWithValue() して提供する
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  throw UnimplementedError('localStorageServiceProvider を ProviderScope で override してください');
});
