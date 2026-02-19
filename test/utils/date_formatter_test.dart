import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:earsmile/utils/date_formatter.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja');
  });

  final testDate = DateTime(2025, 2, 18, 14, 30, 5);

  group('DateFormatter', () {
    test('toHistoryListFormat: "M月d日 HH:mm" 形式', () {
      expect(DateFormatter.toHistoryListFormat(testDate), '2月18日 14:30');
    });

    test('toDetailTitleFormat: "M月d日の会話" 形式', () {
      expect(DateFormatter.toDetailTitleFormat(testDate), '2月18日の会話');
    });

    test('toConversationTitle: "yyyy/MM/dd HH:mm の会話" 形式', () {
      expect(DateFormatter.toConversationTitle(testDate),
          '2025/02/18 14:30 の会話');
    });

    test('toMessageTimestamp: "HH:mm:ss" 形式', () {
      expect(DateFormatter.toMessageTimestamp(testDate), '14:30:05');
    });

    test('午前0時のフォーマットが正しい', () {
      final midnight = DateTime(2025, 1, 1, 0, 0, 0);
      expect(DateFormatter.toHistoryListFormat(midnight), '1月1日 00:00');
      expect(DateFormatter.toMessageTimestamp(midnight), '00:00:00');
    });

    test('12月31日のフォーマットが正しい', () {
      final yearEnd = DateTime(2025, 12, 31, 23, 59, 59);
      expect(DateFormatter.toHistoryListFormat(yearEnd), '12月31日 23:59');
      expect(DateFormatter.toMessageTimestamp(yearEnd), '23:59:59');
    });
  });
}
