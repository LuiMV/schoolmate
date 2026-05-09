import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course.dart';
import '../models/resource.dart';
import '../models/comprehension_score.dart';
import '../models/ai_feedback.dart';
import '../models/quiz_result.dart';

class DatabaseService {
  final _supabase = Supabase.instance.client;

  // ------ Teacher: Courses ------
  Future<List<Course>> getTeacherCourses(String teacherId) async {
    final data = await _supabase
        .from('courses')
        .select('*')
        .eq('teacher_id', teacherId)
        .order('created_at', ascending: false);
    return data.map((e) => Course.fromMap(e)).toList();
  }

  Future<Course> createCourse(Course course) async {
    final data = await _supabase
        .from('courses')
        .insert(course.toMap())
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
}
