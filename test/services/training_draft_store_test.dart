import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stronger/infrastructure/services/training_draft_store.dart';
import 'package:stronger/models/selected_exercise.dart';
import 'package:stronger/models/serie.dart';

void main() {
  late SharedPreferencesTrainingDraftStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = SharedPreferencesTrainingDraftStore();
  });

  test('saves and restores a complete draft', () async {
    await store.save('Pierna', [
      SelectedExercise(
        id: 'squat',
        name: 'Sentadilla',
        category: 'Piernas',
        series: [Series(repetitions: 8, weight: 100)],
      ),
    ]);

    expect(await store.exists(), true);
    final draft = await store.load();
    expect(draft?.name, 'Pierna');
    expect(draft?.exercises.single.id, 'squat');
    expect(draft?.exercises.single.series.single.repetitions, 8);
    expect(draft?.exercises.single.series.single.weight, 100);
  });

  test('returns null for malformed or structurally invalid JSON', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesTrainingDraftStore.key: 'not-json',
    });
    expect(await store.load(), isNull);

    SharedPreferences.setMockInitialValues({
      SharedPreferencesTrainingDraftStore.key: '{"name":"Incomplete"}',
    });
    expect(await store.load(), isNull);
  });

  test('clears the stored draft', () async {
    await store.save('Draft', []);

    await store.clear();

    expect(await store.exists(), false);
    expect(await store.load(), isNull);
  });
}
