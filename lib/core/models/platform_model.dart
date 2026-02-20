class PlatformModel {
  final int id;
  final String name;
  final String code;

  PlatformModel({required this.id, required this.name, required this.code});

  factory PlatformModel.fromJson(Map<String, dynamic> json) {
    return PlatformModel(id: json['id'] ?? 0, name: json['name'] ?? '', code: json['code'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "code": code,
    };
  }
}
