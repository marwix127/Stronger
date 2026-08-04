import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stronger/UI/pages/training_page.dart';
import 'package:stronger/UI/pages/trainings_history_page.dart';
import 'package:stronger/infrastructure/services/firebase/training_service.dart';
import 'package:stronger/infrastructure/services/muscle_fatigue_service.dart';
import 'package:stronger/infrastructure/services/training_draft_store.dart';
import 'package:stronger/models/selected_exercise.dart';
import 'package:stronger/models/serie.dart';
import 'package:stronger/models/training.dart';

class MockFlowTrainingService extends Mock implements TrainingService {}

class MockFlowFatigueService extends Mock implements MuscleFatigueService {}

class MockFlowDraftStore extends Mock implements TrainingDraftStore {}

class FakeFlowTraining extends Fake implements Training {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeFlowTraining());
  });

  testWidgets('continues a draft, saves it and refreshes history', (
    tester,
  ) async {
    final trainingService = MockFlowTrainingService();
    final fatigueService = MockFlowFatigueService();
    final draftStore = MockFlowDraftStore();
    Training? savedTraining;

    when(() => draftStore.exists()).thenAnswer((_) async => true);
    when(() => draftStore.load()).thenAnswer(
      (_) async => TrainingDraft(
        name: 'Entrenamiento desde borrador',
        exercises: [
          SelectedExercise(
            id: 'squat',
            name: 'Sentadilla',
            category: 'Piernas',
            series: [Series(repetitions: 8, weight: 100)],
          ),
        ],
      ),
    );
    when(() => draftStore.clear()).thenAnswer((_) async {});
    when(
      () => trainingService.getTrainings(),
    ).thenAnswer((_) async => savedTraining == null ? [] : [savedTraining!]);
    when(
      () => trainingService.getLastSeriesForExercise(any()),
    ).thenAnswer((_) async => null);
    when(() => trainingService.saveTraining(any())).thenAnswer((
      invocation,
    ) async {
      savedTraining = invocation.positionalArguments.single as Training;
    });
    when(
      () => fatigueService.analyzeAndUpdate(any(), any()),
    ).thenAnswer((_) async {});

    late final GoRouter router;
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => TrainingHistoryPage(
            trainingService: trainingService,
            draftStore: draftStore,
          ),
        ),
        GoRoute(
          path: '/training',
          builder: (_, state) => TrainingPage(
            loadDraft: state.uri.queryParameters['loadDraft'] == 'true',
            trainingService: trainingService,
            fatigueService: fatigueService,
            draftStore: draftStore,
            getUid: () => 'user-1',
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Continuar borrador'));
    await tester.pumpAndSettle();
    expect(find.text('Sentadilla'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Entrenamiento desde borrador'), findsOneWidget);
    verify(() => trainingService.saveTraining(any())).called(1);
    verify(() => draftStore.clear()).called(1);
  });
}
