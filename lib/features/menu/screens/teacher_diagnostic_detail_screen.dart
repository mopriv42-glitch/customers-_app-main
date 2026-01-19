import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/widgets/app_header.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class TeacherDiagnosticDetailScreen extends ConsumerStatefulWidget {
  final String diagnosticId;

  const TeacherDiagnosticDetailScreen({
    super.key,
    required this.diagnosticId,
  });

  @override
  ConsumerState<TeacherDiagnosticDetailScreen> createState() =>
      _TeacherDiagnosticDetailScreenState();
}

class _TeacherDiagnosticDetailScreenState
    extends ConsumerState<TeacherDiagnosticDetailScreen>
    with AnalyticsScreenMixin {
  @override
  String get screenName => 'TeacherDiagnosticDetailScreen';

  bool _isLoading = true;
  Map<String, dynamic>? _diagnostic;

  @override
  void initState() {
    super.initState();
    _loadDiagnostic();
  }

  Future<void> _loadDiagnostic() async {
    setState(() => _isLoading = true);
    try {
      final diagnostic = await ref
          .read(ApiProviders.teachersProvider)
          .getTeacherDiagnosticDetail(
            context: context,
            diagnosticId: widget.diagnosticId,
          );
      if (mounted) {
        setState(() {
          _diagnostic = diagnostic;
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
          title: 'تفاصيل التشخيص',
          showBackButton: true,
        ),
        body: SafeArea(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: context.primary,
                  ),
                )
              : _diagnostic == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64.sp,
                            color: context.error,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'لم يتم العثور على التشخيص',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: context.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadDiagnostic,
                      color: context.primary,
                      child: Padding(
                        padding: EdgeInsets.all(12.w),
                        child: _buildDiagnosticContent(),
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildDiagnosticContent() {
    final data = _diagnostic!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header Section
        _buildHeaderSection(data),
        SizedBox(height: 8.h),

        // Body Sections (from API structure)
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _buildBodySections(data),
            ),
          ),
        ),

        // Footer Section (Teacher Name and Date)
        if (_hasAnyValue(data, [
          'teacher_name',
          'teacherName',
          'teacher',
          'date',
          'report_date',
          'reportDate',
          'created_at'
        ])) ...[
          SizedBox(height: 8.h),
          _buildFooterSection(data),
        ],
      ],
    );
  }

  List<Widget> _buildBodySections(Map<String, dynamic> data) {
    final List<Widget> sections = [];

    // Check if data contains 'sections' array (new API structure)
    if (data.containsKey('sections') && data['sections'] is List) {
      final sectionsList = data['sections'] as List;
      for (var sectionData in sectionsList) {
        if (sectionData is Map<String, dynamic> &&
            sectionData.containsKey('section')) {
          final section = sectionData['section'] as Map<String, dynamic>;
          final sectionLabel = section['label']?.toString() ?? '';
          final items = section['items'] as List? ?? [];

          if (sectionLabel.isNotEmpty && items.isNotEmpty) {
            final List<Widget> sectionChildren = [];

            for (var item in items) {
              if (item is Map<String, dynamic>) {
                final label = item['label']?.toString() ?? '';
                final text = item['text']?.toString() ?? '';

                if (text.isNotEmpty) {
                  // Check if this is a message/vision section (long text)
                  if (sectionLabel.contains('رؤية') ||
                      sectionLabel.contains('خلاصة') ||
                      sectionLabel.contains('رسالة') ||
                      sectionLabel.contains('message')) {
                    sectionChildren.add(_buildMessageCard(text));
                  } else {
                    sectionChildren.add(_buildInfoRow(label, text));
                  }
                }
              }
            }

            if (sectionChildren.isNotEmpty) {
              sections.add(
                _buildSection(
                  title: sectionLabel,
                  children: sectionChildren,
                ),
              );
              sections.add(SizedBox(height: 10.h));
            }
          }
        }
      }
    }

    return sections;
  }

  Widget _buildHeaderSection(Map<String, dynamic> data) {
    String subject = _getValue(data, [
      'subject',
      'subject_name',
      'subjectName',
      'material',
      'material_name'
    ]);
    String title =
        _getValue(data, ['title', 'name', 'report_title', 'reportTitle']);

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: context.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: context.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.medical_services,
                size: 22.sp,
                color: context.primary,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title.isNotEmpty ? title : 'تقرير التشخيص + خطة التحسين',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: context.primaryText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (subject.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              subject,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: context.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          SizedBox(height: 4.h),
          Text(
            'قبل بداية البرنامج وأثناء التخطيط',
            style: TextStyle(
              fontSize: 12.sp,
              color: context.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      width: double.infinity,
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: context.primaryText,
            ),
          ),
          SizedBox(height: 10.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: context.secondaryText,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: context.primaryText,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(String message) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: context.primary.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
          color: context.primaryText,
          height: 1.4,
        ),
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildFooterSection(Map<String, dynamic> data) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: context.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_hasValue(data, ['teacher_name', 'teacherName', 'teacher']))
            Expanded(
              child: Text(
                'تم بواسطة: ${_getValue(data, [
                      'teacher_name',
                      'teacherName',
                      'teacher'
                    ])}',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: context.secondaryText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (_hasValue(
              data, ['date', 'report_date', 'reportDate', 'created_at']))
            Text(
              'تاريخ التقرير: ${_formatDate(_getValue(data, [
                    'date',
                    'report_date',
                    'reportDate',
                    'created_at'
                  ]))}',
              style: TextStyle(
                fontSize: 11.sp,
                color: context.secondaryText,
              ),
            ),
        ],
      ),
    );
  }

  bool _hasValue(Map<String, dynamic> data, List<String> keys) {
    for (var key in keys) {
      if (data.containsKey(key) && data[key] != null && data[key] != '') {
        return true;
      }
    }
    return false;
  }

  bool _hasAnyValue(Map<String, dynamic> data, List<String> keys) {
    return keys.any(
        (key) => data.containsKey(key) && data[key] != null && data[key] != '');
  }

  String _getValue(Map<String, dynamic> data, List<String> keys) {
    for (var key in keys) {
      if (data.containsKey(key) && data[key] != null && data[key] != '') {
        return _formatValue(data[key]);
      }
    }
    return '';
  }

  String _formatDate(String dateStr) {
    try {
      // Try to parse and format the date
      final date = DateTime.tryParse(dateStr);
      if (date != null) {
        return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
      }
    } catch (e) {
      // If parsing fails, return original string
    }
    return dateStr;
  }

  String _formatValue(dynamic value) {
    if (value is Map) {
      return value.toString();
    } else if (value is List) {
      return value.join(', ');
    } else {
      return value.toString();
    }
  }
}
