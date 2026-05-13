import 'package:flutter/material.dart';
import '../../models/resource_analysis.dart';

class FlashcardsScreen extends StatefulWidget {
  final ResourceAnalysis analysis;
  const FlashcardsScreen({super.key, required this.analysis});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final List<Map<String, String>> _cards = [];
  int _currentIndex = 0;
  bool _isRevealed = false;

  @override
  void initState() {
    super.initState();
    if (widget.analysis.flashcards != null) {
      _cards.addAll(widget.analysis.flashcards!.map((e) => Map<String, String>.from(e)));
    }
  }

  void _next() {
    if (_currentIndex < _cards.length - 1) {
      setState(() {
        _currentIndex++;
        _isRevealed = false;
      });
    }
  }

  void _previous() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _isRevealed = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Flashcards'), backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
        body: const Center(child: Text('No flashcards available')),
      );
    }

    final card = _cards[_currentIndex];
    final progress = '${_currentIndex + 1} of ${_cards.length}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(progress, style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                SizedBox(
                  width: 120,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (_currentIndex + 1) / _cards.length,
                      backgroundColor: Colors.grey[200],
                      color: const Color(0xFF2E7D32),
                      minHeight: 6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isRevealed = !_isRevealed),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    key: ValueKey(_isRevealed),
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: _isRevealed ? const Color(0xFF2E7D32).withValues(alpha: 0.06) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isRevealed ? const Color(0xFF2E7D32) : Colors.grey[300]!,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isRevealed ? Icons.lightbulb_rounded : Icons.help_outline_rounded,
                          size: 40,
                          color: _isRevealed ? const Color(0xFF2E7D32) : Colors.grey[400],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _isRevealed ? card['answer'] ?? '' : card['question'] ?? '',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: _isRevealed ? 18 : 20,
                            fontWeight: FontWeight.w600,
                            color: _isRevealed ? const Color(0xFF2E7D32) : Colors.black87,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _isRevealed ? 'Tap to see question' : 'Tap to reveal answer',
                          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _currentIndex > 0 ? _previous : null,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Previous'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _currentIndex < _cards.length - 1 ? _next : null,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Next'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
