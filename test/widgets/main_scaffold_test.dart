import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stronger/UI/widgets/main_scaffold.dart';
import 'package:stronger/infrastructure/services/firebase/auth_service.dart';
import 'package:stronger/infrastructure/services/theme_notifier.dart';

class MockScaffoldAuthService extends Mock implements AuthService {}

class MockScaffoldUser extends Mock implements User {}

void main() {
  late MockScaffoldAuthService authService;
  late ThemeNotifier themeNotifier;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'themeMode': 'light'});
    authService = MockScaffoldAuthService();
    final user = MockScaffoldUser();
    when(() => authService.currentUser).thenReturn(user);
    when(() => user.email).thenReturn('user@example.com');
    when(() => user.photoURL).thenReturn(null);
    when(() => authService.signOut()).thenAnswer((_) async {});
    themeNotifier = ThemeNotifier();
    await pumpEventQueue();
  });

  Future<void> pumpRouter(WidgetTester tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('Login destino')),
        ),
        GoRoute(
          path: '/exercise-management',
          builder: (_, _) => Scaffold(
            appBar: AppBar(),
            body: const Text('Gestión de ejercicios'),
          ),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, _) => Scaffold(
            appBar: AppBar(),
            body: const Text('Ajustes destino'),
          ),
        ),
        ShellRoute(
          builder: (_, _, child) => MainScaffold(
            authService: authService,
            themeNotifier: themeNotifier,
            child: child,
          ),
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const Text('Inicio contenido'),
            ),
            GoRoute(
              path: '/muscle-map',
              builder: (_, _) => const Text('Cuerpo contenido'),
            ),
            GoRoute(
              path: '/grafics',
              builder: (_, _) => const Text('Gráficos contenido'),
            ),
            GoRoute(
              path: '/ia-chat',
              builder: (_, _) => const Text('Chat contenido'),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  testWidgets('navigates between the primary tabs', (tester) async {
    await pumpRouter(tester);
    expect(find.text('Inicio contenido'), findsOneWidget);

    await tester.tap(find.text('Coach IA'));
    await tester.pumpAndSettle();

    expect(find.text('Chat contenido'), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Coach IA'), findsOneWidget);
  });

  testWidgets('shows the user and signs out from the drawer', (tester) async {
    await pumpRouter(tester);
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    expect(find.text('user@example.com'), findsOneWidget);
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    verify(() => authService.signOut()).called(1);
    expect(find.text('Login destino'), findsOneWidget);
  });

  testWidgets('closes the drawer before opening a secondary route', (
    tester,
  ) async {
    await pumpRouter(tester);
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gestionar Ejercicios'));
    await tester.pumpAndSettle();
    expect(find.text('Gestión de ejercicios'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold));
    expect(scaffold.isDrawerOpen, isFalse);
  });
}
