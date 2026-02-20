import 'package:private_4t_app/core/models/cart_item_model.dart';
import 'package:private_4t_app/core/models/coupon_model.dart';
import 'package:private_4t_app/core/models/user_model.dart';

/// Represents a user's shopping cart.
class CartModel {
  /// Unique identifier for the cart.
  final int? id;

  /// ID of the user who owns the cart (nullable for guest carts).
  final int? userId;

  /// Token identifying the cart, especially for guest users.
  final String? token;

  /// Timestamp indicating when the cart expires.
  final DateTime? expiresAt;

  /// Timestamp indicating when the cart was archived (soft delete).
  final DateTime? archivedAt;

  /// ID of the coupon applied to the cart.
  final int? couponId;

  // --- Relationships (often included in API responses) ---
  /// List of items in the cart.
  final List<CartItemModel>? items;

  /// The user who owns the cart.
  final UserModel? user; // BelongsTo

  /// The coupon applied to the cart.
  final CouponModel? coupon; // BelongsTo

  CartModel({
    this.id,
    this.userId,
    this.token,
    this.expiresAt,
    this.archivedAt,
    this.couponId,
    this.items,
    this.user,
    this.coupon,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      id: json['id'] as int?,
      userId: json['user_id'] as int?,
      token: json['token'] as String?,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      archivedAt: json['archived_at'] != null
          ? DateTime.parse(json['archived_at'])
          : null,
      couponId: json['coupon_id'] as int?,
      items: (json['items'] as List?)
          ?.map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      coupon: json['coupon'] != null
          ? CouponModel.fromJson(json['coupon'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'token': token,
      'expires_at': expiresAt?.toIso8601String(),
      'archived_at': archivedAt?.toIso8601String(),
      'coupon_id': couponId,
      'items': items?.map((e) => e.toJson()).toList(),
      'user': user?.toJson(),
      'coupon': coupon?.toJson(),
    };
  }

  // --- Business Logic (Translated from Laravel methods) ---

  /// Calculates the subtotal of all cart items.
  /// Assumes items and their lineTotal are already loaded/fetched.
  num subtotal() {
    // Ensure items are not null and sum their lineTotal
    return (items ?? [])
        .map((item) => item.lineTotal ?? 0)
        .fold(0, (sum, element) => sum + element);
  }

  /// Calculates the total discount applied by the cart's coupon.
  /// Assumes the coupon is already loaded/fetched.
  num discountTotal() {
    final CouponModel? c = coupon;
    if (c == null) return 0;

    final base = subtotal();

    if (c.amountOff != null) {
      // Laravel uses min(amount_off, base)
      return (c.amountOff! < base) ? c.amountOff! : base;
    } else if (c.percentOff != null) {
      // Laravel uses intdiv(base * percent_off, 100)
      // intdiv performs integer division towards zero
      double discountValue =
          double.tryParse(((base * c.percentOff!) / 100).toStringAsFixed(3)) ??
              (base * c.percentOff!) / 100; // ~/ is integer division in Dart
      return discountValue;
    } else {
      return 0;
    }
  }

  /// Calculates the final total after applying the discount.
  num grandTotal() {
    return subtotal() - discountTotal();
  }

  /// Checks if the cart is considered active (not archived).
  bool get isActive {
    return archivedAt == null;
  }
}
