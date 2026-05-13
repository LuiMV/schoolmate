class ChatSession {
  final String id;
  final String userId;
  final String? courseId;
  final String? resourceId;
  final String? subject;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatSession({
    required this.id,
    required this.userId,
    this.courseId,
    this.resourceId,
    this.subject,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : title = title ?? 'New Chat',
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory ChatSession.fromMap(Map<String, dynamic> map) {
    return ChatSession(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      courseId: map['course_id'],
      resourceId: map['resource_id'],
      subject: map['subject'],
      title: map['title'] ?? 'New Chat',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'course_id': courseId,
        'resource_id': resourceId,
        'subject': subject,
        'title': title,
      };
}
