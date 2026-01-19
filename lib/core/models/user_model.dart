import 'package:private_4t_app/core/models/user_address_model.dart';
import 'package:private_4t_app/core/models/user_profile_model.dart';

class UserModel {
  int? id;
  String? name;
  String? username;
  String? email;
  String? imageUrl;
  String? address;
  String? phone;
  String matrixUserSupportId;
  bool isExistingCustomer;
  UserProfileModel? profile;
  UserAddressModel? mapAddress;

  UserModel({
    this.id,
    this.name,
    this.username,
    this.email,
    this.imageUrl,
    this.phone,
    this.address,
    this.profile,
    this.mapAddress,
    this.matrixUserSupportId = 'support',
    this.isExistingCustomer = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'photo_url': imageUrl,
      'phone': phone,
      'address': address,
      'matrix_user_support_id': matrixUserSupportId,
      'is_existing_customer': isExistingCustomer,
      'profile': profile?.toJson(),
      'map_address': mapAddress?.toJson(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> map) {
    return UserModel(
      id: int.parse("${map['id'] ?? 0}"),
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      imageUrl: map['photo_url'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      matrixUserSupportId: map['matrix_user_support_id'] ?? 'support',
      profile: map['profile'] != null
          ? UserProfileModel.fromJson(map['profile'])
          : null,
      mapAddress: map['map_address'] != null
          ? UserAddressModel.fromJson(map['map_address'])
          : null,
      isExistingCustomer: map['is_existing_customer'] ?? false,
    );
  }
}
