import 'package:flutter_test/flutter_test.dart';
import 'package:stronger/models/training_exercise.dart';

void main() {
  test('TrainingExercise preserves its series during a round trip', () {
    final exercise = TrainingExercise.fromMap({
      'exerciseId': 'bench',
      'name': 'Press banca',
      'series': [
        {'repetitions': 10, 'weight': 80},
      ],
    });

    expect(exercise.exerciseId, 'bench');
    expect(exercise.series.single.repetitions, 10);
    expect(exercise.series.single.weight, 80);
    expect(exercise.toMap(), {
      'exerciseId': 'bench',
      'name': 'Press banca',
      'series': [
        {'repetitions': 10, 'weight': 80.0},
      ],
    });
  });
}
