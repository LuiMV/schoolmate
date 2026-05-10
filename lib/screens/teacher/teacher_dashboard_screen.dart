import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/course.dart';
import '../login_screen.dart';
import 'course_detail_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final _authService = AuthService();
  final _dbService = DatabaseService();
  List<Course> _courses = [];
  bool _isLoading = true;
  String _teacherId = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = _authService.currentUser;
    if (user == null) return;
    setState(() {
      _teacherId = user.id;
      _isLoading = true;
    });
    final courses = await _dbService.getTeacherCourses(user.id);
    if (!mounted) return;
    setState(() {
      _courses = courses;
      _isLoading = false;
    });
  }

  Future<void> _showCreateDialog() async {
    final nameCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    final gradeCtrl = TextEditingController();
    final sectionCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Course'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Course Name', hintText: 'e.g. Algebra I'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: subjectCtrl,
                  decoration: const InputDecoration(labelText: 'Subject', hintText: 'e.g. Mathematics'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: gradeCtrl,
                        decoration: const InputDecoration(labelText: 'Grade', hintText: 'e.g. 10'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: sectionCtrl,
                        decoration: const InputDecoration(labelText: 'Section', hintText: 'e.g. A'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description (optional)'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final course = Course(
      id: '',
      teacherId: _teacherId,
      name: nameCtrl.text.trim(),
      subject: subjectCtrl.text.trim(),
      grade: gradeCtrl.text.trim(),
      section: sectionCtrl.text.trim().toUpperCase(),
      description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
    );

    Course? created;
    try {
      created = await _dbService.createCourse(course);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating course: $e'), backgroundColor: Colors.red),
      );
      return;
    }
    _load();

    if (!mounted || created == null || created.inviteCode == null) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Course Created!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share this code with your students:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    created!.inviteCode!,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: created!.inviteCode!));
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Code copied!')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        backgroundColor: const Color.fromARGB(255, 120, 166, 164),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _courses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.school_outlined, size: 72, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No courses yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Text('Tap + to create your first course', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _courses.length,
                    itemBuilder: (_, i) => _buildCourseCard(_courses[i]),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 48, 118, 13),
        foregroundColor: Colors.white,
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _deleteCourse(Course course) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text('Are you sure you want to delete "${course.name}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _dbService.deleteCourse(course.id);
    _load();
  }

  Widget _buildCourseCard(Course course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CourseDetailScreen(course: course)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFE65100).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu_book_rounded, color: Color(0xFFE65100)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      '${course.subject}  ·  Grade ${course.grade}-${course.section}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    if (course.inviteCode != null) ...[
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: course.inviteCode!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Code copied!'), duration: Duration(seconds: 1)),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.vpn_key_rounded, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              'Code: ${course.inviteCode}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.copy_rounded, size: 14, color: Colors.grey[400]),
                          ],
                        ),
                      ),
                    ],
                    if (course.description != null && course.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(course.description!, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Delete course',
                onPressed: () => _deleteCourse(course),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
