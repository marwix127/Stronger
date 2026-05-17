import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stronger/models/training.dart';
import 'package:stronger/models/selected_exercise.dart';
import 'package:stronger/models/serie.dart';

void main() {
  final testDate = DateTime(2025, 1, 15, 10, 0);

  final testExercise = SelectedExercise(
    id: 'ex1',
    name: 'Bench Press',
    category: 'Chest',
    series: [Series(repetitions: 10, weight: 80.0)],
  );

  group('Training', () {
    group('toMap', () {
      test('serializes all fields correctly', () {
        final training = Training(
          id: 'train1',
          name: 'Push Day',
          date: testDate,
          weight: 75.0,
          exercises: [testExercise],
        );
        final map = training.toMap();

        expect(map['name'], 'Push Day');
        expect(map['weight'], 75.0);
        expect(map['date'], isA<Timestamp>());
        expect((map['date'] as Timestamp).toDate(), testDate);
        expect((map['exercises'] as List).length, 1);
      });

      test('serializes null weight', () {
        final training = Training(
          id: 'train2',
          name: 'Leg Day',
          date: testDate,
          exercises: [],
        );
        expect(training.toMap()['weight'], isNull);
      });

      test('does not include id in map (Firestore manages it)', () {
        final training = Training(
          id: 'train1',
          name: 'Test',
          date: testDate,
          exercises: [],
        );
        expect(training.toMap().containsKey('id'), false);
      });
    });

    group('fromFirestore', () {
      test('parses all fields correctly', () {
        final training = Training.fromFirestore('train1', {
          'name': 'Push Day',
          'weight': 75.0,
          'date': Timestamp.fromDate(testDate),
          'exercises': [
            {
              'exerciseId': 'ex1',
              'name': 'Bench Press',
              'category': 'Chest',
              'series': [
                {'repetitions': 10, 'weight': 80.0},
              ],
            },
          ],
        });

        expect(training.id, 'train1');
        expect(training.name, 'Push Day');
        expect(training.weight, 75.0);
        expect(training.date, testDate);
        expect(training.exercises.length, 1);
        expect(training.exercises[0].name, 'Bench Press');
      });

      test('handles empty exercise list', () {
        final training = Training.fromFirestore('train2', {
          'name': 'Rest Day',
          'weight': null,
          'date': Timestamp.fromDate(testDate),
          'exercises': [],
        });

        expect(training.exercises, isEmpty);
      });
    });
  });
}
