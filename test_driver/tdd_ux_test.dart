import 'dart:io';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('Sara UI/UX TDD Tests', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver.close();
    });

    test('Verify Status Indicator and Copy Button exist after messaging', () async {
      // 1. Initialize model
      await driver.tap(find.text('Initialize selected model'));
      
      // 2. Wait for initialization to complete (Send button becomes tappable)
      await driver.waitForTappable(find.byValueKey('sendMessageButton'), timeout: const Duration(seconds: 60));

      // 3. Focus and enter text
      await driver.tap(find.byValueKey('messageInput'));
      await driver.enterText('Test message for TDD');
      
      // 4. Tap send
      await driver.tap(find.byValueKey('sendMessageButton'));

      // 5. RED PHASE: These should fail if not implemented
      print('Checking for "Sara is thinking..." status indicator...');
      await driver.waitFor(find.text('Sara is thinking...'), timeout: const Duration(seconds: 5));
      
      print('Waiting for AI response to finish...');
      await driver.waitForTappable(find.byValueKey('sendMessageButton'), timeout: const Duration(seconds: 30));

      print('Checking for Copy button on the response...');
      await driver.waitFor(find.byTooltip('Copy to clipboard'), timeout: const Duration(seconds: 5));
    });

  });
}
