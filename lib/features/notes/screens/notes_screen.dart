import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/models/lib_item_model.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/utils/subjects_info.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class NotesScreen extends ConsumerStatefulWidget {
  final String itemType;

  const NotesScreen({super.key, required this.itemType});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen>
    with TickerProviderStateMixin , AnalyticsScreenMixin {
  
  @override
  String get screenName => 'Notesscreen';
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<LibItemModel> _notesItems = [];

  final titleScreenMap = {
    'مذكرات': 'مذكرات شرح ومراجعة',
    'كتب': 'الكتب المدرسية',
    'حلول': 'حلول الكتب المدرسية',
    'تقارير': 'التقارير المدرسية',
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ApiProviders.libraryProvider).getItems(context, widget.itemType);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(ApiProviders.libraryProvider);
    bool isLoading = provider.isLoading;

    if (!isLoading && provider.libItemsList.isNotEmpty) {
      _notesItems = provider.libItemsList;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6D9), // Brand background
      body: SafeArea(
        child: isLoading
            ? CommonComponents.loadingDataFromServer()
            : Column(
                children: [
                  // Header
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 24.w, vertical: 16.h),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => context.pop(),
                              icon: Icon(
                                Icons.arrow_back_ios,
                                color: const Color(0xFF482099),
                                size: 24.sp,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                titleScreenMap[widget.itemType] ?? '',
                                style: TextStyle(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF482099),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(width: 48.w), // Balance the layout
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 1,
                              childAspectRatio:
                                  1.8.r, // Increased height to prevent overflow
                              crossAxisSpacing: 16.w,
                              mainAxisSpacing: 16.h,
                            ),
                            itemCount: _notesItems.length,
                            itemBuilder: (context, index) {
                              return _buildNoteCard(_notesItems[index]);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
      ),
    );
  }

  Widget _buildNoteCard(LibItemModel note) {
    final subjectInfo = getSubjectInfo(note.subSection?.name.toString() ?? '');

    return GestureDetector(
      onTap: () {
        context.push('/note-detail', extra: note.id.toString());
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFE9E7F8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Use minimum space required
            children: [
              // Header row: subject chip + bookmark
              Row(
                children: [
                  Flexible(
                    // Make the subject chip flexible
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color:
                            (subjectInfo?.backgroundColor ?? context.accent)
                                .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(subjectInfo?.icon ?? Icons.menu_book,
                              size: 16.sp,
                              color: subjectInfo?.iconColor ??
                                  context.accentSecondary),
                          SizedBox(width: 6.w),
                          Flexible(
                            // Make text flexible within chip
                            child: Text(
                              note.subSection?.name.toString() ?? '',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF482099),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Icon(
                  //   Icons.bookmark_border,
                  //   color: const Color(0xFF8C6042),
                  //   size: 18.sp,
                  // ),
                ],
              ),
              SizedBox(height: 10.h), // Reduced spacing
              // Title & meta
              Flexible(
                // Make title flexible
                child: Text(
                  note.name.toString(),
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: context.primaryText,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: 4.h), // Reduced spacing
              // Primary actions
              SizedBox(
                width: double.infinity,
                // Fixed height for button
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.push('/note-detail', extra: note.id.toString()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        subjectInfo?.iconColor ?? context.accentSecondary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                  ),
                  icon: Icon(Icons.visibility, size: 16.sp),
                  label: Flexible(
                    child: Text(
                      note.placeholderLink ?? 'عرض/تحميل',
                      style: TextStyle(fontSize: 12.sp),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NoteCard {
  final String subjectName;
  final String grade;
  final IconData subjectIcon;
  final Color iconColor;
  final Color backgroundColor;

  NoteCard({
    required this.subjectName,
    required this.grade,
    required this.subjectIcon,
    required this.iconColor,
    required this.backgroundColor,
  });
}
