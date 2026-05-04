import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sara/models/chat_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final historyServiceProvider = Provider<HistoryService>((ref) => HistoryService());

class HistoryService {
  final String? storagePath;

  HistoryService({this.storagePath});

  Future<String> _getDirectoryPath() async {
    if (storagePath != null) return storagePath!;
    final directory = await getApplicationSupportDirectory();
    final path = p.join(directory.path, 'history');
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return path;
  }

  Future<List<ChatSession>> loadSessions() async {
    final path = await _getDirectoryPath();
    final dir = Directory(path);
    if (!await dir.exists()) return [];

    final sessions = <ChatSession>[];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        try {
          final content = await entity.readAsString();
          final json = jsonDecode(content);
          sessions.add(ChatSession.fromJson(json));
        } catch (e) {
          // Skip invalid session files
        }
      }
    }

    sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sessions;
  }

  Future<void> saveSession(ChatSession session) async {
    final path = await _getDirectoryPath();
    final file = File(p.join(path, '${session.id}.json'));
    await file.writeAsString(jsonEncode(session.toJson()));
  }

  Future<void> deleteSession(String id) async {
    final path = await _getDirectoryPath();
    final file = File(p.join(path, '$id.json'));
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> clearHistory() async {
    final path = await _getDirectoryPath();
    final dir = Directory(path);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
