import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';

class NewsNotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final String time;
  final bool isRead;
  final VoidCallback onTap;

  const NewsNotificationCard({
    super.key,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isRead ? context.surface : context.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isRead
              ? context.secondary.withOpacity(0.1)
              : context.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: context.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.newspaper,
                    color: context.primary,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight:
                                    isRead ? FontWeight.w500 : FontWeight.w600,
                                color: isRead
                                    ? context.primaryText
                                    : context.primaryText,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8.w,
                              height: 8.h,
                              decoration: BoxDecoration(
                                color: context.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: context.secondaryText,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: context.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  Icons.arrow_forward_ios,
                  color: context.secondaryText,
                  size: 16.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NewsNotificationsSection extends StatelessWidget {
  const NewsNotificationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final newsNotifications = [
      {
        'title': 'إطلاق منصة تعليمية جديدة',
        'message': 'تم إطلاق منصة تعليمية شاملة تقدم محتوى عالي الجودة للطلاب',
        'time': 'منذ ساعتين',
        'isRead': false,
      },
      {
        'title': 'تحديث المناهج الدراسية',
        'message': 'تم تحديث المناهج الدراسية للعام الجديد مع إضافة مواد جديدة',
        'time': 'منذ 5 ساعات',
        'isRead': false,
      },
      {
        'title': 'ورشة عمل للمدرسين',
        'message': 'ورشة عمل متخصصة حول التعليم الرقمي وأحدث التقنيات',
        'time': 'منذ يوم واحد',
        'isRead': true,
      },
      {
        'title': 'نتائج الامتحانات متاحة',
        'message': 'يمكن للطلاب الاطلاع على نتائج الامتحانات النهائية',
        'time': 'منذ يومين',
        'isRead': true,
      },
      {
        'title': 'جديد: تطبيق الهاتف المحمول',
        'message': 'تم إطلاق تطبيق الهاتف المحمول للوصول السريع للمحتوى',
        'time': 'منذ 3 أيام',
        'isRead': true,
      },
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'أخبار تهمك',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: context.primaryText,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Mark all as read
                },
                child: Text(
                  'تحديد الكل كمقروء',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: context.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Notifications List
          ...newsNotifications.map((notification) => NewsNotificationCard(
                title: notification['title'] as String,
                message: notification['message'] as String,
                time: notification['time'] as String,
                isRead: notification['isRead'] as bool,
                onTap: () {
                  // Handle notification tap
                },
              )),
          // View All Button
          SizedBox(height: 16.h),
          Center(
            child: OutlinedButton.icon(
              onPressed: () {
                // Navigate to full news screen
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: context.primary,
                side: BorderSide(color: context.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
              icon: Icon(Icons.newspaper, size: 16.sp),
              label: Text(
                'عرض جميع الأخبار',
                style: TextStyle(fontSize: 14.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
