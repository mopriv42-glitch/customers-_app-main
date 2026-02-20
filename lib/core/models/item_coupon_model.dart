/// Represents a specific application of a coupon to a cart item.
class ItemCouponModel {
  /// Unique identifier for the item-coupon link.
  final int? id;

  /// ID of the coupon being applied.
  final int? couponId;

  /// The type of the related item model (e.g., 'CartItem').
  final String? itemType;

  /// The ID of the related item model instance.
  final int? itemId;

  /// The specific discount amount applied by this coupon to the item.
  /// This might be calculated or set explicitly.
  final int? discount;

  // Add timestamps if needed and exposed by your API
  // final DateTime? createdAt;
  // final DateTime? updatedAt;

  // --- Relationships (if included in API response) ---
  // The actual related 'item' (CartItem, etc.) would be dynamic based on itemType/itemId
  // final dynamic item; // You would deserialize this based on itemType if included
  // final Coupon? coupon; // BelongsTo relationship

  ItemCouponModel({
    this.id,
    this.couponId,
    this.itemType,
    this.itemId,
    this.discount,
    // this.item,
    // this.coupon,
    // this.createdAt,
    // this.updatedAt,
  });

  factory ItemCouponModel.fromJson(Map<String, dynamic> json) {
    return ItemCouponModel(
      id: json['id'] as int?,
      couponId: json['coupon_id'] as int?,
      itemType: json['item_type'] as String?,
      itemId: json['item_id'] as int?,
      discount: json['discount'] as int?,
      // item: json['item'] != null ? /* Deserialize based on itemType */ : null,
      // coupon: json['coupon'] != null ? Coupon.fromJson(json['coupon'] as Map<String, dynamic>) : null,
      // createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      // updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coupon_id': couponId,
      'item_type': itemType,
      'item_id': itemId,
      'discount': discount,
      // 'item': item, // Serialize item if needed and possible
      // 'coupon': coupon?.toJson(),
      // 'created_at': createdAt?.toIso8601String(),
      // 'updated_at': updatedAt?.toIso8601String(),
    };
  }
}