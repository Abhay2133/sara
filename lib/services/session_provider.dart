import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sara/models/chat_session.dart';
import 'package:sara/services/history_service.dart';
import 'package:uuid/uuid.dart';

final historyListProvider = StateNotifierProvider<HistoryNotifier, List<ChatSession>>((ref) {
  return HistoryNotifier(ref.read(historyServiceProvider));
});

class HistoryNotifier extends StateNotifier<List<ChatSession>> {
  final HistoryService _service;

  HistoryNotifier(this._service) : super([]) {
    loadSessions();
  }

  Future<void> loadSessions() async {
    state = await _service.loadSessions();
  }

  Future<void> saveSession(ChatSession session) async {
    await _service.saveSession(session);
    await loadSessions();
  }

  Future<void> deleteSession(String id) async {
    await _service.deleteSession(id);
    await loadSessions();
  }
}

final activeSessionProvider = StateProvider<ChatSession?>((ref) => null);

class SessionManager {
  static ChatSession createNewSession() {
    return ChatSession(
      id: const Uuid().v4(),
      title: 'New Chat',
      messages: [],
      updatedAt: DateTime.now(),
    );
  }
}
