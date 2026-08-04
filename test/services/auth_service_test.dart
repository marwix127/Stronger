import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stronger/infrastructure/services/firebase/auth_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

class FakeAuthCredential extends Fake implements AuthCredential {}

void main() {
  const uid = 'user-1';
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late MockUser user;
  late AuthService service;

  setUpAll(() {
    registerFallbackValue(FakeAuthCredential());
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'chat_messages_$uid': '[]',
      'training_draft': '{}',
      'unrelated': 'keep-me',
    });
    firestore = FakeFirebaseFirestore();
    auth = MockFirebaseAuth();
    user = MockUser();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn(uid);
    when(() => user.email).thenReturn('user@example.com');
    when(
      () => user.reauthenticateWithCredential(any()),
    ).thenAnswer((_) async => MockUserCredential());
    when(() => user.delete()).thenAnswer((_) async {});
    service = AuthService(auth: auth, firestore: firestore);
  });

  Future<void> seedUserData() async {
    await firestore.collection('users').doc(uid).set({'name': 'Current user'});
    await firestore
        .collection('users')
        .doc(uid)
        .collection('trainings')
        .doc('training-1')
        .set({'name': 'Leg day'});
    await firestore
        .collection('users')
        .doc(uid)
        .collection('body_measurements')
        .doc('measurement-1')
        .set({'weight': 80});
    await firestore
        .collection('users')
        .doc(uid)
        .collection('muscle_data')
        .doc('scores')
        .set({'chest': 50});
    await firestore.collection('ejercicios2').doc('mine').set({
      'uid': uid,
      'esPersonalizado': true,
    });

    await firestore.collection('users').doc('user-2').set({'name': 'Other'});
    await firestore.collection('ejercicios2').doc('other').set({
      'uid': 'user-2',
      'esPersonalizado': true,
    });
    await firestore.collection('ejercicios2').doc('global').set({
      'uid': null,
      'esPersonalizado': false,
    });
  }

  test('register creates the user and stores a trimmed display name', () async {
    final credential = MockUserCredential();
    when(
      () => auth.createUserWithEmailAndPassword(
        email: 'new@example.com',
        password: 'password',
      ),
    ).thenAnswer((_) async => credential);
    when(() => credential.user).thenReturn(user);
    when(() => user.updateDisplayName('Ana')).thenAnswer((_) async {});

    final result = await service.register(
      'new@example.com',
      'password',
      displayName: ' Ana ',
    );

    expect(result, user);
    verify(() => user.updateDisplayName('Ana')).called(1);
  });

  test('logIn and signOut delegate to Firebase Auth', () async {
    final credential = MockUserCredential();
    when(
      () => auth.signInWithEmailAndPassword(
        email: 'user@example.com',
        password: 'password',
      ),
    ).thenAnswer((_) async => credential);
    when(() => credential.user).thenReturn(user);
    when(() => auth.signOut()).thenAnswer((_) async {});

    expect(await service.logIn('user@example.com', 'password'), user);
    await service.signOut();

    verify(() => auth.signOut()).called(1);
  });

  test('deleteAccount removes only owned remote and local data', () async {
    await seedUserData();

    await service.deleteAccount(password: 'valid-password');

    expect((await firestore.collection('users').doc(uid).get()).exists, false);
    expect(
      (await firestore
              .collection('users')
              .doc(uid)
              .collection('trainings')
              .get())
          .docs,
      isEmpty,
    );
    expect(
      (await firestore.collection('ejercicios2').doc('mine').get()).exists,
      false,
    );
    expect(
      (await firestore.collection('users').doc('user-2').get()).exists,
      true,
    );
    expect(
      (await firestore.collection('ejercicios2').doc('other').get()).exists,
      true,
    );
    expect(
      (await firestore.collection('ejercicios2').doc('global').get()).exists,
      true,
    );

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey('chat_messages_$uid'), false);
    expect(preferences.containsKey('training_draft'), false);
    expect(preferences.getString('unrelated'), 'keep-me');
    verify(() => user.reauthenticateWithCredential(any())).called(1);
    verify(() => user.delete()).called(1);
  });

  test('deleteAccount preserves data when reauthentication fails', () async {
    await seedUserData();
    when(
      () => user.reauthenticateWithCredential(any()),
    ).thenThrow(FirebaseAuthException(code: 'wrong-password'));

    await expectLater(
      service.deleteAccount(password: 'wrong-password'),
      throwsA(isA<FirebaseAuthException>()),
    );

    expect((await firestore.collection('users').doc(uid).get()).exists, true);
    expect(
      (await firestore.collection('ejercicios2').doc('mine').get()).exists,
      true,
    );
    verifyNever(() => user.delete());
  });

  test('deleteAccount rejects a missing authenticated user', () async {
    when(() => auth.currentUser).thenReturn(null);

    await expectLater(
      service.deleteAccount(password: 'password'),
      throwsStateError,
    );
  });
}
