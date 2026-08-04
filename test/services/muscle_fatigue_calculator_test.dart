import 'package:flutter_test/flutter_test.dart';
import 'package:stronger/infrastructure/services/muscle_fatigue_calculator.dart';

void main() {
  group('MuscleFatigueCalculator', () {
    test('accepts allowed muscles and clamps scores', () {
      final result = MuscleFatigueCalculator.parseScores(
        '{"chest": 120, "triceps": -10, "unknown": 50}',
      );

      expect(result, {'chest': 100, 'triceps': 0});
    });

    test('accepts a JSON response wrapped in a code fence', () {
      final result = MuscleFatigueCalculator.parseScores(
        '```json\n{"quads": 72.5}\n```',
      );

      expect(result, {'quads': 72.5});
    });

    test('rejects malformed output', () {
      expect(MuscleFatigueCalculator.parseScores('not json'), isEmpty);
      expect(MuscleFatigueCalculator.parseScores('[]'), isEmpty);
    });

    test('uses a linear 72 hour recovery window', () {
      final updatedAt = DateTime(2026, 8, 1, 12);

      expect(
        MuscleFatigueCalculator.applyDecay(
          90,
          updatedAt,
          now: updatedAt.add(const Duration(hours: 24)),
        ),
        closeTo(60, 0.001),
      );
      expect(
        MuscleFatigueCalculator.applyDecay(
          90,
          updatedAt,
          now: updatedAt.add(const Duration(hours: 72)),
        ),
        0,
      );
    });
  });
}
