class ChatMessage {
  final String id;
  final String sessionId;
  final String role;
  final String content;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    this.metadata,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      sessionId: map['session_id'] ?? '',
      role: map['role'] ?? '',
      content: map['content'] ?? '',
      metadata: map['metadata'] is Map ? Map<String, dynamic>.from(map['metadata']) : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'session_id': sessionId,
        'role': role,
        'content': content,
        'metadata': metadata,
      };
}
