import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  Future<User> login(String email, String password, String role) async {
    final authResponse = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = authResponse.user!;

    final profileRes = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();

    final Map<String, dynamic> profileData =
        Map<String, dynamic>.from(profileRes);

    if (profileData['role'] != role) {
      await _supabase.auth.signOut();
      throw Exception('El rol seleccionado no coincide con esta cuenta');
    }

    return user;
  }

  Future<User> register({
    required String email,
    required String password,
    required String role,
    required String name,
    String? studentId,
    String? grade,
    String? section,
    String? employeeId,
    String? department,
    String? subjects,
  }) async {
    final authResponse = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = authResponse.user!;

    await _supabase.from('profiles').insert({
      'id': user.id,
      'name': name,
      'role': role,
      if (role == 'Student') ...{
        'student_id': studentId,
        'grade': grade,
        'section': section,
      },
      if (role == 'Teacher') ...{
        'employee_id': employeeId,
        'department': department,
        'subjects': subjects,
      },
    });

    return user;
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final res = await _supabase
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .single();

    return Map<String, dynamic>.from(res);
  }

  Future<String?> getRole() async {
    final profile = await getProfile();
    return profile?['role'] as String?;
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  bool get isLoggedIn => _supabase.auth.currentUser != null;

  User? get currentUser => _supabase.auth.currentUser;
}
