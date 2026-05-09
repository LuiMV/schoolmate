class Resource {
  final String id;
  final String courseId;
  final String teacherId;
  final String title;
  final String type;
  final String? url;
  final String? filePath;
  final String? fileName;
  final DateTime createdAt;

  Resource({
    required this.id,
    required this.courseId,
    required this.teacherId,
    required this.title,
    required this.type,
    this.url,
    this.filePath,
    this.fileName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Resource.fromMap(Map<String, dynamic> map) {
    return Resource(
      id: map['id'] ?? '',
      courseId: map['course_id'] ?? '',
      teacherId: map['teacher_id'] ?? '',
      title: map['title'] ?? '',
      type: map['type'] ?? '',
      url: map['url'],
      filePath: map['file_path'],
      fileName: map['file_name'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'course_id': courseId,
        'teacher_id': teacherId,
        'title': title,
        'type': type,
        'url': url,
        'file_path': filePath,
        'file_name': fileName,
      };

  IconType get iconType {
    switch (type) {
      case 'document':
        return IconType.document;
      case 'video':
        return IconType.video;
      case 'image':
        return IconType.image;
      case 'url':
        return IconType.url;
      default:
        return IconType.document;
    }
  }
}

enum IconType { document, video, image, url }
