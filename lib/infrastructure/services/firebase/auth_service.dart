import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _deleteBatchSize = 400;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  Future<User?> register(
    String email,
    String password, {
    String? displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    final normalizedName = displayName?.trim();
    if (user != null && normalizedName != null && normalizedName.isNotEmpty) {
      await user.updateDisplayName(normalizedName);
    }
    return user;
  }

  Future<User?> logIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  Stream<User?> get userStream => _auth.authStateChanges();

  Future<void> signOut() => _auth.signOut();

  User? get currentUser => _auth.currentUser;

  /// Deletes all Stronger data owned by the user before deleting their
  /// Firebase Authentication identity.
  Future<void> deleteAccount({required String password}) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw StateError('Usuario no autenticado');
    }

    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: email, password: password),
    );

    final userReference = _firestore.collection('users').doc(user.uid);
    await _deleteQuery(userReference.collection('trainings'));
    await _deleteQuery(userReference.collection('body_measurements'));
    await _deleteQuery(userReference.collection('muscle_data'));
    await _deleteQuery(
      _firestore.collection('ejercicios2').where('uid', isEqualTo: user.uid),
    );
    await userReference.delete();

    await user.delete();
    await _clearLocalUserData(user.uid);
  }

  Future<void> _deleteQuery(Query<Map<String, dynamic>> query) async {
    while (true) {
      final snapshot = await query.limit(_deleteBatchSize).get();
      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final document in snapshot.docs) {
        batch.delete(document.reference);
      }
      await batch.commit();

      if (snapshot.docs.length < _deleteBatchSize) return;
    }
  }

  Future<void> _clearLocalUserData(String uid) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove('chat_messages_$uid');
      await preferences.remove('training_draft');
    } catch (_) {
      // Remote deletion already succeeded, so local cleanup is best-effort.
    }
  }
}
