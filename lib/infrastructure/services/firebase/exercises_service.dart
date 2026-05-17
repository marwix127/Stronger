import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class ExerciseService {
  final FirebaseFirestore _db;

  ExerciseService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  Future<void> loadInitialExercisesIfNeeded() async {
    final snap = await _db.collection('ejercicios2').get();

    if (snap.docs.isEmpty) {
      final jsonString = await rootBundle.loadString('assets/ejercicios2.json');
      final List<dynamic> exercises = jsonDecode(jsonString);

      for (final exercise in exercises) {
        await _db.collection('ejercicios2').add({
          ...exercise,
          'esPersonalizado': false,
          'uid': null,
        });
      }
    }
  }

  Future<List<String>> getUniqueCategories() async {
    final snapshot = await _db.collection('ejercicios2').get();
    final categories = snapshot.docs
        .map((doc) => doc.data()['categoria'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  Future<List<Map<String, dynamic>>> getByCategory(String category) async {
    final snapshot = await _db
        .collection('ejercicios2')
        .where('categoria', isEqualTo: category)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {'id': doc.id, ...data};
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getAllExercises() async {
    final snapshot = await _db.collection('ejercicios2').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {'id': doc.id, ...data};
    }).toList();
  }

  Future<void> addCustomExercise(Map<String, dynamic> exercise) async {
    await _db.collection('ejercicios2').add({
      ...exercise,
      'esPersonalizado': true,
    });
  }

  Future<void> deleteExercise(String id) async {
    await _db.collection('ejercicios2').doc(id).delete();
  }

  Future<void> updateExercise(String id, Map<String, dynamic> exercise) async {
    await _db.collection('ejercicios2').doc(id).update(exercise);
  }

  Future<void> renameCategory(String oldCategory, String newCategory) async {
    final snapshot = await _db
        .collection('ejercicios2')
        .where('categoria', isEqualTo: oldCategory)
        .get();

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'categoria': newCategory});
    }
    await batch.commit();
  }

  Future<void> deleteCategory(String category) async {
    final snapshot = await _db
        .collection('ejercicios2')
        .where('categoria', isEqualTo: category)
        .get();

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
