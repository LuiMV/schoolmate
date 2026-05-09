import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:dotenv/dotenv.dart';
import '../lib/database.dart';
import '../lib/handlers/auth_handler.dart';

Middleware corsMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok(
          null,
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization',
          },
        );
      }

      final response = await innerHandler(request);
      return response.change(headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      });
    };
  };
}

Future<void> main() async {
  final env = DotEnv()..load();

  final mongoUri = env['MONGODB_URI'] ?? 'mongodb://localhost:27017/schoolmate';
  await Database.instance.connect(mongoUri);
  print('Connected to MongoDB');

  final authHandler = AuthHandler();

  final router = Router()
    ..post('/api/auth/login', authHandler.login)
    ..post('/api/auth/register', authHandler.register)
    ..get('/api/auth/me', authHandler.me);

  final handler = Pipeline()
      .addMiddleware(corsMiddleware())
      .addMiddleware(logRequests())
      .addHandler(router);

  final ip = InternetAddress.anyIPv4;
  final port = int.parse(Platform.environment['PORT'] ?? env['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);

  print('SchoolMate backend running at http://${server.address.host}:${server.port}');
}
