import 'subject_model.dart';
import 'grade_model.dart';
import 'user_model.dart';

class CourseModel {
  final int? id;
  final String? orderType;
  final String? orderStatus;
  final int? newId;
  final int? userId;
  final int? teacherId;
  final int? communicationId;
  final int? gradeId;
  final int? subjectId;
  final double? price;
  final bool? isPaid;

  final SubjectModel? subject;
  final GradeModel? grade;
  final UserModel? user;
  final UserModel? teacher;
  final UserModel? partner;
  final String? productName;
  final String? salesPerson;
  final String? newOrderNumber;
  final String? collectionStatus;
  final int? collectionPrice;

  CourseModel({
    this.id,
    this.orderType,
    this.orderStatus,
    this.newId,
    this.userId,
    this.teacherId,
    this.communicationId,
    this.gradeId,
    this.subjectId,
    this.price,
    this.isPaid,
    this.subject,
    this.grade,
    this.user,
    this.teacher,
    this.partner,
    this.productName,
    this.salesPerson,
    this.newOrderNumber,
    this.collectionStatus,
    this.collectionPrice,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'],
      orderType: json['order_type'],
      orderStatus: json['order_status'],
      newId: json['new_id'],
      userId: json['user_id'],
      teacherId: json['teacher_id'],
      communicationId: json['communication_id'],
      gradeId: json['grade_id'],
      subjectId: json['subject_id'],
      price: double.tryParse("${json['price']}"),
      isPaid: json['is_paid'] == 1,
      subject: json['subject'] != null ? SubjectModel.fromJson(json['subject']) : null,
      grade: json['grade'] != null ? GradeModel.fromJson(json['grade']) : null,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      teacher: json['teacher'] != null ? UserModel.fromJson(json['teacher']) : null,
      partner: json['partner'] != null ? UserModel.fromJson(json['partner']) : null,
      productName: json['product_name'],
      salesPerson: json['sales_person'],
      newOrderNumber: json['new_order_number'],
      collectionStatus: json['collection_status'],
      collectionPrice: json['collection_price'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_type': orderType,
      'order_status': orderStatus,
      'new_id': newId,
      'user_id': userId,
      'teacher_id': teacherId,
      'communication_id': communicationId,
      'grade_id': gradeId,
      'subject_id': subjectId,
      'price': price,
      'is_paid': isPaid == true ? 1 : 0,
      'subject': subject?.toJson(),
      'grade': grade?.toJson(),
      'user': user?.toJson(),
      'teacher': teacher?.toJson(),
      'partner': partner?.toJson(),
      'product_name': productName,
      'sales_person': salesPerson,
      'new_order_number': newOrderNumber,
      'collection_status': collectionStatus,
      'collection_price': collectionPrice,
    };
  }
}