import 'package:mongo_dart/mongo_dart.dart';
import '../database.dart';

class UserModel {
  final String? id;
  final String name;
  final String email;
  final String passwordHash;
  final String role;
  final String? studentId;
  final String? grade;
  final String? section;
  final String? employeeId;
  final String? department;
  final String? subjects;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.role,
    this.studentId,
    this.grade,
    this.section,
    this.employeeId,
    this.department,
    this.subjects,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'email': email,
      'passwordHash': passwordHash,
      'role': role,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
    if (studentId != null) {
      map.addAll({'studentId': studentId, 'grade': grade, 'section': section});
    }
    if (employeeId != null) {
      map.addAll({
        'employeeId': employeeId,
        'department': department,
        'subjects': subjects,
      });
    }
    return map;
  }

  Map<String, dynamic> toPublicMap() {
    final map = <String, dynamic>{
      'name': name,
      'email': email,
      'role': role,
    };
    if (studentId != null) {
      map.addAll({'studentId': studentId, 'grade': grade, 'section': section});
    }
    if (employeeId != null) {
      map.addAll({
        'employeeId': employeeId,
        'department': department,
        'subjects': subjects,
      });
    }
    return map;
  }

  static UserModel fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['_id']?.toString(),
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      passwordHash: map['passwordHash'] ?? '',
      role: map['role'] ?? '',
      studentId: map['studentId'],
      grade: map['grade'],
      section: map['section'],
      employeeId: map['employeeId'],
      department: map['department'],
      subjects: map['subjects'],
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt']
          : DateTime.parse(map['createdAt'].toString()),
      updatedAt: map['updatedAt'] is DateTime
          ? map['updatedAt']
          : DateTime.parse(map['updatedAt'].toString()),
    );
  }

  static DbCollection get _users =>
      Database.instance.db.collection('users');

  static Future<UserModel?> findByEmail(String email) async {
    final doc = await _users.findOne(where.eq('email', email));
    return doc != null ? UserModel.fromMap(doc) : null;
  }

  static Future<bool> emailExists(String email) async {
    final count = await _users.count(where.eq('email', email));
    return count > 0;
  }

  static Future<bool> studentIdExists(String studentId) async {
    final count = await _users.count(where.eq('studentId', studentId));
    return count > 0;
  }

  static Future<bool> employeeIdExists(String employeeId) async {
    final count = await _users.count(where.eq('employeeId', employeeId));
    return count > 0;
  }

  static Future<UserModel> create(UserModel user) async {
    final map = user.toMap();
    map.remove('_id');
    await _users.insertOne(map);
    return UserModel.fromMap(map);
  }
}
