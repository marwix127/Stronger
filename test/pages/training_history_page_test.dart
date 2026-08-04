import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stronger/UI/pages/trainings_history_page.dart';
import 'package:stronger/infrastructure/services/firebase/training_service.dart';
import 'package:stronger/infrastructure/services/training_draft_store.dart';
import 'package:stronger/models/training.dart';

class MockHistoryTrainingService extends Mock implements TrainingService {}

class MockHistoryDraftStore extends Mock implements TrainingDraftStore {}

void main() {
  late MockHistoryTrainingService trainingService;
  late MockHistoryDraftStore draftStore;

  setUp(() {
    trainingService = MockHistoryTrainingService();
    draftStore = MockHistoryDraftStore();
    when(() => draftStore.exists()).thenAnswer((_) async => false);
  });

  Future<void> pumpPage(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: TrainingHistoryPage(
        trainingService: trainingService,
        draftStore: draftStore,
      ),
    ),
  );

  testWidgets('shows an empty state and the new training action', (
    tester,
  ) async {
    when(() => trainingService.getTrainings()).thenAnswer((_) async => []);

    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.text('No hay entrenamientos registrados.'), findsOneWidget);
    expect(find.byTooltip('Nuevo entrenamiento'), findsOneWidget);
  });

  testWidgets('shows stored trainings with formatted dates', (tester) async {
    when(() => trainingService.getTrainings()).thenAnswer(
      (_) async => [
        Training(
          id: 'training-1',
          name: 'Pierna',
          weight: null,
          date: DateTime(2026, 2, 3),
          exercises: [],
        ),
      ],
    );

    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.text('Pierna'), findsOneWidget);
    expect(find.text('Fecha: 03/02/2026'), findsOneWidget);
  });

  testWidgets('offers to continue when a draft exists', (tester) async {
    when(() => trainingService.getTrainings()).thenAnswer((_) async => []);
    when(() => draftStore.exists()).thenAnswer((_) async => true);

    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Continuar borrador'), findsOneWidget);
  });

  testWidgets('shows an actionable error instead of an endless spinner', (
    tester,
  ) async {
    when(
      () => trainingService.getTrainings(),
    ).thenAnswer((_) => Future.error(Exception('offline')));

    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('No se han podido cargar los entrenamientos.'),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
