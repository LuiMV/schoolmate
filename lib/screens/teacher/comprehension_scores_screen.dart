import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../models/comprehension_score.dart';
import '../../models/quiz_analytics.dart';
import '../../services/database_service.dart';

class ComprehensionScoresScreen extends StatefulWidget {
  final Course course;
  const ComprehensionScoresScreen({super.key, required this.course});

  @override
  State<ComprehensionScoresScreen> createState() => _ComprehensionScoresScreenState();
}

class _ComprehensionScoresScreenState extends State<ComprehensionScoresScreen> {
  final _dbService = DatabaseService();
  List<ComprehensionScore> _scores = [];
  QuizAnalytics? _analytics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _dbService.getCourseScores(widget.course.id),
      _dbService.getQuizAnalytics(widget.course.id),
    ]);
    if (!mounted) return;
    setState(() {
      _scores = results[0] as List<ComprehensionScore>;
      _analytics = results[1] as QuizAnalytics;
      _isLoading = false;
    });
  }

  Color _scoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scores & Analytics'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildTopScoresSection(),
                  const SizedBox(height: 24),
                  _buildDifficultQuestionsSection(),
                  const SizedBox(height: 24),
                  _buildComprehensionScoresSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final avg = _scores.isEmpty ? 0 : _scores.map((s) => s.score).reduce((a, b) => a + b) ~/ _scores.length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.course.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Grade ${widget.course.grade} · Section ${widget.course.section}',
                    style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _scoreColor(avg).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text('$avg%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _scoreColor(avg))),
                Text('Average', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------ Top Scores ------
  Widget _buildTopScoresSection() {
    final scores = _analytics?.topScores ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: Color(0xFFE65100), size: 22),
            const SizedBox(width: 8),
            Text('Top Quiz Scores', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[800])),
          ],
        ),
        const SizedBox(height: 12),
        if (scores.isEmpty)
          _emptyState('No quiz results yet', Icons.emoji_events_outlined)
        else
          ...scores.take(10).toList().asMap().entries.map((e) => _buildScoreCard(e.value, e.key)),
      ],
    );
  }

  Widget _buildScoreCard(StudentTopScore s, int rank) {
    final medalColors = [const Color(0xFFFFD700), const Color(0xFFC0C0C0), const Color(0xFFCD7F32)];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: rank < 3 ? medalColors[rank].withValues(alpha: 0.2) : Colors.grey[100],
          child: rank < 3
              ? Icon(Icons.emoji_events_rounded, color: medalColors[rank], size: 20)
              : Text('${rank + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[500])),
        ),
        title: Text(s.studentName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text('${s.subject}${s.topic != null ? ' - ${s.topic}' : ''}',
            style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _scoreColor(s.score).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('${s.score}%',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _scoreColor(s.score))),
        ),
      ),
    );
  }

  // ------ Difficult Questions ------
  Widget _buildDifficultQuestionsSection() {
    final questions = _analytics?.difficultQuestions ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 22),
            const SizedBox(width: 8),
            Text('Most Difficult Questions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[800])),
          ],
        ),
        const SizedBox(height: 4),
        Text('Questions with highest wrong-answer rate', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        const SizedBox(height: 12),
        if (questions.isEmpty)
          _emptyState('No quiz data yet', Icons.quiz_outlined)
        else
          ...questions.take(10).map((q) => _buildDifficultyCard(q)),
      ],
    );
  }

  Widget _buildDifficultyCard(QuestionDifficulty q) {
    final pct = q.wrongPercentage.toStringAsFixed(0);
    final color = q.wrongPercentage > 60
        ? Colors.red
        : q.wrongPercentage > 30
            ? Colors.orange
            : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(q.question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, height: 1.3)),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$pct% wrong', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${q.wrongCount} of ${q.totalAttempts} students got this wrong',
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 8),
            ...q.options.asMap().entries.map((e) {
              final isCorrect = e.key == q.correctIndex;
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green.withValues(alpha: 0.08) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isCorrect ? Colors.green : Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(isCorrect ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        size: 16, color: isCorrect ? Colors.green : Colors.grey[400]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(e.value,
                          style: TextStyle(fontSize: 13, color: isCorrect ? Colors.green[800] : Colors.grey[700])),
                    ),
                  ],
                ),
              );
            }),
            if (q.explanation != null && q.explanation!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline_rounded, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 6),
                    Expanded(child: Text(q.explanation!, style: TextStyle(fontSize: 12, color: Colors.blue[800], height: 1.3))),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ------ Comprehension Scores ------
  Widget _buildComprehensionScoresSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.analytics_rounded, color: Color(0xFF1565C0), size: 22),
            const SizedBox(width: 8),
            Text('Comprehension Scores',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[800])),
          ],
        ),
        const SizedBox(height: 12),
        if (_scores.isEmpty)
          _emptyState('No scores recorded yet', Icons.analytics_outlined)
        else
          ..._scores.map((s) => _buildComprehensionCard(s)),
      ],
    );
  }

  Widget _buildComprehensionCard(ComprehensionScore score) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _scoreColor(score.score).withValues(alpha: 0.15),
          child: Text('${score.score}',
              style: TextStyle(fontWeight: FontWeight.bold, color: _scoreColor(score.score))),
        ),
        title: Text(score.studentName ?? 'Student', style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: score.notes != null
            ? Text(score.notes!, style: TextStyle(fontSize: 12, color: Colors.grey[500]))
            : null,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _scoreColor(score.score).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _scoreLabel(score.score),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _scoreColor(score.score)),
          ),
        ),
      ),
    );
  }

  String _scoreLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Needs Work';
    return 'Struggling';
  }

  Widget _emptyState(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text(text, style: TextStyle(fontSize: 15, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}
