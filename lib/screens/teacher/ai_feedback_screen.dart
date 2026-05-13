import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../models/ai_feedback.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../services/edge_function_service.dart';

class AiFeedbackScreen extends StatefulWidget {
  final Course course;
  const AiFeedbackScreen({super.key, required this.course});

  @override
  State<AiFeedbackScreen> createState() => _AiFeedbackScreenState();
}

class _AiFeedbackScreenState extends State<AiFeedbackScreen> {
  final _dbService = DatabaseService();
  final _authService = AuthService();
  final _requestCtrl = TextEditingController();
  List<AiFeedback> _feedbacks = [];
  bool _isLoading = true;
  String _selectedType = 'resource_analysis';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _requestCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final feedbacks = await _dbService.getCourseFeedback(widget.course.id);
    if (!mounted) return;
    setState(() {
      _feedbacks = feedbacks;
      _isLoading = false;
    });
  }

  Future<void> _requestFeedback() async {
    if (_requestCtrl.text.trim().isEmpty) return;

    final user = _authService.currentUser;
    if (user == null) return;

    final requestText = _requestCtrl.text.trim();
    _requestCtrl.clear();
    setState(() => _isLoading = true);

    try {
      final prompt = _selectedType == 'resource_analysis'
          ? 'As a teaching assistant, analyze this request about course resources for ${widget.course.name} (${widget.course.subject}): $requestText'
          : 'As a teaching assistant, analyze these common student difficulties for ${widget.course.name} (${widget.course.subject}): $requestText';

      final responseText = await EdgeFunctionService().invokeChat(
        sessionId: '', // teacher feedback uses one-off calls without session
        message: prompt,
        subject: widget.course.subject,
      );

      final feedback = AiFeedback(
        id: '',
        courseId: widget.course.id,
        teacherId: user.id,
        feedbackType: _selectedType,
        requestText: requestText,
        responseText: responseText,
      );

      await _dbService.createFeedback(feedback);
    } catch (e) {
      final feedback = AiFeedback(
        id: '',
        courseId: widget.course.id,
        teacherId: user.id,
        feedbackType: _selectedType,
        requestText: requestText,
        responseText: 'Error generating AI response: $e',
      );
      await _dbService.createFeedback(feedback);
    }

    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Feedback'),
        backgroundColor: const Color(0xFF7B1FA2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  color: const Color(0xFF7B1FA2).withValues(alpha: 0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.course.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTypeChip('resource_analysis', 'Analyze Resources'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTypeChip('common_difficulties', 'Common Difficulties'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _requestCtrl,
                          decoration: InputDecoration(
                            hintText: _selectedType == 'resource_analysis'
                                ? 'Ask about a resource or topic...'
                                : 'Describe common issues...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            isDense: true,
                          ),
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _requestCtrl.text.trim().isEmpty ? null : _requestFeedback,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7B1FA2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Icon(Icons.send_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Text('Previous Feedback', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                      const Spacer(),
                      if (_feedbacks.isNotEmpty)
                        Text('${_feedbacks.length} requests', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                ),
                if (_feedbacks.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text('No AI feedback requested yet', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
                          const SizedBox(height: 4),
                          Text('Ask about resources or student difficulties', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _feedbacks.length,
                      itemBuilder: (_, i) => _buildFeedbackCard(_feedbacks[i]),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildTypeChip(String type, String label) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7B1FA2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? const Color(0xFF7B1FA2) : Colors.grey[300]!),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(AiFeedback feedback) {
    final isAnalysis = feedback.feedbackType == 'resource_analysis';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isAnalysis ? Icons.analytics_rounded : Icons.help_outline_rounded, size: 18, color: const Color(0xFF7B1FA2)),
                const SizedBox(width: 8),
                Text(
                  isAnalysis ? 'Resource Analysis' : 'Common Difficulties',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const Spacer(),
                Text(
                  _formatDate(feedback.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
            if (feedback.requestText != null && feedback.requestText!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(feedback.requestText!, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
              ),
            ],
            if (feedback.responseText != null && feedback.responseText!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(feedback.responseText!, style: TextStyle(fontSize: 13, height: 1.4)),
            ] else ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.hourglass_empty, size: 14, color: Colors.orange[700]),
                    const SizedBox(width: 6),
                    Text('Processing...', style: TextStyle(fontSize: 12, color: Colors.orange[700])),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
