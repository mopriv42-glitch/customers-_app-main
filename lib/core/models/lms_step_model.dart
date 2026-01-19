class LmsStepModel {
  final int id;
  final int lessonId;
  final int order;
  final String name;
  final String slug;
  final int? materialId;
  final String? materialType;
  final String? description;
  final String sourceUrl;
  final Map<String, dynamic>? settings;
  final DateTime? deletedAt;

  LmsStepModel({
    required this.id,
    required this.lessonId,
    required this.order,
    required this.name,
    required this.slug,
    required this.sourceUrl,
    this.materialId,
    this.materialType,
    this.description,
    this.settings,
    this.deletedAt,
  });

  factory LmsStepModel.fromJson(Map<String, dynamic> json) {
    return LmsStepModel(
      id: json['id'],
      lessonId: json['lesson_id'],
      order: json['order'],
      name: json['name'],
      slug: json['slug'],
      sourceUrl: json['source_url'] ?? '',
      materialId: json['material_id'],
      materialType: json['material_type'],
      description: json['description'],
      settings: json['settings'],
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lesson_id': lessonId,
      'order': order,
      'name': name,
      'slug': slug,
      'material_id': materialId,
      'material_type': materialType,
      'description': description,
      'source_url': sourceUrl,
      'settings': settings,
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  /// Computed Property (similar to getIsFreeAttribute)
  bool get isFree {
    return settings?['is_free'] ?? false;
  }

  /// Helper: Get material type name
  String get materialTypeName {
    switch (materialType) {
      case 'App\\\\Models\\\\LmsVideo':
      case 'App\\Models\\LmsVideo':
        return 'Video';
      case 'App\\\\Models\\\\LmsDocument':
      case 'App\\Models\\LmsDocument':
        return 'Document';
      case 'App\\\\Models\\\\LmsLink':
      case 'App\\Models\\LmsLink':
        return 'Link';
      case 'App\\\\Models\\\\LmsPage':
      case 'App\\Models\\LmsPage':
        return 'Page';
      case 'App\\\\Models\\\\LmsQuiz':
      case 'App\\Models\\LmsQuiz':
        return 'Quiz';
      default:
        return 'Unknown';
    }
  }

  /// Helper: Get material type icon class
  String get materialTypeIcon {
    switch (materialType) {
      case 'App\\\\Models\\\\LmsVideo':
      case 'App\\Models\\LmsVideo':
        return 'fas fa-video';
      case 'App\\\\Models\\\\LmsDocument':
      case 'App\\Models\\LmsDocument':
        return 'fas fa-file-alt';
      case 'App\\\\Models\\\\LmsLink':
      case 'App\\Models\\LmsLink':
        return 'fas fa-link';
      case 'App\\\\Models\\\\LmsPage':
      case 'App\\Models\\LmsPage':
        return 'fas fa-file-signature';
      case 'App\\\\Models\\\\LmsQuiz':
      case 'App\\Models\\LmsQuiz':
        return 'fas fa-question-circle';
      default:
        return 'fas fa-question';
    }
  }

  /// Helper: Get material type color
  String get materialTypeColor {
    switch (materialType) {
      case 'App\\\\Models\\\\LmsVideo':
      case 'App\\Models\\LmsVideo':
        return 'primary';
      case 'App\\\\Models\\\\LmsDocument':
      case 'App\\Models\\LmsDocument':
        return 'info';
      case 'App\\\\Models\\\\LmsLink':
      case 'App\\Models\\LmsLink':
        return 'success';
      case 'App\\\\Models\\\\LmsPage':
      case 'App\\Models\\LmsPage':
        return 'warning';
      case 'App\\\\Models\\\\LmsQuiz':
      case 'App\\Models\\LmsQuiz':
        return 'danger';
      default:
        return 'secondary';
    }
  }
}
