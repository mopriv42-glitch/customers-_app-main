import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/core/models/user_model.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/widgets/app_header.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

import 'package:riverpod_context/riverpod_context.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with AnalyticsScreenMixin {
  
  @override
  String get screenName => 'MenuScreen';
  
  UserModel? _loggedUser;

  @override
  void initState() {
    super.initState();
    _loggedUser = context.read(ApiProviders.loginProvider).loggedUser;
  }

  @override
  Widget build(BuildContext context) {
    _loggedUser = context.watch(ApiProviders.loginProvider).loggedUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.background,
        appBar: const AppHeader(
          title: 'قائمة',
          showBackButton: false,
          showLogo: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Column(
                    children: [
                      _buildProfileSection(),
                      SizedBox(height: 24.h),
                      _buildMainMenu(),
                      SizedBox(height: 24.h),
                      _buildBottomActions(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60.w,
            height: 60.h,
            decoration: BoxDecoration(
              color: context.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30.r),
            ),
            child: Icon(
              Icons.person,
              size: 30.sp,
              color: context.primary,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: GestureDetector(
              onTap: () {
                logButtonClick('menu_profile_section');
                context.push('/profile');
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _loggedUser?.name ?? '',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: context.primaryText,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'طالب - ${_loggedUser?.profile?.grade?.grade ?? ''}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: context.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              logButtonClick('menu_profile_edit');
              context.push('/profile');
            },
            icon: Icon(Icons.edit, size: 20.sp, color: context.secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMainMenu() {
    final menuItems = [
      MenuItem(
        icon: Icons.local_offer,
        title: 'العروض',
        subtitle: 'عروض خاصة وحسومات',
        color: context.accent,
        onTap: () => context.push('/offers'),
      ),
      MenuItem(
        icon: Icons.school,
        title: 'مدرسينك',
        subtitle: 'مدرسينك المفضلين',
        color: context.primary,
        onTap: () => context.push('/teachers'),
      ),
      MenuItem(
        icon: Icons.medical_services,
        title: 'تشخيصات المدرسين',
        subtitle: 'تشخيصات وتقييمات المدرسين',
        color: context.accentSecondary,
        onTap: () => context.push('/teacher-diagnostics'),
      ),
      MenuItem(
        icon: Icons.track_changes,
        title: 'متابعات المدرسين',
        subtitle: 'متابعة أداء المدرسين',
        color: context.primary,
        onTap: () => context.push('/teacher-follow-ups'),
      ),
      // MenuItem(
      //   icon: Icons.folder,
      //   title: 'ملفاتي',
      //   subtitle: 'مذكرات وكتب مدرسية',
      //   color: context.accentSecondary,
      //   onTap: () => context.push('/files'),
      // ),
      // MenuItem(
      //   icon: Icons.calendar_today,
      //   title: 'التقويم',
      //   subtitle: 'جدول الحصص والمواعيد',
      //   color: context.primary,
      //   onTap: () => context.push('/calendar'),
      // ),
      MenuItem(
        icon: Icons.person_add,
        title: 'دعوة الأصدقاء',
        subtitle: 'شارك التطبيق مع أصدقائك',
        color: context.accentSecondary,
        onTap: () => context.push('/invite-friends'),
      ),
      MenuItem(
        icon: Icons.share,
        title: 'مشاركة',
        subtitle: 'شارك المحتوى مع الآخرين',
        color: context.accent,
        onTap: () => context.push('/share-app'),
      ),
      MenuItem(
        icon: Icons.shopping_cart,
        title: 'السلة',
        subtitle: 'المشتريات والحجوزات',
        color: context.primary,
        onTap: () => context.push('/cart'),
      ),
      // MenuItem(
      //   icon: Icons.favorite,
      //   title: 'المفضلة',
      //   subtitle: 'المحتوى المحفوظ',
      //   color: context.accent,
      //   onTap: () => context.push('/favorites'),
      // ),
      // MenuItem(
      //   icon: Icons.quiz,
      //   title: 'الاختبارات',
      //   subtitle: 'اختبارات وتقييمات',
      //   color: context.accentSecondary,
      //   onTap: () => context.push('/exams'),
      // ),
      // MenuItem(
      //   icon: Icons.trending_up,
      //   title: 'التقدم',
      //   subtitle: 'إحصائيات وتقدم التعلم',
      //   color: context.primary,
      //   onTap: () => context.push('/progress'),
      // ),
      // MenuItem(
      //   icon: Icons.live_tv,
      //   title: 'البث المباشر',
      //   subtitle: 'حصص مباشرة',
      //   color: context.accentSecondary,
      //   onTap: () => context.push('/live-stream'),
      // ),
      MenuItem(
        icon: Icons.person,
        title: 'الملف الشخصي',
        subtitle: 'تعديل البيانات الشخصية',
        color: context.primary,
        onTap: () => context.push('/profile'),
      ),
      MenuItem(
        icon: Icons.settings,
        title: 'الإعدادات',
        subtitle: 'إعدادات التطبيق',
        color: context.secondary,
        onTap: () => context.push('/settings'),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 1.r, // Increased height to prevent overflow
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        return _buildMenuItem(menuItems[index], context);
      },
    );
  }

  Widget _buildMenuItem(MenuItem item, BuildContext context) {
    return GestureDetector(
      onTap: () {
        logButtonClick('menu_item', data: {
          'item_title': item.title,
        });
        item.onTap();
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: context.secondary.withOpacity(0.1),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Use minimum required space
          children: [
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                item.icon,
                size: 20.sp,
                color: item.color,
              ),
            ),
            SizedBox(height: 10.h), // Reduced spacing
            Flexible(
              // Make title flexible
              child: Text(
                item.title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: context.primaryText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 3.h), // Reduced spacing
            Expanded(
              // Allow subtitle to take remaining space
              child: Text(
                item.subtitle,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: context.secondaryText,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            logButtonClick('menu_help_support');
            context.push('/help-support');
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.help_outline,
                  size: 20.sp,
                  color: context.secondary,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'مساعدة ودعم',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: context.primaryText,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16.sp,
                  color: context.secondary,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 12.h),
        GestureDetector(
          onTap: () async {
            logButtonClick('menu_logout');
            await context
                .read(ApiProviders.loginProvider)
                .userLogout(context: context);

            if (mounted) {
              context.go('/welcome');
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.logout,
                  size: 20.sp,
                  color: context.error,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'تسجيل الخروج',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: context.error,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16.sp,
                  color: context.error,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}
