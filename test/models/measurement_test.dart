import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stronger/models/measurement.dart';

void main() {
  final testDate = DateTime(2025, 3, 10);

  group('Measurement', () {
    group('fromMap', () {
      test('parses new field names (fat_percentage, muscle_mass)', () {
        final m = Measurement.fromMap({
          'date': Timestamp.fromDate(testDate),
          'weight': 78.5,
          'fat_percentage': 18.0,
          'muscle_mass': 35.0,
        });

        expect(m.date, testDate);
        expect(m.weight, 78.5);
        expect(m.fat, 18.0);
        expect(m.muscle, 35.0);
      });

      test('parses legacy field names (currentWeight, currentBodyFat, currentMuscle)', () {
        final m = Measurement.fromMap({
          'date': Timestamp.fromDate(testDate),
          'currentWeight': 80.0,
          'currentBodyFat': 20.0,
          'currentMuscle': 38.0,
        });

        expect(m.weight, 80.0);
        expect(m.fat, 20.0);
        expect(m.muscle, 38.0);
      });

      test('legacy fields take priority over new fields', () {
        final m = Measurement.fromMap({
          'date': Timestamp.fromDate(testDate),
          'currentWeight': 80.0,
          'weight': 78.0,
        });

        expect(m.weight, 80.0);
      });

      test('defaults to 0 when fields are missing', () {
        final m = Measurement.fromMap({
          'date': Timestamp.fromDate(testDate),
        });

        expect(m.weight, 0.0);
        expect(m.fat, 0.0);
        expect(m.muscle, 0.0);
      });

      test('defaults date to now when null', () {
        final before = DateTime.now();
        final m = Measurement.fromMap({'date': null});
        final after = DateTime.now();

        expect(m.date.isAfter(before) || m.date.isAtSameMomentAs(before), true);
        expect(m.date.isBefore(after) || m.date.isAtSameMomentAs(after), true);
      });
    });

    group('toMap', () {
      test('serializes all fields correctly', () {
        final m = Measurement(
          date: testDate,
          weight: 78.5,
          fat: 18.0,
          muscle: 35.0,
        );
        final map = m.toMap();

        expect(map['currentWeight'], 78.5);
        expect(map['currentBodyFat'], 18.0);
        expect(map['currentMuscle'], 35.0);
      });
    });
  });
}
