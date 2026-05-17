import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stronger/infrastructure/services/firebase/training_service.dart';
import 'package:stronger/models/selected_exercise.dart';
import 'package:stronger/models/serie.dart';
import 'package:stronger/models/training.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late TrainingService service;
  late TrainingService unauthService;

  const uid = 'user123';
  final testDate = DateTime(2025, 3, 1, 10, 0);

  Training makeTraining({String id = '', String name = 'Push Day'}) {
    return Training(
      id: id,
      name: name,
      date: testDate,
      exercises: [
        SelectedExercise(
          id: 'ex1',
          name: 'Bench Press',
          category: 'Chest',
          series: [Series(repetitions: 10, weight: 80.0)],
        ),
      ],
    );
  }

  CollectionReference trainingsRef() =>
      fakeFirestore.collection('users').doc(uid).collection('trainings');

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = TrainingService(db: fakeFirestore, getUid: () => uid);
    unauthService = TrainingService(db: fakeFirestore, getUid: () => null);
  });

  group('TrainingService', () {
    group('getTrainings', () {
      test('returns empty list when no user is logged in', () async {
        final result = await unauthService.getTrainings();
        expect(result, isEmpty);
      });

      test('returns trainings ordered by date descending', () async {
        await trainingsRef().add({
          'name': 'Session A',
          'date': Timestamp.fromDate(DateTime(2025, 1, 1)),
          'exercises': [],
          'weight': null,
        });
        await trainingsRef().add({
          'name': 'Session B',
          'date': Timestamp.fromDate(DateTime(2025, 2, 1)),
          'exercises': [],
          'weight': null,
        });

        final result = await service.getTrainings();
        expect(result.length, 2);
        expect(result[0].name, 'Session B');
        expect(result[1].name, 'Session A');
      });

      test('returns empty list when user has no trainings', () async {
        final result = await service.getTrainings();
        expect(result, isEmpty);
      });
    });

    group('saveTraining', () {
      test('creates new document when id is empty', () async {
        await service.saveTraining(makeTraining(id: ''));

        final snap = await trainingsRef().get();
        expect(snap.docs.length, 1);
        expect(snap.docs[0]['name'], 'Push Day');
      });

      test('updates existing document when id is not empty', () async {
        final ref = await trainingsRef().add({
          'name': 'Old Name',
          'exercises': [],
          'weight': null,
          'date': Timestamp.fromDate(testDate),
        });

        await service.saveTraining(makeTraining(id: ref.id, name: 'New Name'));

        final snap = await trainingsRef().get();
        expect(snap.docs.length, 1);
        expect(snap.docs[0]['name'], 'New Name');
      });

      test('throws when no user is logged in', () async {
        expect(
          () => unauthService.saveTraining(makeTraining()),
          throwsException,
        );
      });
    });

    group('deleteTraining', () {
      test('removes the training document', () async {
        final ref = await trainingsRef().add({
          'name': 'To Delete',
          'exercises': [],
          'weight': null,
          'date': Timestamp.fromDate(testDate),
        });

        await service.deleteTraining(makeTraining(id: ref.id));

        final snap = await trainingsRef().get();
        expect(snap.docs, isEmpty);
      });

      test('does nothing when no user is logged in', () async {
        await expectLater(
          unauthService.deleteTraining(makeTraining(id: 'any')),
          completes,
        );
      });
    });

    group('getLastSeriesForExercise', () {
      test('returns null when no user is logged in', () async {
        final result = await unauthService.getLastSeriesForExercise('ex1');
        expect(result, isNull);
      });

      test('returns series from most recent training containing the exercise',
          () async {
        await trainingsRef().add({
          'name': 'Session',
          'date': Timestamp.fromDate(testDate),
          'weight': null,
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

        final result = await service.getLastSeriesForExercise('ex1');
        expect(result, isNotNull);
        expect(result!.length, 1);
        expect(result[0].repetitions, 10);
        expect(result[0].weight, 80.0);
      });

      test('returns null when exercise is not found in any training', () async {
        await trainingsRef().add({
          'name': 'Session',
          'date': Timestamp.fromDate(testDate),
          'weight': null,
          'exercises': [],
        });

        final result = await service.getLastSeriesForExercise('nonexistent');
        expect(result, isNull);
      });
    });
  });
}
