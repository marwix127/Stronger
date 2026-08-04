import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stronger/UI/pages/grafics_page.dart';
import 'package:stronger/infrastructure/services/firebase/training_service.dart';
import 'package:stronger/models/selected_exercise.dart';
import 'package:stronger/models/serie.dart';
import 'package:stronger/models/training.dart';

class MockGraphicsTrainingService extends Mock implements TrainingService {}

void main() {
  late MockGraphicsTrainingService trainingService;

  setUp(() {
    trainingService = MockGraphicsTrainingService();
  });

  Future<void> pumpPage(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(home: GraficsPage(trainingService: trainingService)),
  );

  Training sampleTraining() => Training(
    id: 'training-1',
    name: 'Pecho',
    weight: null,
    date: DateTime(2026, 1, 1),
    exercises: [
      SelectedExercise(
        id: 'bench',
        name: 'Press banca',
        category: 'Pecho',
        series: [Series(repetitions: 10, weight: 80)],
      ),
    ],
  );

  testWidgets('selects an exercise and switches between chart types', (
    tester,
  ) async {
    when(
      () => trainingService.getTrainings(),
    ).thenAnswer((_) async => [sampleTraining()]);
    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.text('No hay datos para este ejercicio'), findsOneWidget);
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Press banca').last);
    await tester.pumpAndSettle();
    expect(find.byType(LineChart), findsOneWidget);

    await tester.tap(find.text('Peso Medio'));
    await tester.pumpAndSettle();
    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('shows a retry state on loading failure', (tester) async {
    when(
      () => trainingService.getTrainings(),
    ).thenAnswer((_) => Future.error(Exception('offline')));

    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.text('No se han podido cargar los gráficos.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
