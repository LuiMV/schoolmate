import '../models/chat_session.dart';
import '../models/chat_message.dart';
import 'database_service.dart';
import 'edge_function_service.dart';

class ChatService {
  final _db = DatabaseService();
  final _edge = EdgeFunctionService();

  Future<ChatSession> createSession({
    required String userId,
    String? courseId,
    String? resourceId,
    String? subject,
    String? title,
  }) async {
    final session = ChatSession(
      id: '',
      userId: userId,
      courseId: courseId,
      resourceId: resourceId,
      subject: subject,
      title: title,
    );
    return await _db.createChatSession(session);
  }

  Future<List<ChatSession>> getSessions(String userId) async {
    return await _db.getChatSessions(userId);
  }

  Future<List<ChatMessage>> getMessages(String sessionId) async {
    return await _db.getChatMessages(sessionId);
  }

  Future<String> sendMessage({
    required String sessionId,
    required String content,
    String? resourceId,
    String? subject,
  }) async {
    final response = await _edge.invokeChat(
      sessionId: sessionId,
      message: content,
      resourceId: resourceId,
      subject: subject,
    );

    await _db.createChatMessage(
      ChatMessage(
        id: '',
        sessionId: sessionId,
        role: 'user',
        content: content,
      ),
    );

    await _db.createChatMessage(
      ChatMessage(
        id: '',
        sessionId: sessionId,
        role: 'assistant',
        content: response,
      ),
    );

    return response;
  }

  Future<void> deleteSession(String sessionId) async {
    await _db.deleteChatSession(sessionId);
  }

  Future<void> updateSessionTitle(String sessionId, String title) async {
    await _db.updateChatSessionTitle(sessionId, title);
  }
}
