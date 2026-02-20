import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/models/learning_course_model.dart';
import 'package:private_4t_app/core/models/lms_step_model.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/widgets/app_header.dart';
import 'package:private_4t_app/core/widgets/smart_video_player.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class CourseViewingScreen extends ConsumerStatefulWidget {
  final String courseId;

  const CourseViewingScreen({
    super.key,
    required this.courseId,
  });

  @override
  ConsumerState<CourseViewingScreen> createState() =>
      _CourseViewingScreenState();
}

class _CourseViewingScreenState extends ConsumerState<CourseViewingScreen>
    with SingleTickerProviderStateMixin , AnalyticsScreenMixin {
  
  @override
  String get screenName => 'CourseViewingscreen';
  
  late TabController _tabController;
  LearningCourseModel? _courseModel;
  LmsStepModel? _selectStep;

  bool _isPlaying = false;
  final double _videoProgress = 0.3; // 30% progress

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(ApiProviders.subscriptionsProvider)
          .getCourse(context, int.parse(widget.courseId));
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(ApiProviders.subscriptionsProvider);
    bool isLoading = provider.isLoading;

    if (!isLoading && provider.learningCourseModel != null) {
      _courseModel = provider.learningCourseModel!;
      _selectStep = _courseModel!.lessons!.first.steps!.first;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: isLoading
          ? CommonComponents.loadingDataFromServer()
          : Scaffold(
              backgroundColor: context.background,
              appBar: AppHeader(
                title: _courseModel?.title.toString() ?? '',
                showBackButton: true,
                showLogo: false,
                showProfile: false,
                showNotifications: false,
                showMenu: false,
                showCart: false,
              ),
              body: Column(
                children: [
                  // Video Player Section
                  // _buildVideoPlayer(),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: SmartVideoPlayer(
                      videoUrl: _selectStep?.sourceUrl ?? '',
                    ),
                  ),

                  SizedBox(
                    height: 10.h,
                  ),

                  // Interactive Buttons
                  _buildInteractiveButtons(),

                  // Navigation Tabs
                  _buildNavigationTabs(),

                  // Course Content
                  Expanded(
                    child: _buildCourseContent(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildVideoPlayer() {
    return Container(
      height: 250.h,
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Stack(
          children: [
            // Video Background (placeholder)
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.primary.withOpacity(0.8),
                    context.primary.withOpacity(0.6),
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.play_circle_filled,
                  size: 60.sp,
                  color: Colors.white,
                ),
              ),
            ),

            // Video Controls Overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // Progress Bar
                    Container(
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _videoProgress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.accent,
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 12.h),

                    // Control Buttons (RTL order)
                    Row(
                      children: [
                        // Right side controls (RTL)
                        IconButton(
                          onPressed: () {},
                          icon: Icon(
                            Icons.fullscreen,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: Icon(
                            Icons.volume_up,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                        ),

                        const Spacer(),

                        // Left side controls (RTL)
                        Text(
                          '25:26',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _isPlaying = !_isPlaying;
                            });
                          },
                          icon: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveButtons() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // RTL order: Share, Rate, Ask, Save
          _buildInteractiveButton(
            icon: Icons.share,
            label: 'شارك',
            onTap: () {},
          ),
          _buildInteractiveButton(
            icon: Icons.thumb_up_outlined,
            label: 'قيم',
            onTap: () {},
          ),
          _buildInteractiveButton(
            icon: Icons.chat_bubble_outline,
            label: 'اسأل',
            onTap: () {},
          ),
          _buildInteractiveButton(
            icon:
                _courseModel!.isSaved! ? Icons.bookmark : Icons.bookmark_border,
            label: _courseModel!.isSaved! ? 'إزالة' : 'حفظ',
            onTap: () async {
              await ref.read(ApiProviders.subscriptionsProvider).saveCourse(
                    context: context,
                    courseId: _courseModel!.id.toString(),
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: context.primary,
                size: 20.sp,
              ),
              SizedBox(height: 4.h),
              Text(
                label,
                style: TextStyle(
                  color: context.primaryText,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationTabs() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: context.primary,
          borderRadius: BorderRadius.circular(8.r),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: context.primaryText,
        labelStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'المحتوى'),
          Tab(text: 'اختبار'),
          Tab(text: 'مذكرات'),
          Tab(text: 'جروب التواصل'),
          Tab(text: 'ملاحظاتي'),
        ],
      ),
    );
  }

  Widget _buildCourseContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        // Content Tab
        _buildContentTab(),
        // Test Tab
        _buildTestTab(),
        // Notes Tab
        _buildNotesTab(),
        // Communication Group Tab
        _buildCommunicationTab(),
        // My Notes Tab
        _buildMyNotesTab(),
      ],
    );
  }

  Widget _buildContentTab() {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      children: _courseModel!.lessons != null
          ? _courseModel!.lessons!
              .map((lesson) => _buildCourseUnit(
                    title: lesson.name,
                    duration: 'دقيقة 0/2 | 45',
                    isExpanded: true,
                    steps: lesson.steps != null ? lesson.steps! : [],
                  ))
              .toList()
          : [],
    );
  }

  Widget _buildCourseUnit({
    required String title,
    required String duration,
    required bool isExpanded,
    required List<LmsStepModel> steps,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: context.primaryText,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    duration,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: context.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        children: steps.map((step) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // RTL order: Duration, Title, Play Icon
                Text(
                  "10 د",
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: context.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    step.name,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: context.primaryText,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectStep = step;
                    });
                  },
                  child: Icon(
                    Icons.play_circle_outline,
                    color: context.primary,
                    size: 20.sp,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTestTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz,
            size: 64.sp,
            color: context.primary.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            'لا توجد اختبارات متاحة حالياً',
            style: TextStyle(
              fontSize: 16.sp,
              color: context.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note,
            size: 64.sp,
            color: context.primary.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            'لا توجد مذكرات متاحة حالياً',
            style: TextStyle(
              fontSize: 16.sp,
              color: context.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunicationTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group,
            size: 64.sp,
            color: context.primary.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            'جروب التواصل غير متاح حالياً',
            style: TextStyle(
              fontSize: 16.sp,
              color: context.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyNotesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.edit_note,
            size: 64.sp,
            color: context.primary.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            'لا توجد ملاحظات شخصية',
            style: TextStyle(
              fontSize: 16.sp,
              color: context.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
