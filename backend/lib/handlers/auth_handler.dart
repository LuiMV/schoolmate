import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:jose/jose.dart';
import 'package:crypto/crypto.dart';
import 'package:bcrypt/bcrypt.dart';
import '../models/user_model.dart';

class AuthHandler {
  static const _issuer = 'schoolmate-backend';

  String get _secret {
    const defaultSecret = 'schoolmate_jwt_secret_change_in_production';
    return const String.fromEnvironment('JWT_SECRET', defaultValue: defaultSecret);
  }

  JsonWebKey _signingKey() {
    final hash = sha256.convert(utf8.encode(_secret));
    return JsonWebKey.fromJson({
      'kty': 'oct',
      'k': base64Url.encode(hash.bytes),
    });
  }

  Future<Response> login(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final email = (body['email'] as String?)?.trim().toLowerCase();
      final password = body['password'] as String?;
      final role = body['role'] as String?;

      if (email == null || password == null || role == null) {
        return Response.badRequest(
          body: jsonEncode({'message': 'Email, password, and role are required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (role != 'Student' && role != 'Teacher') {
        return Response.badRequest(
          body: jsonEncode({'message': 'Role must be Student or Teacher'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final user = await UserModel.findByEmail(email);
      if (user == null) {
        return Response.unauthorized(jsonEncode({'message': 'Invalid email or password'}));
      }

      if (!BCrypt.checkpw(password, user.passwordHash)) {
        return Response.unauthorized(jsonEncode({'message': 'Invalid email or password'}));
      }

      if (user.role != role) {
      return Response.unauthorized(jsonEncode({'message': 'Invalid email or password'}));
      }

      final token = _generateToken(email, role);

      return Response.ok(
        jsonEncode({'token': token, 'user': user.toPublicMap()}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'message': 'Internal server error'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> register(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final email = (body['email'] as String?)?.trim().toLowerCase();
      final password = body['password'] as String?;
      final role = body['role'] as String?;
      final name = (body['name'] as String?)?.trim();

      if (email == null || password == null || role == null || name == null) {
        return Response.badRequest(
          body: jsonEncode({'message': 'All fields are required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (role != 'Student' && role != 'Teacher') {
        return Response.badRequest(
          body: jsonEncode({'message': 'Role must be Student or Teacher'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (await UserModel.emailExists(email)) {
        return Response.badRequest(
          body: jsonEncode({'message': 'An account with this email already exists'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      String? studentId, grade, section;
      String? employeeId, department, subjects;

      if (role == 'Student') {
        studentId = (body['studentId'] as String?)?.trim();
        grade = (body['grade'] as String?)?.trim();
        section = (body['section'] as String?)?.trim();
        if (studentId == null || grade == null || section == null) {
          return Response.badRequest(
            body: jsonEncode({'message': 'Student ID, grade, and section are required'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
        if (await UserModel.studentIdExists(studentId)) {
          return Response.badRequest(
            body: jsonEncode({'message': 'Student ID already exists'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
      } else {
        employeeId = (body['employeeId'] as String?)?.trim();
        department = (body['department'] as String?)?.trim();
        subjects = (body['subjects'] as String?)?.trim();
        if (employeeId == null || department == null || subjects == null) {
          return Response.badRequest(
            body: jsonEncode({'message': 'Employee ID, department, and subjects are required'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
        if (await UserModel.employeeIdExists(employeeId)) {
          return Response.badRequest(
            body: jsonEncode({'message': 'Employee ID already exists'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
      }

      final passwordHash = BCrypt.hashpw(password, BCrypt.gensalt());

      final user = UserModel(
        name: name,
        email: email,
        passwordHash: passwordHash,
        role: role,
        studentId: studentId,
        grade: grade,
        section: section,
        employeeId: employeeId,
        department: department,
        subjects: subjects,
      );

      final created = await UserModel.create(user);
      final token = _generateToken(email, role);

      return Response.ok(
        jsonEncode({'token': token, 'user': created.toPublicMap()}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'message': 'Internal server error'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> me(Request request) async {
    final authHeader = request.headers['authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response.unauthorized(jsonEncode({'message': 'Invalid email or password'}));
    }

    try {
      final token = authHeader.substring(7);
      final payload = await _verifyToken(token);
      final email = payload['email'] as String;

      final user = await UserModel.findByEmail(email);
      if (user == null) {
      return Response.unauthorized(jsonEncode({'message': 'Role does not match this account'}));
      }

      return Response.ok(
        jsonEncode({'user': user.toPublicMap()}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.unauthorized(jsonEncode({'message': 'Invalid or expired token'}));
    }
  }

  String _generateToken(String email, String role) {
    final builder = JsonWebSignatureBuilder()
      ..jsonContent = {
        'sub': email,
        'email': email,
        'role': role,
        'iss': _issuer,
        'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'exp':
            DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch ~/ 1000,
      }
      ..addRecipient(_signingKey(), algorithm: 'HS256');

    return builder.build().toCompactSerialization();
  }

  Future<Map<String, dynamic>> _verifyToken(String token) async {
    final jws = JsonWebSignature.fromCompactSerialization(token);
    final key = _signingKey();
    final keyStore = JsonWebKeyStore()..addKey(key);
    final payload = await jws.getPayload(keyStore);
    return payload.jsonContent as Map<String, dynamic>;
  }
}
