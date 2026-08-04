import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stronger/models/user.dart';

void main() {
  test('User maps a Firestore profile in both directions', () {
    final date = DateTime(2026, 1, 1);
    final user = User.fromMap('user-1', {
      'name': 'Ana',
      'email': 'ana@example.com',
      'age': 30,
      'height': 170,
      'gender': 'female',
      'currentGoal': 'strength',
      'currentWeight': 65,
      'currentBodyFat': 20,
      'currentMuscle': 45,
      'lastUpdate': Timestamp.fromDate(date),
    });

    expect(user.uid, 'user-1');
    expect(user.currentWeight, 65.0);
    expect(user.lastUpdate, date);
    expect(user.toMap(), containsPair('email', 'ana@example.com'));
    expect(user.toMap(), containsPair('currentMuscle', 45.0));
  });
}
