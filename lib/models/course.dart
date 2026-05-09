class Course {
  final String id;
  final String teacherId;
  final String name;
  final String? description;
  final String subject;
  final String grade;
  final String section;
  final DateTime createdAt;

  Course({
    required this.id,
    required this.teacherId,
    required this.name,
    this.description,
    required this.subject,
    required this.grade,
    required this.section,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] ?? '',
      teacherId: map['teacher_id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      subject: map['subject'] ?? '',
      grade: map['grade'] ?? '',
      section: map['section'] ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'teacher_id': teacherId,
        'name': name,
        'description': description,
        'subject': subject,
        'grade': grade,
        'section': section,
      };
}
