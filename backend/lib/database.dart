import 'package:mongo_dart/mongo_dart.dart';

class Database {
  static Database? _instance;
  late final Db _db;

  Database._();

  static Database get instance {
    _instance ??= Database._();
    return _instance!;
  }

  Future<void> connect(String uri) async {
    _db = await Db.create(uri);
    await _db.open();
    await _ensureIndexes();
  }

  Db get db => _db;

  Future<void> close() async {
    await _db.close();
  }

  Future<void> _ensureIndexes() async {
    final users = _db.collection('users');
    await users.createIndex(key: 'email', unique: true);
    await users.createIndex(key: 'studentId', unique: true, sparse: true);
    await users.createIndex(key: 'employeeId', unique: true, sparse: true);
    await users.createIndex(key: 'role');
  }
}
