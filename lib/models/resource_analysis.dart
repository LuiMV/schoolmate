class ResourceAnalysis {
  final String id;
  final String resourceId;
  final String? summary;
  final String? fullText;
  final Map<String, dynamic>? metadata;
  final List<String>? tags;
  final List<Map<String, String>>? flashcards;
  final Map<String, dynamic>? quiz;
  final DateTime createdAt;
  final DateTime updatedAt;

  ResourceAnalysis({
    required this.id,
    required this.resourceId,
    this.summary,
    this.fullText,
    this.metadata,
    this.tags,
    this.flashcards,
    this.quiz,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory ResourceAnalysis.fromMap(Map<String, dynamic> map) {
    return ResourceAnalysis(
      id: map['id'] ?? '',
      resourceId: map['resource_id'] ?? '',
      summary: map['summary'],
      fullText: map['full_text'],
      metadata: map['metadata'] is Map ? Map<String, dynamic>.from(map['metadata']) : null,
      tags: map['tags'] is List ? (map['tags'] as List).cast<String>() : null,
      flashcards: map['flashcards'] is List
          ? (map['flashcards'] as List)
              .map((e) => Map<String, String>.from(e as Map))
              .toList()
          : null,
      quiz: map['quiz'] is Map ? Map<String, dynamic>.from(map['quiz']) : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'resource_id': resourceId,
        'summary': summary,
        'full_text': fullText,
        'metadata': metadata,
        'tags': tags,
        'flashcards': flashcards,
        'quiz': quiz,
      };
}
