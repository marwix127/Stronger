import 'package:flutter_test/flutter_test.dart';
import 'package:stronger/models/training.dart';
import 'package:stronger/models/selected_exercise.dart';
import 'package:stronger/models/serie.dart';
import 'package:stronger/UI/pages/grafics_page.dart';

Training _makeTraining({
  required String exerciseName,
  required List<Series> series,
  DateTime? date,
}) {
  return Training(
    id: 'test',
    name: 'Test Training',
    date: date ?? DateTime(2025, 1, 1),
    exercises: [
      SelectedExercise(
        id: 'ex1',
        name: exerciseName,
        category: 'Test',
        series: series,
      ),
    ],
  );
}

void main() {
  group('calculateVolumePerExercise', () {
    test('calculates volume as sum of weight × reps per series', () {
      final trainings = [
        _makeTraining(
          exerciseName: 'Bench Press',
          series: [
            Series(repetitions: 10, weight: 80.0), // 800
            Series(repetitions: 8, weight: 85.0),  // 680
          ],
        ),
      ];

      final result = calculateVolumePerExercise(trainings, 'Bench Press');

      expect(result.length, 1);
      expect(result[0]['volume'], 1480.0);
    });

    test('filters out trainings where exercise has zero volume', () {
      final trainings = [
        _makeTraining(
          exerciseName: 'Bench Press',
          series: [Series(repetitions: 0, weight: 0)],
        ),
      ];

      final result = calculateVolumePerExercise(trainings, 'Bench Press');
      expect(result, isEmpty);
    });

    test('ignores trainings that do not contain the exercise', () {
      final trainings = [
        _makeTraining(
          exerciseName: 'Squat',
          series: [Series(repetitions: 5, weight: 100.0)],
        ),
      ];

      final result = calculateVolumePerExercise(trainings, 'Bench Press');
      expect(result, isEmpty);
    });

    test('is case-insensitive when matching exercise name', () {
      final trainings = [
        _makeTraining(
          exerciseName: 'bench press',
          series: [Series(repetitions: 10, weight: 80.0)],
        ),
      ];

      final result = calculateVolumePerExercise(trainings, 'Bench Press');
      expect(result.length, 1);
    });

    test('returns one entry per training sorted by insertion order', () {
      final dates = [DateTime(2025, 1, 1), DateTime(2025, 1, 8)];
      final trainings = [
        _makeTraining(
          exerciseName: 'Squat',
          series: [Series(repetitions: 5, weight: 100.0)],
          date: dates[0],
        ),
        _makeTraining(
          exerciseName: 'Squat',
          series: [Series(repetitions: 5, weight: 110.0)],
          date: dates[1],
        ),
      ];

      final result = calculateVolumePerExercise(trainings, 'Squat');
      expect(result.length, 2);
      expect(result[0]['date'], dates[0]);
      expect(result[1]['date'], dates[1]);
    });
  });

  group('calculateAverageWeightPerExercise', () {
    test('calculates average weight across all series', () {
      final trainings = [
        _makeTraining(
          exerciseName: 'Deadlift',
          series: [
            Series(repetitions: 5, weight: 100.0),
            Series(repetitions: 5, weight: 120.0),
          ],
        ),
      ];

      final result = calculateAverageWeightPerExercise(trainings, 'Deadlift');
      expect(result.length, 1);
      expect(result[0]['average_weight'], 110.0);
    });

    test('filters out trainings where exercise has zero average weight', () {
      final trainings = [
        _makeTraining(
          exerciseName: 'Deadlift',
          series: [Series(repetitions: 0, weight: 0)],
        ),
      ];

      final result = calculateAverageWeightPerExercise(trainings, 'Deadlift');
      expect(result, isEmpty);
    });

    test('ignores trainings that do not contain the exercise', () {
      final trainings = [
        _makeTraining(
          exerciseName: 'Squat',
          series: [Series(repetitions: 5, weight: 100.0)],
        ),
      ];

      final result = calculateAverageWeightPerExercise(trainings, 'Deadlift');
      expect(result, isEmpty);
    });

    test('handles single series correctly', () {
      final trainings = [
        _makeTraining(
          exerciseName: 'Curl',
          series: [Series(repetitions: 12, weight: 20.0)],
        ),
      ];

      final result = calculateAverageWeightPerExercise(trainings, 'Curl');
      expect(result[0]['average_weight'], 20.0);
    });
  });
}
