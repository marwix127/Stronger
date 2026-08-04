import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stronger/UI/pages/exercise_management_by_category.dart';
import 'package:stronger/UI/pages/exercise_management_categories.dart';
import 'package:stronger/infrastructure/services/firebase/exercises_service.dart';

class MockManagementExerciseService extends Mock implements ExerciseService {}

void main() {
  late MockManagementExerciseService service;

  setUp(() {
    service = MockManagementExerciseService();
    when(
      () => service.getPersonalCategories(),
    ).thenAnswer((_) async => ['Personal']);
    when(() => service.getPersonalByCategory('Personal')).thenAnswer(
      (_) async => [
        {
          'id': 'custom-1',
          'nombre': 'Mi ejercicio',
          'descripcion': 'Descripción',
          'categoria': 'Personal',
        },
      ],
    );
  });

  testWidgets('lists only personal categories and renames one', (tester) async {
    when(
      () => service.renameCategory('Personal', 'Favoritos'),
    ).thenAnswer((_) async {});
    await tester.pumpWidget(
      MaterialApp(home: ExerciseManagementCategories(exerciseService: service)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Personal'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Favoritos');
    await tester.tap(find.widgetWithText(TextButton, 'Guardar'));
    await tester.pumpAndSettle();

    verify(() => service.renameCategory('Personal', 'Favoritos')).called(1);
  });

  testWidgets('confirms before deleting a personal category', (tester) async {
    when(() => service.deleteCategory('Personal')).thenAnswer((_) async {});
    await tester.pumpWidget(
      MaterialApp(home: ExerciseManagementCategories(exerciseService: service)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Eliminar'));
    await tester.pumpAndSettle();

    verify(() => service.deleteCategory('Personal')).called(1);
  });

  testWidgets('lists and deletes only a personal exercise', (tester) async {
    when(() => service.deleteExercise('custom-1')).thenAnswer((_) async {});
    await tester.pumpWidget(
      MaterialApp(
        home: ExerciseManagementByCategory(
          category: 'Personal',
          exerciseService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mi ejercicio'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Eliminar'));
    await tester.pumpAndSettle();

    verify(() => service.deleteExercise('custom-1')).called(1);
  });
}
