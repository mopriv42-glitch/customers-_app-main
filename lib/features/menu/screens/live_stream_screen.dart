import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:private_4t_app/core/widgets/app_header.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';

class LiveStreamScreen extends StatelessWidget {
  const LiveStreamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.background,
        appBar: const AppHeader(
          title: 'البث المباشر',
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
                _buildStreamsList(context),
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
          colors: [context.accentSecondary, context.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Icon(Icons.live_tv, size: 32.sp, color: Colors.white),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'البث المباشر',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'حصص مباشرة وتفاعلية',
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

  Widget _buildStreamsList(BuildContext context) {
    return Expanded(
      child: ListView(
        children: [
          _buildStreamItem(context,
            'درس الرياضيات المباشر',
            'أحمد محمد',
            '3:30 مساءً',
            'مباشر الآن',
            true,
          ),
          _buildStreamItem(
            context,
            'مراجعة العلوم',
            'فاطمة علي',
            '5:00 مساءً',
            'قريباً',
            false,
          ),
          _buildStreamItem(
            context,
            'حل التمارين',
            'خالد حسن',
            '7:00 مساءً',
            'قريباً',
            false,
          ),
          _buildStreamItem(
            context,
            'جلسة أسئلة وأجوبة',
            'سارة أحمد',
            '8:30 مساءً',
            'قريباً',
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildStreamItem(
    BuildContext context,
    String title,
    String teacher,
    String time,
    String status,
    bool isLive,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isLive
              ? Colors.red.withOpacity(0.3)
              : context.accentSecondary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: isLive
                  ? Colors.red.withOpacity(0.1)
                  : context.accentSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.video_camera_front,
                    size: 28.sp,
                    color: isLive ? Colors.red : context.accentSecondary,
                  ),
                ),
                if (isLive)
                  Positioned(
                    top: 4.h,
                    right: 4.w,
                    child: Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'المعلم: $teacher',
                  style: TextStyle(fontSize: 14.sp, color: context.secondary),
                ),
                SizedBox(height: 4.h),
                Text(
                  time,
                  style: TextStyle(fontSize: 12.sp, color: context.secondary),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: isLive ? Colors.red : context.accentSecondary,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
