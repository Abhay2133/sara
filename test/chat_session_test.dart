import 'package:flutter_test/flutter_test.dart';
import 'package:sara/models/chat_session.dart';

void main() {
  group('ChatSession Model', () {
    test('should serialize to JSON correctly', () {
      final session = ChatSession(
        id: '1',
        title: 'Test Session',
        messages: [
          ChatMessage(text: 'Hello', isUser: true),
          ChatMessage(text: 'Hi there', isUser: false),
        ],
        updatedAt: DateTime(2023, 10, 10),
      );

      final json = session.toJson();

      expect(json['id'], '1');
      expect(json['title'], 'Test Session');
      expect(json['messages'].length, 2);
      expect(json['messages'][0]['text'], 'Hello');
      expect(json['messages'][0]['isUser'], true);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': '2',
        'title': 'Another Session',
        'messages': [
          {'text': 'User message', 'isUser': true},
          {'text': 'AI message', 'isUser': false},
        ],
        'updatedAt': '2023-10-11T00:00:00.000',
      };

      final session = ChatSession.fromJson(json);

      expect(session.id, '2');
      expect(session.title, 'Another Session');
      expect(session.messages.length, 2);
      expect(session.messages[0].text, 'User message');
      expect(session.messages[1].isUser, false);
    });
  });
}
