import 'package:flutter_test/flutter_test.dart';
import 'package:stronger/models/selected_exercise.dart';
import 'package:stronger/models/serie.dart';

void main() {
  group('SelectedExercise', () {
    final seriesMapList = [
      {'repetitions': 10, 'weight': 50.0},
      {'repetitions': 8, 'weight': 55.0},
    ];

    group('fromMap', () {
      test('parses all fields correctly', () {
        final exercise = SelectedExercise.fromMap({
          'exerciseId': 'ex1',
          'name': 'Bench Press',
          'category': 'Chest',
          'series': seriesMapList,
        });

        expect(exercise.id, 'ex1');
        expect(exercise.name, 'Bench Press');
        expect(exercise.category, 'Chest');
        expect(exercise.series.length, 2);
        expect(exercise.series[0].repetitions, 10);
        expect(exercise.series[1].weight, 55.0);
      });
    });

    group('toMap', () {
      test('serializes all fields with correct keys', () {
        final exercise = SelectedExercise(
          id: 'ex1',
          name: 'Squat',
          category: 'Legs',
          series: [Series(repetitions: 5, weight: 100.0)],
        );
        final map = exercise.toMap();

        expect(map['exerciseId'], 'ex1');
        expect(map['name'], 'Squat');
        expect(map['category'], 'Legs');
        expect((map['series'] as List).length, 1);
      });
    });

    test('defaults to one empty series when none provided', () {
      final exercise = SelectedExercise(
        id: 'ex1',
        name: 'Deadlift',
        category: 'Back',
      );
      expect(exercise.series.length, 1);
      expect(exercise.series[0].repetitions, 0);
      expect(exercise.series[0].weight, 0.0);
    });

    test('round-trip fromMap → toMap preserves values', () {
      final original = {
        'exerciseId': 'ex2',
        'name': 'Pull-up',
        'category': 'Back',
        'series': seriesMapList,
      };
      final map = SelectedExercise.fromMap(original).toMap();

      expect(map['exerciseId'], original['exerciseId']);
      expect(map['name'], original['name']);
      expect(map['category'], original['category']);
    });
  });
}
