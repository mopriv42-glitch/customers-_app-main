import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/models/learning_course_model.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/widgets/smart_video_player.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class CourseDetailsScreen extends ConsumerStatefulWidget {
  final LearningCourseModel course;

  const CourseDetailsScreen({super.key, required this.course});

  @override
  ConsumerState<CourseDetailsScreen> createState() =>
      _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends ConsumerState<CourseDetailsScreen> with AnalyticsScreenMixin {
  
  @override
  String get screenName => 'CourseDetailsscreen';
  
  final List<String> features = [
    'المنهج طبقاً لمنهج وزارة التربية لعام 2025',
    'تواصل مباشر مع المدرس',
    'أمثلة محلولة وتطبيقات عملية لكل درس',
    'مراجعات واختبارات بعد كل وحدة',
    'دروس مسجلة ترجع لها بأي وقت',
    'مراجعات خاصة قبل اختبارات القصير',
  ];

  LearningCourseModel? _courseModel;

  @override
  void initState() {
    super.initState();
    // Initialize booking data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCourse();
    });
  }

  Future<void> _getCourse() async {
    ref.read(ApiProviders.videoCoursesProvider).getCourse(
          context,
          widget.course.id!,
        );
  }

  @override
  Widget build(BuildContext context) {
    final videoCoursesProvider = ref.watch(ApiProviders.videoCoursesProvider);
    bool isLoading = videoCoursesProvider.isLoading;
    // Update the lists when data is loaded
    if (!isLoading && videoCoursesProvider.currentCourseModel != null) {
      _courseModel = videoCoursesProvider.currentCourseModel!;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.background,
        appBar: _buildAppBar(context),
        body: isLoading
            ? CommonComponents.loadingDataFromServer()
            : RefreshIndicator(
                onRefresh: () async {
                  await videoCoursesProvider.getCourses(context);
                },
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      padding: EdgeInsets.only(bottom: 96.h),
                      child: Column(
                        children: [
                          _buildCourseHeader(),
                          _buildFeaturesList(),
                          Padding(
                            padding: EdgeInsets.all(15.r),
                            child: SmartVideoPlayer(
                              videoUrl:
                                  _courseModel?.videoThumbnailUrl.toString() ??
                                      '',
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: _buildContentTab(),
                          ),
                          SizedBox(height: 16.h),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.surface,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: _buildBottomPinnedBar(context),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.primary,
      elevation: 0,
      toolbarHeight: 60.h,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'تفاصيل الدورة',
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: context.surface,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.shopping_cart, color: Colors.white, size: 24.sp),
          onPressed: () => context.push('/cart'),
        ),
      ],
    );
  }

  Widget _buildCourseHeader() {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.secondary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: context.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                widget.course.title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: context.primary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          _buildCourseIcon(widget.course.thumbnailUrl ?? ''),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.secondary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مميزات الدورة',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: context.primaryText,
            ),
          ),
          SizedBox(height: 12.h),
          ...features.map(
            (feature) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Container(
                    width: 20.w,
                    height: 20.w,
                    decoration:  BoxDecoration(
                      color: context.accentSecondary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      size: 14.sp,
                      color: context.surface,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: context.primaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Container(
      margin: EdgeInsets.all(16.w),
      height: 250.h,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Stack(
        children: [
          // Video placeholder
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              gradient: LinearGradient(
                colors: [Colors.grey[800]!, Colors.grey[900]!],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person,
                    size: 60.sp,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'DIGITAL MARKETING',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Play button
          Center(
            child: Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: context.accentSecondary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.play_arrow,
                size: 40.sp,
                color: context.surface,
              ),
            ),
          ),
          // Video controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12.r),
                  bottomRight: Radius.circular(12.r),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.play_arrow, color: Colors.white, size: 20.sp),
                  SizedBox(width: 8.w),
                  Text(
                    '-00:13',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(Icons.volume_up, color: Colors.white, size: 20.sp),
                  Expanded(
                    child: Container(
                      height: 4.h,
                      margin: EdgeInsets.symmetric(horizontal: 8.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.3,
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.accentSecondary,
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Icon(Icons.closed_caption, color: Colors.white, size: 20.sp),
                  SizedBox(width: 8.w),
                  Icon(Icons.settings, color: Colors.white, size: 20.sp),
                  SizedBox(width: 8.w),
                  Icon(Icons.fullscreen, color: Colors.white, size: 20.sp),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionSection() {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.secondary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!_courseModel!.isCartable!)
            GestureDetector(
              onTap: () async {
                final result = await ref
                    .read(ApiProviders.cartProvider)
                    .addLearningCourseIntoCart(
                      context,
                      _courseModel!.id.toString(),
                    );

                if (result) {
                  context.push('/cart');

                  _getCourse();
                }
              },
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: context.accentSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.shopping_cart,
                  color: context.accentSecondary,
                  size: 24.sp,
                ),
              ),
            ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.course.price.toStringAsFixed(2)} د.ك',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: context.primaryText,
                  ),
                ),
                Text(
                  widget.course.title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: context.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 3.w,
          ),
          if (!_courseModel!.isEnrolled!)
            GestureDetector(
              onTap: _handleSubscribe,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  gradient:  LinearGradient(
                    colors: [context.primary, context.accentSecondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'اشترك الآن',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: context.surface,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(
                      Icons.star,
                      color: Colors.yellow,
                      size: 20.sp,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCourseIcon(String imageType) {
    switch (imageType) {
      case 'math_cube':
        return Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Center(
            child: Text(
              'π',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ),
        );
      case 'chemistry_flask':
        return Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Center(
            child: Icon(
              Icons.science,
              size: 20.sp,
              color: Colors.teal,
            ),
          ),
        );
      default:
        return Icon(
          Icons.school,
          size: 24.sp,
          color: context.primary,
        );
    }
  }

  Widget _buildCourseUnit({
    required String title,
    required String duration,
    required bool isExpanded,
    required List<Map<String, String>> lessons,
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
        children: lessons.map((lesson) {
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
                  lesson['duration']!,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: context.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    lesson['title']!,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: context.primaryText,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Icon(
                  Icons.play_circle_outline,
                  color: context.primary,
                  size: 20.sp,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContentTab() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: _courseModel!.lessons?.length ?? 0,
      itemBuilder: (BuildContext context, int index) {
        var lesson = _courseModel!.lessons?[index];
        var steps = lesson?.steps;
        return _buildCourseUnit(
          title: lesson?.name ?? '',
          duration: 'دقيقة 0/2 | 45',
          isExpanded: steps?.isNotEmpty ?? false,
          lessons: steps != null
              ? steps
                  .map((step) => {
                        'title': step.name,
                        'duration': '10 د',
                      })
                  .toList()
              : [],
        );
      },
    );
  }

  void _handleSubscribe() {
    // Navigate to payment screen
    context.push('/video-payment');
  }

  Widget _buildBottomPinnedBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: GestureDetector(
          onTap: !(_courseModel?.isEnrolled ?? true) ? _handleSubscribe : null,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              gradient:  LinearGradient(
                colors: [context.primary, context.accentSecondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Row(
              children: [
                // Cart icon inside the same bar
                if (!(_courseModel?.isCartable ?? true))
                  InkWell(
                    onTap: () async {
                      final result = await ref
                          .read(ApiProviders.cartProvider)
                          .addLearningCourseIntoCart(
                            context,
                            widget.course.id.toString(),
                          );
                      if (result) {
                        _getCourse();
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.add_shopping_cart,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                  ),
                SizedBox(width: 10.w),
                Icon(Icons.play_arrow, color: Colors.white, size: 20.sp),
                SizedBox(width: 6.w),
                Text(
                  'اشترك الآن',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.course.price.toStringAsFixed(2)} د.ك',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
