import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:private_4t_app/core/widgets/app_header.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.background,
        appBar: const AppHeader(
          title: 'أخبار تهمك',
          showBackButton: true,
          showLogo: false,
          showProfile: false,
          showNotifications: false,
          showMenu: false,
          showCart: false,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              SizedBox(height: 20.h),
              _buildNewsList(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'أخبار تهمك',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            color: context.primaryText,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'آخر الأخبار والتحديثات المهمة في مجال التعليم',
          style: TextStyle(
            fontSize: 14.sp,
            color: context.secondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildNewsList(BuildContext context) {
    final newsItems = [
      {
        'title': 'إطلاق منصة تعليمية جديدة للطلاب',
        'subtitle': 'منصة شاملة تقدم محتوى تعليمي عالي الجودة',
        'image': 'assets/images/news1.jpg',
        'time': 'منذ ساعتين',
        'category': 'تطوير التعليم',
      },
      {
        'title': 'تحديث المناهج الدراسية للعام الجديد',
        'subtitle': 'إضافة مواد جديدة وتحسين المحتوى التعليمي',
        'image': 'assets/images/news2.jpg',
        'time': 'منذ 5 ساعات',
        'category': 'المناهج الدراسية',
      },
      {
        'title': 'ورشة عمل للمدرسين حول التعليم الرقمي',
        'subtitle': 'تدريب متخصص على أحدث تقنيات التعليم',
        'image': 'assets/images/news3.jpg',
        'time': 'منذ يوم واحد',
        'category': 'التدريب المهني',
      },
      {
        'title': 'نتائج الامتحانات النهائية متاحة الآن',
        'subtitle': 'يمكن للطلاب الاطلاع على نتائجهم عبر المنصة',
        'image': 'assets/images/news4.jpg',
        'time': 'منذ يومين',
        'category': 'النتائج',
      },
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: newsItems.length,
      separatorBuilder: (context, index) => SizedBox(height: 16.h),
      itemBuilder: (context, index) {
        final news = newsItems[index];
        return _buildNewsCard(context, news);
      },
    );
  }

  Widget _buildNewsCard(BuildContext context, Map<String, String> news) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // News Image
          Container(
            height: 160.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.primary.withOpacity(0.8),
                  context.accentSecondary.withOpacity(0.6),
                ],
              ),
            ),
            child: Center(
              child: Icon(Icons.newspaper, size: 48.sp, color: Colors.white),
            ),
          ),
          // News Content
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category and Time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: context.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        news['category']!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: context.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      news['time']!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: context.secondaryText,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                // Title
                Text(
                  news['title']!,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: context.primaryText,
                  ),
                ),
                SizedBox(height: 8.h),
                // Subtitle
                Text(
                  news['subtitle']!,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: context.secondaryText,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 16.h),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to full news article
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        icon: Icon(Icons.read_more, size: 16.sp),
                        label: Text(
                          'اقرأ المزيد',
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    IconButton(
                      onPressed: () {
                        // Share news
                      },
                      icon: Icon(
                        Icons.share,
                        color: context.primary,
                        size: 20.sp,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // Bookmark news
                      },
                      icon: Icon(
                        Icons.bookmark_border,
                        color: context.primary,
                        size: 20.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
