import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/resource_analysis.dart';

class EdgeFunctionService {
  final _supabase = Supabase.instance.client;

  Map<String, dynamic> _parseResponse(FunctionResponse response) {
    if (response.data is String) {
      return jsonDecode(response.data as String) as Map<String, dynamic>;
    }
    return response.data as Map<String, dynamic>;
  }

  Future<ResourceAnalysis> invokeIngestion({
    required String resourceId,
    required String fileText,
    required String title,
  }) async {
    final response = await _supabase.functions.invoke(
      'ai-ingestion',
      body: {
        'resource_id': resourceId,
        'file_text': fileText.substring(0, fileText.length.clamp(0, 30000)),
        'title': title,
      },
      method: HttpMethod.post,
    );

    final data = _parseResponse(response);
    return ResourceAnalysis.fromMap(data);
  }

  Future<String> invokeChat({
    required String sessionId,
    required String message,
    String? resourceId,
    String? subject,
  }) async {
    final response = await _supabase.functions.invoke(
      'ai-chat',
      body: {
        'session_id': sessionId,
        'message': message,
        'resource_id': resourceId,
        'subject': subject,
      },
      method: HttpMethod.post,
    );

    final data = _parseResponse(response);
    return data['response'] as String;
  }
}
