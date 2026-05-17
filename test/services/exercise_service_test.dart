import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stronger/infrastructure/services/firebase/exercises_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late ExerciseService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = ExerciseService(db: fakeFirestore);
  });

  Future<DocumentReference> seedExercise(Map<String, dynamic> data) =>
      fakeFirestore.collection('ejercicios2').add(data);

  group('ExerciseService', () {
    group('getUniqueCategories', () {
      test('returns sorted unique categories', () async {
        await seedExercise({'nombre': 'Squat', 'categoria': 'Legs'});
        await seedExercise({'nombre': 'Deadlift', 'categoria': 'Back'});
        await seedExercise({'nombre': 'Lunge', 'categoria': 'Legs'});

        final categories = await service.getUniqueCategories();
        expect(categories, ['Back', 'Legs']);
      });

      test('returns empty list when collection is empty', () async {
        final categories = await service.getUniqueCategories();
        expect(categories, isEmpty);
      });

      test('ignores documents without categoria field', () async {
        await seedExercise({'nombre': 'Exercise without category'});
        await seedExercise({'nombre': 'Squat', 'categoria': 'Legs'});

        final categories = await service.getUniqueCategories();
        expect(categories, ['Legs']);
      });
    });

    group('getByCategory', () {
      test('returns only exercises from the given category', () async {
        await seedExercise({'nombre': 'Squat', 'categoria': 'Legs'});
        await seedExercise({'nombre': 'Bench Press', 'categoria': 'Chest'});

        final result = await service.getByCategory('Legs');
        expect(result.length, 1);
        expect(result[0]['nombre'], 'Squat');
      });

      test('includes document id in result', () async {
        await seedExercise({'nombre': 'Squat', 'categoria': 'Legs'});

        final result = await service.getByCategory('Legs');
        expect(result[0].containsKey('id'), true);
        expect(result[0]['id'], isNotEmpty);
      });

      test('returns empty list when category has no exercises', () async {
        final result = await service.getByCategory('Unknown');
        expect(result, isEmpty);
      });
    });

    group('getAllExercises', () {
      test('returns all exercises with ids', () async {
        await seedExercise({'nombre': 'Squat', 'categoria': 'Legs'});
        await seedExercise({'nombre': 'Bench Press', 'categoria': 'Chest'});

        final result = await service.getAllExercises();
        expect(result.length, 2);
        expect(result.every((e) => e.containsKey('id')), true);
      });

      test('returns empty list when collection is empty', () async {
        final result = await service.getAllExercises();
        expect(result, isEmpty);
      });
    });

    group('addCustomExercise', () {
      test('adds exercise with esPersonalizado set to true', () async {
        await service.addCustomExercise({
          'nombre': 'My Exercise',
          'categoria': 'Custom',
        });

        final snap = await fakeFirestore.collection('ejercicios2').get();
        expect(snap.docs.length, 1);
        expect(snap.docs[0]['esPersonalizado'], true);
        expect(snap.docs[0]['nombre'], 'My Exercise');
      });
    });

    group('deleteExercise', () {
      test('removes the document with the given id', () async {
        final ref = await seedExercise({'nombre': 'Squat', 'categoria': 'Legs'});

        await service.deleteExercise(ref.id);

        final snap = await fakeFirestore.collection('ejercicios2').get();
        expect(snap.docs, isEmpty);
      });
    });

    group('updateExercise', () {
      test('updates fields of the given document', () async {
        final ref = await seedExercise({'nombre': 'Squat', 'categoria': 'Legs'});

        await service.updateExercise(ref.id, {'nombre': 'Front Squat'});

        final doc = await fakeFirestore.collection('ejercicios2').doc(ref.id).get();
        expect(doc['nombre'], 'Front Squat');
        expect(doc['categoria'], 'Legs');
      });
    });

    group('renameCategory', () {
      test('updates categoria field on all matching documents', () async {
        await seedExercise({'nombre': 'Squat', 'categoria': 'Legs'});
        await seedExercise({'nombre': 'Lunge', 'categoria': 'Legs'});
        await seedExercise({'nombre': 'Bench Press', 'categoria': 'Chest'});

        await service.renameCategory('Legs', 'Lower Body');

        final legsSnap = await fakeFirestore
            .collection('ejercicios2')
            .where('categoria', isEqualTo: 'Legs')
            .get();
        final newSnap = await fakeFirestore
            .collection('ejercicios2')
            .where('categoria', isEqualTo: 'Lower Body')
            .get();

        expect(legsSnap.docs, isEmpty);
        expect(newSnap.docs.length, 2);
      });

      test('does not affect other categories', () async {
        await seedExercise({'nombre': 'Bench Press', 'categoria': 'Chest'});

        await service.renameCategory('Legs', 'Lower Body');

        final chestSnap = await fakeFirestore
            .collection('ejercicios2')
            .where('categoria', isEqualTo: 'Chest')
            .get();
        expect(chestSnap.docs.length, 1);
      });
    });

    group('deleteCategory', () {
      test('deletes all exercises in the category', () async {
        await seedExercise({'nombre': 'Squat', 'categoria': 'Legs'});
        await seedExercise({'nombre': 'Lunge', 'categoria': 'Legs'});
        await seedExercise({'nombre': 'Bench Press', 'categoria': 'Chest'});

        await service.deleteCategory('Legs');

        final snap = await fakeFirestore.collection('ejercicios2').get();
        expect(snap.docs.length, 1);
        expect(snap.docs[0]['categoria'], 'Chest');
      });
    });
  });
}
