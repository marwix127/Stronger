import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stronger/UI/pages/login_page.dart';
import 'package:stronger/UI/pages/register_page.dart';
import 'package:stronger/infrastructure/services/firebase/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

class MockUser extends Mock implements User {}

void main() {
  late MockAuthService authService;

  setUp(() {
    authService = MockAuthService();
  });

  Future<GoRouter> pumpAuthRouter(
    WidgetTester tester, {
    required String initialLocation,
  }) async {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, _) => LogInPage(authService: authService),
        ),
        GoRoute(
          path: '/register',
          builder: (_, _) => RegisterPage(authService: authService),
        ),
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Inicio privado')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  group('LogInPage', () {
    testWidgets('validates required fields without calling Firebase', (
      tester,
    ) async {
      await pumpAuthRouter(tester, initialLocation: '/login');

      await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
      await tester.pump();

      expect(find.text('Completa todos los campos'), findsOneWidget);
      verifyNever(() => authService.logIn(any(), any()));
    });

    testWidgets('shows a friendly authentication error', (tester) async {
      when(
        () => authService.logIn(any(), any()),
      ).thenThrow(FirebaseAuthException(code: 'invalid-credential'));
      await pumpAuthRouter(tester, initialLocation: '/login');

      await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'wrong-password');
      await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('Email o contraseña incorrectos'), findsOneWidget);
    });

    testWidgets('navigates to the private home after a successful login', (
      tester,
    ) async {
      when(
        () => authService.logIn('user@example.com', 'valid-password'),
      ).thenAnswer((_) async => MockUser());
      await pumpAuthRouter(tester, initialLocation: '/login');

      await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'valid-password');
      await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('Inicio privado'), findsOneWidget);
    });

    testWidgets('opens the registration page', (tester) async {
      await pumpAuthRouter(tester, initialLocation: '/login');

      await tester.tap(find.text('¿No tienes cuenta? Regístrate'));
      await tester.pumpAndSettle();

      expect(find.text('Empieza tu transformación'), findsOneWidget);
    });
  });

  group('RegisterPage', () {
    testWidgets('validates required fields and minimum password length', (
      tester,
    ) async {
      await pumpAuthRouter(tester, initialLocation: '/register');

      await tester.tap(find.widgetWithText(FilledButton, 'Regístrate'));
      await tester.pump();
      expect(find.text('Completa todos los campos'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'Ana');
      await tester.enterText(find.byType(TextField).at(1), 'ana@example.com');
      await tester.enterText(find.byType(TextField).at(2), '123');
      await tester.tap(find.widgetWithText(FilledButton, 'Regístrate'));
      await tester.pump();
      expect(
        find.text('La contraseña debe tener al menos 6 caracteres'),
        findsOneWidget,
      );
      verifyNever(
        () => authService.register(
          any(),
          any(),
          displayName: any(named: 'displayName'),
        ),
      );
    });

    testWidgets('passes the display name and navigates after registration', (
      tester,
    ) async {
      when(
        () => authService.register(
          'ana@example.com',
          'valid-password',
          displayName: 'Ana',
        ),
      ).thenAnswer((_) async => MockUser());
      await pumpAuthRouter(tester, initialLocation: '/register');

      await tester.enterText(find.byType(TextField).at(0), ' Ana ');
      await tester.enterText(find.byType(TextField).at(1), 'ana@example.com');
      await tester.enterText(find.byType(TextField).at(2), 'valid-password');
      await tester.tap(find.widgetWithText(FilledButton, 'Regístrate'));
      await tester.pumpAndSettle();

      expect(find.text('Inicio privado'), findsOneWidget);
      verify(
        () => authService.register(
          'ana@example.com',
          'valid-password',
          displayName: 'Ana',
        ),
      ).called(1);
    });

    testWidgets('shows a friendly duplicate email error', (tester) async {
      when(
        () => authService.register(
          any(),
          any(),
          displayName: any(named: 'displayName'),
        ),
      ).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));
      await pumpAuthRouter(tester, initialLocation: '/register');

      await tester.enterText(find.byType(TextField).at(0), 'Ana');
      await tester.enterText(find.byType(TextField).at(1), 'ana@example.com');
      await tester.enterText(find.byType(TextField).at(2), 'valid-password');
      await tester.tap(find.widgetWithText(FilledButton, 'Regístrate'));
      await tester.pumpAndSettle();

      expect(find.text('Ya existe una cuenta con este email'), findsOneWidget);
    });
  });
}
