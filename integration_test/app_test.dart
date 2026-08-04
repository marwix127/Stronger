import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stronger/main.dart' as app;

const _emulatorHost = String.fromEnvironment(
  'FIREBASE_EMULATOR_HOST',
  defaultValue: '127.0.0.1',
);
const _firebaseProjectId = 'stronger-f7c9c';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const email = 'portfolio-e2e@example.com';
  const password = 'Portfolio-E2E-123';

  testWidgets('complete authenticated user lifecycle', (tester) async {
    await _resetEmulators();
    await app.main();
    await _waitFor(tester, find.text('¿No tienes cuenta? Regístrate'));

    // Authentication: register, log out and log back in through the real UI.
    await _tap(tester, find.text('¿No tienes cuenta? Regístrate'));
    await _waitFor(tester, find.text('Empieza tu transformación'));
    await tester.enterText(_field('Nombre'), 'Portfolio E2E');
    await tester.enterText(_field('Email'), email);
    await tester.enterText(_field('Contraseña'), password);
    await _tap(tester, find.widgetWithText(FilledButton, 'Regístrate'));
    await _waitFor(tester, find.text('No hay entrenamientos registrados.'));

    final uid = FirebaseAuth.instance.currentUser!.uid;
    expect(FirebaseAuth.instance.currentUser!.email, email);

    await _openDrawer(tester);
    await _tap(tester, find.text('Cerrar sesión'));
    await _waitFor(tester, find.widgetWithText(FilledButton, 'Entrar'));
    await tester.enterText(_field('Email'), email);
    await tester.enterText(_field('Contraseña'), password);
    await _tap(tester, find.widgetWithText(FilledButton, 'Entrar'));
    await _waitFor(tester, find.text('No hay entrenamientos registrados.'));

    // Personal exercise: create it and edit it using the management screens.
    await _openDrawer(tester);
    await _tap(tester, find.text('Gestionar Ejercicios'));
    await _waitFor(tester, find.text('No hay categorías'));
    await _tap(tester, find.byIcon(Icons.add));
    await _waitFor(tester, find.text('Añadir ejercicio'));
    await tester.enterText(_field('Nombre del ejercicio'), 'Press E2E');
    await tester.enterText(_field('Añadir descripción'), 'Creado en E2E');
    await tester.enterText(
      _field('Categoría (elige o crea una)'),
      'Portfolio E2E',
    );
    await _tap(tester, find.text('Guardar ejercicio'));
    await _waitFor(tester, find.text('Portfolio E2E'));

    await _tap(tester, find.text('Portfolio E2E'));
    await _waitFor(tester, find.text('Press E2E'));
    await _tap(tester, find.text('Press E2E'));
    await _waitFor(tester, find.text('Editar ejercicio'));
    await tester.enterText(_field('Nombre del ejercicio'), 'Press E2E editado');
    await _tap(tester, find.text('Actualizar ejercicio'));
    await _waitFor(tester, find.text('Press E2E editado'));

    await _back(tester);
    await _back(tester);
    await _waitFor(tester, find.text('No hay entrenamientos registrados.'));

    // Training: select that exercise, save, edit and delete the training.
    await _tap(tester, find.byType(FloatingActionButton));
    await _waitFor(tester, find.text('No hay ejercicios añadidos.'));
    await tester.enterText(
      _field('Nombre del entrenamiento'),
      'Entrenamiento E2E',
    );
    await _tap(tester, find.text('Agregar ejercicio'));
    await _waitFor(tester, find.text('Grupos musculares'));
    await _tap(tester, find.text('Portfolio E2E'));
    await _waitFor(tester, find.text('Press E2E editado'));
    await _tap(tester, find.text('Press E2E editado'));
    await _waitFor(tester, find.text('Añadir serie'));

    final seriesFields = find.byType(TextFormField);
    expect(seriesFields, findsNWidgets(2));
    await tester.enterText(seriesFields.at(0), '50');
    await tester.enterText(seriesFields.at(1), '10');
    await _tap(tester, find.widgetWithText(ElevatedButton, 'Guardar'));
    await _waitFor(tester, find.text('Entrenamiento E2E'));
    await _waitUntilGone(tester, find.byType(SnackBar));

    await _tap(tester, find.text('Entrenamiento E2E'));
    await _waitFor(tester, find.text('Editar entrenamiento'));
    await tester.enterText(
      _field('Nombre del entrenamiento'),
      'Entrenamiento E2E editado',
    );
    await _tap(tester, find.widgetWithText(ElevatedButton, 'Guardar'));
    await _waitFor(tester, find.text('Entrenamiento E2E editado'));
    await _waitUntilGone(tester, find.byType(SnackBar));

    await _tap(tester, find.text('Entrenamiento E2E editado'));
    await _waitFor(tester, find.text('Editar entrenamiento'));
    await _tap(
      tester,
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.delete),
      ),
    );
    await _waitFor(tester, find.text('Eliminar entrenamiento'));
    await _tap(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Eliminar'),
      ),
    );
    await _waitFor(tester, find.text('No hay entrenamientos registrados.'));

    // The personal exercise remains usable after a training, then is deleted.
    await _openDrawer(tester);
    await _tap(tester, find.text('Gestionar Ejercicios'));
    await _waitFor(tester, find.text('Portfolio E2E'));
    await _tap(tester, find.text('Portfolio E2E'));
    await _waitFor(tester, find.text('Press E2E editado'));
    await _tap(tester, find.byIcon(Icons.delete));
    await _waitFor(tester, find.text('Eliminar ejercicio'));
    await _tap(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Eliminar'),
      ),
    );
    await _waitFor(tester, find.text('No hay ejercicios en esta categoría'));
    await _back(tester);
    await _back(tester);
    await _waitFor(tester, find.text('No hay entrenamientos registrados.'));

    // Body measurements: create, edit and delete a record.
    await _tap(tester, find.text('Cuerpo'));
    await _waitFor(tester, find.text('Nueva Medición'));
    await tester.enterText(_field('Peso (kg)'), '80,5');
    await tester.enterText(_field('Altura (cm)'), '180');
    await tester.enterText(_field('% Grasa'), '20');
    await tester.enterText(_field('Músculo (kg)'), '60');
    await _tap(tester, find.widgetWithText(FilledButton, 'Guardar'));
    await _waitFor(tester, find.textContaining('80.5 kg'));
    await _waitUntilGone(tester, find.byType(SnackBar));

    await tester.scrollUntilVisible(
      find.byIcon(Icons.edit),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await _tap(tester, find.byIcon(Icons.edit));
    await _waitFor(tester, find.text('Editar Medición'));
    final editDialog = find.byType(AlertDialog);
    await tester.enterText(
      find.descendant(
        of: editDialog,
        matching: find.widgetWithText(TextFormField, 'Peso (kg)'),
      ),
      '82,5',
    );
    await _tap(
      tester,
      find.descendant(
        of: editDialog,
        matching: find.widgetWithText(FilledButton, 'Guardar'),
      ),
    );
    await _waitFor(tester, find.textContaining('82.5 kg'));

    await _tap(tester, find.byIcon(Icons.delete));
    await _waitFor(tester, find.text('Borrar Medición'));
    await _tap(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Borrar'),
      ),
    );
    await _waitFor(tester, find.text('No hay mediciones registradas'));

    // Seed every owned data type, then verify account deletion removes it all.
    final firestore = FirebaseFirestore.instance;
    final userReference = firestore.collection('users').doc(uid);
    await userReference.set({'email': email});
    await userReference.collection('trainings').doc('cleanup-training').set({
      'name': 'Cleanup',
      'date': Timestamp.now(),
      'exercises': <Map<String, dynamic>>[],
    });
    await userReference
        .collection('body_measurements')
        .doc('cleanup-measurement')
        .set({'weight': 80, 'date': Timestamp.now()});
    await userReference.collection('muscle_data').doc('scores').set({
      'chest': {'score': 50, 'updatedAt': Timestamp.now()},
    });
    await firestore.collection('ejercicios2').doc('cleanup-exercise').set({
      'nombre': 'Cleanup',
      'categoria': 'Cleanup',
      'descripcion': 'Cleanup',
      'esPersonalizado': true,
      'uid': uid,
    });

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('chat_messages_$uid', 'seed');
    await preferences.setString('training_draft', 'seed');

    await _openDrawer(tester);
    await _tap(tester, find.text('Ajustes'));
    await _waitFor(tester, find.text('Eliminar cuenta'));
    await _tap(tester, find.text('Eliminar cuenta'));
    await _waitFor(tester, find.text('¿Eliminar cuenta?'));
    await tester.enterText(_field('Confirma tu contraseña'), password);
    await _tap(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Eliminar'),
      ),
    );
    await _waitFor(tester, find.widgetWithText(FilledButton, 'Entrar'));

    expect(FirebaseAuth.instance.currentUser, isNull);
    expect(preferences.getString('chat_messages_$uid'), isNull);
    expect(preferences.getString('training_draft'), isNull);

    for (final path in [
      'users/$uid',
      'users/$uid/trainings/cleanup-training',
      'users/$uid/body_measurements/cleanup-measurement',
      'users/$uid/muscle_data/scores',
      'ejercicios2/cleanup-exercise',
    ]) {
      expect(
        await _emulatorDocumentStatus(path),
        404,
        reason: '$path should have been deleted',
      );
    }

    await expectLater(
      FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      ),
      throwsA(isA<FirebaseAuthException>()),
    );
  });
}

Finder _field(String label) {
  final textField = find.widgetWithText(TextField, label);
  return textField.evaluate().isNotEmpty
      ? textField
      : find.widgetWithText(TextFormField, label);
}

Future<void> _openDrawer(WidgetTester tester) async {
  await _tap(tester, find.byIcon(Icons.menu));
  await _waitFor(tester, find.text('Gestionar Ejercicios'));
}

Future<void> _back(WidgetTester tester) async {
  await _tap(tester, find.byIcon(Icons.arrow_back).first);
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _waitFor(tester, finder);
  await _dismissKeyboard(tester);
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _dismissKeyboard(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');

  final limit = DateTime.now().add(const Duration(seconds: 5));
  while (tester.view.viewInsets.bottom > 0 && DateTime.now().isBefore(limit)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final limit = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(limit)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for an expected widget');
}

Future<void> _waitUntilGone(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 6),
}) async {
  final limit = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(limit)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isEmpty) return;
  }
  throw TestFailure('Timed out waiting for a widget to disappear');
}

Future<int> _emulatorDocumentStatus(String documentPath) async {
  final projectId = Firebase.app().options.projectId;
  final uri = Uri.http(
    '$_emulatorHost:8080',
    '/v1/projects/$projectId/databases/(default)/documents/$documentPath',
  );
  final response = await http.get(
    uri,
    headers: const {'Authorization': 'Bearer owner'},
  );
  return response.statusCode;
}

Future<void> _resetEmulators() async {
  final responses = await Future.wait([
    http.delete(
      Uri.http(
        '$_emulatorHost:9099',
        '/emulator/v1/projects/$_firebaseProjectId/accounts',
      ),
    ),
    http.delete(
      Uri.http(
        '$_emulatorHost:8080',
        '/emulator/v1/projects/$_firebaseProjectId/databases/(default)/documents',
      ),
    ),
  ]);

  for (final response in responses) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Could not reset Firebase Emulator Suite '
        '(HTTP ${response.statusCode}: ${response.body})',
      );
    }
  }
}
