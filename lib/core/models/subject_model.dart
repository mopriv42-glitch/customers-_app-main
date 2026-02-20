class SubjectModel {
  final int? id;
  final String? subject;

  SubjectModel({
    required this.id,
    required this.subject,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
    };
  }

  factory SubjectModel.fromJson(Map<String, dynamic> map) {
    return SubjectModel(
        id: map['id'] ?? 0, subject: map['subject'] ?? '');
  }
}
