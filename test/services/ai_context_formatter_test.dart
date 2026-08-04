import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stronger/infrastructure/services/ai_context_formatter.dart';

void main() {
  group('AiContextFormatter', () {
    test('formats training data and tolerates incomplete entries', () {
      final result = AiContextFormatter.formatTrainingHistory([
        {
          'name': 'Push day',
          'date': Timestamp.fromDate(DateTime(2026, 8, 4)),
          'exercises': [
            {
              'name': 'Press banca',
              'series': [
                {'repetitions': 8, 'weight': 60},
                {'repetitions': 6, 'weight': 62.5},
              ],
            },
            'invalid exercise',
          ],
        },
        <String, dynamic>{},
      ]);

      expect(result, contains('4/8/2026: Push day'));
      expect(result, contains('Press banca: 8x60kg, 6x62.5kg'));
      expect(result, contains('Sin nombre'));
    });

    test('formats only available body measurements', () {
      final result = AiContextFormatter.formatBodyMeasurements([
        {'date': DateTime(2026, 8, 3), 'weight': 80, 'fat_percentage': 15.5},
        {'date': 'invalid'},
      ]);

      expect(result, '- 3/8/2026: Peso: 80 kg, Grasa: 15.5 %');
    });

    test('keeps a short alternating user-first history', () {
      final result = AiContextFormatter.sanitizeHistory([
        {'role': 'assistant', 'text': 'leading model turn'},
        {'role': 'user', 'text': ' first '},
        {'role': 'user', 'text': 'duplicate user'},
        {'role': 'assistant', 'text': 'answer'},
        {'role': 'invalid', 'text': 'ignored'},
        {'role': 'user', 'text': ''},
      ]);

      expect(result, [
        {'role': 'user', 'text': 'first'},
        {'role': 'assistant', 'text': 'answer'},
      ]);
    });
  });
}
