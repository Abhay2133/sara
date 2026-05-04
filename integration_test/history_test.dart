import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sara/main.dart' as app;
import 'package:sara/services/gemma_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MockGemmaService extends GemmaService {
  @override
  bool get isInitialized => true;
  
  @override
  Stream<String> sendMessage(
    String text,
    Future<String> Function(String name, Map<String, dynamic> args) onToolCall, {
    void Function(String?)? onActionChanged,
  }) async* {
    yield 'Mock response to: $text';
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Conversation history persistence test', (WidgetTester tester) async {
    // Override Gemma to avoid real model initialization
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gemmaServiceProvider.overrideWithValue(MockGemmaService()),
        ],
        child: const app.SaraApp(),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Send a message
    final input = find.byKey(const Key('messageInput'));
    await tester.enterText(input, 'Hello history');
    await tester.tap(find.byKey(const Key('sendMessageButton')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Hello history'), findsOneWidget);
    expect(find.textContaining('Mock response to: Hello history'), findsOneWidget);

    // 2. Open drawer and check if session exists
    await tester.dragFrom(tester.getTopLeft(find.byType(Scaffold)), const Offset(300, 0));
    await tester.pumpAndSettle();

    expect(find.text('Hello history'), findsOneWidget); // The title should be the first message

    // 3. Create new chat
    await tester.tap(find.text('New Chat'));
    await tester.pumpAndSettle();

    expect(find.text('Hello history'), findsNothing); // Chat cleared

    // 4. Re-open drawer and switch back
    await tester.dragFrom(tester.getTopLeft(find.byType(Scaffold)), const Offset(300, 0));
    await tester.pumpAndSettle();
    
    await tester.tap(find.text('Hello history'));
    await tester.pumpAndSettle();

    expect(find.text('Hello history'), findsOneWidget); // Chat restored
  });
}
