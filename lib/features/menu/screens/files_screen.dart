import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/core/widgets/app_header.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/features/home/widgets/animated_tools_card.dart';

class FilesScreen extends StatelessWidget {
  const FilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.background,
        appBar: const AppHeader(
          title: 'ملفاتي',
          showBackButton: true,
          showLogo: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                SizedBox(height: 24.h),
                _buildFilesList(context),
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
          Icon(Icons.folder, size: 32.sp, color: Colors.white),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ملفاتي التعليمية',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'مذكرات وكتب مدرسية منظمة',
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

  Widget _buildFilesList(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      childAspectRatio: 1.4,
      children: [
        AnimatedToolsCard(
          title: 'مذكرات',
          icon: Icons.note_alt,
          gradientStart: const Color(0xFF667eea),
          gradientEnd: const Color(0xFF764ba2),
          onTap: () {
            context.push('/notes');
          },
        ),
        AnimatedToolsCard(
          title: 'كتب مدرسية',
          icon: Icons.menu_book,
          gradientStart: const Color(0xFFf093fb),
          gradientEnd: const Color(0xFFf5576c),
          onTap: () {
            context.push('/notes', extra: 'كتب');
          },
        ),
        AnimatedToolsCard(
          title: 'حلول الكتب المدرسية',
          icon: Icons.assignment_turned_in,
          gradientStart: const Color(0xFF4facfe),
          gradientEnd: const Color(0xFF00f2fe),
          onTap: () {
            context.push('/notes', extra: 'حلول');
          },
        ),
        AnimatedToolsCard(
          title: 'تقارير مدرسية',
          icon: Icons.assessment,
          gradientStart: const Color(0xFF43e97b),
          gradientEnd: const Color(0xFF38f9d7),
          onTap: () {
            context.push('/notes', extra: 'تقارير');
          },
        ),
      ],
    );
  }
}
