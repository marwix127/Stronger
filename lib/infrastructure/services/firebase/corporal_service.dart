import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stronger/infrastructure/services/firebase/auth_service.dart';

class BodyMeasurementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  Future<void> addMeasurement(Map<String, dynamic> data) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('body_measurements')
          .add({...data, 'date': FieldValue.serverTimestamp()});
    } catch (e) {
      rethrow;
    }
  }

  Stream<QuerySnapshot> getMeasurements() {
    final user = _authService.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('body_measurements')
        .orderBy('date', descending: true)
        .snapshots();
  }

  Future<Map<String, dynamic>?> getLastMeasurement() async {
    final user = _authService.currentUser;
    if (user == null) return null;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('body_measurements')
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateMeasurement(String id, Map<String, dynamic> data) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('body_measurements')
          .doc(id)
          .update(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteMeasurement(String id) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('body_measurements')
          .doc(id)
          .delete();
    } catch (e) {
      rethrow;
    }
  }
}
