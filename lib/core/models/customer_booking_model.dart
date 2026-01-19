import 'package:flutter/material.dart';
import 'package:private_4t_app/core/models/grade_model.dart';
import 'package:private_4t_app/core/models/offer_model.dart';
import 'package:private_4t_app/core/models/service_type_model.dart';
import 'package:private_4t_app/core/models/subject_model.dart';

class CustomerBookingModel {
  int id;
  int userId;
  int serviceTypeId;
  int subjectId;
  int gradeId;
  DateTime bookingDate;
  String? title;
  String status;
  String timeFrom;
  String? altTime; // وقت ثاني احتياطي للحصة (غير إلزامي)
  double numberOfHours;
  String? notes;
  String? purposeOfReservation;
  int? teacherType;
  int? school; // 1 => مدارس عربية, 2 => مدارس أجنبية, 3 => جامعات
  double? price;
  bool isInCart;

  // حقول العرض
  int? offerId;
  double? offerPrice;

  SubjectModel? subject;
  GradeModel? grade;
  OfferModel? offer;
  ServiceTypeModel? serviceType;

  factory CustomerBookingModel.init() {
    return CustomerBookingModel(
      id: 0,
      userId: 0,
      serviceTypeId: 0,
      subjectId: 0,
      gradeId: 0,
      bookingDate: DateTime(2025),
      status: '',
      timeFrom: '',
      altTime: null,
      numberOfHours: 2.0,
      teacherType: 1, // Default: مدرس
      school: 1, // Default: مدارس عربية
      isInCart: false,
    );
  }

  CustomerBookingModel({
    required this.id,
    required this.userId,
    required this.serviceTypeId,
    required this.subjectId,
    required this.gradeId,
    required this.bookingDate,
    required this.status,
    required this.timeFrom,
    this.altTime,
    required this.numberOfHours,
    this.notes,
    this.purposeOfReservation,
    this.teacherType,
    this.school,
    this.price,
    this.offerId,
    this.offerPrice,
    this.subject,
    this.title,
    this.grade,
    this.offer,
    this.serviceType,
    this.isInCart = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id.toString(),
      'user_id': userId.toString(),
      'service_type_id': serviceTypeId.toString(),
      'subject_id': subjectId.toString(),
      'grade_id': gradeId.toString(),
      'booking_date': bookingDate.toIso8601String(),
      'status': status,
      'time_from': timeFrom,
      'alt_time': altTime,
      'number_of_hours': numberOfHours.toString(),
      'notes': notes,
      'title': title,
      'purpose_of_reservation': purposeOfReservation,
      'teacher_type': teacherType?.toString(),
      'school': school?.toString(),
      'price': price.toString(),
      'offer_id': offerId?.toString(),
      'offer_price': offerPrice?.toString(),
      'is_in_cart': isInCart,
    };
  }

  factory CustomerBookingModel.fromJson(Map<String, dynamic> json) {
    return CustomerBookingModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id']),
      userId:
          json['user_id'] is int ? json['user_id'] : int.parse(json['user_id']),
      serviceTypeId: json['service_type_id'] is int
          ? json['service_type_id']
          : int.parse(json['service_type_id']),
      subjectId: json['subject_id'] is int
          ? json['subject_id']
          : int.parse(json['subject_id']),
      gradeId: json['grade_id'] is int
          ? json['grade_id']
          : int.parse(json['grade_id']),
      bookingDate: json['booking_date'] != null
          ? DateTime.parse(json['booking_date'])
          : DateTime.now(),
      status: json['status'] ?? 'pending',
      title: json['title'],
      isInCart: json['is_in_cart'] ?? false,
      timeFrom: json['time_from'] ?? '',
      altTime: json['alt_time'],
      numberOfHours: json['number_of_hours'] is num
          ? (json['number_of_hours'] as num).toDouble()
          : double.parse(json['number_of_hours'].toString()),
      notes: json['notes'],
      purposeOfReservation: json['purpose_of_reservation'],
      teacherType: json['teacher_type'] != null
          ? (json['teacher_type'] is int
              ? json['teacher_type']
              : int.tryParse(json['teacher_type'].toString()))
          : null,
      school: json['school'] != null
          ? (json['school'] is int
              ? json['school']
              : int.tryParse(json['school'].toString()))
          : null,
      price: json['price'] != null
          ? (json['price'] is num
              ? (json['price'] as num).toDouble()
              : double.tryParse(json['price'].toString()))
          : null,
      offerId: json['offer_id'] != null
          ? (json['offer_id'] is int
              ? json['offer_id']
              : int.tryParse(json['offer_id'].toString()))
          : null,
      offerPrice: json['offer_price'] != null
          ? (json['offer_price'] is num
              ? (json['offer_price'] as num).toDouble()
              : double.tryParse(json['offer_price'].toString()))
          : null,
      subject: json['subject'] != null
          ? SubjectModel.fromJson(json['subject'])
          : null,
      grade: json['grade'] != null ? GradeModel.fromJson(json['grade']) : null,
      offer: json['offer'] != null ? OfferModel.fromJson(json['offer']) : null,
      serviceType: json['service_type'] != null
          ? ServiceTypeModel.fromJson(json['service_type'])
          : null,
    );
  }

  String get numberOfHoursFormatted {
    if (numberOfHours == 1.5) return 'ساعة ونصف';
    if (numberOfHours == 2) return 'ساعتين';
    return '$numberOfHours hours';
  }

  String get timeTo {
    final from = DateTime.parse("2024-01-01 $timeFrom");
    final to = from.add(Duration(
        hours: numberOfHours.floor(),
        minutes: (numberOfHours % 1 * 60).round()));
    return "${to.hour.toString().padLeft(2, '0')}:${to.minute.toString().padLeft(2, '0')}";
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  String get formattedBookingTime {
    final datePart =
        '${bookingDate.day.toString().padLeft(2, '0')}/${bookingDate.month.toString().padLeft(2, '0')}/${bookingDate.year}';

    final time = DateTime.tryParse(timeFrom);

    String timePart = timeFrom;

    if (time != null) {
      final timeOfDay = TimeOfDay(hour: time.hour, minute: time.minute);
      final period = timeOfDay.period == DayPeriod.am ? 'صباحًا' : 'مساءً';
      timePart =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
    }

    return '$datePart - $timePart - $numberOfHoursFormatted';
  }
}
