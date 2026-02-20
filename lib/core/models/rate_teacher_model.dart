import 'package:private_4t_app/core/models/order_course_model.dart';
import 'package:private_4t_app/core/models/user_model.dart';

class RateTeacherModel {
  final int? id;
  final int rate;
  final String notes;
  final int clientId;
  final int teacherId;
  final int orderCourseId;

  final UserModel? client;
  final UserModel? teacher;
  final OrderCourseModel? orderCourse;

  RateTeacherModel({
    this.id,
    required this.rate,
    required this.notes,
    required this.clientId,
    required this.teacherId,
    required this.orderCourseId,
    this.client,
    this.teacher,
    this.orderCourse,
  });

  factory RateTeacherModel.fromJson(Map<String, dynamic> json) {
    return RateTeacherModel(
      id: json['id'],
      rate: int.tryParse("${json['rate']}") ?? 0,
      notes: json['notes'] ?? '',
      clientId: int.tryParse("${json['client_id']}") ?? 0,
      teacherId: int.tryParse("${json['teacher_id']}") ?? 0,
      orderCourseId: int.tryParse("${json['order_course_id']}") ?? 0,
      client:
          json['client'] != null ? UserModel.fromJson(json['client']) : null,
      teacher:
          json['teacher'] != null ? UserModel.fromJson(json['teacher']) : null,
      orderCourse: json['order_course'] != null
          ? OrderCourseModel.fromJson(json['order_course'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rate': rate,
      'notes': notes,
      'client_id': clientId,
      'teacher_id': teacherId,
      'order_course_id': orderCourseId,
      'client': client?.toJson(),
      'teacher': teacher?.toJson(),
      'order_course': orderCourse?.toJson(),
    };
  }

  /// Getter for readable Arabic label
  String get rateLabel {
    switch (rate) {
      case 1:
        return 'ممتاز';
      case 2:
        return 'جيد جداً';
      case 3:
        return 'جيد';
      default:
        return 'غير جيد';
    }
  }
}
