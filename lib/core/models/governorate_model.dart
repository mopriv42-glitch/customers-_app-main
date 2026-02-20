class GovernorateModel {
  final int? id;
  final String? governorate;

  GovernorateModel({
    required this.id,
    required this.governorate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'governorate': governorate,
    };
  }

  factory GovernorateModel.fromJson(Map<String, dynamic> map) {
    return GovernorateModel(
        id: map['id'] ?? 0, governorate: map['governorate'] ?? '');
  }
}
