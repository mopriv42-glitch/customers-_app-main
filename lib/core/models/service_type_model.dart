class ServiceTypeModel {
  final int? id;
  final String? serviceType;

  ServiceTypeModel({
    required this.id,
    required this.serviceType,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_type': serviceType,
    };
  }

  factory ServiceTypeModel.fromJson(Map<String, dynamic> map) {
    return ServiceTypeModel(
        id: map['id'] ?? 0, serviceType: map['service_type'] ?? '');
  }
}
