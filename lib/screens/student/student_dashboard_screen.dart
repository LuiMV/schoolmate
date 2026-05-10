import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/course.dart';
import '../login_screen.dart';
import 'course_materials_screen.dart';
import 'ai_assistant_screen.dart';
import 'ai_quiz_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final _authService = AuthService();
  final _dbService = DatabaseService();
  List<Course> _courses = [];
  String _userName = '';
  String _grade = '';
  String _section = '';
  String _studentId = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await _authService.getProfile();
    if (!mounted || profile == null) return;

    final grade = profile['grade'] as String? ?? '';
    final section = profile['section'] as String? ?? '';
    final studentId = profile['id'] as String? ?? '';

    final enrolledCourses = await _dbService.getEnrolledCourses(studentId);
    final gradeCourses = await _dbService.getStudentCourses(grade, section);

    final merged = <String, Course>{};
    for (final c in enrolledCourses) {
      merged[c.id] = c;
    }
    for (final c in gradeCourses) {
      merged.putIfAbsent(c.id, () => c);
    }

    if (!mounted) return;
    setState(() {
      _userName = profile['name'] as String? ?? 'Student';
      _grade = grade;
      _section = section;
      _studentId = studentId;
      _courses = merged.values.toList();
      _isLoading = false;
    });
  }

  Future<void> _showJoinDialog() async {
    final codeCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join a Course'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: codeCtrl,
            maxLength: 6,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 24, letterSpacing: 6, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              labelText: 'Enter 6-digit code',
              hintText: '000000',
              counterText: '',
            ),
            validator: (v) {
              if (v == null || v.trim().length != 6) return 'Enter a valid 6-digit code';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final code = codeCtrl.text.trim();
    final course = await _dbService.getCourseByInviteCode(code);

    if (!mounted) return;

    if (course == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid code. No course found.')),
      );
      return;
    }

    try {
      await _dbService.joinCourse(course.id, _studentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joined "${course.name}" successfully!')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You are already in this course.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key_rounded),
            tooltip: 'Join by Code',
            onPressed: _showJoinDialog,
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded),
            tooltip: 'AI Assistant',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AiAssistantScreen(subjects: _courses.map((c) => c.subject).toSet().toList()),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () async {
              await AuthService().logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SafeArea(
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    Expanded(child: _buildCourseList()),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              _userName.isNotEmpty ? _userName[0].toUpperCase() : 'S',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hi, $_userName!', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Grade $_grade · Section $_section', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text('Student', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseList() {
    if (_courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined, size: 72, color: Colors.white.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('No courses available yet', style: TextStyle(fontSize: 18, color: Colors.white.withValues(alpha: 0.7))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _courses.length,
      itemBuilder: (_, i) => _buildCourseCard(_courses[i]),
    );
  }

  Widget _buildCourseCard(Course course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CourseMaterialsScreen(course: course)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_subjectIcon(course.subject), color: const Color(0xFF1565C0), size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(course.subject, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    if (course.description != null && course.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(course.description!, style: TextStyle(fontSize: 12, color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.auto_awesome_rounded, size: 20, color: Color(0xFF7B1FA2)),
                    tooltip: 'Ask AI',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AiAssistantScreen(subjects: [course.subject], initialSubject: course.subject),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.quiz_rounded, size: 20, color: Color(0xFFE65100)),
                    tooltip: 'Take Quiz',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AiQuizScreen(course: course),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _subjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'math':
        return Icons.calculate_rounded;
      case 'science':
        return Icons.biotech_rounded;
      case 'english':
        return Icons.menu_book_rounded;
      case 'history':
        return Icons.history_rounded;
      default:
        return Icons.school_rounded;
    }
  }
}
