import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stronger/main.dart';
import 'package:stronger/router.dart' show router;

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({'themeMode': 'light'});
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Stronger lista')),
        ),
      ],
    );
  });

  tearDownAll(() {
    router.dispose();
  });

  testWidgets(
    'shows a useful Firebase startup failure instead of a black screen',
    (tester) async {
      await tester.pumpWidget(const StartupErrorApp());

      expect(
        find.textContaining('no ha podido iniciar Firebase'),
        findsOneWidget,
      );
    },
  );

  testWidgets('builds the application shell with Stronger branding', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Stronger lista'), findsOneWidget);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
      'Stronger',
    );
  });
}
