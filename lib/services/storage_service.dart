import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/resource.dart';

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

  /// Returns the download URL for a resource.
  /// For URL-type resources, returns the stored URL directly.
  /// For file-type resources, returns the Supabase Storage public URL.
  String getDownloadUrl(Resource resource) {
    if (resource.type == 'url' && resource.url != null) {
      return resource.url!;
    }
    return resource.url ?? '';
  }
}
