class AiFeedback {
  final String id;
  final String courseId;
  final String? resourceId;
  final String teacherId;
  final String feedbackType;
  final String? requestText;
  final String? responseText;
  final DateTime createdAt;

  AiFeedback({
    required this.id,
    required this.courseId,
    this.resourceId,
    required this.teacherId,
    required this.feedbackType,
    this.requestText,
    this.responseText,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AiFeedback.fromMap(Map<String, dynamic> map) {
    return AiFeedback(
      id: map['id'] ?? '',
      courseId: map['course_id'] ?? '',
      resourceId: map['resource_id'],
      teacherId: map['teacher_id'] ?? '',
      feedbackType: map['feedback_type'] ?? '',
      requestText: map['request_text'],
      responseText: map['response_text'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'course_id': courseId,
        'resource_id': resourceId,
        'teacher_id': teacherId,
        'feedback_type': feedbackType,
        'request_text': requestText,
        'response_text': responseText,
      };
}
