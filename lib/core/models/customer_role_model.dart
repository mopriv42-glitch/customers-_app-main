class CustomerRoleModel {
  final int id;
  final String role;

  CustomerRoleModel({required this.id, required this.role});

  factory CustomerRoleModel.fromJson(Map<String, dynamic> json) {
    return CustomerRoleModel(id: json['id'] ?? 0, role: json['role'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "role": role,
    };
  }
}
