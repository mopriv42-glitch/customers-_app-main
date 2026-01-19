import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/models/teacher_model.dart';
import 'package:private_4t_app/core/widgets/optimized_cached_image.dart';
import 'package:riverpod_context/riverpod_context.dart';

class TeacherCard extends StatefulWidget {
  final TeacherModel teacher;
  final VoidCallback? onContact;

  const TeacherCard({
    super.key,
    required this.teacher,
    this.onContact,
  });

  @override
  State<TeacherCard> createState() => _TeacherCardState();
}

class _TeacherCardState extends State<TeacherCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: EdgeInsets.only(bottom: 16.h),
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
                border: Border.all(
                  color: context.surfaceLight,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  _buildContent(context),
                  _buildActions(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.primary.withOpacity(0.05),
            context.accent.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Row(
        children: [
          _buildAvatar(context),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.teacher.name ?? 'مدرس',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: context.primaryText,
                        ),
                      ),
                    ),
                    _buildOnlineStatus(context),
                  ],
                ),
                SizedBox(height: 8.h),
                _buildRating(context),
                SizedBox(height: 4.h),
                Text(
                  widget.teacher.bio ?? 'مدرس متخصص',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 70.w,
          height: 70.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [context.primary, context.accent],
            ),
            borderRadius: BorderRadius.circular(35.r),
            boxShadow: [
              BoxShadow(
                color: context.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: widget.teacher.avatar != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(35.r),
                  child: OptimizedCachedImage(
                    imageUrl: widget.teacher.avatar!,
                    errorWidget: Icon(
                      Icons.person,
                      size: 35.sp,
                      color: context.surface,
                    ),
                  ),
                )
              : Icon(
                  Icons.person,
                  size: 35.sp,
                  color: context.surface,
                ),
        ),
        if (widget.teacher.isOnline == true)
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 16.w,
              height: 16.h,
              decoration: BoxDecoration(
                color: context.success,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: context.surface,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOnlineStatus(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: widget.teacher.isOnline == true
            ? context.success.withOpacity(0.1)
            : context.secondaryText.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.w,
            height: 6.h,
            decoration: BoxDecoration(
              color: widget.teacher.isOnline == true
                  ? context.success
                  : context.secondaryText,
              borderRadius: BorderRadius.circular(3.r),
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            widget.teacher.isOnline == true ? 'متصل' : 'غير متصل',
            style: TextStyle(
              fontSize: 10.sp,
              color: widget.teacher.isOnline == true
                  ? context.success
                  : context.secondaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRating(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.star,
          size: 16.sp,
          color: context.accent,
        ),
        SizedBox(width: 4.w),
        Text(
          widget.teacher.rating?.toStringAsFixed(1) ?? '0.0',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: context.primaryText,
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          '(${widget.teacher.totalLessons ?? 0} حصة)',
          style: TextStyle(
            fontSize: 12.sp,
            color: context.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            context,
            Icons.school,
            'التخصصات',
            widget.teacher.subjects?.join(', ') ?? 'غير محدد',
            context.primary,
          ),
          SizedBox(height: 12.h),
          _buildInfoRow(
            context,
            Icons.grade,
            'المراحل',
            widget.teacher.grades?.join(', ') ?? 'غير محدد',
            context.accent,
          ),
          SizedBox(height: 12.h),
          _buildInfoRow(
            context,
            Icons.work,
            'الخبرة',
            widget.teacher.experience ?? 'غير محدد',
            context.success,
          ),
          SizedBox(height: 12.h),
          _buildInfoRow(
            context,
            Icons.people,
            'عدد الطلاب',
            '${widget.teacher.totalStudents ?? 0} طالب',
            context.accentSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(
              icon,
              size: 14.sp,
              color: color,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: context.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.sp,
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

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              context,
              Icons.chat_bubble_outline,
              'تواصل',
              context.accentSecondary,
              widget.onContact,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildActionButton(
              context,
              Icons.star_outline,
              'تقييم',
              context.primary,
              () async {
                final TextEditingController notesController =
                    TextEditingController();

                if (!mounted) return;

                CommonComponents.loading(context);

                notesController.text = (await context
                        .read(ApiProviders.teachersProvider)
                        .getTeacherRate(widget.teacher.id.toString())) ??
                    '';

                if (context.mounted) context.pop();

                showDialog(
                  context: context,
                  builder: (ctx) {
                    return AlertDialog(
                      title: const Text('تقييم المدرس',
                          textAlign: TextAlign.right),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('التقييم'),
                            const SizedBox(height: 8),
                            TextField(
                              controller: notesController,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder()),
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
                            if (notesController.text.isEmpty) {
                              CommonComponents.showCustomizedSnackBar(
                                  context: context,
                                  title: 'يرجى إدخال التقييم');
                              return;
                            }
                            var ok = await context
                                .read(ApiProviders.teachersProvider)
                                .addTeacherRate(
                                  widget.teacher.id.toString(),
                                  notesController.text.trim(),
                                );

                            if (ok && mounted) Navigator.pop(ctx);
                          },
                          child: const Text('تقييم'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20.sp,
              color: color,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
