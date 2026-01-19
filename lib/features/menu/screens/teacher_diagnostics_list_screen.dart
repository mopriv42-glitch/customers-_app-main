import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/widgets/app_header.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class TeacherDiagnosticsListScreen extends ConsumerStatefulWidget {
  const TeacherDiagnosticsListScreen({super.key});

  @override
  ConsumerState<TeacherDiagnosticsListScreen> createState() =>
      _TeacherDiagnosticsListScreenState();
}

class _TeacherDiagnosticsListScreenState
    extends ConsumerState<TeacherDiagnosticsListScreen>
    with AnalyticsScreenMixin {
  @override
  String get screenName => 'TeacherDiagnosticsListScreen';

  bool _isLoading = true;
  List<Map<String, dynamic>> _diagnostics = [];

  @override
  void initState() {
    super.initState();
    _loadDiagnostics();
  }

  Future<void> _loadDiagnostics() async {
    setState(() => _isLoading = true);
    try {
      final diagnostics = await ref
          .read(ApiProviders.teachersProvider)
          .getTeacherDiagnostics(context: context);
      if (mounted) {
        setState(() {
          _diagnostics = diagnostics ?? [];
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
          title: 'تشخيصات المدرسين',
          showBackButton: true,
        ),
        body: SafeArea(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: context.primary,
                  ),
                )
              : _diagnostics.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.medical_services_outlined,
                            size: 64.sp,
                            color: context.secondaryText,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'لا توجد تشخيصات متاحة',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: context.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadDiagnostics,
                      color: context.primary,
                      child: ListView.builder(
                        padding: EdgeInsets.all(16.w),
                        itemCount: _diagnostics.length,
                        itemBuilder: (context, index) {
                          final diagnostic = _diagnostics[index];
                          return _buildDiagnosticCard(diagnostic);
                        },
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildDiagnosticCard(Map<String, dynamic> diagnostic) {
    return GestureDetector(
      onTap: () {
        logButtonClick('diagnostic_card_tapped', data: {
          'diagnostic_id': diagnostic['id']?.toString() ?? '',
        });
        context.push('/teacher-diagnostics/${diagnostic['id']}');
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
                Icons.medical_services,
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
                    diagnostic['title']?.toString() ??
                        diagnostic['name']?.toString() ??
                        'تشخيص بدون عنوان',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: context.primaryText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (diagnostic['teacher_name'] != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      'المدرس: ${diagnostic['teacher_name']}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: context.secondaryText,
                      ),
                    ),
                  ],
                  if (diagnostic['date'] != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      'التاريخ: ${diagnostic['date']}',
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

