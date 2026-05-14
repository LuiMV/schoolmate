class QuestionDifficulty {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String? explanation;
  final int wrongCount;
  final int totalAttempts;
  final double wrongPercentage;

  QuestionDifficulty({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation,
    required this.wrongCount,
    required this.totalAttempts,
    required this.wrongPercentage,
  });
}

class StudentTopScore {
  final String studentId;
  final String studentName;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final String subject;
  final String? topic;
  final DateTime completedAt;

  StudentTopScore({
    required this.studentId,
    required this.studentName,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.subject,
    this.topic,
    required this.completedAt,
  });
}

class QuizAnalytics {
  final List<QuestionDifficulty> difficultQuestions;
  final List<StudentTopScore> topScores;

  QuizAnalytics({
    required this.difficultQuestions,
    required this.topScores,
  });
}
