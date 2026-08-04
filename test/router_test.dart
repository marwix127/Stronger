import 'package:flutter_test/flutter_test.dart';
import 'package:stronger/router.dart';

void main() {
  group('authRedirect', () {
    test('sends signed-out users to login from protected routes', () {
      expect(
        authRedirect(loggedIn: false, uri: Uri.parse('/training')),
        '/login',
      );
    });

    test('allows signed-out users to access authentication pages', () {
      expect(authRedirect(loggedIn: false, uri: Uri.parse('/login')), isNull);
      expect(
        authRedirect(loggedIn: false, uri: Uri.parse('/register')),
        isNull,
      );
    });

    test('sends authenticated users away from authentication pages', () {
      expect(authRedirect(loggedIn: true, uri: Uri.parse('/login')), '/');
      expect(authRedirect(loggedIn: true, uri: Uri.parse('/register')), '/');
    });

    test('uses only the path when authentication routes have a query', () {
      expect(
        authRedirect(
          loggedIn: false,
          uri: Uri.parse('/login?redirect=/training'),
        ),
        isNull,
      );
    });

    test('allows authenticated users to access protected routes', () {
      expect(
        authRedirect(loggedIn: true, uri: Uri.parse('/muscle-map')),
        isNull,
      );
    });
  });
}
