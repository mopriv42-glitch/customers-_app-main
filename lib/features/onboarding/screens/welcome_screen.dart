import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/core/providers/app_container.dart';
import 'package:private_4t_app/core/services/navigation_queue.dart';
import 'package:private_4t_app/core/services/navigation_service.dart';
import 'package:riverpod_context/riverpod_context.dart';

import '../../../core/services/notification_service.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with TickerProviderStateMixin, AnalyticsScreenMixin {
  @override
  String get screenName => 'Welcomescreen';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  bool _isAuthenticated = true;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check authentication status
    if (context.watch(ApiProviders.loginProvider).loggedUser == null) {
      setState(() {
        _isAuthenticated = false;
      });
    } else {
      if (mounted && !context.canPop()) {
        setState(() {
          _isAuthenticated = true;
        });
        getMatrix();
      }
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F6D9), // Brand background
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // SizedBox(height: 40.h),
                // Platform Logo with improved design
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo container with better styling
                      // Container(
                      //   width: 120.w,
                      //   height: 120.h,
                      //   decoration: BoxDecoration(
                      //     color: Colors.transparent,
                      //     borderRadius: BorderRadius.circular(20.r),
                      //     boxShadow: [
                      //       BoxShadow(
                      //         color: const Color(0xFF482099)
                      //             .withOpacity(0.1),
                      //         blurRadius: 15,
                      //         offset: const Offset(0, 8),
                      //       ),
                      //     ],
                      //   ),
                      //   child: ClipRRect(
                      //     borderRadius: BorderRadius.circular(20.r),
                      //     child: Image.asset(
                      //       'assets/images/private-4t-logo.png',
                      //       width: 80.w,
                      //       height: 80.h,
                      //       fit: BoxFit.contain,
                      //       errorBuilder: (context, error, stackTrace) {
                      //         return Container(
                      //           decoration: BoxDecoration(
                      //             gradient: const LinearGradient(
                      //               begin: Alignment.topLeft,
                      //               end: Alignment.bottomRight,
                      //               colors: [
                      //                 Color(0xFF482099),
                      //                 Color(0xFF1BA39C),
                      //               ],
                      //             ),
                      //             borderRadius:
                      //                 BorderRadius.circular(20.r),
                      //           ),
                      //           child: Icon(
                      //             Icons.school,
                      //             size: 50.sp,
                      //             color: Colors.white,
                      //           ),
                      //         );
                      //       },
                      //     ),
                      //   ),
                      // ),
                      // SizedBox(height: 20.h),
                      // Both logos side by side
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Castle logo
                          Container(
                            width: 150.w,
                            height: 150.h,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12.r),
                              // boxShadow: [
                              //   BoxShadow(
                              //     color: const Color(0xFFa30218)
                              //         .withOpacity(0.1),
                              //     blurRadius: 8,
                              //     offset: const Offset(0, 4),
                              //   ),
                              // ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12.r),
                              child: Image.asset(
                                'assets/images/castle-logo.png',
                                width: 150.w,
                                height: 150.h,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFFa30218),
                                          Color(0xFFc3021f),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Icon(
                                      Icons.castle,
                                      size: 30.sp,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(width: 20.w),
                          // Private logo
                          Container(
                            width: 100.w,
                            height: 100.h,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12.r),
                              // boxShadow: [
                              //   BoxShadow(
                              //     color: const Color(0xFF482099)
                              //         .withOpacity(0.1),
                              //     blurRadius: 8,
                              //     offset: const Offset(0, 4),
                              //   ),
                              // ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12.r),
                              child: Image.asset(
                                'assets/images/private-4t-logo.png',
                                width: 100.w,
                                height: 100.h,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF482099),
                                          Color(0xFF1BA39C),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Icon(
                                      Icons.school,
                                      size: 30.sp,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      // Platform labels
                    ],
                  ),
                ),
                SizedBox(height: 32.h),
                // Main Headline with improved typography
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        'حصص ولدك خلها علينا',
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF482099),
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),
                // Trust Indicators with improved design
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        _buildTrustIndicator(
                          icon: Icons.people,
                          text: 'انضم إلى أكثر من ١,٠٠٠ طالب وطالبة وثقوا بنا',
                          backgroundColor: const Color(0xFFE8F5E8),
                          iconColor: const Color(0xFF2E7D32),
                          textColor: const Color(0xFF2E7D32),
                        ),
                        SizedBox(height: 12.h),
                        _buildTrustIndicator(
                          icon: Icons.school,
                          text: 'تم إنجاز أكثر من ٧,٠٠٠ حصة خصوصية',
                          backgroundColor: const Color(0xFFFFF3E0),
                          iconColor: const Color(0xFFE65100),
                          textColor: const Color(0xFFE65100),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        // Primary CTA with improved styling
                        Transform.scale(
                          scale: _scaleAnimation.value,
                          child: SizedBox(
                            width: double.infinity,
                            height: 56.h,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_isAuthenticated) {
                                  // final loggedUser = ref
                                  //     .read(ApiProviders.loginProvider)
                                  //     .loggedUser;
                                  // if (loggedUser?.phone == null ||
                                  //     (loggedUser != null &&
                                  //         loggedUser.phone != null &&
                                  //         loggedUser.phone!.isEmpty)) {
                                  //   context.push('/phone-verification');
                                  // } else {
                                  //   context.go('/home');
                                  // }
                                  context.go('/home');
                                } else {
                                  context.push('/signin');
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFB547),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                elevation: 6,
                                shadowColor:
                                    const Color(0xFFFFB547).withOpacity(0.4),
                              ),
                              child: Text(
                                'ابدأ الآن',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Action buttons with improved design
          ),
        ),
      ),
    );
  }

  Widget _buildTrustIndicator({
    required IconData icon,
    required String text,
    required Color backgroundColor,
    required Color iconColor,
    required Color textColor,
  }) {
    var splitText = text.split('|');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: iconColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24.sp,
            color: iconColor,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: splitText.length == 1
                ? Text(
                    text,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        splitText[0],
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        splitText[1],
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: textColor,
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
}
