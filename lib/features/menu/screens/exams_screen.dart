import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:private_4t_app/core/widgets/app_header.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';

class ExamsScreen extends StatelessWidget {
  const ExamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.background,
        appBar: const AppHeader(
          title: 'الاختبارات',
          showBackButton: true,
          showLogo: false,
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                SizedBox(height: 24.h),
                _buildExamsList(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.accentSecondary, context.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Icon(Icons.quiz, size: 32.sp, color: Colors.white),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الاختبارات والتقييمات',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'اختبر معلوماتك وتابع تقدمك',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamsList(BuildContext context) {
    return Expanded(
      child: ListView(
        children: [
          _buildExamItem(context,'اختبار الرياضيات - الوحدة الأولى', '20 سؤال',
              '30 دقيقة', 'متاح'),
          _buildExamItem(context,
              'اختبار العلوم - الفصل الثاني', '15 سؤال', '25 دقيقة', 'مكتمل'),
          _buildExamItem(context,'اختبار اللغة العربية', '25 سؤال', '40 دقيقة', 'متاح'),
          _buildExamItem(context,'اختبار التاريخ', '18 سؤال', '35 دقيقة', 'قريباً'),
        ],
      ),
    );
  }

  Widget _buildExamItem(
      BuildContext context, String title, String questions, String duration, String status) {
    Color statusColor = status == 'متاح'
        ? context.accentSecondary
        : status == 'مكتمل'
            ? context.accent
            : context.secondary;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(Icons.assignment, size: 24.sp, color: statusColor),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 16.sp, fontWeight: FontWeight.w600)),
                SizedBox(height: 4.h),
                Text('$questions • $duration',
                    style:
                        TextStyle(fontSize: 14.sp, color: context.secondary)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              status,
              style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
