import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sara/services/gemma_service.dart';
import 'package:sara/ui/chat_screen.dart';

class FakeGemmaService extends GemmaService {
  @override
  bool get isInitialized => true;

  @override
  Future<void> initialize(String modelPath) async {}

  @override
  Stream<String> sendMessage(
    String text,
    Future<String> Function(String name, Map<String, dynamic> args) onToolCall, {
    void Function(String?)? onActionChanged,
  }) async* {
    yield 'Response to: $text';
  }
}

void main() {
  group('Chat Input Behavior', () {
    late FakeGemmaService fakeGemmaService;

    setUp(() {
      fakeGemmaService = FakeGemmaService();
    });

    Widget buildTestApp() {
      return ProviderScope(
        overrides: [gemmaServiceProvider.overrideWithValue(fakeGemmaService)],
        child: const MaterialApp(
          home: ChatScreen(),
        ),
      );
    }

    testWidgets('Enter key does not send message (allows default behavior)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      final inputFinder = find.byKey(const Key('messageInput'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.widget<TextField>(inputFinder).enabled, isTrue);

      await tester.tap(inputFinder);
      await tester.enterText(inputFinder, 'First line');
      await tester.pump();
      
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(find.text('Response to: First line'), findsNothing);
    });

    testWidgets('Ctrl + Enter sends the message', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      final inputFinder = find.byKey(const Key('messageInput'));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(inputFinder);
      await tester.enterText(inputFinder, 'Hello');
      await tester.pump();
      
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump(); 
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Response to: Hello'), findsOneWidget);
      
      final controller = tester.widget<TextField>(inputFinder).controller!;
      expect(controller.text, isEmpty);
    });
  });
}
