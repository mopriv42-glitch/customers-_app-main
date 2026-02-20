import 'package:private_4t_app/core/models/governorate_model.dart';
import 'package:private_4t_app/core/models/grade_model.dart';
import 'package:private_4t_app/core/models/region_model.dart';

class UserProfileModel {
  int id;
  int userId;
  int? governorateId;
  int? regionId;
  int? workPlaceId;
  int? gradeId;
  String? address;
  String? state;
  int? moodleUserId;
  String? platform; // 'private', 'castle', 'none' or null
  GovernorateModel? governorate;
  RegionModel? region;
  dynamic workPlace;
  GradeModel? grade;

  UserProfileModel({
    required this.id,
    required this.userId,
    this.governorateId,
    this.regionId,
    this.workPlaceId,
    this.gradeId,
    this.address,
    this.state,
    this.moodleUserId,
    this.platform,
    this.governorate,
    this.region,
    this.workPlace,
    this.grade,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'],
      userId: json['user_id'],
      governorateId: json['governorate_id'],
      regionId: json['region_id'],
      workPlaceId: json['work_place_id'],
      gradeId: json['grade_id'],
      address: json['address'],
      state: json['state'],
      moodleUserId: json['moodle_user_id'],
      platform: json['platform'],
      governorate: json['governorate'] != null
          ? GovernorateModel.fromJson(json['governorate'])
          : null,
      region: json['region'] != null
          ? RegionModel.fromJson(json['region'])
          : null,
      workPlace: json['work_place'],
      grade: json['grade'] != null ? GradeModel.fromJson(json['grade']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'governorate_id': governorateId,
      'region_id': regionId,
      'work_place_id': workPlaceId,
      'grade_id': gradeId,
      'address': address,
      'state': state,
      'moodle_user_id': moodleUserId,
      'platform': platform,
      'governorate': governorate?.toJson(),
      'region': region?.toJson(),
      'work_place': workPlace,
      'grade': grade?.toJson(),
    };
  }
}
