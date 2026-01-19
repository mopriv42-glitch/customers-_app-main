import 'package:private_4t_app/core/models/item_coupon_model.dart';

/// Represents a discount coupon.
class CouponModel {
  /// Unique identifier for the coupon.
  final int? id;

  /// Unique code for the coupon.
  final String? code;

  /// Description of the coupon.
  final String? description;

  /// Fixed amount discount (in smallest currency unit, e.g., cents).
  final double? amountOff;

  /// Percentage discount.
  final int? percentOff;

  /// Maximum total times this coupon can be used.
  final int? maxUses;

  /// Number of times this coupon has been used.
  final int? timesUsed;

  /// Maximum times a single user can use this coupon.
  final int? maxUsesPerUser;

  /// JSON defining which products/categories the coupon applies to.
  /// Type depends on API structure (Map, List, String).
  final dynamic appliesToJson;

  /// When the coupon becomes valid.
  final DateTime? startsAt;

  /// When the coupon expires.
  final DateTime? endsAt;

  /// Whether this coupon can be combined with others.
  final bool? isStackable;

  /// ID of the user/admin who created the coupon.
  final int? createdBy;

  // Add timestamps if needed and exposed by your API
  // final DateTime? createdAt;
  // final DateTime? updatedAt;

  // --- Relationships (if included in API response) ---
  // final List<CouponRedemption>? redemptions; // HasMany
  final List<ItemCouponModel>? itemCoupons; // HasMany

  CouponModel({
    this.id,
    this.code,
    this.description,
    this.amountOff,
    this.percentOff,
    this.maxUses,
    this.timesUsed,
    this.maxUsesPerUser,
    this.appliesToJson,
    this.startsAt,
    this.endsAt,
    this.isStackable,
    this.createdBy,
    // this.redemptions,
    this.itemCoupons,
    // this.createdAt,
    // this.updatedAt,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id'] as int?,
      code: json['code'] as String?,
      description: json['description'] as String?,
      amountOff: json['amount_off'] as double?,
      percentOff: json['percent_off'] as int?,
      maxUses: json['max_uses'] as int?,
      timesUsed: json['times_used'] as int?,
      maxUsesPerUser: json['max_uses_per_user'] as int?,
      appliesToJson: json['applies_to_json'], // Handle as dynamic based on API
      startsAt:
          json['starts_at'] != null ? DateTime.parse(json['starts_at']) : null,
      endsAt: json['ends_at'] != null ? DateTime.parse(json['ends_at']) : null,
      isStackable: json['is_stackable'] == 1 ? true : false,
      createdBy: json['created_by'] as int?,
      // redemptions: (json['redemptions'] as List?)
      //     ?.map((e) => CouponRedemption.fromJson(e as Map<String, dynamic>))
      //     .toList(),
      itemCoupons: (json['item_coupons'] as List?)
          ?.map((e) => ItemCouponModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      // createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      // updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'description': description,
      'amount_off': amountOff,
      'percent_off': percentOff,
      'max_uses': maxUses,
      'times_used': timesUsed,
      'max_uses_per_user': maxUsesPerUser,
      'applies_to_json':
          appliesToJson, // Serialize dynamic as is, or convert if needed
      'starts_at': startsAt?.toIso8601String(),
      'ends_at': endsAt?.toIso8601String(),
      'is_stackable': isStackable,
      'created_by': createdBy,
      // 'redemptions': redemptions?.map((e) => e.toJson()).toList(),
      // 'item_coupons': itemCoupons?.map((e) => e.toJson()).toList(),
      // 'created_at': createdAt?.toIso8601String(),
      // 'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
