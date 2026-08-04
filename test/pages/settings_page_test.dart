import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stronger/UI/pages/settings_page.dart';
import 'package:stronger/infrastructure/services/firebase/auth_service.dart';

class MockSettingsAuthService extends Mock implements AuthService {}

void main() {
  late MockSettingsAuthService authService;

  setUp(() {
    authService = MockSettingsAuthService();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (_, _) => SettingsPage(authService: authService),
        ),
        GoRoute(
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('Login destino')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  Future<void> openDialog(WidgetTester tester) async {
    await tester.tap(find.text('Eliminar cuenta'));
    await tester.pumpAndSettle();
  }

  testWidgets('requires the password before deleting', (tester) async {
    await pumpPage(tester);
    await openDialog(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Eliminar'));
    await tester.pump();

    expect(find.text('Introduce tu contraseña'), findsOneWidget);
    verifyNever(
      () => authService.deleteAccount(password: any(named: 'password')),
    );
  });

  testWidgets('deletes all account data and navigates to login', (
    tester,
  ) async {
    when(
      () => authService.deleteAccount(password: 'valid-password'),
    ).thenAnswer((_) async {});
    await pumpPage(tester);
    await openDialog(tester);
    await tester.enterText(find.byType(TextFormField), 'valid-password');

    await tester.tap(find.widgetWithText(TextButton, 'Eliminar'));
    await tester.pumpAndSettle();

    verify(
      () => authService.deleteAccount(password: 'valid-password'),
    ).called(1);
    expect(find.text('Login destino'), findsOneWidget);
  });

  testWidgets('shows a friendly wrong-password error', (tester) async {
    when(
      () => authService.deleteAccount(password: 'wrong-password'),
    ).thenThrow(FirebaseAuthException(code: 'wrong-password'));
    await pumpPage(tester);
    await openDialog(tester);
    await tester.enterText(find.byType(TextFormField), 'wrong-password');

    await tester.tap(find.widgetWithText(TextButton, 'Eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('La contraseña no es correcta.'), findsOneWidget);
    expect(find.text('Eliminar cuenta'), findsOneWidget);
  });
}
