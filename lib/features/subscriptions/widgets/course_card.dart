import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/core/models/learning_course_model.dart';
import 'package:private_4t_app/core/services/navigation_service.dart';
import 'package:private_4t_app/core/utils/constants.dart';
import 'package:private_4t_app/core/widgets/optimized_cached_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';

class CourseCard extends ConsumerWidget {
  final LearningCourseModel course;
  final bool isExpired;

  const CourseCard({
    super.key,
    required this.course,
    this.isExpired = false,
  });

  final progress = 0;

  // Navigate to chat room for this course
  void _navigateToChat(BuildContext context) {
    if (course.matrixRoomId != null && course.matrixRoomId!.isNotEmpty) {
      NavigationService.navigateToRoomTimeline(context, course.matrixRoomId!);
    }
  }

  // Share the app
  Future<void> _shareApp(BuildContext context) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final appName = packageInfo.appName;

      final shareText = '''🎓 $appName - تطبيق التعلم الذكي

تطبيق تعليمي متطور يوفر:
📚 دروس فيديو تعليمية عالية الجودة
🎯 حجز دروس خصوصية مع أفضل المعلمين
📖 مكتبة تعليمية شاملة ومتنوعة
🎬 مقاطع تعليمية قصيرة (Clips)
💬 تواصل مباشر مع المعلمين والطلاب

🌐 موقع الويب: https://private-4t.com

📱 تحميل التطبيق:
• Android: https://play.google.com/store/apps/details?id=com.private_4t.app
• iOS: https://apps.apple.com/app/private-4t/id123456789

🚀 ابدأ رحلتك التعليمية معنا الآن!''';

      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: 'جرب تطبيق $appName',
          sharePositionOrigin:
              box != null ? box.localToGlobal(Offset.zero) & box.size : null,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('خطأ في مشاركة التطبيق'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'إعادة المحاولة',
            textColor: Colors.white,
            onPressed: () => _shareApp(context),
          ),
        ),
      );
    }
  }

  // Show course list/contents
  void _showCourseList(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('محتويات الكورس'),
          content: Text(
              'قائمة محتويات الكورس "${course.title}"\n\nستتمكن من رؤية جميع الدروس والمواد التعليمية المتاحة في هذا الكورس.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to course content
                context.push('/course-viewing', extra: {
                  'courseId': course.id.toString(),
                });
              },
              child: const Text('عرض المحتوى'),
            ),
          ],
        );
      },
    );
  }

  // Show group information
  void _showGroupInfo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('ميزة المجموعات ستكون متاحة قريباً'),
        backgroundColor: context.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Show help information
  void _showHelpInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('مساعدة'),
          content: Text(
              'بحاجة للمساعدة في الكورس "${course.title}"؟\n\nيمكنك التواصل معنا عبر زر المراسلة أو زيارة قسم المساعدة في القائمة الرئيسية.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToChat(context);
              },
              child: const Text('تواصل معنا'),
            ),
          ],
        );
      },
    );
  }

  // Save/bookmark the course using subscription provider
  Future<void> _saveCourse(BuildContext context, WidgetRef ref) async {
    final bool currentSaveStatus = course.isSaved == true;

    try {
      // Call the API to save/unsave the course
      await ref.read(ApiProviders.subscriptionsProvider).saveCourse(
            context: context,
            courseId: course.id.toString(),
          );

      // The API response should update the course model via the provider
      // Show appropriate success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(currentSaveStatus
                ? 'تم إلغاء حفظ الكورس "${course.title}"'
                : 'تم حفظ الكورس "${course.title}" بنجاح'),
            backgroundColor: context.primary,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'تراجع',
              textColor: Colors.white,
              onPressed: () => _saveCourse(context, ref), // Reverse the action
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(currentSaveStatus
                ? 'خطأ في إلغاء حفظ الكورس'
                : 'خطأ في حفظ الكورس'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'إعادة المحاولة',
              textColor: Colors.white,
              onPressed: () => _saveCourse(context, ref),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: context.secondary.withOpacity(0.12),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnail(context),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(context),
                  _buildProgressBar(context),
                  SizedBox(height: 8.h),
                  _buildStatus(context),
                  _buildActions(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    return Container(
      height: 140.h,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12.r),
          topRight: Radius.circular(12.r),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.primary, context.accentSecondary],
        ),
      ),
      child: SizedBox.expand(
        child: OptimizedCachedImage(
          imageUrl: course.thumbnailUrl!,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // removed unused legacy quick action; replaced with unified circle action

  Widget _buildCircleAction(BuildContext context, IconData icon, String tooltip,
      {VoidCallback? onTap, bool isSaved = false}) {
    return Material(
      color: isSaved ? context.primary : Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap ?? () {},
        child: Padding(
          padding: EdgeInsets.all(10.r),
          child: Icon(
            icon,
            size: 18.sp,
            color: isSaved ? Colors.white : context.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            course.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: context.primaryText,
              height: 1.25,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Icon(Icons.science_outlined, color: context.primary, size: 18.sp),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8.h),
        Container(
          height: 6.h,
          decoration: BoxDecoration(
            color: context.secondary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(999.r),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth * (progress / 100);
              return Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: width,
                  decoration: BoxDecoration(
                    color: context.accentSecondary,
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatus(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            '${progress.toInt()}% مكتمل • متاح حتى ${DateTime.december}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.sp,
              color: context.secondaryText,
            ),
          ),
        ),
        if (isExpired)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: context.disabled,
              borderRadius: BorderRadius.circular(999.r),
            ),
            child: Text(
              'منتهي',
              style: TextStyle(
                fontSize: 10.sp,
                color: context.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCircleAction(
                context,
                Icons.chat_bubble,
                'مراسلة',
                onTap: () => _navigateToChat(context),
              ),
              _buildCircleAction(
                context,
                Icons.list_alt,
                'قائمة',
                onTap: () => _showCourseList(context),
              ),
              _buildCircleAction(
                context,
                Icons.share,
                'مشاركة التطبيق',
                onTap: () => _shareApp(context),
              ),
              _buildCircleAction(
                context,
                Icons.groups_2,
                'مجموعة',
                onTap: () => _showGroupInfo(context),
              ),
              _buildCircleAction(
                context,
                Icons.help_outline,
                'مساعدة',
                onTap: () => _showHelpInfo(context),
              ),
              Consumer(
                builder: (context, ref, _) => _buildCircleAction(
                  context,
                  course.isSaved == true
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  course.isSaved == true ? 'محفوظ' : 'حفظ',
                  onTap: () => _saveCourse(context, ref),
                  isSaved: course.isSaved == true,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isExpired
                ? null
                : () {
                    context.push('/course-viewing', extra: {
                      'courseId': course.id.toString(),
                    });
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primary,
              foregroundColor: context.textOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              padding: EdgeInsets.symmetric(vertical: 12.h),
            ),
            icon: Icon(Icons.play_arrow, size: 16.sp),
            label: Text('استمر', style: TextStyle(fontSize: 14.sp)),
          ),
        ),
      ],
    );
  }
}
