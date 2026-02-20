import 'package:private_4t_app/core/models/lms_step_model.dart';

class LmsLessonModel {
  final int id;
  final int courseId;
  final int order;
  final String name;
  final String slug;
  final DateTime? deletedAt;

  final List<LmsStepModel>? steps;

  LmsLessonModel({
    required this.id,
    required this.courseId,
    required this.order,
    required this.name,
    required this.slug,
    this.steps,
    this.deletedAt,
  });

  factory LmsLessonModel.fromJson(Map<String, dynamic> json) {
    return LmsLessonModel(
      id: json['id'],
      courseId: json['course_id'],
      order: json['order'],
      name: json['name'],
      slug: json['slug'],
      steps: json['steps'] != null
          ? List<LmsStepModel>.from(
              json['steps'].map((x) => LmsStepModel.fromJson(x)))
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'order': order,
      'name': name,
      'slug': slug,
      'deleted_at': deletedAt?.toIso8601String(),
      'steps': steps?.map((x) => x.toJson()).toList(),
    };
  }
}
