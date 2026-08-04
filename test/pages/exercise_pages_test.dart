import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stronger/UI/pages/add_exercise_page.dart';
import 'package:stronger/UI/pages/exercises_by_categories.dart';
import 'package:stronger/UI/pages/exercises_categories.dart';
import 'package:stronger/infrastructure/services/firebase/exercises_service.dart';

class MockExerciseService extends Mock implements ExerciseService {}

void main() {
  late MockExerciseService service;

  setUp(() {
    service = MockExerciseService();
    when(
      () => service.getUniqueCategories(),
    ).thenAnswer((_) async => ['Pecho']);
  });

  Future<GoRouter> pumpAddPage(
    WidgetTester tester, {
    Map<String, dynamic>? exercise,
  }) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/add',
          builder: (_, _) =>
              AddExercisePage(exercise: exercise, exerciseService: service),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.push('/add');
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('requires both name and category', (tester) async {
    await pumpAddPage(tester);
    await tester.enterText(find.byType(TextField).at(0), 'Ejercicio');

    await tester.tap(find.text('Guardar ejercicio'));
    await tester.pump();

    expect(find.text('Completa los campos obligatorios'), findsOneWidget);
    verifyNever(() => service.addCustomExercise(any()));
  });

  testWidgets('creates a personal exercise with a default description', (
    tester,
  ) async {
    when(() => service.addCustomExercise(any())).thenAnswer((_) async {});
    await pumpAddPage(tester);
    await tester.enterText(find.byType(TextField).at(0), 'Press personal');
    await tester.enterText(find.byType(TextField).at(2), 'Pecho');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    await tester.ensureVisible(find.text('Guardar ejercicio'));
    await tester.tap(find.text('Guardar ejercicio'));
    await tester.pumpAndSettle();

    final data =
        verify(() => service.addCustomExercise(captureAny())).captured.single
            as Map<String, dynamic>;
    expect(data, {
      'nombre': 'Press personal',
      'descripcion': 'Sin descripción',
      'categoria': 'Pecho',
    });
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('prefills and updates an existing personal exercise', (
    tester,
  ) async {
    when(() => service.updateExercise(any(), any())).thenAnswer((_) async {});
    await pumpAddPage(
      tester,
      exercise: {
        'id': 'custom-1',
        'nombre': 'Press',
        'descripcion': 'Descripción',
        'categoria': 'Pecho',
      },
    );

    expect(find.text('Pecho'), findsWidgets);
    await tester.enterText(find.byType(TextField).at(0), 'Press actualizado');
    await tester.tap(find.text('Actualizar ejercicio'));
    await tester.pumpAndSettle();

    verify(
      () => service.updateExercise(
        'custom-1',
        any(that: containsPair('nombre', 'Press actualizado')),
      ),
    ).called(1);
  });

  testWidgets('shows a friendly message when saving fails', (tester) async {
    when(
      () => service.addCustomExercise(any()),
    ).thenAnswer((_) => Future.error(Exception('denied')));
    await pumpAddPage(tester);
    await tester.enterText(find.byType(TextField).at(0), 'Press personal');
    await tester.enterText(find.byType(TextField).at(2), 'Pecho');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    await tester.ensureVisible(find.text('Guardar ejercicio'));
    await tester.tap(find.text('Guardar ejercicio'));
    await tester.pumpAndSettle();

    expect(find.text('No se ha podido guardar el ejercicio'), findsOneWidget);
    expect(find.text('Añadir ejercicio'), findsOneWidget);
  });

  testWidgets('category selection loads exercises through the same service', (
    tester,
  ) async {
    when(() => service.getByCategory('Pecho')).thenAnswer(
      (_) async => [
        {
          'id': 'bench',
          'nombre': 'Press banca',
          'descripcion': 'Barra',
          'categoria': 'Pecho',
        },
      ],
    );
    await tester.pumpWidget(
      MaterialApp(home: ExercisesCategories(exerciseService: service)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pecho'));
    await tester.pumpAndSettle();

    expect(find.text('Press banca'), findsOneWidget);
    verify(() => service.getByCategory('Pecho')).called(1);
  });

  testWidgets('exercise list shows a stable error state', (tester) async {
    when(
      () => service.getByCategory('Pecho'),
    ).thenAnswer((_) => Future.error(Exception('offline')));

    await tester.pumpWidget(
      MaterialApp(
        home: ExercisesByCategories(
          category: 'Pecho',
          exerciseService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No se han podido cargar los ejercicios'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
