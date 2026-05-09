class ComprehensionScore {
  final String id;
  final String courseId;
  final String studentId;
  final String? studentName;
  final int score;
  final String? notes;
  final DateTime createdAt;

  ComprehensionScore({
    required this.id,
    required this.courseId,
    required this.studentId,
    this.studentName,
    required this.score,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ComprehensionScore.fromMap(Map<String, dynamic> map) {
    return ComprehensionScore(
      id: map['id'] ?? '',
      courseId: map['course_id'] ?? '',
      studentId: map['student_id'] ?? '',
      studentName: map['student_name'],
      score: map['score'] ?? 0,
      notes: map['notes'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'course_id': courseId,
        'student_id': studentId,
        'score': score,
        'notes': notes,
      };
}
