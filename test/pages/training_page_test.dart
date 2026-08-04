import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stronger/UI/pages/training_page.dart';
import 'package:stronger/infrastructure/services/firebase/training_service.dart';
import 'package:stronger/infrastructure/services/muscle_fatigue_service.dart';
import 'package:stronger/infrastructure/services/training_draft_store.dart';
import 'package:stronger/models/selected_exercise.dart';
import 'package:stronger/models/serie.dart';
import 'package:stronger/models/training.dart';

class MockTrainingService extends Mock implements TrainingService {}

class MockFatigueService extends Mock implements MuscleFatigueService {}

class MockDraftStore extends Mock implements TrainingDraftStore {}

class FakeTraining extends Fake implements Training {}

void main() {
  const uid = 'user-1';
  late MockTrainingService trainingService;
  late MockFatigueService fatigueService;
  late MockDraftStore draftStore;

  setUpAll(() {
    registerFallbackValue(FakeTraining());
  });

  setUp(() {
    trainingService = MockTrainingService();
    fatigueService = MockFatigueService();
    draftStore = MockDraftStore();
    when(
      () => trainingService.getLastSeriesForExercise(any()),
    ).thenAnswer((_) async => null);
    when(() => draftStore.clear()).thenAnswer((_) async {});
    when(() => draftStore.save(any(), any())).thenAnswer((_) async {});
    when(
      () => fatigueService.analyzeAndUpdate(any(), any()),
    ).thenAnswer((_) async {});
  });

  SelectedExercise squat() => SelectedExercise(
    id: 'squat',
    name: 'Sentadilla',
    category: 'Piernas',
    series: [Series(repetitions: 8, weight: 100)],
  );

  Future<GoRouter> pumpPage(
    WidgetTester tester, {
    Training? training,
    TrainingDraft? draft,
    bool loadDraft = false,
  }) async {
    when(() => draftStore.load()).thenAnswer((_) async => draft);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Historial')),
        ),
        GoRoute(
          path: '/training',
          builder: (_, _) => TrainingPage(
            training: training,
            loadDraft: loadDraft,
            trainingService: trainingService,
            fatigueService: fatigueService,
            draftStore: draftStore,
            getUid: () => uid,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.push('/training');
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('validates name and exercises before saving', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
    await tester.pump();

    expect(
      find.text('Añade un nombre y al menos un ejercicio.'),
      findsOneWidget,
    );
    verifyNever(() => trainingService.saveTraining(any()));
  });

  testWidgets('loads a requested draft', (tester) async {
    await pumpPage(
      tester,
      loadDraft: true,
      draft: TrainingDraft(name: 'Día de pierna', exercises: [squat()]),
    );

    expect(find.text('Sentadilla'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller?.text,
      'Día de pierna',
    );
    verify(() => draftStore.load()).called(1);
  });

  testWidgets('saves a new training, clears its draft and starts fatigue', (
    tester,
  ) async {
    when(() => trainingService.saveTraining(any())).thenAnswer((_) async {});
    await pumpPage(
      tester,
      loadDraft: true,
      draft: TrainingDraft(name: 'Día de pierna', exercises: [squat()]),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
    await tester.pumpAndSettle();

    final captured =
        verify(() => trainingService.saveTraining(captureAny())).captured.single
            as Training;
    expect(captured.id, isEmpty);
    expect(captured.name, 'Día de pierna');
    expect(captured.exercises.single.name, 'Sentadilla');
    verify(() => draftStore.clear()).called(1);
    verify(() => fatigueService.analyzeAndUpdate(any(), uid)).called(1);
    expect(find.text('Historial'), findsOneWidget);
  });

  testWidgets('prevents duplicate saves while the first save is pending', (
    tester,
  ) async {
    final completer = Completer<void>();
    when(
      () => trainingService.saveTraining(any()),
    ).thenAnswer((_) => completer.future);
    await pumpPage(
      tester,
      loadDraft: true,
      draft: TrainingDraft(name: 'Día de pierna', exercises: [squat()]),
    );

    final saveButton = find.widgetWithText(ElevatedButton, 'Guardar');
    await tester.tap(saveButton);
    await tester.pump();
    await tester.tap(saveButton);
    await tester.pump();

    verify(() => trainingService.saveTraining(any())).called(1);
    completer.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('editing preserves id/date and does not recalculate fatigue', (
    tester,
  ) async {
    final originalDate = DateTime(2025, 12, 1);
    final original = Training(
      id: 'training-1',
      name: 'Nombre anterior',
      weight: null,
      date: originalDate,
      exercises: [squat()],
    );
    when(() => trainingService.saveTraining(any())).thenAnswer((_) async {});
    await pumpPage(tester, training: original);

    await tester.enterText(find.byType(TextField).first, 'Nombre actualizado');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
    await tester.pumpAndSettle();

    final captured =
        verify(() => trainingService.saveTraining(captureAny())).captured.single
            as Training;
    expect(captured.id, 'training-1');
    expect(captured.date, originalDate);
    expect(captured.name, 'Nombre actualizado');
    verifyNever(() => fatigueService.analyzeAndUpdate(any(), any()));
  });

  testWidgets('removes the selected series instead of the last visible row', (
    tester,
  ) async {
    final original = Training(
      id: 'training-1',
      name: 'Tres series',
      weight: null,
      date: DateTime(2025, 12, 1),
      exercises: [
        SelectedExercise(
          id: 'squat',
          name: 'Sentadilla',
          category: 'Piernas',
          series: [
            Series(repetitions: 1, weight: 10),
            Series(repetitions: 2, weight: 20),
            Series(repetitions: 3, weight: 30),
          ],
        ),
      ],
    );
    await pumpPage(tester, training: original);

    await tester.tap(find.byIcon(Icons.remove_circle).at(1));
    await tester.pump();

    final visibleValues = tester
        .widgetList<EditableText>(find.byType(EditableText))
        .map((field) => field.controller.text)
        .toList();
    expect(visibleValues, ['Tres series', '10.0', '1', '30.0', '3']);
  });

  testWidgets('offers to save unsaved new work as a draft', (tester) async {
    await pumpPage(tester);
    await tester.enterText(find.byType(TextField).first, 'Trabajo pendiente');

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Guardar como draft'), findsOneWidget);

    await tester.tap(find.text('Guardar como draft'));
    await tester.pumpAndSettle();

    verify(() => draftStore.save('Trabajo pendiente', any())).called(1);
    expect(find.text('Historial'), findsOneWidget);
  });

  testWidgets('confirms and deletes an existing training', (tester) async {
    final original = Training(
      id: 'training-1',
      name: 'Entrenamiento',
      weight: null,
      date: DateTime(2025, 12, 1),
      exercises: [squat()],
    );
    when(
      () => trainingService.deleteTraining(original),
    ).thenAnswer((_) async {});
    await pumpPage(tester, training: original);

    await tester.tap(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.delete),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Eliminar'));
    await tester.pumpAndSettle();

    verify(() => trainingService.deleteTraining(original)).called(1);
    expect(find.text('Historial'), findsOneWidget);
  });
}
