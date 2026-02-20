import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/models/course_category_model.dart';
import 'package:private_4t_app/core/models/learning_course_model.dart';
import 'package:private_4t_app/core/models/user_model.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/widgets/optimized_cached_image.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class CourseCardsScreen extends ConsumerStatefulWidget {
  const CourseCardsScreen({super.key});

  @override
  ConsumerState<CourseCardsScreen> createState() => _CourseCardsScreenState();
}

class _CourseCardsScreenState extends ConsumerState<CourseCardsScreen> with AnalyticsScreenMixin {
  
  @override
  String get screenName => 'CourseCardsScreen';
  
  int selectCategory = -1;
  int selectedFilterIndex = 1;
  late UserModel _loggedUser;
  List<CourseCategoryModel> courseCategories = [];

  List<LearningCourseModel> courses = [];

  List<LearningCourseModel> get filteredCourses {
    if (selectCategory == -1) {
      return courses;
    }
    return courses
        .where((course) => course.categoryId == selectCategory)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    // Initialize booking data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ApiProviders.videoCoursesProvider).getCourses(context);
    });
    _loggedUser = ref.read(ApiProviders.loginProvider).loggedUser!;
  }

  @override
  Widget build(BuildContext context) {
    final videoCoursesProvider = ref.watch(ApiProviders.videoCoursesProvider);
    _loggedUser = ref.watch(ApiProviders.loginProvider).loggedUser!;
    bool isLoading = videoCoursesProvider.isLoading;
    // Update the lists when data is loaded
    if (!isLoading && videoCoursesProvider.categoriesList.isNotEmpty) {
      courseCategories = videoCoursesProvider.categoriesList;
      courses = videoCoursesProvider.coursesList;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.background,
        appBar: _buildAppBar(),
        body: RefreshIndicator(
          onRefresh: () async {
            await videoCoursesProvider.getCourses(context);
          },
          child: isLoading
              ? CommonComponents.loadingDataFromServer()
              : Column(
                  children: [
                    _buildSubjectFilters(),
                    Expanded(
                      child: _buildCourseCards(),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
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
        'شروحات ${_loggedUser.profile?.grade?.grade}',
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

  Widget _categoryCard(
      {void Function()? onTap,
      required Color containerColor,
      required String title,
      required Color bolderColor,
      required Color titleColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(left: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: bolderColor,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: titleColor,
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectFilters() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: courseCategories.map(
            (cat) {
              final index = cat.id;
              final isSelected = selectedFilterIndex == index;

              return _categoryCard(
                onTap: () {
                  setState(() {
                    selectedFilterIndex = index;
                    selectCategory = cat.id;
                  });
                },
                containerColor: isSelected ? context.primary : context.surface,
                title: cat.name,
                bolderColor: isSelected
                    ? context.primary
                    : context.secondary.withOpacity(0.3),
                titleColor: isSelected ? context.surface : context.primaryText,
              );
            },
          ).toList(),
        ),
      ),
    );
  }

  Widget _buildCourseCards() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: filteredCourses.length,
      itemBuilder: (context, index) {
        final course = filteredCourses[index];
        return _CourseCard(
          course: course,
          onSubscribe: () => _handleSubscribe(course),
          onViewDetails: () => _handleViewDetails(course),
        );
      },
    );
  }

  void _handleSubscribe(LearningCourseModel course) {
    // Navigate to payment screen
    if (!course.isEnrolled!) {
      context.push('/video-payment');
    } else {
      context.push('/course-viewing', extra: {
        'courseId': course.id.toString(),
      });
    }
  }

  void _handleViewDetails(LearningCourseModel course) {
    context.push('/course-details', extra: course);
  }
}

class _CourseCard extends StatelessWidget {
  final LearningCourseModel course;
  final VoidCallback onSubscribe;
  final VoidCallback onViewDetails;

  const _CourseCard({
    required this.course,
    required this.onSubscribe,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: const Color(
            0xFFF3F7FF), // Subtle bluish card to stand out from page bg
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
            color:
                const Color(0xFF6FA8DC).withOpacity(0.25)), // Soft blue border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top section with image background
          Container(
            height: 120.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                topRight: Radius.circular(12.r),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                topRight: Radius.circular(12.r),
              ),
              child: Stack(
                children: [
                  // Image background
                  Positioned.fill(
                    child: course.thumbnailUrl != null &&
                            course.thumbnailUrl!.isNotEmpty
                        ? OptimizedCachedImage(
                            imageUrl: course.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorWidget: Material(
                              color: const Color(0xFF2C3E50),
                              child: Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.white,
                                  size: 40.sp,
                                ),
                              ),
                            ),
                          )
                        : Image.asset(
                            "assets/course_thumbnails/math-course.png",
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFF2C3E50),
                                child: Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Colors.white,
                                    size: 40.sp,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  // Gradient overlay for better text readability
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.black.withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom section with light beige background
          Container(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        course.title,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: context.primary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'السعر يبدأ من ${course.price.toStringAsFixed(2)} دينار',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: context.success,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: onSubscribe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C00), // Orange button
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 48.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    course.isEnrolled! ? 'تعلم الان' : 'اشترك الان',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                TextButton(
                  onPressed: onViewDetails,
                  child: Text(
                    'عرض المزيد',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF8B4513), // Brown color
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
