class QuizResult {
  final String id;
  final String courseId;
  final String studentId;
  final String subject;
  final String? topic;
  final List<Map<String, dynamic>> questions;
  final List<Map<String, dynamic>> answers;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final DateTime completedAt;

  QuizResult({
    required this.id,
    required this.courseId,
    required this.studentId,
    required this.subject,
    this.topic,
    required this.questions,
    required this.answers,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    DateTime? completedAt,
  }) : completedAt = completedAt ?? DateTime.now();

  factory QuizResult.fromMap(Map<String, dynamic> map) {
    return QuizResult(
      id: map['id'] ?? '',
      courseId: map['course_id'] ?? '',
      studentId: map['student_id'] ?? '',
      subject: map['subject'] ?? '',
      topic: map['topic'],
      questions: (map['questions'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      answers: (map['answers'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      score: map['score'] ?? 0,
      totalQuestions: map['total_questions'] ?? 0,
      correctAnswers: map['correct_answers'] ?? 0,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'course_id': courseId,
        'student_id': studentId,
        'subject': subject,
        'topic': topic,
        'questions': questions,
        'answers': answers,
        'score': score,
        'total_questions': totalQuestions,
        'correct_answers': correctAnswers,
      };
}
