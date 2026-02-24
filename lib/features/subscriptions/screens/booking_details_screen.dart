import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/common_components.dart';

import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/models/course_model.dart';
import 'package:private_4t_app/core/models/order_course_model.dart';
import 'package:private_4t_app/core/providers/app_container.dart';
import 'package:private_4t_app/core/services/navigation_service.dart';
import 'package:riverpod_context/riverpod_context.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  final OrderCourseModel order;

  const BookingDetailScreen({super.key, required this.order});

  @override
  ConsumerState<BookingDetailScreen> createState() =>
      _OrderCourseDetailScreenState();
}

class _OrderCourseDetailScreenState extends ConsumerState<BookingDetailScreen>
    with AnalyticsScreenMixin {
  @override
  String get screenName => 'BookingDetailsscreen';

  final TextEditingController _addressController = TextEditingController();

  late OrderCourseModel _orderCourseModel;

  @override
  void initState() {
    super.initState();

    _orderCourseModel = widget.order;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(ApiProviders.subscriptionsProvider)
          .getBookingDetails(context, _orderCourseModel.id.toString());
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(ApiProviders.subscriptionsProvider);
    bool isLoading = provider.isLoading;
    if (!isLoading &&
        provider.orderCourseModel.id != null &&
        provider.orderCourseModel.id == widget.order.id) {
      _orderCourseModel = provider.orderCourseModel;
      _addressController.text = _orderCourseModel.mapAddress ?? '';
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: isLoading
          ? CommonComponents.loadingDataFromServer(color: context.primary)
          : Scaffold(
              backgroundColor: context.background,
              appBar: AppBar(
                backgroundColor: context.surface,
                elevation: 0,
                centerTitle: true,
                title: Text(
                  'تفاصيل الحصة',
                  style: TextStyle(
                      color: context.primaryText, fontWeight: FontWeight.w700),
                ),
                iconTheme: IconThemeData(color: context.primaryText),
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Timeline at the top
                      _singleSessionTimelineSection(),
                      SizedBox(height: 20.h),

                      // Header card with modern design
                      _modernHeaderCard(),
                      SizedBox(height: 16.h),

                      // Details card with enhanced design
                      _modernDetailsCard(),
                      SizedBox(height: 16.h),

                      // Course information (if applicable)
                      // if (isCourse) _modernCourseSection(),

                      // Actions at the bottom
                      SizedBox(height: 20.h),
                      _modernActionsCard(),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ===================== Timeline Sections (Top) =====================

  Widget _singleSessionTimelineSection() {
    final steps = _buildStepsFromState(
        _orderCourseModel.orderStatus ?? _orderCourseModel.state ?? 'pending');

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.primary.withOpacity(0.05),
            context.accent.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: context.primary.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: context.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: context.primary,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.timeline,
                  color: context.surface,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'حالة الحصة',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: context.primaryText,
                      ),
                    ),
                    Text(
                      'تابع تقدم حصتك',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: context.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          _modernHorizontalTimeline(steps),
        ],
      ),
    );
  }

  Widget _courseTimelineSection() {
    final CourseModel? course = _orderCourseModel.course;
    final sessionsCount =
        int.tryParse(_orderCourseModel.numberOfSessions ?? '') ??
            (course?.collectionPrice ?? 0);
    final safeCount = sessionsCount > 0 ? sessionsCount : 1;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.accent.withOpacity(0.05),
            context.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: context.accent.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: context.accent.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: context.accent,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.school,
                  color: context.surface,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تقدم الكورس',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: context.primaryText,
                      ),
                    ),
                    Text(
                      '$safeCount حصة - ${_arabicStatus(course?.orderStatus ?? _orderCourseModel.orderStatus)}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: context.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          _buildCourseProgressIndicator(safeCount),
        ],
      ),
    );
  }

  Widget _buildCourseProgressIndicator(int totalSessions) {
    final completedSessions = _getCompletedSessionsCount();
    final progress =
        totalSessions > 0 ? completedSessions / totalSessions : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'التقدم',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: context.primaryText,
              ),
            ),
            Text(
              '$completedSessions / $totalSessions',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: context.accent,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: context.surfaceLight,
          valueColor: AlwaysStoppedAnimation<Color>(context.accent),
          minHeight: 8.h,
        ),
        SizedBox(height: 16.h),
        _buildSessionsGrid(totalSessions),
      ],
    );
  }

  Widget _buildSessionsGrid(int totalSessions) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 8.h,
        childAspectRatio: 1.2,
      ),
      itemCount: totalSessions,
      itemBuilder: (context, index) {
        final sessionNumber = index + 1;
        final isCompleted = sessionNumber <= _getCompletedSessionsCount();
        final isCurrent = sessionNumber == _getCompletedSessionsCount() + 1;

        return Container(
          decoration: BoxDecoration(
            color: isCompleted
                ? context.success.withOpacity(0.1)
                : isCurrent
                    ? context.accent.withOpacity(0.1)
                    : context.surfaceLight,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isCompleted
                  ? context.success
                  : isCurrent
                      ? context.accent
                      : context.surfaceLight,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCompleted
                    ? Icons.check_circle
                    : isCurrent
                        ? Icons.play_circle_outline
                        : Icons.radio_button_unchecked,
                color: isCompleted
                    ? context.success
                    : isCurrent
                        ? context.accent
                        : context.secondaryText,
                size: 20.sp,
              ),
              SizedBox(height: 4.h),
              Text(
                '$sessionNumber',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: isCompleted
                      ? context.success
                      : isCurrent
                          ? context.accent
                          : context.secondaryText,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int _getCompletedSessionsCount() {
    // This is a simplified calculation - you might want to implement
    // more sophisticated logic based on actual session completion data
    final status =
        _orderCourseModel.orderStatus ?? _orderCourseModel.state ?? 'pending';
    switch (status) {
      case 'completed':
        return int.tryParse(_orderCourseModel.numberOfSessions ?? '') ?? 1;
      case 'under_review':
        return (int.tryParse(_orderCourseModel.numberOfSessions ?? '') ?? 1) -
            1;
      case 'started':
        return (int.tryParse(_orderCourseModel.numberOfSessions ?? '') ?? 1) -
            2;
      default:
        return 0;
    }
  }

  // ===================== Header =====================

  Widget _modernHeaderCard() {
    final title = _orderCourseModel.course?.productName ??
        _orderCourseModel.course?.subject?.subject ??
        _orderCourseModel.subject?.subject ??
        'حجز';
    final teacher = _orderCourseModel.teacherName ??
        _orderCourseModel.course?.teacher?.name ??
        'لم يتم تحديد مدرس';

    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: context.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [context.primary, context.accent],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(
                  Icons.book_online,
                  color: context.surface,
                  size: 28.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: context.primaryText,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(Icons.person, size: 16.sp, color: context.accent),
                        SizedBox(width: 8.w),
                        Flexible(
                          child: Text(
                            teacher,
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: context.secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          _buildModernMetaInfo(),
        ],
      ),
    );
  }

  Widget _buildModernMetaInfo() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: context.background,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.surfaceLight),
      ),
      child: Column(
        children: [
          _buildModernMetaRow(
            Icons.calendar_today,
            'التاريخ',
            _orderCourseModel.formatBookingDateArabic,
            context.primary,
          ),
          SizedBox(height: 12.h),
          _buildModernMetaRow(
            Icons.access_time,
            'الوقت',
            '${_orderCourseModel.timeFrom ?? '-'} - ${_orderCourseModel.timeTo ?? '-'}',
            context.accent,
          ),
          if (_orderCourseModel.mapAddress?.isNotEmpty == true) ...[
            SizedBox(height: 12.h),
            _buildModernMetaRow(
              Icons.place,
              'الموقع',
              _orderCourseModel.mapAddress ?? '',
              context.success,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernMetaRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 16.sp, color: color),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: context.secondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: context.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _headerCard() {
    final title = _orderCourseModel.course?.productName ??
        _orderCourseModel.course?.subject?.subject ??
        _orderCourseModel.subject?.subject ??
        'حجز';
    final teacher = _orderCourseModel.teacherName ??
        _orderCourseModel.course?.teacher?.name ??
        'لم يتم تحديد مدرس';

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          // صورة/أفاتار
          // Container(
          //   width: 84.r,
          //   height: 84.r,
          //   decoration: BoxDecoration(
          //     color: context.accent.withOpacity(0.12),
          //     borderRadius: BorderRadius.circular(12.r),
          //   ),
          //   child: Center(
          //     child: Icon(Icons.person, size: 40.r, color: context.accent),
          //   ),
          // ),
          // SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: context.primaryText)),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Icon(Icons.star, size: 14.sp, color: context.success),
                    SizedBox(width: 6.w),
                    Flexible(
                        child: Text(teacher,
                            style: TextStyle(
                                fontSize: 14.sp,
                                color: context.secondaryText))),
                  ],
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    _metaPill(Icons.calendar_today,
                        _orderCourseModel.formatBookingDateArabic),
                    _metaPill(Icons.access_time,
                        '${_orderCourseModel.timeFrom ?? '-'} - ${_orderCourseModel.timeTo ?? '-'}'),
                    if (_orderCourseModel.mapAddress?.isNotEmpty == true)
                      _metaPill(
                          Icons.place, _orderCourseModel.mapAddress ?? ''),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _metaPill(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: context.surfaceLight,
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: context.surfaceLight, width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: context.secondaryText),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              text,
              maxLines: 2,
              style: TextStyle(fontSize: 12.sp, color: context.secondaryText),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== Modern Details Card =====================

  Widget _modernDetailsCard() {
    final o = _orderCourseModel;

    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: context.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: context.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: context.secondary,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'تفاصيل الحجز',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: context.primaryText,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          _buildModernDetailGrid(o),
        ],
      ),
    );
  }

  Widget _buildModernDetailGrid(OrderCourseModel o) {
    return Column(
      children: [
        _buildModernDetailRow('رقم الطلب', o.orderNumber, Icons.receipt_long),
        _buildModernDetailRow('نوع الطلب', o.orderType, Icons.category),
        _buildModernDetailRow('الحالة',
            _arabicStatus(o.orderStatus?.replaceAll('_', ' ')), Icons.flag),
        _buildModernDetailRow('طريقة الدفع', o.paymentMethod, Icons.payment),
        _buildModernDetailRow(
          'حالة الدفع',
          (o.isPaid == true || (o.payment?.toLowerCase() == 'paid'))
              ? 'مدفوع'
              : (o.txStatus ?? o.payment ?? 'غير مدفوع'),
          Icons.check_circle_outline,
        ),
        _buildModernDetailRow('السعر', o.price, Icons.attach_money),
        _buildModernDetailRow(
            'المعلم', o.teacherName ?? o.course?.teacher?.name, Icons.person),
        _buildModernDetailRow(
            'المرحلة الدراسية', o.grade?.grade ?? o.grade?.grade, Icons.school),
        _buildModernDetailRow(
            'المادة', o.subject?.subject ?? o.subject?.subject, Icons.book),
        _buildModernDetailRow(
            'عدد الساعات', o.numberOfHours, Icons.access_time),
        _buildModernDetailRow(
            'عدد الحصص',
            o.numberOfSessions ?? o.course?.collectionPrice?.toString(),
            Icons.event),
        _buildModernDetailRow('الموقع', o.mapAddress, Icons.place),
        _buildModernDetailRow('ملاحظاتك', o.ratingStudent, Icons.note),
        _buildModernDetailRow('ملاحظات النظام', o.notes, Icons.info),
        _buildModernDetailRow(
            'أُنشئ في', _formatDateTime(o.createdAt), Icons.schedule),
        _buildModernDetailRow(
            'آخر تحديث', _formatDateTime(o.updatedAt), Icons.update),
      ],
    );
  }

  Widget _buildModernDetailRow(String label, String? value, IconData icon) {
    final displayValue = (value == null || value.isEmpty) ? '-' : value;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: context.background,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.surfaceLight),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: context.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, size: 16.sp, color: context.primary),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: context.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: context.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== Details =====================

  Widget _detailsCard() {
    final o = _orderCourseModel;

    Widget row(String title, String? value, {bool bold = false}) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 120.w,
                child: Text(title,
                    style: TextStyle(
                        fontSize: 14.sp, color: context.secondaryText))),
            Expanded(
              child: Text(
                (value == null || value.isEmpty) ? '-' : value,
                style: TextStyle(
                    fontSize: 14.sp,
                    color: context.primaryText,
                    fontWeight: bold ? FontWeight.w600 : FontWeight.normal),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row('رقم الطلب', o.orderNumber),
          row('نوع الطلب', o.orderType),
          row('الحالة', _arabicStatus(o.orderStatus ?? o.state)),
          row('طريقة الدفع', o.paymentMethod),
          row(
              'حالة الدفع',
              (o.isPaid == true || (o.payment?.toLowerCase() == 'paid'))
                  ? 'مدفوع'
                  : (o.txStatus ?? o.payment ?? 'غير مدفوع')),
          row('السعر', o.price),
          row('المعلم', o.teacherName ?? o.course?.teacher?.name),
          row('المرحلة الدراسية', o.grade?.grade ?? o.grade?.grade),
          row('المادة', o.subject?.subject ?? o.subject?.subject),
          row('عدد الساعات', o.numberOfHours),
          row('عدد الحصص',
              o.numberOfSessions ?? o.course?.collectionPrice?.toString()),
          row('الموقع', o.mapAddress),
          row('ملاحظاتك', o.ratingStudent),
          row('ملاحظات النظام', o.notes),
          row('أُنشئ في', _formatDateTime(o.createdAt)),
          row('آخر تحديث', _formatDateTime(o.updatedAt)),
        ],
      ),
    );
  }

  String _formatDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '-';
    return intl.DateFormat('y/M/d HH:mm', 'ar').format(dt);
  }

  String _arabicStatus(String? s) {
    if (s == null) return '-';
    switch (s) {
      case 'pending':
        return 'قيد المعالجة';
      case 'sent_to_teacher':
        return 'تم الإرسال للمدرسين';
      case 'searching_teacher':
        return 'جاري اختيار مدرس';
      case 'teacher_selected':
        return 'تم اختيار مدرس';
      case 'started':
        return 'بدأت الحصة';
      case 'under_review':
        return 'بانتظار المراجعة';
      case 'completed':
        return 'مكتمل';
      case 'not_completed':
        return 'غير مكتمل';
      default:
        return s;
    }
  }

  // ===================== Modern Actions Card (Bottom) =====================

  Widget _modernActionsCard() {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: context.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: context.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.touch_app,
                  color: context.accent,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'الإجراءات المتاحة',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: context.primaryText,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          _buildModernActionButtons(),
        ],
      ),
    );
  }

  Widget _buildModernActionButtons() {
    return Column(
      children: [
        if (_orderCourseModel.teacherId != null &&
            _orderCourseModel.teacherId! > 0)
          _buildModernActionButton(
            icon: Icons.chat_bubble_outline,
            title: 'مراسلة المدرس',
            subtitle: 'تواصل مع مدرسك مباشرة',
            color: context.accentSecondary,
            onTap: () => _navigateToChat(context),
          ),
        if (_orderCourseModel.orderStatus == 'مكتمل' ||
            _orderCourseModel.orderStatus == 'انتظار_مراجعة') ...[
          SizedBox(height: 12.h),
          _buildModernActionButton(
            icon: Icons.star,
            title: 'تقييم المدرس',
            subtitle: 'شاركنا رأيك في أداء المدرس',
            color: context.accent,
            onTap: () => _showTeacherRatingDialog(context),
          ),
          SizedBox(height: 12.h),
          _buildModernActionButton(
            icon: Icons.note,
            title: 'إضافة ملاحظة',
            subtitle: 'اكتب ملاحظاتك حول الدرس',
            color: context.secondary,
            onTap: () => _showStudentNoteDialog(context),
          ),
        ],
        if (_orderCourseModel.diagnosticId != null) ...[
          SizedBox(height: 12.h),
          _buildModernActionButton(
            icon: Icons.medical_services,
            title: 'التشخيص',
            subtitle: 'عرض تفاصيل التشخيص',
            color: context.primary,
            onTap: _navigateToDiagnostic,
          ),
        ],
        if (_orderCourseModel.followUpId != null) ...[
          SizedBox(height: 12.h),
          _buildModernActionButton(
            icon: Icons.track_changes,
            title: 'المتابعة',
            subtitle: 'عرض تفاصيل المتابعة',
            color: context.accent,
            onTap: _navigateToFollowUp,
          ),
        ],
        if (_orderCourseModel.orderStatus == 'تم_الارسال_للمدرسين' &&
            _orderCourseModel.orderStatus == 'تم_اختيار_مدرس') ...[
          SizedBox(height: 12.h),
          _buildModernActionButton(
            icon: Icons.edit_calendar,
            title: 'تعديل الحجز',
            subtitle: 'غيّر موعد أو تفاصيل الحجز',
            color: context.primary,
            onTap: () => _showEditBookingDialog(context),
          ),
        ],
        if (_orderCourseModel.orderStatus == 'مكتمل' &&
            _orderCourseModel.orderType == 'حصة') ...[
          SizedBox(height: 12.h),
          _buildModernActionButton(
            icon: Icons.refresh,
            title: 'تجديد حجز الحصة',
            subtitle: 'احجز حصة جديدة بنفس التفاصيل',
            color: context.success,
            onTap: () => _showRenewBookingDialog(context),
          ),
        ],
      ],
    );
  }

  Widget _buildModernActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, size: 24.sp, color: color),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: context.primaryText,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: context.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16.sp,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  // ===================== Actions (same as ClassCard) =====================

  Widget _actionsCard() {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12.r),
        border:
            Border.all(color: context.secondary.withOpacity(0.10), width: 0.8),
      ),
      child: Wrap(
        spacing: 10.w,
        runSpacing: 10.h,
        children: [
          if (_orderCourseModel.courseId == null)
            _actionPill(
              icon: Icons.chat_bubble_outline,
              label: 'مراسلة',
              color: context.accentSecondary,
              onTap: () => _navigateToChat(context),
            ),
          _actionPill(
            icon: Icons.star,
            label: 'تقييم',
            color: context.accent,
            onTap: () => _showTeacherRatingDialog(context),
          ),
          _actionPill(
            icon: Icons.note,
            label: 'ملاحظة',
            color: context.secondary,
            onTap: () => _showStudentNoteDialog(context),
          ),
          _actionPill(
            icon: Icons.edit_calendar,
            label: "تعديل الحجز",
            color: context.primary,
            onTap: () => _showEditBookingDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _actionPill({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(999.r),
          border: Border.all(color: color.withOpacity(0.18), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14.sp, color: color),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                  fontSize: 11.sp, color: color, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToChat(BuildContext context) {
    logButtonClick('booking_details_message_teacher', data: {
      'order_id': _orderCourseModel.id?.toString(),
      'room_id': _orderCourseModel.matrixRoomId,
    });

    final roomId = _orderCourseModel.matrixRoomId;
    if (roomId != null && roomId.isNotEmpty) {
      NavigationService.navigateToRoomTimeline(context, roomId);
    } else {
      CommonComponents.showCustomizedSnackBar(
        context: context,
        title: 'لا توجد محادثة متاحة لهذا الطلب',
      );
    }
  }

  // Navigate to diagnostic - find the one related to this order if exists
  Future<void> _navigateToDiagnostic() async {
    context.push('/teacher-diagnostics/${_orderCourseModel.diagnosticId}');
  }

  // Navigate to follow-up - find the one related to this order if exists
  Future<void> _navigateToFollowUp() async {
    context.push('/teacher-follow-ups/${_orderCourseModel.followUpId}');
  }

  Future<void> _showTeacherRatingDialog(BuildContext context) async {
    logButtonClick('booking_details_rate_teacher', data: {
      'order_id': _orderCourseModel.id?.toString(),
    });

    final orderId = _orderCourseModel.id ?? 0;
    final provider = context.read(ApiProviders.subscriptionsProvider);

    final rateTeacherModel = await provider.getRateTeacher(
      context: context,
      orderId: orderId,
    );

    final TextEditingController notesController = TextEditingController();
    notesController.text = rateTeacherModel?.notes ?? '';
    int? selectedRating = rateTeacherModel?.rate;

    final List<String> ratings = ['ممتاز', 'جيد جدًا', 'جيد', 'ضعيف'];

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('تقييم المدرس', textAlign: TextAlign.right),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('التقييم'),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: selectedRating,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                  items: ratings.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final label = entry.value;
                    return DropdownMenuItem<int>(
                        value: idx + 1, child: Text(label));
                  }).toList(),
                  onChanged: (v) => selectedRating = v,
                ),
                const SizedBox(height: 16),
                const Text('ملاحظات'),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 4,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (selectedRating == null) {
                  CommonComponents.showCustomizedSnackBar(
                      context: context, title: 'يرجى تحديد التقييم');
                  return;
                }
                logStep('booking_details_rating_submitted', data: {
                  'order_id': orderId.toString(),
                  'rating': selectedRating,
                });
                await provider.rateTeacher(
                  context: context,
                  orderId: orderId,
                  rate: selectedRating!,
                  notes: notesController.text.trim(),
                );
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('تقييم'),
            ),
          ],
        );
      },
    );
  }

  void _showEditBookingDialog(BuildContext context) {
    logButtonClick('booking_details_edit_booking', data: {
      'order_id': _orderCourseModel.id?.toString(),
    });

    String selectedAddress = _orderCourseModel.mapAddress ?? '';
    DateTime selectedDate =
        DateTime.tryParse(_orderCourseModel.bookingDate ?? '') ??
            DateTime.now();
    TimeOfDay selectedTime = _orderCourseModel.timeFromParsed;
    double selectedHours =
        double.tryParse(_orderCourseModel.numberOfHours ?? '') ?? 2.0;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'تعديل بيانات الحصة',
                  style: TextStyle(fontSize: 18.r, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 16.h),

              // Location Picker
              StatefulBuilder(
                builder: (context, setLocalState) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dropdown for Number of Hours
                      // Row(
                      //   children: [
                      //     Expanded(
                      //       child: DropdownButtonFormField<double>(
                      //         value: selectedHours,
                      //         items: const [
                      //           DropdownMenuItem<double>(
                      //             value: 1.5,
                      //             child: Text('ساعة ونصف'),
                      //           ),
                      //           DropdownMenuItem<double>(
                      //             value: 2.0,
                      //             child: Text('ساعتين'),
                      //           )
                      //         ],
                      //         onChanged: (value) {
                      //           if (value != null) {
                      //             selectedHours = value;
                      //           }
                      //         },
                      //         decoration: const InputDecoration(
                      //           labelText: 'عدد الساعات',
                      //           border: OutlineInputBorder(),
                      //         ),
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      // SizedBox(height: 16.h),
                      TextField(
                        controller:
                            TextEditingController(text: selectedAddress),
                        decoration: const InputDecoration(
                          labelText: 'العنوان',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          selectedAddress = value;
                        },
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 16.h),

              // Date Picker
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(
                        text:
                            intl.DateFormat('MM/dd/yyyy').format(selectedDate),
                      ),
                      decoration: const InputDecoration(
                        labelText: 'تاريخ الحجز',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(DateTime.now().year),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (pickedDate != null && pickedDate != selectedDate) {
                          // Use a local state variable instead of setState on the parent
                          selectedDate = pickedDate;
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(DateTime.now().year),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (pickedDate != null && pickedDate != selectedDate) {
                        selectedDate = pickedDate;
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              // Time Picker
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(
                        text: selectedTime.format(context),
                      ),
                      decoration: const InputDecoration(
                        labelText: 'تاريخ بداية الحجز',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (pickedTime != null && pickedTime != selectedTime) {
                          selectedTime = pickedTime;
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (pickedTime != null && pickedTime != selectedTime) {
                        selectedTime = pickedTime;
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Dropdown for Number of Hours
              // Row(
              //   children: [
              //     Expanded(
              //       child: DropdownButtonFormField<double>(
              //         value: selectedHours,
              //         items: const [
              //           DropdownMenuItem<double>(
              //             value: 1.5,
              //             child: Text('ساعة ونصف'),
              //           ),
              //           DropdownMenuItem<double>(
              //             value: 2.0,
              //             child: Text('ساعتين'),
              //           )
              //         ],
              //         onChanged: (value) {
              //           if (value != null) {
              //             selectedHours = value;
              //           }
              //         },
              //         decoration: const InputDecoration(
              //           labelText: 'عدد الساعات',
              //           border: OutlineInputBorder(),
              //         ),
              //       ),
              //     ),
              //   ],
              // ),
              // SizedBox(height: 16.h),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      logStep('booking_details_booking_updated', data: {
                        'order_id': _orderCourseModel.id?.toString(),
                        'has_address': selectedAddress.isNotEmpty,
                      });
                      await context
                          .read(ApiProviders.subscriptionsProvider)
                          .updateOrder(
                              context: context,
                              orderId: _orderCourseModel.id ?? 0,
                              orderType: _orderCourseModel.orderType.toString(),
                              address: selectedAddress,
                              date: selectedDate,
                              time: selectedTime,
                              numberOfHours: selectedHours);
                      Navigator.pop(context);
                      print(
                          'Saved: $selectedAddress, $selectedDate, $selectedTime, $selectedHours');
                    },
                    child: const Text('حفظ'),
                  ),
                  SizedBox(width: 16.h),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('إغلاق'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRenewBookingDialog(BuildContext context) {
    logButtonClick('booking_details_renew_booking', data: {
      'order_id': _orderCourseModel.id?.toString(),
    });

    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
    final TextEditingController purposeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
          ),
          child: Container(
            padding: EdgeInsets.all(20.r),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header with icon
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: context.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.refresh,
                          color: context.success,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'تجديد حجز الحصة',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: context.primaryText,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),

                  // Date Field
                  Text(
                    'تاريخ الحصة *',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: context.primaryText,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: TextEditingController(
                      text: intl.DateFormat('yyyy/MM/dd').format(selectedDate),
                    ),
                    decoration: InputDecoration(
                      labelText: 'اختر التاريخ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      prefixIcon: const Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: bottomSheetContext,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (pickedDate != null) {
                        selectedDate = pickedDate;
                      }
                    },
                  ),
                  SizedBox(height: 16.h),

                  // Time Field
                  Text(
                    'وقت الحصة *',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: context.primaryText,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: TextEditingController(
                      text: selectedTime.format(bottomSheetContext),
                    ),
                    decoration: InputDecoration(
                      labelText: 'اختر الوقت',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      prefixIcon: const Icon(Icons.access_time),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final pickedTime = await showTimePicker(
                        context: bottomSheetContext,
                        initialTime: selectedTime,
                      );
                      if (pickedTime != null) {
                        selectedTime = pickedTime;
                      }
                    },
                  ),
                  SizedBox(height: 16.h),

                  // Purpose Field (Optional)
                  Text(
                    'الغرض من الحصة (اختياري)',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: context.primaryText,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: purposeController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'مثال: مراجعة للامتحان النهائي',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(bottomSheetContext),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.secondary.withOpacity(0.1),
                            foregroundColor: context.secondary,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            'إلغاء',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        flex: 2,
                        child: Consumer(
                          builder: (ctx, ref, _) {
                            return ElevatedButton(
                              onPressed: () async {
                                // Validate
                                if (selectedDate.isBefore(DateTime.now())) {
                                  CommonComponents.showCustomizedSnackBar(
                                    context: context,
                                    title: 'يرجى اختيار تاريخ مستقبلي',
                                  );
                                  return;
                                }

                                Navigator.pop(bottomSheetContext);

                                logStep('booking_details_renewing', data: {
                                  'order_id': _orderCourseModel.id?.toString(),
                                  'has_purpose':
                                      purposeController.text.trim().isNotEmpty,
                                });

                                // Call API to renew booking
                                final renewedBooking = await ref
                                    .read(ApiProviders.subscriptionsProvider)
                                    .renewOrder(
                                      context: context,
                                      orderId: _orderCourseModel.id ?? 0,
                                      bookingDate: selectedDate,
                                      bookingTime: selectedTime,
                                      purpose: purposeController.text.trim(),
                                    );

                                if (renewedBooking != null && context.mounted) {
                                  logStep('booking_details_renewed_success',
                                      data: {
                                        'order_id':
                                            _orderCourseModel.id?.toString(),
                                      });

                                  providerAppContainer
                                      .read(ApiProviders.bookingProvider)
                                      .setCustomerBooking(renewedBooking);

                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    NavigationService.router
                                        ?.push('/booking-payment');
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.success,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.refresh, size: 18.sp),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'تجديد الحجز',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showStudentNoteDialog(BuildContext context) {
    logButtonClick('booking_details_add_note', data: {
      'order_id': _orderCourseModel.id?.toString(),
    });

    final TextEditingController noteController = TextEditingController();
    noteController.text = _orderCourseModel.ratingStudent ?? '';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.note, color: context.primary),
              const SizedBox(width: 8),
              const Text('إضافة ملاحظة'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: noteController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'اكتب ملاحظتك هنا...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide:
                        BorderSide(color: context.secondary.withOpacity(0.3)),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'ستساعدك هذه الملاحظة في تذكر التفاصيل المهمة حول الدرس',
                style: TextStyle(
                    fontSize: 12.sp,
                    color: context.secondaryText.withOpacity(0.8),
                    fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                final note = noteController.text.trim();
                if (note.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('يرجى كتابة ملاحظة قبل الحفظ'),
                        backgroundColor: Colors.orange),
                  );
                  return;
                }
                logStep('booking_details_note_saved', data: {
                  'order_id': _orderCourseModel.id?.toString(),
                  'note_length': note.length,
                });
                await context
                    .read(ApiProviders.subscriptionsProvider)
                    .saveStudentNote(
                      context: context,
                      orderCourseId: _orderCourseModel.id!,
                      note: note,
                    );
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  // ===================== Single session =====================

  Widget _singleSessionSection() {
    final steps = _buildStepsFromState(
        _orderCourseModel.orderStatus ?? _orderCourseModel.state ?? 'pending');

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
          color: context.surface, borderRadius: BorderRadius.circular(12.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('حالة الحصة',
              style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: context.primaryText)),
          SizedBox(height: 12.h),
          _horizontalTimeline(steps),
        ],
      ),
    );
  }

  // ===================== Course (sessions list + timeline per session) ======

  Widget _courseSection() {
    final CourseModel? course = _orderCourseModel.course;
    final sessionsCount =
        int.tryParse(_orderCourseModel.numberOfSessions ?? '') ??
            (course?.collectionPrice ?? 0);

    final safeCount = sessionsCount > 0 ? sessionsCount : 1;

    final sessions = List.generate(
      safeCount,
      (i) => _SessionInfo(
        number: i + 1,
        title: 'الحصة رقم ${i + 1}',
        status:
            _orderCourseModel.orderStatus ?? course?.orderStatus ?? 'pending',
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(12.r)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('معلومات الكورس',
                  style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: context.primaryText)),
              SizedBox(height: 10.h),
              _infoRow('اسم الكورس', course?.productName ?? '-'),
              _infoRow(
                  'رقم الطلب',
                  course?.newOrderNumber ??
                      _orderCourseModel.orderNumber ??
                      '-'),
              _infoRow('حالة الكورس', _arabicStatus(course?.orderStatus)),
              _infoRow(
                  'المعلم',
                  course?.teacher?.name ??
                      _orderCourseModel.teacherName ??
                      '-'),
              _infoRow('عدد الحصص', safeCount.toString()),
              _infoRow(
                  'السعر',
                  (course?.price ?? int.tryParse(_orderCourseModel.price ?? ''))
                          ?.toString() ??
                      '-'),
              _infoRow('حالة التحصيل', course?.collectionStatus ?? '-'),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Text('حصص الكورس',
            style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: context.primaryText)),
        SizedBox(height: 12.h),
        ...sessions.map((s) => _sessionCard(s)).toList(),
      ],
    );
  }

  Widget _infoRow(String k, String? v) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          SizedBox(
              width: 120.w,
              child: Text(k, style: TextStyle(color: context.secondaryText))),
          Expanded(
              child: Text((v == null || v.isEmpty) ? '-' : v,
                  style: TextStyle(
                      color: context.primaryText,
                      fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _sessionCard(_SessionInfo s) {
    final steps = _buildStepsFromState(s.status ?? 'pending');

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
          color: context.surface, borderRadius: BorderRadius.circular(12.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.title,
                  style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: context.primaryText)),
              Text('رقم ${s.number}',
                  style: TextStyle(color: context.secondaryText)),
            ],
          ),
          SizedBox(height: 8.h),
          _horizontalTimeline(steps),
          SizedBox(height: 10.h),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _navigateToChat(context),
                icon: Icon(Icons.chat_bubble_outline, color: context.accent),
                label: const Text('رسالة'),
              ),
              SizedBox(width: 8.w),
              TextButton.icon(
                onPressed: () => _showStudentNoteDialog(context),
                icon: Icon(Icons.note_add_outlined, color: context.secondary),
                label: const Text('ملاحظة'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _showTeacherRatingDialog(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: context.accent,
                    foregroundColor: context.textOnAccent),
                child: const Text('تقييم المدرس'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===================== Modern Timeline =====================

  Widget _modernHorizontalTimeline(List<_StepInfo> steps) {
    return SizedBox(
      height: 100.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: steps.length,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (_, i) {
          final step = steps[i];
          final active = step.state == StepState.completed ||
              step.state == StepState.current;
          return Container(
            width: 180.w,
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              gradient: active
                  ? LinearGradient(
                      colors: [
                        context.primary.withOpacity(0.1),
                        context.accent.withOpacity(0.1)
                      ],
                    )
                  : null,
              color: active ? null : context.surfaceLight,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: active ? context.primary : context.surfaceLight,
                width: 2,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: context.primary.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: active ? context.primary : context.surfaceLight,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    step.icon,
                    size: 20.sp,
                    color: active ? context.surface : context.secondaryText,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: active
                              ? context.primaryText
                              : context.secondaryText,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        step.subtitle ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: context.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _modernCourseSection() {
    final CourseModel? course = _orderCourseModel.course;
    final sessionsCount =
        int.tryParse(_orderCourseModel.numberOfSessions ?? '') ??
            (course?.collectionPrice ?? 0);
    final safeCount = sessionsCount > 0 ? sessionsCount : 1;

    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: context.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: context.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.school,
                  color: context.accent,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'معلومات الكورس',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: context.primaryText,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          _buildModernCourseInfo(course, safeCount),
        ],
      ),
    );
  }

  Widget _buildModernCourseInfo(CourseModel? course, int sessionsCount) {
    return Column(
      children: [
        _buildModernInfoCard(
          Icons.book,
          'اسم الكورس',
          course?.productName ?? '-',
          context.primary,
        ),
        SizedBox(height: 12.h),
        _buildModernInfoCard(
          Icons.receipt_long,
          'رقم الطلب',
          course?.newOrderNumber ?? _orderCourseModel.orderNumber ?? '-',
          context.accent,
        ),
        SizedBox(height: 12.h),
        _buildModernInfoCard(
          Icons.flag,
          'حالة الكورس',
          _arabicStatus(course?.orderStatus),
          context.secondary,
        ),
        SizedBox(height: 12.h),
        _buildModernInfoCard(
          Icons.person,
          'المعلم',
          course?.teacher?.name ?? _orderCourseModel.teacherName ?? '-',
          context.success,
        ),
        SizedBox(height: 12.h),
        _buildModernInfoCard(
          Icons.event,
          'عدد الحصص',
          sessionsCount.toString(),
          context.accentSecondary,
        ),
        SizedBox(height: 12.h),
        _buildModernInfoCard(
          Icons.attach_money,
          'السعر',
          (course?.price ?? int.tryParse(_orderCourseModel.price ?? ''))
                  ?.toString() ??
              '-',
          context.primary,
        ),
        SizedBox(height: 12.h),
        _buildModernInfoCard(
          Icons.check_circle_outline,
          'حالة التحصيل',
          course?.collectionStatus ?? '-',
          context.success,
        ),
      ],
    );
  }

  Widget _buildModernInfoCard(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: context.background,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.surfaceLight),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, size: 16.sp, color: color),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: context.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: context.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== Timeline =====================

  Widget _horizontalTimeline(List<_StepInfo> steps) {
    return SizedBox(
      height: 76.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: steps.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (_, i) {
          final step = steps[i];
          final active = step.state == StepState.completed ||
              step.state == StepState.current;
          return Container(
            width: 150.w,
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: active ? context.surfaceLight : context.surface,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                  color: active ? context.accent : context.surfaceLight),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16.r,
                  backgroundColor:
                      active ? context.accent : context.surfaceLight,
                  child: Icon(step.icon,
                      size: 18.sp,
                      color: active
                          ? context.textOnAccent
                          : context.secondaryText),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(step.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: context.primaryText)),
                      SizedBox(height: 4.h),
                      Text(step.subtitle ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12.sp, color: context.secondaryText)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<_StepInfo> _buildStepsFromState(String state) {
    final steps = <_StepInfo>[
      _StepInfo(
          icon: Icons.send,
          title: 'أُرسل للمدرسين',
          subtitle: 'تم إرسال طلبك',
          state: StepState.completed),
      _StepInfo(
          icon: Icons.search,
          title: 'اختيار مدرس',
          subtitle: 'نبحث عن مدرس مناسب',
          state: StepState.current),
      _StepInfo(
          icon: Icons.check_circle_outline,
          title: 'اختيار المدرس',
          subtitle: 'تم اختيار المدرس',
          state: StepState.pending),
      _StepInfo(
          icon: Icons.play_circle_outline,
          title: 'بدء الحصة',
          subtitle: 'الحصة بدأت',
          state: StepState.pending),
      _StepInfo(
          icon: Icons.verified,
          title: 'مراجعة',
          subtitle: 'بانتظار المراجعة',
          state: StepState.pending),
      _StepInfo(
          icon: Icons.done_all,
          title: 'مكتمل',
          subtitle: 'اكتملت الحصة',
          state: StepState.pending),
    ];

    switch (state) {
      case 'تم_الارسال_للمدرسين':
      case 'انتظار':
        steps[0] = steps[0].copyWith(state: StepState.completed);
        steps[1] = steps[1].copyWith(state: StepState.current);
        break;
      case 'تم_اختيار_مدرس':
        steps[0] = steps[0].copyWith(state: StepState.completed);
        steps[1] = steps[1].copyWith(state: StepState.completed);
        steps[2] = steps[2].copyWith(state: StepState.current);
        break;
      case 'قيد_العمل':
        for (var i = 0; i <= 2; i++) {
          steps[i] = steps[i].copyWith(state: StepState.completed);
        }
        steps[3] = steps[3].copyWith(state: StepState.current);
        break;
      case 'انتظار_مراجعة':
        for (var i = 0; i <= 3; i++) {
          steps[i] = steps[i].copyWith(state: StepState.completed);
        }
        steps[4] = steps[4].copyWith(state: StepState.current);
        break;
      case 'مكتمل':
        for (var i = 0; i < steps.length; i++) {
          steps[i] = steps[i].copyWith(state: StepState.completed);
        }
        break;
      case 'عدم_اكتمال':
        for (var i = 0; i < steps.length; i++) {
          steps[i] = steps[i].copyWith(
              state: i <= 3 ? StepState.completed : StepState.pending);
        }
        steps.add(_StepInfo(
            icon: Icons.error_outline,
            title: 'غير مكتمل',
            subtitle: 'تم إنهاء الحصة دون اكتمال',
            state: StepState.current));
        break;
      default:
        steps[0] = steps[0].copyWith(state: StepState.completed);
        steps[1] = steps[1].copyWith(state: StepState.current);
    }
    return steps;
  }
}

// ===================== Helpers models for UI only =====================

class _SessionInfo {
  final int number;
  final String title;
  final String? status;

  _SessionInfo({required this.number, required this.title, this.status});
}

enum StepState { pending, current, completed }

class _StepInfo {
  final IconData icon;
  final String title;
  final String? subtitle;
  final StepState state;

  _StepInfo({
    required this.icon,
    required this.title,
    this.subtitle,
    this.state = StepState.pending,
  });

  _StepInfo copyWith(
      {IconData? icon, String? title, String? subtitle, StepState? state}) {
    return _StepInfo(
      icon: icon ?? this.icon,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      state: state ?? this.state,
    );
  }
}
