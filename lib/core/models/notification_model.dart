import 'package:flutter/material.dart';

enum NotificationType {
  offer, // عروض
  reminder, // تذكيرات
  system, // نظام
  message, // رسائل
  call, // مكالمات
  booking, // حجوزات
  payment, // مدفوعات
  academic, // أكاديمي
  news, // أخبار
  promotion, // ترقيات
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.offer:
        return 'عروض';
      case NotificationType.reminder:
        return 'تذكيرات';
      case NotificationType.system:
        return 'النظام';
      case NotificationType.message:
        return 'رسائل';
      case NotificationType.call:
        return 'مكالمات';
      case NotificationType.booking:
        return 'حجوزات';
      case NotificationType.payment:
        return 'مدفوعات';
      case NotificationType.academic:
        return 'أكاديمي';
      case NotificationType.news:
        return 'أخبار';
      case NotificationType.promotion:
        return 'ترقيات';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.offer:
        return Icons.local_offer;
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.system:
        return Icons.system_update;
      case NotificationType.message:
        return Icons.message;
      case NotificationType.call:
        return Icons.call;
      case NotificationType.booking:
        return Icons.book_online;
      case NotificationType.payment:
        return Icons.payment;
      case NotificationType.academic:
        return Icons.school;
      case NotificationType.news:
        return Icons.newspaper;
      case NotificationType.promotion:
        return Icons.trending_up;
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.offer:
        return Colors.orange;
      case NotificationType.reminder:
        return Colors.blue;
      case NotificationType.system:
        return Colors.grey;
      case NotificationType.message:
        return Colors.green;
      case NotificationType.call:
        return Colors.red;
      case NotificationType.booking:
        return Colors.purple;
      case NotificationType.payment:
        return Colors.teal;
      case NotificationType.academic:
        return Colors.indigo;
      case NotificationType.news:
        return Colors.amber;
      case NotificationType.promotion:
        return Colors.pink;
    }
  }

  static NotificationType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'offer':
        return NotificationType.offer;
      case 'reminder':
        return NotificationType.reminder;
      case 'system':
        return NotificationType.system;
      case 'message':
        return NotificationType.message;
      case 'call':
        return NotificationType.call;
      case 'booking':
        return NotificationType.booking;
      case 'payment':
        return NotificationType.payment;
      case 'academic':
        return NotificationType.academic;
      case 'news':
        return NotificationType.news;
      case 'promotion':
        return NotificationType.promotion;
      default:
        return NotificationType.system;
    }
  }
}

class NotificationModel {
  final int id;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? deepLink;
  final String? status;
  final Map<String, dynamic>? metadata;
  final int? userId; // Target user ID

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    this.createdAt,
    this.updatedAt,
    this.deepLink,
    this.metadata,
    this.status,
    this.userId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> parsedMetadata = {}; // Default to empty map
    final metadataValue = json['metadata'];

    if (metadataValue is Map<String, dynamic>) {
      // If it's already the correct type, use it
      parsedMetadata = metadataValue;
    } else if (metadataValue is Map) {
      // If it's a Map but not explicitly <String, dynamic>, try casting or converting keys
      // This handles cases where the map might have non-string keys initially
      parsedMetadata = Map<String, dynamic>.from(metadataValue);
    } else if (metadataValue is List) {
      // If it's a List (e.g., []), treat it as empty metadata
      // You could also convert it using asMap() if needed, but decide if that's the intent
      // parsedMetadata = Map<int, dynamic>.from(metadataValue).map((key, value) => MapEntry(key.toString(), value));
      // For now, assuming empty list means empty metadata map
      parsedMetadata = {}; // Or handle list conversion if needed
    }
    return NotificationModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? json['body'] ?? '',
      type: NotificationTypeExtension.fromString(json['type'] ?? 'system'),
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      metadata: parsedMetadata,
      deepLink: json['deep_link'] ?? json['deepLink'],
      userId: json['user_id'] ?? json['userId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': message,
      'type': type.name,
      'is_read': isRead,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deep_link': deepLink,
      'user_id': userId,
      'metadata': metadata,
    };
  }

  NotificationModel copyWith({
    int? id,
    String? title,
    String? message,
    NotificationType? type,
    bool? isRead,
    DateTime? timestamp,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? deepLink,
    int? userId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deepLink: deepLink ?? this.deepLink,
      metadata: metadata ?? this.metadata,
      userId: userId ?? this.userId,
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, type: $type, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
