import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../models/quiz_result.dart';
import '../../services/ai_service.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

class AiQuizScreen extends StatefulWidget {
  final Course course;
  final String? resourceId;
  const AiQuizScreen({super.key, required this.course, this.resourceId});

  @override
  State<AiQuizScreen> createState() => _AiQuizScreenState();
}

class _AiQuizScreenState extends State<AiQuizScreen> {
  final _dbService = DatabaseService();
  final _authService = AuthService();

  List<QuizQuestion> _questions = [];
  Map<int, int> _answers = {};
  int _currentIndex = 0;
  bool _isGenerating = true;
  bool _isCompleted = false;
  int _score = 0;
  int _correctCount = 0;
  String? _topic;

  @override
  void initState() {
    super.initState();
    _generateQuiz();
  }

  Future<void> _generateQuiz() async {
    if (widget.resourceId != null) {
      final analysis = await _dbService.getResourceAnalysis(widget.resourceId!);
      if (analysis?.quiz != null) {
        final quiz = analysis!.quiz!;
        if (quiz['questions'] is List) {
          final loaded = (quiz['questions'] as List).map((q) {
            final qMap = q as Map<String, dynamic>;
            return QuizQuestion(
              question: qMap['question'] ?? '',
              options: (qMap['options'] as List?)?.cast<String>() ?? [],
              correctIndex: qMap['correct_index'] is int
                  ? qMap['correct_index'] as int
                  : int.tryParse(qMap['correct_index']?.toString() ?? '0') ?? 0,
              explanation: qMap['explanation'],
            );
          }).toList();
          if (loaded.isNotEmpty) {
            if (!mounted) return;
            setState(() {
              _questions = loaded;
              _isGenerating = false;
            });
            return;
          }
        }
      }
    }

    final questions = await AiService.generateQuiz(
      subject: widget.course.subject,
      topic: _topic,
      questionCount: 5,
    );
    if (!mounted) return;
    setState(() {
      _questions = questions;
      _isGenerating = false;
    });
  }

  void _selectAnswer(int index) {
    if (_isCompleted) return;
    setState(() => _answers[_currentIndex] = index);
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  Future<void> _submitQuiz() async {
    int correct = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_answers[i] == _questions[i].correctIndex) {
        correct++;
      }
    }
    final total = _questions.length;
    final score = ((correct / total) * 100).round();

    final user = _authService.currentUser;
    if (user != null) {
      await _dbService.saveQuizResult(QuizResult(
        id: '',
        courseId: widget.course.id,
        studentId: user.id,
        subject: widget.course.subject,
        topic: _topic,
        questions: _questions.asMap().entries.map((e) => {
              'question': e.value.question,
              'options': e.value.options,
              'correct_index': e.value.correctIndex,
              'explanation': e.value.explanation,
            }).toList(),
        answers: _answers.entries.map((e) => {
              'question_index': e.key,
              'selected_index': e.value,
            }).toList(),
        score: score,
        totalQuestions: total,
        correctAnswers: correct,
      ));
    }

    if (!mounted) return;
    setState(() {
      _isCompleted = true;
      _score = score;
      _correctCount = correct;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz: ${widget.course.subject}'),
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isGenerating
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating quiz questions...'),
                ],
              ),
            )
          : _isCompleted
              ? _buildResults()
              : _buildQuiz(),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Question ${_currentIndex + 1} of ${_questions.length}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${_answers.length} answered', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              backgroundColor: Colors.grey[200],
              color: const Color(0xFFE65100),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuiz() {
    final question = _questions[_currentIndex];
    final selected = _answers[_currentIndex];

    return Column(
      children: [
        _buildProgressBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE65100).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE65100).withValues(alpha: 0.15)),
                  ),
                  child: Text(question.question,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.4)),
                ),
                const SizedBox(height: 20),
                ...List.generate(question.options.length, (i) => _buildOption(i, question.options[i], selected)),
              ],
            ),
          ),
        ),
        _buildNavigation(),
      ],
    );
  }

  Widget _buildOption(int index, String text, int? selected) {
    final isSelected = selected == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _selectAnswer(index),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE65100).withValues(alpha: 0.08) : Colors.grey[50],
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? const Color(0xFFE65100) : Colors.grey[200]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE65100) : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isSelected ? null : Border.all(color: Colors.grey[400]!),
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + index),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
              if (isSelected) const Icon(Icons.check_circle, color: Color(0xFFE65100), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigation() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          if (_currentIndex > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousQuestion,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Previous'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            )
          else
            const Spacer(),
          if (_currentIndex < _questions.length - 1) ...[
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _answers.containsKey(_currentIndex) ? _nextQuestion : null,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Next'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _answers.length == _questions.length ? _submitQuiz : null,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Submit'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResults() {
    final grade = _score >= 80
        ? 'Excellent!'
        : _score >= 60
            ? 'Good Job!'
            : _score >= 40
                ? 'Keep Practicing'
                : 'Needs Improvement';

    final gradeColor = _score >= 80
        ? Colors.green
        : _score >= 60
            ? Colors.orange
            : Colors.red;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gradeColor.withValues(alpha: 0.1),
              ),
              child: Icon(Icons.emoji_events_rounded, size: 48, color: gradeColor),
            ),
            const SizedBox(height: 24),
            Text(grade, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: gradeColor)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text('$_score%', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: gradeColor)),
                  const SizedBox(height: 8),
                  Text('$_correctCount of ${_questions.length} correct', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isCompleted = false;
                    _isGenerating = true;
                    _answers = {};
                    _currentIndex = 0;
                    _score = 0;
                    _correctCount = 0;
                  });
                  _generateQuiz();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Courses'),
            ),
          ],
        ),
      ),
    );
  }
}
