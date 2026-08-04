import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stronger/infrastructure/services/firebase/auth_state_notifier.dart';

class MockAuthUser extends Mock implements User {}

void main() {
  test('tracks login and logout events and notifies listeners', () async {
    final controller = StreamController<User?>();
    final notifier = AuthStateNotifier(authStateChanges: controller.stream);
    final user = MockAuthUser();
    var notifications = 0;
    notifier.addListener(() => notifications++);

    expect(notifier.initialized, false);
    expect(notifier.isLoggedIn, false);

    controller.add(user);
    await pumpEventQueue();
    expect(notifier.initialized, true);
    expect(notifier.user, user);
    expect(notifier.isLoggedIn, true);

    controller.add(null);
    await pumpEventQueue();
    expect(notifier.isLoggedIn, false);
    expect(notifications, 2);

    notifier.dispose();
    await controller.close();
  });
}
