import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:stronger/models/selected_exercise.dart';

class TrainingDraft {
  final String name;
  final List<SelectedExercise> exercises;

  const TrainingDraft({required this.name, required this.exercises});
}

abstract interface class TrainingDraftStore {
  Future<bool> exists();
  Future<TrainingDraft?> load();
  Future<void> save(String name, List<SelectedExercise> exercises);
  Future<void> clear();
}

class SharedPreferencesTrainingDraftStore implements TrainingDraftStore {
  static const key = 'training_draft';

  @override
  Future<bool> exists() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.containsKey(key);
  }

  @override
  Future<TrainingDraft?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(key);
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final rawExercises = decoded['exercises'];
      if (rawExercises is! List) return null;

      return TrainingDraft(
        name: decoded['name'] is String ? decoded['name'] as String : '',
        exercises: rawExercises
            .whereType<Map>()
            .map(
              (exercise) =>
                  SelectedExercise.fromMap(Map<String, dynamic>.from(exercise)),
            )
            .toList(),
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  @override
  Future<void> save(String name, List<SelectedExercise> exercises) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      key,
      jsonEncode({
        'name': name,
        'exercises': exercises.map((exercise) => exercise.toMap()).toList(),
      }),
    );
  }

  @override
  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(key);
  }
}
