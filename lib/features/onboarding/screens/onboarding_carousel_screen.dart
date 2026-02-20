import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class OnboardingCarouselScreen extends StatefulWidget {
  final String role;

  const OnboardingCarouselScreen({
    super.key,
    required this.role,
  });

  @override
  State<OnboardingCarouselScreen> createState() =>
      _OnboardingCarouselScreenState();
}

class _OnboardingCarouselScreenState extends State<OnboardingCarouselScreen>
    with TickerProviderStateMixin , AnalyticsScreenMixin {
  
  @override
  String get screenName => 'OnboardingCarouselscreen';
  
  late PageController _pageController;
  late AnimationController _animationController;
  int _currentPage = 0;

  late List<OnboardingPage> _pages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Set up role-specific content
    _pages = widget.role == 'student' ? _getStudentPages() : _getParentPages();
  }

  List<OnboardingPage> _getStudentPages() {
    return [
      OnboardingPage(
        title: 'احجز حصص خصوصية بالبيت أو أونلاين',
        description: 'اختر المدرس المناسب واحجز الحصة في الوقت المناسب لك',
        icon: Icons.calendar_today,
        iconColor: const Color(0xFF1BA39C), // Teal
        backgroundColor: const Color(0xFF1BA39C).withOpacity(0.1),
      ),
      OnboardingPage(
        title: 'تابع تقدمك',
        description: 'راقب تقدمك التعليمي من خلال تقارير مفصلة',
        icon: Icons.analytics,
        iconColor: const Color(0xFFFFB547), // Orange
        backgroundColor: const Color(0xFFFFB547).withOpacity(0.1),
      ),
      OnboardingPage(
        title: 'شروحات فيديو ومذكرات',
        description: 'احصل على شروحات تفصيلية ومذكرات شاملة',
        icon: Icons.video_library,
        iconColor: const Color(0xFF482099), // Purple
        backgroundColor: const Color(0xFF482099).withOpacity(0.1),
      ),
    ];
  }

  List<OnboardingPage> _getParentPages() {
    return [
      OnboardingPage(
        title: 'احجز حصص خصوصية بالبيت أو أونلاين',
        description: 'احجز جلسات تعليمية لطفلك بضغطة واحدة',
        icon: Icons.calendar_today,
        iconColor: const Color(0xFF482099), // Purple
        backgroundColor: const Color(0xFF482099).withOpacity(0.1),
      ),
      OnboardingPage(
        title: 'تابع تقدم أبنائك',
        description: 'راقب تقدم أبنائك من خلال تقارير مفصلة',
        icon: Icons.analytics,
        iconColor: const Color(0xFF1BA39C), // Teal
        backgroundColor: const Color(0xFF1BA39C).withOpacity(0.1),
      ),
      OnboardingPage(
        title: 'شروحات فيديو ومذكرات',
        description: 'احصل على شروحات تفصيلية ومذكرات شاملة',
        icon: Icons.video_library,
        iconColor: const Color(0xFFFFB547), // Orange
        backgroundColor: const Color(0xFFFFB547).withOpacity(0.1),
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _animationController.reset();
    _animationController.forward();
  }

  void _showSkipConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('تأكيد التخطي'),
          content: Text('هل أنت متأكد من تخطي الإعدادات؟'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('لا'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('نعم'),
            ),
          ],
        );
      },
    ).then((confirmed) {
      if (confirmed == true) {
        context.go('/auth-choice/${widget.role}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _showSkipConfirmationDialog();
        return false; // Prevent default back behavior
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F6D9), // Brand background
        body: SafeArea(
          child: Column(
            children: [
              // Header with skip button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Skip button
                    TextButton(
                      onPressed: () {
                        _showSkipConfirmationDialog();
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 8.h),
                        backgroundColor: Colors.white.withOpacity(0.8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                      ),
                      child: Text(
                        'تخطي',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: const Color(0xFF8C6042),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Page indicator
                    Row(
                      children: List.generate(
                        _pages.length,
                        (index) => Container(
                          margin: EdgeInsets.symmetric(horizontal: 4.w),
                          width: 8.w,
                          height: 8.h,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? const Color(0xFF482099) // Primary purple
                                : const Color(0xFF482099).withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 60.w), // Balance the layout
                  ],
                ),
              ),
              // Page content
              Expanded(
                child: GestureDetector(
                  onDoubleTap: () {
                    _showSkipConfirmationDialog();
                  },
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _buildPage(_pages[index]);
                    },
                  ),
                ),
              ),
              // Bottom navigation
              Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Previous button
                        if (_currentPage > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF482099),
                                side:
                                    BorderSide(color: const Color(0xFF482099)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                              ),
                              child: Text(
                                'السابق',
                                style: TextStyle(fontSize: 16.sp),
                              ),
                            ),
                          ),
                        if (_currentPage > 0) SizedBox(width: 16.w),
                        // Next/Finish button
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_currentPage < _pages.length - 1) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              } else {
                                // Navigate to auth choice screen
                                context.go('/auth-choice/${widget.role}');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFFFFB547), // Orange accent
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              elevation: 8,
                              shadowColor:
                                  const Color(0xFFFFB547).withOpacity(0.4),
                            ),
                            child: Text(
                              _currentPage < _pages.length - 1
                                  ? 'التالي'
                                  : 'إنشاء حسابي',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * _animationController.value),
                child: Container(
                  width: 200.w,
                  height: 200.h,
                  decoration: BoxDecoration(
                    color: page.backgroundColor,
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  child: Icon(
                    page.icon,
                    size: 80.sp,
                    color: page.iconColor,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 48.h),
          // Title
          Text(
            page.title,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF482099),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          // Description
          Text(
            page.description,
            style: TextStyle(
              fontSize: 16.sp,
              color: const Color(0xFF8C6042),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });
}
