import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stronger/infrastructure/services/firebase/exercises_service.dart';

void main() {
  const uid = 'user-1';
  late FakeFirebaseFirestore fakeFirestore;
  late ExerciseService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = ExerciseService(db: fakeFirestore, getUid: () => uid);
  });

  Future<DocumentReference<Map<String, dynamic>>> seedExercise(
    Map<String, dynamic> data,
  ) => fakeFirestore.collection('ejercicios2').add(data);

  Map<String, dynamic> globalExercise({
    required String name,
    required String category,
  }) => {
    'nombre': name,
    'categoria': category,
    'uid': null,
    'esPersonalizado': false,
  };

  Map<String, dynamic> personalExercise({
    required String name,
    required String category,
    String owner = uid,
  }) => {
    'nombre': name,
    'categoria': category,
    'uid': owner,
    'esPersonalizado': true,
  };

  group('ExerciseService', () {
    group('visible catalogue', () {
      test(
        'combines global exercises with the current user exercises',
        () async {
          await seedExercise(globalExercise(name: 'Squat', category: 'Legs'));
          await seedExercise(
            personalExercise(name: 'My Lunge', category: 'Legs'),
          );
          await seedExercise(
            personalExercise(
              name: 'Private Exercise',
              category: 'Secret',
              owner: 'user-2',
            ),
          );

          final exercises = await service.getAllExercises();

          expect(exercises.map((exercise) => exercise['nombre']), {
            'Squat',
            'My Lunge',
          });
        },
      );

      test('returns sorted unique visible categories', () async {
        await seedExercise(globalExercise(name: 'Squat', category: 'Legs'));
        await seedExercise(personalExercise(name: 'My Row', category: 'Back'));

        expect(await service.getUniqueCategories(), ['Back', 'Legs']);
      });

      test('filters visible exercises by category and includes ids', () async {
        await seedExercise(globalExercise(name: 'Squat', category: 'Legs'));
        await seedExercise(
          personalExercise(name: 'My Press', category: 'Chest'),
        );

        final result = await service.getByCategory('Legs');

        expect(result, hasLength(1));
        expect(result.single['nombre'], 'Squat');
        expect(result.single['id'], isNotEmpty);
      });

      test('returns no catalogue when the user is signed out', () async {
        final signedOutService = ExerciseService(
          db: fakeFirestore,
          getUid: () => null,
        );
        await seedExercise(globalExercise(name: 'Squat', category: 'Legs'));

        expect(await signedOutService.getAllExercises(), isEmpty);
      });
    });

    group('personal catalogue', () {
      test('returns only the current user categories and exercises', () async {
        await seedExercise(globalExercise(name: 'Squat', category: 'Legs'));
        await seedExercise(personalExercise(name: 'My Row', category: 'Back'));
        await seedExercise(
          personalExercise(
            name: 'Other Row',
            category: 'Other',
            owner: 'user-2',
          ),
        );

        expect(await service.getPersonalCategories(), ['Back']);
        final exercises = await service.getPersonalByCategory('Back');
        expect(exercises.map((exercise) => exercise['nombre']), ['My Row']);
      });
    });

    group('personal mutations', () {
      test('adds the owner uid and personal marker', () async {
        await service.addCustomExercise({
          'nombre': 'My Exercise',
          'categoria': 'Custom',
        });

        final snapshot = await fakeFirestore.collection('ejercicios2').get();
        expect(snapshot.docs.single['uid'], uid);
        expect(snapshot.docs.single['esPersonalizado'], true);
      });

      test('rejects writes when the user is signed out', () async {
        final signedOutService = ExerciseService(
          db: fakeFirestore,
          getUid: () => null,
        );

        expect(
          () => signedOutService.addCustomExercise({
            'nombre': 'My Exercise',
            'categoria': 'Custom',
          }),
          throwsStateError,
        );
      });

      test('updates only an exercise owned by the current user', () async {
        final reference = await seedExercise(
          personalExercise(name: 'My Squat', category: 'Legs'),
        );

        await service.updateExercise(reference.id, {
          'nombre': 'My Front Squat',
          'uid': 'attacker',
          'esPersonalizado': false,
        });

        final document = await reference.get();
        expect(document['nombre'], 'My Front Squat');
        expect(document['uid'], uid);
        expect(document['esPersonalizado'], true);
      });

      test('rejects updating a global or another user exercise', () async {
        final global = await seedExercise(
          globalExercise(name: 'Squat', category: 'Legs'),
        );
        final other = await seedExercise(
          personalExercise(name: 'Other', category: 'Other', owner: 'user-2'),
        );

        expect(
          () => service.updateExercise(global.id, {'nombre': 'Changed'}),
          throwsStateError,
        );
        expect(
          () => service.updateExercise(other.id, {'nombre': 'Changed'}),
          throwsStateError,
        );
      });

      test('deletes only an exercise owned by the current user', () async {
        final mine = await seedExercise(
          personalExercise(name: 'Mine', category: 'Custom'),
        );
        final other = await seedExercise(
          personalExercise(name: 'Other', category: 'Custom', owner: 'user-2'),
        );

        await service.deleteExercise(mine.id);

        expect((await mine.get()).exists, false);
        expect((await other.get()).exists, true);
        expect(() => service.deleteExercise(other.id), throwsStateError);
      });

      test('renames only the current user category', () async {
        final mine = await seedExercise(
          personalExercise(name: 'Mine', category: 'Legs'),
        );
        final other = await seedExercise(
          personalExercise(name: 'Other', category: 'Legs', owner: 'user-2'),
        );
        final global = await seedExercise(
          globalExercise(name: 'Squat', category: 'Legs'),
        );

        await service.renameCategory('Legs', 'Lower Body');

        expect((await mine.get())['categoria'], 'Lower Body');
        expect((await other.get())['categoria'], 'Legs');
        expect((await global.get())['categoria'], 'Legs');
      });

      test('deletes only the current user exercises in a category', () async {
        final mine = await seedExercise(
          personalExercise(name: 'Mine', category: 'Legs'),
        );
        final other = await seedExercise(
          personalExercise(name: 'Other', category: 'Legs', owner: 'user-2'),
        );
        final global = await seedExercise(
          globalExercise(name: 'Squat', category: 'Legs'),
        );

        await service.deleteCategory('Legs');

        expect((await mine.get()).exists, false);
        expect((await other.get()).exists, true);
        expect((await global.get()).exists, true);
      });
    });
  });
}
