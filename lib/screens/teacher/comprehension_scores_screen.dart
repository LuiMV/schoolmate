import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../models/comprehension_score.dart';
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final scores = await _dbService.getCourseScores(widget.course.id);
    if (!mounted) return;
    setState(() {
      _scores = scores;
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
        title: const Text('Comprehension Scores'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  color: const Color(0xFF1565C0).withValues(alpha: 0.05),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.course.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Grade ${widget.course.grade} · Section ${widget.course.section}', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      _buildStatBadge('Avg', _scores.isEmpty ? 0 : _scores.map((s) => s.score).reduce((a, b) => a + b) ~/ _scores.length),
                    ],
                  ),
                ),
                if (_scores.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text('No scores recorded yet', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _scores.length,
                      itemBuilder: (_, i) => _buildScoreCard(_scores[i]),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildStatBadge(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _scoreColor(value).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text('$value%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _scoreColor(value))),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildScoreCard(ComprehensionScore score) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _scoreColor(score.score).withValues(alpha: 0.15),
          child: Text('${score.score}', style: TextStyle(fontWeight: FontWeight.bold, color: _scoreColor(score.score))),
        ),
        title: Text(score.studentName ?? 'Student', style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: score.notes != null ? Text(score.notes!, style: TextStyle(fontSize: 12, color: Colors.grey[500])) : null,
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
}
