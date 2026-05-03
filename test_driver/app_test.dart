import 'dart:io';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('Sara App', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver.close();
    });

    test('take screenshot', () async {
      // Wait a moment for the app to fully render
      await Future.delayed(const Duration(seconds: 3));
      
      final pixels = await driver.screenshot();
      final file = File('screenshot.png');
      await file.writeAsBytes(pixels);
      
      print('Screenshot successfully saved to \${file.absolute.path}');
    });
  });
}
