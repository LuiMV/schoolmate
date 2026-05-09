import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final _supabase = Supabase.instance.client;
  static const _bucket = 'course-resources';

  Future<String> uploadFile(String userId, String courseId, File file) async {
    final path = '$userId/$courseId/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    await _supabase.storage.from(_bucket).upload(path, file);
    final url = _supabase.storage.from(_bucket).getPublicUrl(path);
    return url;
  }

  Future<void> deleteFile(String path) async {
    await _supabase.storage.from(_bucket).remove([path]);
  }
}
