import 'package:flutter_test/flutter_test.dart';
import 'package:stronger/models/serie.dart';

void main() {
  group('Series', () {
    group('fromMap', () {
      test('parses all fields correctly', () {
        final series = Series.fromMap({'repetitions': 10, 'weight': 75.5});
        expect(series.repetitions, 10);
        expect(series.weight, 75.5);
      });

      test('defaults to 0 when fields are missing', () {
        final series = Series.fromMap({});
        expect(series.repetitions, 0);
        expect(series.weight, 0.0);
      });

      test('coerces int weight to double', () {
        final series = Series.fromMap({'repetitions': 8, 'weight': 100});
        expect(series.weight, isA<double>());
        expect(series.weight, 100.0);
      });
    });

    group('toMap', () {
      test('serializes all fields', () {
        final series = Series(repetitions: 12, weight: 60.0);
        final map = series.toMap();
        expect(map['repetitions'], 12);
        expect(map['weight'], 60.0);
      });
    });

    test('round-trip fromMap → toMap preserves values', () {
      final original = {'repetitions': 5, 'weight': 80.0};
      final map = Series.fromMap(original).toMap();
      expect(map['repetitions'], original['repetitions']);
      expect(map['weight'], original['weight']);
    });
  });
}
