import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/material/time.dart';
import 'package:private_4t_app/core/models/course_model.dart';
import 'package:private_4t_app/core/models/grade_model.dart';
import 'package:private_4t_app/core/models/service_type_model.dart';
import 'package:private_4t_app/core/models/subject_model.dart';

class OrderCourseModel {
  final int? id;
  final int? userId;
  final int? teacherId;
  final int? reservationId;
  final int? operationId;
  final int? partnerId;
  final int? courseId;
  final int? workPlaceId;
  final int? gradeId;
  final int? subjectId;
  final int? educationId;
  final int? governorateId;
  final int? regionId;
  final int? communicationId;
  final int? classLocationId;
  final int? uncompletedWorkId;
  final String? state;
  final String? gender;
  final String? notes;
  final String? paymentMethod;
  final String? orderType;
  final bool? isPaid;
  final String? moneyBack;
  final bool? accountatntIsPaid;
  final String? orderNumber;
  final String? teacherApproved;
  final String? orderStatus;
  final String? teacherViews;
  final String? price;
  final String? teacherPercentage;
  final String? partnerPercentage;
  final String? privatePercentage;
  final String? rating;
  final String? bookingDate;
  final String? numberOfHours;
  final String? numberOfSessions;
  final String? receivingBank;
  final String? outgoingBank;
  final String? comments;
  final String? timeFrom;
  final String? timeTo;
  final String? tTimeFrom;
  final String? tTimeTo;
  final String? startedAt;
  final String? endedAt;
  final String? myfile;
  final String? payment;
  final String? teacherName;
  final String? mapAddress;
  final String? latitude;
  final String? longitude;
  final int? serviceTypeId;
  final String? ratingStudent;
  final String? matrixRoomId;
  final bool? bookingOnline;
  final bool? isCompleted;
  final int? transactionId;
  final int? diagnosticId;
  final int? followUpId;
  final String? txStatus;
  final int? school;
  final String? createdAt;
  final String? updatedAt;

  // Related Models
  final CourseModel? course;
  final SubjectModel? subject;
  final GradeModel? grade;
  final ServiceTypeModel? serviceType;

  OrderCourseModel({
    this.id,
    this.userId,
    this.teacherId,
    this.reservationId,
    this.operationId,
    this.partnerId,
    this.courseId,
    this.workPlaceId,
    this.gradeId,
    this.subjectId,
    this.educationId,
    this.governorateId,
    this.regionId,
    this.communicationId,
    this.classLocationId,
    this.uncompletedWorkId,
    this.state,
    this.gender,
    this.notes,
    this.paymentMethod,
    this.orderType,
    this.isPaid,
    this.moneyBack,
    this.accountatntIsPaid,
    this.orderNumber,
    this.teacherApproved,
    this.orderStatus,
    this.teacherViews,
    this.matrixRoomId,
    this.price,
    this.teacherPercentage,
    this.partnerPercentage,
    this.privatePercentage,
    this.rating,
    this.bookingDate,
    this.numberOfHours,
    this.numberOfSessions,
    this.receivingBank,
    this.outgoingBank,
    this.comments,
    this.timeFrom,
    this.timeTo,
    this.tTimeFrom,
    this.tTimeTo,
    this.startedAt,
    this.endedAt,
    this.myfile,
    this.mapAddress,
    this.latitude,
    this.longitude,
    this.serviceTypeId,
    this.payment,
    this.ratingStudent,
    this.bookingOnline,
    this.transactionId,
    this.teacherName,
    this.txStatus,
    this.school,
    this.isCompleted,
    this.diagnosticId,
    this.followUpId,
    this.createdAt,
    this.updatedAt,
    this.course,
    this.subject,
    this.grade,
    this.serviceType,
  });

  factory OrderCourseModel.fromJson(Map<String, dynamic> json) {
    return OrderCourseModel(
      id: json['id'],
      userId: json['user_id'],
      teacherId: json['teacher_id'],
      reservationId: json['reservation_id'],
      operationId: json['operation_id'],
      partnerId: json['partner_id'],
      courseId: json['course_id'],
      workPlaceId: json['work_place_id'],
      gradeId: json['grade_id'],
      subjectId: json['subject_id'],
      educationId: json['education_id'],
      governorateId: json['governorate_id'],
      regionId: json['region_id'],
      communicationId: json['communication_id'],
      classLocationId: json['class_location_id'],
      uncompletedWorkId: json['uncompleted_work_id'],
      state: json['state'],
      gender: json['gender'],
      notes: json['notes'],
      paymentMethod: json['payment_method'],
      orderType: json['order_type'],
      isPaid: json['is_paid'] == true || json['is_paid'] == 1,
      moneyBack: json['money_back'],
      accountatntIsPaid: json['accountatnt_is_paid'] == true ||
          json['accountatnt_is_paid'] == 1,
      orderNumber: json['order_number'],
      teacherApproved: json['teacher_approved'],
      orderStatus: json['order_status'],
      teacherViews: json['teacher_views'],
      price: "${json['price']}",
      teacherPercentage: "${json['teacher_percentage']}",
      partnerPercentage: "${json['partner_percentage']}",
      privatePercentage: "${json['private_percentage']}",
      rating: json['rating'],
      bookingDate: json['booking_date'],
      numberOfHours: "${json['number_of_hours']}",
      numberOfSessions: "${json['number_of_sessions']}",
      receivingBank: json['receiving_bank'],
      outgoingBank: json['outgoing_bank'],
      comments: json['comments'],
      timeFrom: json['time_from'],
      timeTo: json['time_to'],
      tTimeFrom: json['t_time_from'],
      tTimeTo: json['t_time_to'],
      startedAt: json['started_at'],
      isCompleted: json['is_completed'] == true || json['is_completed'] == 1,
      endedAt: json['ended_at'],
      payment: json['payment'],
      myfile: json['myfile'],
      teacherName: json['teacher_name'],
      mapAddress: json['map_address'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      serviceTypeId: json['service_type_id'],
      ratingStudent: json['rating_student'],
      bookingOnline:
          json['booking_online'] == true || json['booking_online'] == 1,
      transactionId: json['transaction_id'],
      diagnosticId: json['diagnostic_id'],
      followUpId: json['follow_up_id'],
      txStatus: json['tx_status'],
      school: json['school'],
      matrixRoomId: json['matrix_room_id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      course:
          json['course'] != null ? CourseModel.fromJson(json['course']) : null,
      subject: json['subject'] != null
          ? SubjectModel.fromJson(json['subject'])
          : null,
      grade: json['grade'] != null ? GradeModel.fromJson(json['grade']) : null,
      serviceType: json['service_type'] != null
          ? ServiceTypeModel.fromJson(json['service_type'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'user_id': userId,
      'teacher_id': teacherId,
      'reservation_id': reservationId,
      'operation_id': operationId,
      'partner_id': partnerId,
      'work_place_id': workPlaceId,
      'grade_id': gradeId,
      'subject_id': subjectId,
      'education_id': educationId,
      'governorate_id': governorateId,
      'region_id': regionId,
      'communication_id': communicationId,
      'class_location_id': classLocationId,
      'uncompleted_work_id': uncompletedWorkId,
      'state': state,
      'gender': gender,
      'notes': notes,
      'payment_method': paymentMethod,
      'order_type': orderType,
      'is_paid': isPaid,
      'money_back': moneyBack,
      'accountatnt_is_paid': accountatntIsPaid,
      'order_number': orderNumber,
      'teacher_approved': teacherApproved,
      'order_status': orderStatus,
      'teacher_views': teacherViews,
      'price': price,
      'teacher_percentage': teacherPercentage,
      'partner_percentage': partnerPercentage,
      'private_percentage': privatePercentage,
      'rating': rating,
      'booking_date': bookingDate,
      'number_of_hours': numberOfHours,
      'number_of_sessions': numberOfSessions,
      'receiving_bank': receivingBank,
      'outgoing_bank': outgoingBank,
      'comments': comments,
      'time_from': timeFrom,
      'time_to': timeTo,
      't_time_from': tTimeFrom,
      't_time_to': tTimeTo,
      'started_at': startedAt,
      'ended_at': endedAt,
      'payment': payment,
      'myfile': myfile,
      'map_address': mapAddress,
      'latitude': latitude,
      'longitude': longitude,
      'is_completed': isCompleted,
      'service_type_id': serviceTypeId,
      'rating_student': ratingStudent,
      'booking_online': bookingOnline,
      'transaction_id': transactionId,
      'tx_status': txStatus,
      'school': school,
      'matrix_room_id': matrixRoomId,
      'teacher_name': teacherName,
      'grade': grade?.toJson(),
      'subject': subject?.toJson(),
      'service_type': serviceType?.toJson(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  String get formatBookingDateArabic {
    if (bookingDate == null) return '';
    final date = DateTime.tryParse(bookingDate!);
    if (date == null) return '';
    final weekday = DateFormat('EEEE', 'ar').format(date);
    return '$weekday ${DateFormat('y-M-d').format(date)}';
  }

  TimeOfDay get timeFromParsed {
    final format = DateFormat.Hm(); // 24-hour format: "HH:mm"
    final dateTime = format.tryParse(timeFrom ?? '');

    if (dateTime == null) {
      return TimeOfDay.now();
    }

    return TimeOfDay.fromDateTime(dateTime);
  }
}
