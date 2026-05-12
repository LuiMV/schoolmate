import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final _supabase = Supabase.instance.client;
  static const _bucket = 'course-resources';

  Future<String> uploadFile(String userId, String courseId, Uint8List bytes, String fileName) async {
    final path = '$userId/$courseId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _supabase.storage.from(_bucket).uploadBinary(path, bytes);
    final url = _supabase.storage.from(_bucket).getPublicUrl(path);
    return url;
  }

  Future<void> deleteFile(String path) async {
    await _supabase.storage.from(_bucket).remove([path]);
  }
}
