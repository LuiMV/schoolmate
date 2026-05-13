import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/chat_session.dart';
import '../../models/chat_message.dart';
import '../../services/chat_service.dart';

class AiAssistantScreen extends StatefulWidget {
  final List<String> subjects;
  final String? initialSubject;
  final String? resourceTitle;
  final String? resourceType;
  final String? resourceUrl;
  final String? courseId;
  final String? resourceId;

  const AiAssistantScreen({
    super.key,
    required this.subjects,
    this.initialSubject,
    this.resourceTitle,
    this.resourceType,
    this.resourceUrl,
    this.courseId,
    this.resourceId,
  });

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _chatService = ChatService();
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<ChatMessage> _messages = [];
  List<ChatSession> _sessions = [];
  bool _isLoading = true;
  bool _isSending = false;
  String _selectedSubject = '';
  ChatSession? _activeSession;

  @override
  void initState() {
    super.initState();
    _selectedSubject = widget.initialSubject ?? (widget.subjects.isNotEmpty ? widget.subjects.first : '');
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final userId = Supabase.instance.client.auth.currentUser!.id;

    if (widget.resourceTitle != null) {
      final session = await _chatService.createSession(
        userId: userId,
        courseId: widget.courseId,
        resourceId: widget.resourceId,
        subject: _selectedSubject,
        title: 'Chat: ${widget.resourceTitle}',
      );
      _activeSession = session;
      await _loadMessages();
    } else {
      _sessions = await _chatService.getSessions(userId);
      if (_sessions.isEmpty) {
        final session = await _chatService.createSession(
          userId: userId,
          subject: _selectedSubject,
        );
        _activeSession = session;
        await _loadMessages();
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _loadMessages() async {
    if (_activeSession == null) return;
    final msgs = await _chatService.getMessages(_activeSession!.id);
    if (!mounted) return;
    setState(() => _messages..clear()..addAll(msgs));
    _scrollToBottom();
  }

  Future<void> _startNewChat() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final session = await _chatService.createSession(
      userId: userId,
      courseId: widget.courseId,
      resourceId: widget.resourceId,
      subject: _selectedSubject,
      title: widget.resourceTitle != null ? 'Chat: ${widget.resourceTitle}' : 'New Chat',
    );
    if (!mounted) return;
    setState(() {
      _activeSession = session;
      _messages.clear();
    });
  }

  Future<void> _selectSession(ChatSession session) async {
    setState(() {
      _activeSession = session;
      _messages.clear();
      _isLoading = true;
    });
    await _loadMessages();
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  void _backToSessions() {
    setState(() {
      _activeSession = null;
      _messages.clear();
      _isLoading = true;
    });
    _load();
  }

  Future<void> _deleteSession(ChatSession session) async {
    await _chatService.deleteSession(session.id);
    if (!mounted) return;
    setState(() => _sessions.removeWhere((s) => s.id == session.id));
    if (_activeSession?.id == session.id) {
      _backToSessions();
    }
  }

  Future<void> _renameSession(ChatSession session) async {
    final ctrl = TextEditingController(text: session.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename Chat'),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(hintText: 'Chat title')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (newTitle != null && newTitle.isNotEmpty) {
      await _chatService.updateSessionTitle(session.id, newTitle);
      if (!mounted) return;
      setState(() {
        final idx = _sessions.indexWhere((s) => s.id == session.id);
        if (idx >= 0) {
          _sessions[idx] = ChatSession(
            id: session.id, userId: session.userId, title: newTitle,
            courseId: session.courseId, resourceId: session.resourceId,
            subject: session.subject, createdAt: session.createdAt, updatedAt: session.updatedAt,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty || _activeSession == null) return;

    setState(() {
      _messages.add(ChatMessage(id: '', sessionId: _activeSession!.id, role: 'user', content: text));
      _isSending = true;
    });
    _messageCtrl.clear();

    try {
      final response = await _chatService.sendMessage(
        sessionId: _activeSession!.id,
        content: text,
        resourceId: widget.resourceId,
        subject: _selectedSubject,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(id: '', sessionId: _activeSession!.id, role: 'assistant', content: response));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(id: '', sessionId: _activeSession!.id, role: 'assistant', content: 'Error: ${e.toString()}', metadata: {'isError': true}));
      });
    }

    if (!mounted) return;
    setState(() => _isSending = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activeSession == null ? _buildSessionList() : _buildChatView(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (_activeSession != null) {
      return AppBar(
        leading: _activeSession == null ? null : IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _backToSessions,
        ),
        title: Text(_activeSession!.title, overflow: TextOverflow.ellipsis),
        backgroundColor: const Color(0xFF7B1FA2),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.subjects.length > 1 && _activeSession == null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.subject_rounded),
              tooltip: 'Change subject',
              onSelected: (s) => setState(() => _selectedSubject = s),
              itemBuilder: (_) => widget.subjects.map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
            ),
        ],
      );
    }

    return AppBar(
      title: const Text('AI Assistant'),
      backgroundColor: const Color(0xFF7B1FA2),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        if (widget.subjects.length > 1)
          PopupMenuButton<String>(
            icon: const Icon(Icons.subject_rounded),
            tooltip: 'Change subject',
            onSelected: (s) => setState(() => _selectedSubject = s),
            itemBuilder: (_) => widget.subjects.map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
          ),
      ],
    );
  }

  Widget _buildSessionList() {
    return Column(
      children: [
        if (widget.resourceTitle != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF7B1FA2).withValues(alpha: 0.08),
            child: Row(
              children: [
                const Icon(Icons.description_rounded, size: 16, color: Color(0xFF7B1FA2)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(widget.resourceTitle!, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF7B1FA2)), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        if (widget.subjects.isNotEmpty && widget.resourceTitle == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF7B1FA2).withValues(alpha: 0.08),
            child: Row(
              children: [
                const Icon(Icons.school_rounded, size: 16, color: Color(0xFF7B1FA2)),
                const SizedBox(width: 8),
                Text('Subject: $_selectedSubject', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF7B1FA2))),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startNewChat,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B1FA2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
        if (_sessions.isEmpty)
          Expanded(child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text('No chat sessions yet', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
              ],
            ),
          ))
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _sessions.length,
              itemBuilder: (_, i) => _buildSessionCard(_sessions[i]),
            ),
          ),
      ],
    );
  }

  Widget _buildSessionCard(ChatSession session) {
    final now = DateTime.now();
    final diff = now.difference(session.updatedAt);
    String timeAgo;
    if (diff.inMinutes < 1) {
      timeAgo = 'Just now';
    } else if (diff.inMinutes < 60) {
      timeAgo = '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      timeAgo = '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      timeAgo = '${diff.inDays}d ago';
    } else {
      timeAgo = '${session.updatedAt.month}/${session.updatedAt.day}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF7B1FA2).withValues(alpha: 0.1),
          child: const Icon(Icons.chat_rounded, color: Color(0xFF7B1FA2), size: 22),
        ),
        title: Text(session.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${session.subject ?? 'General'}  ·  $timeAgo', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'rename') _renameSession(session);
            if (v == 'delete') _deleteSession(session);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'rename', child: Text('Rename')),
            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
          ],
        ),
        onTap: () => _selectSession(session),
      ),
    );
  }

  Widget _buildChatView() {
    return Column(
      children: [
        Expanded(child: _buildMessageList()),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _buildMessageBubble(_messages[i]),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.role == 'user';
    final isError = msg.metadata?['isError'] == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF7B1FA2).withValues(alpha: 0.15),
              child: const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFF7B1FA2)),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isError ? Colors.red[50] : isUser ? const Color(0xFF1565C0) : Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isUser ? const Radius.circular(18) : Radius.zero,
                  bottomRight: isUser ? Radius.zero : const Radius.circular(18),
                ),
              ),
              child: Text(
                msg.content,
                style: TextStyle(
                  fontSize: 14,
                  color: isError ? Colors.red[900] : isUser ? Colors.white : Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageCtrl,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: widget.resourceTitle != null
                    ? 'Ask about "${widget.resourceTitle}"...'
                    : 'Ask anything about $_selectedSubject...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF7B1FA2),
            child: IconButton(
              icon: _isSending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: _isSending ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
