import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.isError = false,
  }) : timestamp = timestamp ?? DateTime.now();
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String? explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] ?? '',
      options: (json['options'] as List).cast<String>(),
      correctIndex: json['correct_index'] ?? 0,
      explanation: json['explanation'],
    );
  }
}

class AiService {
  static const _defaultKey = 'YOUR_API_KEY';
  static const _defaultUrl = 'https://api.openai.com/v1/chat/completions';

  static String apiKey = _defaultKey;
  static String apiUrl = _defaultUrl;
  static String model = 'gpt-3.5-turbo';

  static void configure({
    String? key,
    String? url,
    String? modelName,
  }) {
    if (key != null) apiKey = key;
    if (url != null) apiUrl = url;
    if (modelName != null) model = modelName;
  }

  static final Map<String, String> _subjectContexts = {
    'Mathematics':
        'You are a math tutor for high school students. Explain concepts clearly with examples.',
    'Science':
        'You are a science tutor for high school students. Provide clear explanations and real-world examples.',
    'English':
        'You are an English language and literature tutor. Help with grammar, writing, and analysis.',
    'History':
        'You are a history tutor. Provide accurate historical context and analysis.',
    'default':
        'You are a helpful tutor for high school students. Give clear, age-appropriate explanations.',
  };

  static Future<String> chat(String message, {String? subject}) async {
    if (apiKey == _defaultKey) {
      return _mockChat(message, subject: subject);
    }

    try {
      final systemPrompt =
          _subjectContexts[subject] ?? _subjectContexts['default']!;
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': message},
          ],
          'max_tokens': 1000,
        }),
      );

      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    } catch (e) {
      return _mockChat(message, subject: subject);
    }
  }

  static Future<List<QuizQuestion>> generateQuiz({
    required String subject,
    String? topic,
    int questionCount = 5,
  }) async {
    if (apiKey == _defaultKey) {
      return _mockQuiz(subject, topic, questionCount);
    }

    final prompt =
        'Generate $questionCount multiple-choice questions for $subject'
        '${topic != null ? ' on topic: $topic' : ''}. '
        'Return ONLY valid JSON array with each object having: '
        'question (string), options (array of 4 strings), correct_index (int 0-3), explanation (string). '
        'Do NOT include markdown formatting.';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {
              'role': 'system',
              'content': 'You are a quiz generator. Return only valid JSON.'
            },
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 2000,
        }),
      );

      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'] as String;
      final cleaned =
          content.replaceAll(RegExp(r'```json|```'), '').trim();
      final List list = jsonDecode(cleaned);
      return list
          .map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return _mockQuiz(subject, topic, questionCount);
    }
  }

  // ---- Mock fallback ----
  static String _mockChat(String message, {String? subject}) {
    final msg = message.toLowerCase();
    if (msg.contains('hello') || msg.contains('hi') || msg.contains('hola')) {
      return 'Hello! I\'m your ${subject ?? 'subject'} tutor. How can I help you today?';
    }
    if (msg.contains('derivative') || msg.contains('calculus')) {
      return 'Great question about calculus! The derivative measures how a function changes as its input changes. '
          'For f(x) = x², f\'(x) = 2x. Think of it as the slope at any point on a curve. '
          'Would you like more examples?';
    }
    if (msg.contains('photosynthesis')) {
      return 'Photosynthesis is where plants convert light into chemical energy. '
          'Equation: 6CO₂ + 6H₂O → C₆H₁₂O₆ + 6O₂. It happens in chloroplasts.';
    }
    if (msg.contains('gravity') || msg.contains('newton')) {
      return 'Newton\'s Law: F = G(m₁m₂)/r². Every mass attracts every other mass with force '
          'proportional to their masses and inversely proportional to distance squared.';
    }
    return 'That\'s an interesting question about ${subject ?? 'your subject'}! '
        'Let me help you understand it step by step. '
        'The key is to first grasp the fundamentals. Would you like me to break this down further?';
  }

  static List<QuizQuestion> _mockQuiz(String subject, String? topic, int count) {
    final rng = Random();
    final all = <QuizQuestion>[
      QuizQuestion(
        question: 'What is the derivative of x²?',
        options: ['x', '2x', '2', 'x²'],
        correctIndex: 1,
        explanation: 'Power rule: d/dx(xⁿ) = nxⁿ⁻¹, so d/dx(x²) = 2x',
      ),
      QuizQuestion(
        question: 'What is π to 2 decimal places?',
        options: ['3.14', '3.16', '3.12', '3.18'],
        correctIndex: 0,
        explanation: 'π ≈ 3.14159..., so to 2 d.p. it is 3.14',
      ),
      QuizQuestion(
        question: 'Solve: 2x + 5 = 13',
        options: ['x = 4', 'x = 6', 'x = 3', 'x = 5'],
        correctIndex: 0,
        explanation: '2x + 5 = 13 → 2x = 8 → x = 4',
      ),
      QuizQuestion(
        question: 'Area of triangle with base 6 and height 4?',
        options: ['24', '12', '10', '48'],
        correctIndex: 1,
        explanation: 'Area = ½ × 6 × 4 = 12',
      ),
      QuizQuestion(
        question: 'What is the chemical symbol for water?',
        options: ['H₂O', 'CO₂', 'NaCl', 'O₂'],
        correctIndex: 0,
        explanation: 'Water: 2 hydrogen + 1 oxygen = H₂O',
      ),
      QuizQuestion(
        question: 'Which planet is known as the Red Planet?',
        options: ['Venus', 'Jupiter', 'Mars', 'Saturn'],
        correctIndex: 2,
        explanation: 'Mars appears red due to iron oxide on its surface',
      ),
    ];
    all.shuffle(rng);
    return all.take(count.clamp(1, all.length)).toList();
  }
}
