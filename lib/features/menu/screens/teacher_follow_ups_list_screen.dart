import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/widgets/app_header.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class TeacherFollowUpsListScreen extends ConsumerStatefulWidget {
  const TeacherFollowUpsListScreen({super.key});

  @override
  ConsumerState<TeacherFollowUpsListScreen> createState() =>
      _TeacherFollowUpsListScreenState();
}

class _TeacherFollowUpsListScreenState
    extends ConsumerState<TeacherFollowUpsListScreen>
    with AnalyticsScreenMixin {
  @override
  String get screenName => 'TeacherFollowUpsListScreen';

  bool _isLoading = true;
  List<Map<String, dynamic>> _followUps = [];

  @override
  void initState() {
    super.initState();
    _loadFollowUps();
  }

  Future<void> _loadFollowUps() async {
    setState(() => _isLoading = true);
    try {
      final followUps = await ref
          .read(ApiProviders.teachersProvider)
          .getTeacherFollowUps(context: context);
      if (mounted) {
        setState(() {
          _followUps = followUps ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CommonComponents.showCustomizedSnackBar(
          context: context,
          title: 'حدث خطأ أثناء تحميل البيانات',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.background,
        appBar: const AppHeader(
          title: 'متابعات المدرسين',
          showBackButton: true,
        ),
        body: SafeArea(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: context.primary,
                  ),
                )
              : _followUps.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.track_changes_outlined,
                            size: 64.sp,
                            color: context.secondaryText,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'لا توجد متابعات متاحة',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: context.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFollowUps,
                      color: context.primary,
                      child: ListView.builder(
                        padding: EdgeInsets.all(16.w),
                        itemCount: _followUps.length,
                        itemBuilder: (context, index) {
                          final followUp = _followUps[index];
                          return _buildFollowUpCard(followUp);
                        },
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildFollowUpCard(Map<String, dynamic> followUp) {
    return GestureDetector(
      onTap: () {
        logButtonClick('follow_up_card_tapped', data: {
          'follow_up_id': followUp['id']?.toString() ?? '',
        });
        context.push('/teacher-follow-ups/${followUp['id']}');
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
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
        child: Row(
          children: [
            Container(
              width: 50.w,
              height: 50.h,
              decoration: BoxDecoration(
                color: context.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.track_changes,
                size: 24.sp,
                color: context.primary,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    followUp['title']?.toString() ??
                        followUp['name']?.toString() ??
                        'متابعة بدون عنوان',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: context.primaryText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (followUp['teacher_name'] != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      'المدرس: ${followUp['teacher_name']}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: context.secondaryText,
                      ),
                    ),
                  ],
                  if (followUp['date'] != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      'التاريخ: ${followUp['date']}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: context.secondaryText,
                      ),
                    ),
                  ],
                ],
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
    );
  }
}

