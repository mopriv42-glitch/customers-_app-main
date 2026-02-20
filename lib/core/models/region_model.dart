import 'package:private_4t_app/core/models/governorate_model.dart';

class RegionModel {
  final int id;
  final String region;
  final int governorateId;
  final GovernorateModel? governorate;

  RegionModel({
    required this.id,
    required this.region,
    required this.governorateId,
    required this.governorate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'region': region,
      'governorate_id': governorateId,
      'governorate': governorate?.toJson(),
    };
  }

  factory RegionModel.fromJson(Map<String, dynamic> map) {
    return RegionModel(
      id: map['id'],
      region: map['region'],
      governorateId: map['governorate_id'] ?? 0,
      governorate: map['governorate'] != null
          ? GovernorateModel.fromJson(map['governorate'])
          : null,
    );
  }
}
