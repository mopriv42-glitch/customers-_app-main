import 'package:private_4t_app/core/models/governorate_model.dart';
import 'package:private_4t_app/core/models/region_model.dart';

class UserAddressModel {
  int? regionId;
  int? governorateId;
  String? blockNumber;
  String? areaNumber;
  String? houseNumber;
  String? streetNumber;
  String? address;

  GovernorateModel? governorate;
  RegionModel? region;

  UserAddressModel({
    this.regionId,
    this.governorateId,
    this.blockNumber,
    this.areaNumber,
    this.houseNumber,
    this.streetNumber,
    this.address,
    this.governorate,
    this.region,
  });

  factory UserAddressModel.fromJson(Map<String, dynamic> json) {
    return UserAddressModel(
      regionId: json['region_id'],
      governorateId: json['governorate_id'],
      blockNumber: json['block_number'],
      areaNumber: json['area_number'],
      houseNumber: json['building_number'],
      streetNumber: json['street_number'],
      address: json['address'],
      governorate: json['governorate'] != null
          ? GovernorateModel.fromJson(json['governorate'])
          : null,
      region:
          json['region'] != null ? RegionModel.fromJson(json['region']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'region_id': regionId,
      'governorate_id': governorateId,
      'block_number': blockNumber,
      'area_number': areaNumber,
      'building_number': houseNumber,
      'street_number': streetNumber,
      'address': address,
      'governorate': governorate?.toJson(),
      'region': region?.toJson(),
    };
  }
}
