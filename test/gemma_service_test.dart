import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sara/services/gemma_service.dart';

void main() {
  group('GemmaService', () {
    late GemmaService gemmaService;

    setUp(() {
      gemmaService = GemmaService();
    });

    test('isInitialized is false before initialization', () {
      expect(gemmaService.isInitialized, isFalse);
    });

    test('initialize throws when model file does not exist', () async {
      final fakePath = '${Directory.systemTemp.path}/nonexistent_gemma_model.litertlm';

      expect(
        () => gemmaService.initialize(fakePath),
        throwsA(isA<Exception>()),
      );
      expect(gemmaService.isInitialized, isFalse);
    });

    test('sendMessage throws when not initialized', () async {
      expect(
        () => gemmaService.sendMessage('hello', (name, args) async => 'ok').first,
        throwsA(isA<Exception>()),
      );
    });
  });
}
