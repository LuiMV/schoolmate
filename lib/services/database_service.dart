import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course.dart';
import '../models/resource.dart';
import '../models/comprehension_score.dart';
import '../models/ai_feedback.dart';
import '../models/quiz_result.dart';
import '../models/chat_session.dart';
import '../models/chat_message.dart';
import '../models/resource_analysis.dart';
import '../models/quiz_analytics.dart';

class DatabaseService {
  final _supabase = Supabase.instance.client;
  final _random = Random();

  // ------ Teacher: Courses ------
  Future<List<Course>> getTeacherCourses(String teacherId) async {
    final data = await _supabase
        .from('courses')
        .select('*')
        .eq('teacher_id', teacherId)
        .order('created_at', ascending: false);
    return data.map((e) => Course.fromMap(e)).toList();
  }

  Future<String> _generateUniqueCode() async {
    while (true) {
      final code = (100000 + _random.nextInt(900000)).toString();
      final existing = await _supabase
          .from('courses')
          .select('id')
          .eq('invite_code', code)
          .maybeSingle();
      if (existing == null) return code;
    }
  }

  Future<Course> createCourse(Course course) async {
    final code = await _generateUniqueCode();
    final map = course.toMap();
    map['invite_code'] = code;
    final data = await _supabase
        .from('courses')
        .insert(map)
        .select()
        .single();
    return Course.fromMap(data);
  }

  Future<void> deleteCourse(String courseId) async {
    await _supabase.from('courses').delete().eq('id', courseId);
  }

  // ------ Student: Courses by grade/section ------
  Future<List<Course>> getStudentCourses(String grade, String section) async {
    final data = await _supabase
        .from('courses')
        .select('*')
        .eq('grade', grade)
        .eq('section', section)
        .order('created_at', ascending: false);
    return data.map((e) => Course.fromMap(e)).toList();
  }

  // ------ Student: Join by invite code ------
  Future<Course?> getCourseByInviteCode(String code) async {
    final data = await _supabase
        .from('courses')
        .select('*')
        .eq('invite_code', code)
        .maybeSingle();
    if (data == null) return null;
    return Course.fromMap(data);
  }

  Future<void> joinCourse(String courseId, String studentId) async {
    await _supabase.from('enrollments').insert({
      'student_id': studentId,
      'course_id': courseId,
    });
  }

  Future<List<Course>> getEnrolledCourses(String studentId) async {
    final data = await _supabase
        .from('enrollments')
        .select('courses(*)')
        .eq('student_id', studentId)
        .order('enrolled_at', ascending: false);
    return data.map((e) => Course.fromMap(e['courses'] as Map<String, dynamic>)).toList();
  }

  // ------ Resources ------
  Future<List<Resource>> getCourseResources(String courseId) async {
    final data = await _supabase
        .from('resources')
        .select('*')
        .eq('course_id', courseId)
        .order('created_at', ascending: false);
    return data.map((e) => Resource.fromMap(e)).toList();
  }

  Future<Resource> createResource(Resource resource) async {
    final data = await _supabase
        .from('resources')
        .insert(resource.toMap())
        .select()
        .single();
    return Resource.fromMap(data);
  }

  Future<void> deleteResource(String resourceId) async {
    await _supabase.from('resources').delete().eq('id', resourceId);
  }

  // ------ Comprehension Scores ------
  Future<List<ComprehensionScore>> getCourseScores(String courseId) async {
    final data = await _supabase
        .from('comprehension_scores')
        .select('*, profiles!student_id(name)')
        .eq('course_id', courseId)
        .order('created_at', ascending: false);

    return data.map((e) {
      final score = ComprehensionScore.fromMap(e);
      final profile = e['profiles'] as Map?;
      return ComprehensionScore(
        id: score.id,
        courseId: score.courseId,
        studentId: score.studentId,
        studentName: profile?['name'] as String?,
        score: score.score,
        notes: score.notes,
        createdAt: score.createdAt,
      );
    }).toList();
  }

  Future<ComprehensionScore> upsertScore(ComprehensionScore score) async {
    final data = await _supabase
        .from('comprehension_scores')
        .upsert(score.toMap(), onConflict: 'course_id,student_id')
        .select()
        .single();
    return ComprehensionScore.fromMap(data);
  }

  // ------ AI Feedback (teacher) ------
  Future<List<AiFeedback>> getCourseFeedback(String courseId) async {
    final data = await _supabase
        .from('ai_feedback')
        .select('*')
        .eq('course_id', courseId)
        .order('created_at', ascending: false);
    return data.map((e) => AiFeedback.fromMap(e)).toList();
  }

  Future<AiFeedback> createFeedback(AiFeedback feedback) async {
    final data = await _supabase
        .from('ai_feedback')
        .insert(feedback.toMap())
        .select()
        .single();
    return AiFeedback.fromMap(data);
  }

  // ------ Quiz Results (student) ------
  Future<QuizResult> saveQuizResult(QuizResult result) async {
    final data = await _supabase
        .from('quiz_results')
        .insert(result.toMap())
        .select()
        .single();
    return QuizResult.fromMap(data);
  }

  Future<List<QuizResult>> getStudentQuizResults(String studentId) async {
    final data = await _supabase
        .from('quiz_results')
        .select('*')
        .eq('student_id', studentId)
        .order('completed_at', ascending: false);
    return data.map((e) => QuizResult.fromMap(e)).toList();
  }

  Future<List<QuizResult>> getCourseQuizResults(String courseId) async {
    final data = await _supabase
        .from('quiz_results')
        .select('*, profiles!student_id(name)')
        .eq('course_id', courseId)
        .order('completed_at', ascending: false);

    return data.map((e) {
      final result = QuizResult.fromMap(e);
      return result;
    }).toList();
  }

  // ------ Chat Sessions ------
  Future<ChatSession> createChatSession(ChatSession session) async {
    final data = await _supabase
        .from('chat_sessions')
        .insert(session.toMap())
        .select()
        .single();
    return ChatSession.fromMap(data);
  }

  Future<List<ChatSession>> getChatSessions(String userId) async {
    final data = await _supabase
        .from('chat_sessions')
        .select('*')
        .eq('user_id', userId)
        .order('updated_at', ascending: false);
    return data.map((e) => ChatSession.fromMap(e)).toList();
  }

  Future<void> deleteChatSession(String sessionId) async {
    await _supabase.from('chat_sessions').delete().eq('id', sessionId);
  }

  Future<void> updateChatSessionTitle(String sessionId, String title) async {
    await _supabase
        .from('chat_sessions')
        .update({'title': title, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', sessionId);
  }

  // ------ Chat Messages ------
  Future<ChatMessage> createChatMessage(ChatMessage message) async {
    final data = await _supabase
        .from('chat_messages')
        .insert(message.toMap())
        .select()
        .single();
    return ChatMessage.fromMap(data);
  }

  Future<List<ChatMessage>> getChatMessages(String sessionId) async {
    final data = await _supabase
        .from('chat_messages')
        .select('*')
        .eq('session_id', sessionId)
        .order('created_at', ascending: true);
    return data.map((e) => ChatMessage.fromMap(e)).toList();
  }

  // ------ Resource Analysis ------
  Future<ResourceAnalysis?> getResourceAnalysis(String resourceId) async {
    final data = await _supabase
        .from('resource_analysis')
        .select('*')
        .eq('resource_id', resourceId)
        .maybeSingle();
    if (data == null) return null;
    return ResourceAnalysis.fromMap(data);
  }

  // ------ Quiz Analytics (teacher) ------
  Future<QuizAnalytics> getQuizAnalytics(String courseId) async {
    final data = await _supabase
        .from('quiz_results')
        .select('*, profiles!student_id(name)')
        .eq('course_id', courseId)
        .order('completed_at', ascending: false);

    final questionStats = <String, int>{};
    final questionAttempts = <String, int>{};
    final questionData = <String, Map<String, dynamic>>{};
    final studentBest = <String, Map<String, dynamic>>{};

    for (final row in data) {
      final result = QuizResult.fromMap(row);
      final studentName = (row['profiles'] as Map?)?['name'] as String? ?? 'Unknown';

      for (final answer in result.answers) {
        final qIdx = answer['question_index'] as int;
        final selected = answer['selected_index'] as int;

        if (qIdx < result.questions.length) {
          final q = result.questions[qIdx];
          final qText = q['question'] as String;
          final correct = q['correct_index'] as int;

          questionAttempts[qText] = (questionAttempts[qText] ?? 0) + 1;
          questionData[qText] = q;

          if (selected != correct) {
            questionStats[qText] = (questionStats[qText] ?? 0) + 1;
          }
        }
      }

      final sid = result.studentId;
      if (!studentBest.containsKey(sid) || result.score > (studentBest[sid]!['score'] as int)) {
        studentBest[sid] = {
          'studentId': sid,
          'studentName': studentName,
          'score': result.score,
          'totalQuestions': result.totalQuestions,
          'correctAnswers': result.correctAnswers,
          'subject': result.subject,
          'topic': result.topic,
          'completedAt': result.completedAt,
        };
      }
    }

    final difficult = questionData.entries
        .map((e) {
          final wrong = questionStats[e.key] ?? 0;
          final total = questionAttempts[e.key] ?? 1;
          return QuestionDifficulty(
            question: e.key,
            options: (e.value['options'] as List).cast<String>(),
            correctIndex: e.value['correct_index'] as int,
            explanation: e.value['explanation'] as String?,
            wrongCount: wrong,
            totalAttempts: total,
            wrongPercentage: (wrong / total) * 100,
          );
        })
        .toList()
      ..sort((a, b) => b.wrongPercentage.compareTo(a.wrongPercentage));

    final top = studentBest.values
        .map((e) => StudentTopScore(
              studentId: e['studentId'] as String,
              studentName: e['studentName'] as String,
              score: e['score'] as int,
              totalQuestions: e['totalQuestions'] as int,
              correctAnswers: e['correctAnswers'] as int,
              subject: e['subject'] as String,
              topic: e['topic'] as String?,
              completedAt: e['completedAt'] as DateTime,
            ))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return QuizAnalytics(difficultQuestions: difficult, topScores: top);
  }
}
