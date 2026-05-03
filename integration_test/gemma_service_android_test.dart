import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sara/services/gemma_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('GemmaService Android integration', () {
    testWidgets('loads local Android model from app documents directory', (WidgetTester tester) async {
      if (!Platform.isAndroid) {
        return;
      }

      final appDocDir = await getApplicationDocumentsDirectory();
      final modelPath = '${appDocDir.path}/gemma-4-e2b.litertlm';
      final modelFile = File(modelPath);

      expect(await modelFile.exists(), isTrue,
          reason: 'Local model file not found at $modelPath. Place a valid litertlm file there to verify Android loading.');

      final service = GemmaService();
      await service.initialize(modelPath);
      expect(service.isInitialized, isTrue);

      final responseStream = service.sendMessage('Hello Sara', (name, args) async => 'ok');
      final firstToken = await responseStream.first;
      expect(firstToken, isNotEmpty);
    });
  });
}
