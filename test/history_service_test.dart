import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sara/models/chat_session.dart';
import 'package:sara/services/history_service.dart';

void main() {
  late HistoryService historyService;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sara_history_test');
    historyService = HistoryService(storagePath: tempDir.path);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('HistoryService', () {
    test('should save and load sessions', () async {
      final session = ChatSession(
        id: '1',
        title: 'Session 1',
        messages: [ChatMessage(text: 'Hello', isUser: true)],
        updatedAt: DateTime.now(),
      );

      await historyService.saveSession(session);
      final sessions = await historyService.loadSessions();

      expect(sessions.length, 1);
      expect(sessions[0].id, '1');
      expect(sessions[0].title, 'Session 1');
    });

    test('should delete a session', () async {
      final session = ChatSession(
        id: '1',
        title: 'Session 1',
        messages: [],
        updatedAt: DateTime.now(),
      );

      await historyService.saveSession(session);
      await historyService.deleteSession('1');
      final sessions = await historyService.loadSessions();

      expect(sessions.isEmpty, true);
    });
  });
}
