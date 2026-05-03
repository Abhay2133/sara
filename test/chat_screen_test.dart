import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sara/services/gemma_service.dart';
import 'package:sara/ui/chat_screen.dart';
import 'dart:io';

class FakeGemmaService extends GemmaService {
  bool _initialized = false;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize(String modelPath) async {
    _initialized = true;
  }

  @override
  Future<File> downloadModel(String url, {void Function(double)? onProgress}) async {
    return File('downloaded_model.litertlm');
  }

  @override
  Stream<String> sendMessage(
    String text,
    Future<String> Function(String name, Map<String, dynamic> args) onToolCall, {
    void Function(String?)? onActionChanged,
  }) async* {
    yield 'Sara says: $text';
  }
}

void main() {
  group('ChatScreen', () {
    late FakeGemmaService fakeGemmaService;

    setUp(() {
      fakeGemmaService = FakeGemmaService();
    });

    Widget buildTestApp() {
      return ProviderScope(
        overrides: [gemmaServiceProvider.overrideWithValue(fakeGemmaService)],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return ChatScreen();
            },
          ),
        ),
      );
    }

    testWidgets('shows model dropdown and download button', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      expect(find.byKey(const Key('selectedModelDropdown')), findsOneWidget);
      expect(find.text('Download model'), findsOneWidget);
    });

    testWidgets('chat input is disabled before initialization', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      final input = find.byKey(const Key('messageInput'));
      expect(tester.widget<TextField>(input).enabled, isFalse);
    });
  });
}
