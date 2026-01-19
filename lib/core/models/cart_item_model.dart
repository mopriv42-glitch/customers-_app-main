import 'package:flutter/material.dart';
import 'package:private_4t_app/core/models/cart_model.dart';
import 'package:private_4t_app/core/models/customer_booking_model.dart';
import 'package:private_4t_app/core/models/item_coupon_model.dart';
import 'package:private_4t_app/core/models/learning_course_model.dart';

/// Represents an item within a shopping cart.
class CartItemModel {
  /// Unique identifier for the cart item.
  final int? id;

  /// Name of the item.
  final String? name;

  /// ID of the cart this item belongs to.
  final int? cartId;

  /// JSON representation of selected options for the item.
  /// Type depends on API structure (Map, List, String).
  final dynamic optionSetJson;

  /// ID of the related model (e.g., Product ID, Course ID).
  final int? modelId;

  /// Type of the related model (e.g., 'App\\Models\\Product').
  final String? modelType;

  /// Quantity of this item in the cart.
  final int? qty;

  /// Price per unit of the item.
  /// Assuming stored in smallest currency unit (e.g., cents).
  final int? unitPrice;

  /// Total price for this line item (qty * unitPrice).
  /// Assuming stored in smallest currency unit.
  final int? lineTotal;

  /// Timestamp indicating when the item was hidden (soft delete for line items).
  final DateTime? hiddenAt;

  // --- Relationships (if included in API response) ---
  /// The cart this item belongs to.
  final CartModel? cart; // BelongsTo

  /// Coupons specifically applied to this cart item.
  final List<ItemCouponModel>?
      coupons; // MorphMany (assuming API provides them)

  // Note: The 'model' relationship (MorphTo) is dynamic.
  // The actual related object (Product, Course, etc.) would need
  // specific handling based on modelType and modelId, or be included
  // directly in the API response under a specific key.
  final dynamic model;

  CartItemModel({
    this.id,
    this.name,
    this.cartId,
    this.optionSetJson,
    this.modelId,
    this.modelType,
    this.qty,
    this.unitPrice,
    this.lineTotal,
    this.hiddenAt,
    this.cart,
    this.coupons,
    this.model,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    dynamic deserializedModel;
    final modelType = json['model_type'] as String?;

    debugPrint(json['model'].toString());

    if (modelType != null) {
      if (modelType.contains('CustomerBooking')) {
        deserializedModel = json['model'] != null
            ? CustomerBookingModel.fromJson(json['model'])
            : null;
      } else if (modelType.contains('LearningCourse')) {
        deserializedModel = json['model'] != null
            ? LearningCourseModel.fromJson(json['model'])
            : null;
      }
    }

    return CartItemModel(
      id: json['id'] as int?,
      name: json['name'] as String?,
      cartId: json['cart_id'] as int?,
      optionSetJson: json['option_set_json'],
      // Handle as dynamic based on API
      modelId: json['model_id'] as int?,
      modelType: json['model_type'] as String?,
      qty: json['qty'] as int?,
      unitPrice: json['unit_price'] as int?,
      lineTotal: json['line_total'] as int?,
      hiddenAt:
          json['hidden_at'] != null ? DateTime.parse(json['hidden_at']) : null,
      cart: json['cart'] != null
          ? CartModel.fromJson(json['cart'] as Map<String, dynamic>)
          : null,
      coupons: (json['coupons'] as List?)
          ?.map((e) => ItemCouponModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      model: deserializedModel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cart_id': cartId,
      'option_set_json': optionSetJson,
      // Serialize dynamic as is, or convert if needed
      'model_id': modelId,
      'model_type': modelType,
      'qty': qty,
      'unit_price': unitPrice,
      'line_total': lineTotal,
      'hidden_at': hiddenAt?.toIso8601String(),
      'cart': cart?.toJson(),
      'coupons': coupons?.map((e) => e.toJson()).toList(),
      'model': model?.toJson(), // Serialize model if needed and possible
    };
  }

  /// Checks if the cart item is visible (not hidden).
  bool get isVisible {
    return hiddenAt == null;
  }
}
