import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'teacher/teacher_dashboard_screen.dart';
import 'student/student_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  String _userRole = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _authService.getProfile();
    if (!mounted) return;
    setState(() {
      _userRole = profile?['role'] as String? ?? '';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userRole == 'Teacher') {
      return const TeacherDashboardScreen();
    }

    return const StudentDashboardScreen();
  }
}
