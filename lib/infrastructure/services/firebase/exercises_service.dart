import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExerciseService {
  final FirebaseFirestore _db;
  final String? Function() _getUid;

  ExerciseService({FirebaseFirestore? db, String? Function()? getUid})
    : _db = db ?? FirebaseFirestore.instance,
      _getUid = getUid ?? (() => FirebaseAuth.instance.currentUser?.uid);

  String _requireUid() {
    final uid = _getUid();
    if (uid == null) throw StateError('Usuario no autenticado');
    return uid;
  }

  Future<List<String>> getUniqueCategories() async {
    final exercises = await _getVisibleExercises();
    final categories = exercises
        .map((exercise) => exercise['categoria'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  Future<List<Map<String, dynamic>>> getByCategory(String category) async {
    final exercises = await _getVisibleExercises();
    return exercises
        .where((exercise) => exercise['categoria'] == category)
        .toList();
  }

  Future<List<Map<String, dynamic>>> getAllExercises() =>
      _getVisibleExercises();

  Future<List<String>> getPersonalCategories() async {
    final exercises = await _getPersonalExercises();
    final categories = exercises
        .map((exercise) => exercise['categoria'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  Future<List<Map<String, dynamic>>> getPersonalByCategory(
    String category,
  ) async {
    final exercises = await _getPersonalExercises();
    return exercises
        .where((exercise) => exercise['categoria'] == category)
        .toList();
  }

  Future<void> addCustomExercise(Map<String, dynamic> exercise) async {
    final uid = _requireUid();
    await _db.collection('ejercicios2').add({
      ...exercise,
      'esPersonalizado': true,
      'uid': uid,
    });
  }

  Future<void> deleteExercise(String id) async {
    final uid = _requireUid();
    final reference = _db.collection('ejercicios2').doc(id);
    final snapshot = await reference.get();
    final data = snapshot.data();
    if (data == null || data['uid'] != uid || data['esPersonalizado'] != true) {
      throw StateError('Solo puedes eliminar tus ejercicios personalizados');
    }
    await reference.delete();
  }

  Future<void> updateExercise(String id, Map<String, dynamic> exercise) async {
    final uid = _requireUid();
    final reference = _db.collection('ejercicios2').doc(id);
    final snapshot = await reference.get();
    final data = snapshot.data();
    if (data == null || data['uid'] != uid || data['esPersonalizado'] != true) {
      throw StateError('Solo puedes editar tus ejercicios personalizados');
    }

    final safeUpdate = Map<String, dynamic>.from(exercise)
      ..remove('uid')
      ..remove('esPersonalizado');
    await reference.update(safeUpdate);
  }

  Future<void> renameCategory(String oldCategory, String newCategory) async {
    final uid = _requireUid();
    final snapshot = await _db
        .collection('ejercicios2')
        .where('categoria', isEqualTo: oldCategory)
        .where('uid', isEqualTo: uid)
        .get();

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'categoria': newCategory});
    }
    await batch.commit();
  }

  Future<void> deleteCategory(String category) async {
    final uid = _requireUid();
    final snapshot = await _db
        .collection('ejercicios2')
        .where('categoria', isEqualTo: category)
        .where('uid', isEqualTo: uid)
        .get();

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> _getVisibleExercises() async {
    final uid = _getUid();
    if (uid == null) return [];

    final collection = _db.collection('ejercicios2');
    final snapshots = await Future.wait([
      collection.where('esPersonalizado', isEqualTo: false).get(),
      collection.where('uid', isEqualTo: uid).get(),
    ]);

    return snapshots
        .expand((snapshot) => snapshot.docs)
        .map((document) => {'id': document.id, ...document.data()})
        .toList();
  }

  Future<List<Map<String, dynamic>>> _getPersonalExercises() async {
    final uid = _requireUid();
    final snapshot = await _db
        .collection('ejercicios2')
        .where('uid', isEqualTo: uid)
        .get();
    return snapshot.docs
        .map((document) => {'id': document.id, ...document.data()})
        .toList();
  }
}
