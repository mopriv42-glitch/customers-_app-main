import 'learning_course_model.dart';

class CourseCategoryModel {
  final int id;
  final String name;
  final String? slug;
  final String? description;
  final int? parentId;
  final bool isActive;
  final int? order;
  final String? icon;
  final String? color;

  final CourseCategoryModel? parent;
  final List<CourseCategoryModel> children;
  final List<LearningCourseModel> courses;

  CourseCategoryModel({
    required this.id,
    required this.name,
    this.slug,
    this.description,
    this.parentId,
    this.isActive = true,
    this.order,
    this.icon,
    this.color,
    this.parent,
    this.children = const [],
    this.courses = const [],
  });

  factory CourseCategoryModel.fromJson(Map<String, dynamic> json) {
    return CourseCategoryModel(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'],
      parentId: json['parent_id'],
      isActive: json['is_active'] ?? false,
      order: json['order'],
      icon: json['icon'],
      color: json['color'],
      parent: json['parent'] != null
          ? CourseCategoryModel.fromJson(json['parent'])
          : null,
      children: json['children'] != null
          ? List<CourseCategoryModel>.from(
          json['children'].map((c) => CourseCategoryModel.fromJson(c)))
          : [],
      courses: json['courses'] != null
          ? List<LearningCourseModel>.from(
          json['courses'].map((c) => LearningCourseModel.fromJson(c)))
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "slug": slug,
      "description": description,
      "parent_id": parentId,
      "is_active": isActive,
      "order": order,
      "icon": icon,
      "color": color,
      "parent": parent?.toJson(),
      "children": children.map((e) => e.toJson()).toList(),
      "courses": courses.map((e) => e.toJson()).toList(),
    };
  }

  /// Get full path like "Parent > Child > This"
  String get fullPath {
    if (parent == null) return name;
    return "${parent!.fullPath} > $name";
  }
}