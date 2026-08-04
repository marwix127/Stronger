import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stronger/UI/pages/body_page.dart';
import 'package:stronger/infrastructure/services/firebase/auth_service.dart';
import 'package:stronger/infrastructure/services/firebase/corporal_service.dart';
import 'package:stronger/infrastructure/services/muscle_fatigue_service.dart';

class MockBodyAuthService extends Mock implements AuthService {}

class MockBodyUser extends Mock implements User {}

class MockBodyFatigueService extends Mock implements MuscleFatigueService {}

void main() {
  const uid = 'user-1';
  late FakeFirebaseFirestore firestore;
  late BodyMeasurementService measurementService;
  late MockBodyFatigueService fatigueService;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    final authService = MockBodyAuthService();
    final user = MockBodyUser();
    when(() => authService.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn(uid);
    measurementService = BodyMeasurementService(
      firestore: firestore,
      authService: authService,
    );
    fatigueService = MockBodyFatigueService();
    when(
      () => fatigueService.loadCurrentScores(uid),
    ).thenAnswer((_) async => {});
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BodyPage(
          measurementService: measurementService,
          fatigueService: fatigueService,
          getUid: () => uid,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  testWidgets('validates required and malformed measurements', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pump();
    expect(find.text('Requerido'), findsOneWidget);

    await tester.enterText(field('Peso (kg)'), 'abc');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pump();
    expect(find.text('Número no válido'), findsOneWidget);
  });

  testWidgets('accepts decimal commas and stores a body measurement', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.enterText(field('Peso (kg)'), '80,5');
    await tester.enterText(field('Altura (cm)'), '180');
    await tester.enterText(field('% Grasa'), '20');
    await tester.enterText(field('Músculo (kg)'), '60');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    final snapshot = await firestore
        .collection('users')
        .doc(uid)
        .collection('body_measurements')
        .get();
    expect(snapshot.docs, hasLength(1));
    expect(snapshot.docs.single['weight'], 80.5);
    expect(snapshot.docs.single['height'], 180);
    expect(snapshot.docs.single['fat_percentage'], 20);
    expect(snapshot.docs.single['muscle_mass'], 60);
    expect(find.text('Medición guardada correctamente'), findsOneWidget);
  });
}
