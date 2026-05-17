import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stronger/infrastructure/services/firebase/auth_service.dart';
import 'package:stronger/infrastructure/services/firebase/corporal_service.dart';

class MockAuthService extends Mock implements AuthService {}
class MockUser extends Mock implements User {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockAuthService mockAuthService;
  late MockUser mockUser;
  late BodyMeasurementService service;

  const uid = 'user123';

  final measurementData = {
    'weight': 78.5,
    'height': 178.0,
    'fat_percentage': 18.0,
    'muscle_mass': 35.0,
  };

  CollectionReference measurementsRef() => fakeFirestore
      .collection('users')
      .doc(uid)
      .collection('body_measurements');

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuthService = MockAuthService();
    mockUser = MockUser();

    when(() => mockUser.uid).thenReturn(uid);
    when(() => mockAuthService.currentUser).thenReturn(mockUser);

    service = BodyMeasurementService(
      firestore: fakeFirestore,
      authService: mockAuthService,
    );
  });

  group('BodyMeasurementService', () {
    group('addMeasurement', () {
      test('saves measurement under the current user', () async {
        await service.addMeasurement(measurementData);

        final snap = await measurementsRef().get();
        expect(snap.docs.length, 1);
        expect(snap.docs[0]['weight'], 78.5);
        expect(snap.docs[0]['fat_percentage'], 18.0);
      });

      test('throws when no user is logged in', () async {
        when(() => mockAuthService.currentUser).thenReturn(null);

        expect(() => service.addMeasurement(measurementData), throwsException);
      });
    });

    group('getMeasurements', () {
      test('returns a stream of measurements ordered by date descending', () async {
        await measurementsRef().add({
          ...measurementData,
          'date': Timestamp.fromDate(DateTime(2025, 1, 1)),
        });
        await measurementsRef().add({
          ...measurementData,
          'date': Timestamp.fromDate(DateTime(2025, 3, 1)),
        });

        final snap = await service.getMeasurements().first;
        expect(snap.docs.length, 2);
      });

      test('returns empty stream when no user is logged in', () async {
        when(() => mockAuthService.currentUser).thenReturn(null);

        final snap = await service.getMeasurements().isEmpty;
        expect(snap, true);
      });
    });

    group('getLastMeasurement', () {
      test('returns the most recent measurement', () async {
        await measurementsRef().add({
          'weight': 77.0,
          'date': Timestamp.fromDate(DateTime(2025, 1, 1)),
        });
        await measurementsRef().add({
          'weight': 78.5,
          'date': Timestamp.fromDate(DateTime(2025, 3, 1)),
        });

        final result = await service.getLastMeasurement();
        expect(result, isNotNull);
        expect(result!['weight'], 78.5);
      });

      test('returns null when no measurements exist', () async {
        final result = await service.getLastMeasurement();
        expect(result, isNull);
      });

      test('returns null when no user is logged in', () async {
        when(() => mockAuthService.currentUser).thenReturn(null);

        final result = await service.getLastMeasurement();
        expect(result, isNull);
      });
    });

    group('updateMeasurement', () {
      test('updates the specified measurement', () async {
        final ref = await measurementsRef().add({'weight': 77.0});

        await service.updateMeasurement(ref.id, {'weight': 80.0});

        final doc = await measurementsRef().doc(ref.id).get();
        expect(doc['weight'], 80.0);
      });

      test('throws when no user is logged in', () async {
        when(() => mockAuthService.currentUser).thenReturn(null);

        expect(
          () => service.updateMeasurement('any', {'weight': 80.0}),
          throwsException,
        );
      });
    });

    group('deleteMeasurement', () {
      test('removes the specified measurement', () async {
        final ref = await measurementsRef().add({'weight': 77.0});

        await service.deleteMeasurement(ref.id);

        final snap = await measurementsRef().get();
        expect(snap.docs, isEmpty);
      });

      test('throws when no user is logged in', () async {
        when(() => mockAuthService.currentUser).thenReturn(null);

        expect(
          () => service.deleteMeasurement('any'),
          throwsException,
        );
      });
    });
  });
}
