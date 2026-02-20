class GradeModel {
  final int? id;
  final String? grade;
  final int? educationId;

  GradeModel({
    required this.id,
    required this.grade,
    required this.educationId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grade': grade,
      'education_id': educationId,
    };
  }

  factory GradeModel.fromJson(Map<String, dynamic> map) {
    return GradeModel(
      id: map['id'] ?? 0,
      grade: map['grade'] ?? '',
      educationId: map['education_id'] ?? 0,
    );
  }
}
