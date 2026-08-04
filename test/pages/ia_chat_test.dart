import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stronger/UI/pages/ia_chat.dart';
import 'package:stronger/infrastructure/services/coach_service.dart';

class MockCoachService extends Mock implements CoachService {}

void main() {
  const uid = 'user-1';
  late MockCoachService coachService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    coachService = MockCoachService();
  });

  Future<void> pumpPage(WidgetTester tester, {String? userId = uid}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: IAChatPage(coachService: coachService, uid: userId),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('restores only the current user conversation', (tester) async {
    SharedPreferences.setMockInitialValues({
      'chat_messages_$uid': jsonEncode([
        {'role': 'user', 'text': 'Mi mensaje'},
        {'role': 'ai', 'text': 'Mi respuesta'},
      ]),
      'chat_messages_user-2': jsonEncode([
        {'role': 'user', 'text': 'Mensaje privado ajeno'},
      ]),
    });

    await pumpPage(tester);

    expect(find.text('Mi mensaje'), findsOneWidget);
    expect(find.text('Mi respuesta'), findsOneWidget);
    expect(find.text('Mensaje privado ajeno'), findsNothing);
  });

  testWidgets('sends history, renders the reply and persists both messages', (
    tester,
  ) async {
    when(
      () => coachService.generateReply(any(), history: any(named: 'history')),
    ).thenAnswer((_) async => 'Respuesta útil');
    await pumpPage(tester);

    await tester.enterText(find.byType(TextField), '¿Cómo voy?');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('¿Cómo voy?'), findsOneWidget);
    expect(find.text('Respuesta útil'), findsOneWidget);
    verify(
      () => coachService.generateReply('¿Cómo voy?', history: const []),
    ).called(1);
    final preferences = await SharedPreferences.getInstance();
    final saved =
        jsonDecode(preferences.getString('chat_messages_$uid')!) as List;
    expect(saved, hasLength(2));
  });

  testWidgets('shows a domain error as a coach message', (tester) async {
    when(
      () => coachService.generateReply(any(), history: any(named: 'history')),
    ).thenThrow(const CoachException('Coach temporalmente no disponible'));
    await pumpPage(tester);

    await tester.enterText(find.byType(TextField), 'Hola');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('Coach temporalmente no disponible'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('does not send empty messages or messages while loading', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    verifyNever(
      () => coachService.generateReply(any(), history: any(named: 'history')),
    );
  });
}
