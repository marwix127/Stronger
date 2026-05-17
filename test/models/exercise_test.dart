import 'package:flutter_test/flutter_test.dart';
import 'package:stronger/models/exercise.dart';

void main() {
  group('Exercise', () {
    group('fromFirestore', () {
      test('maps Firestore field names to model properties', () {
        final exercise = Exercise.fromFirestore('id1', {
          'nombre': 'Bench Press',
          'categoria': 'Chest',
          'descripcion': 'Flat bench press',
          'tipo': 'compound',
          'nivel': 'intermediate',
          'uid': null,
          'esPersonalizado': false,
        });

        expect(exercise.id, 'id1');
        expect(exercise.name, 'Bench Press');
        expect(exercise.category, 'Chest');
        expect(exercise.description, 'Flat bench press');
        expect(exercise.type, 'compound');
        expect(exercise.level, 'intermediate');
        expect(exercise.uid, isNull);
        expect(exercise.isCustom, false);
      });

      test('handles missing optional fields as null', () {
        final exercise = Exercise.fromFirestore('id2', {
          'nombre': 'Push-up',
          'categoria': 'Chest',
        });

        expect(exercise.description, isNull);
        expect(exercise.type, isNull);
        expect(exercise.level, isNull);
        expect(exercise.isCustom, false);
      });

      test('marks custom exercises correctly', () {
        final exercise = Exercise.fromFirestore('id3', {
          'nombre': 'My Exercise',
          'categoria': 'Custom',
          'esPersonalizado': true,
          'uid': 'user123',
        });

        expect(exercise.isCustom, true);
        expect(exercise.uid, 'user123');
      });
    });

    group('toMap', () {
      test('uses Firestore field names', () {
        final exercise = Exercise(
          id: 'id1',
          name: 'Squat',
          category: 'Legs',
          description: 'Barbell squat',
          type: 'compound',
          level: 'advanced',
          isCustom: false,
        );
        final map = exercise.toMap();

        expect(map['nombre'], 'Squat');
        expect(map['categoria'], 'Legs');
        expect(map['descripcion'], 'Barbell squat');
        expect(map['tipo'], 'compound');
        expect(map['nivel'], 'advanced');
        expect(map['esPersonalizado'], false);
      });
    });

    test('round-trip fromFirestore → toMap preserves values', () {
      final data = {
        'nombre': 'Deadlift',
        'categoria': 'Back',
        'descripcion': 'Romanian deadlift',
        'tipo': 'compound',
        'nivel': 'advanced',
        'uid': null,
        'esPersonalizado': false,
      };
      final map = Exercise.fromFirestore('id1', data).toMap();

      expect(map['nombre'], data['nombre']);
      expect(map['categoria'], data['categoria']);
      expect(map['descripcion'], data['descripcion']);
    });
  });
}
