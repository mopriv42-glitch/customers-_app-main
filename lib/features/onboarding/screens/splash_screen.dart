import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin , AnalyticsScreenMixin {
  
  @override
  String get screenName => 'Splashscreen';
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );

    _startAnimation();
  }

  void _startAnimation() async {
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6D9), // Brand background color
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with animations
                Transform.scale(
                  scale: _scaleAnimation.value,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        // Main logo
                        // Container(
                        //   width: 120.w,
                        //   height: 120.h,
                        //   decoration: BoxDecoration(
                        //     borderRadius: BorderRadius.circular(24.r),
                        //   ),
                        //   child: ClipRRect(
                        //     borderRadius: BorderRadius.circular(24.r),
                        //     child: Image.asset(
                        //       'assets/images/private-4t-logo.png',
                        //       width: 80.w,
                        //       height: 80.h,
                        //       fit: BoxFit.contain,
                        //       errorBuilder: (context, error, stackTrace) {
                        //         return Icon(
                        //           Icons.school,
                        //           size: 60.sp,
                        //           color: Colors.white,
                        //         );
                        //       },
                        //     ),
                        //   ),
                        // ),
                        // SizedBox(height: 16.h),
                        // Both platform logos side by side
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Castle logo
                            Container(
                              width: 100.w,
                              height: 100.h,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12.r),
                                child: Image.asset(
                                  'assets/images/castle-logo.png',
                                  width: 100.w,
                                  height: 100.h,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFa30218),
                                            Color(0xFFc3021f),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.castle,
                                        size: 25.sp,
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            // Private logo
                            Container(
                              width: 50.w,
                              height: 50.h,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12.r),
                                child: Image.asset(
                                  'assets/images/private-4t-logo.png',
                                  width: 40.w,
                                  height: 40.h,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF482099),
                                            Color(0xFF1BA39C),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.school,
                                        size: 25.sp,
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // FadeTransition(
                //   opacity: _fadeAnimation,
                //   child: Text(
                //     'Private 4T',
                //     style: TextStyle(
                //       fontSize: 28.sp,
                //       fontWeight: FontWeight.w700,
                //       color: const Color(0xFF482099),
                //       letterSpacing: 1.2,
                //     ),
                //   ),
                // ),
                // SizedBox(height: 8.h),
                // Tagline with delayed fade
                FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
                    ),
                  ),
                  child: Text(
                    'تعليم ذكي لمستقبل مشرق',
                    style: TextStyle(
                      fontSize: 17.sp,
                      color: const Color(0xFF8C6042),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 48.h),
                // Loading indicator
                FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.8, 1.0, curve: Curves.easeInOut),
                    ),
                  ),
                  child: SizedBox(
                    width: 40.w,
                    height: 40.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.w,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFFFB547), // Orange accent
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
