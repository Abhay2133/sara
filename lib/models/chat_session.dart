class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class ChatSession {
  final String id;
  final String title;
  final List<ChatMessage> messages;
  final DateTime updatedAt;

  ChatSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'messages': messages.map((m) => {
        'text': m.text,
        'isUser': m.isUser,
      }).toList(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      title: json['title'],
      messages: (json['messages'] as List).map((m) => ChatMessage(
        text: m['text'],
        isUser: m['isUser'],
      )).toList(),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  ChatSession copyWith({
    String? id,
    String? title,
    List<ChatMessage>? messages,
    DateTime? updatedAt,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
