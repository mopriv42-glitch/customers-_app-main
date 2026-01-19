import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class AuthChoiceScreen extends StatefulWidget {
  final String role;

  const AuthChoiceScreen({
    super.key,
    required this.role,
  });

  @override
  State<AuthChoiceScreen> createState() => _AuthChoiceScreenState();
}

class _AuthChoiceScreenState extends State<AuthChoiceScreen>
    with TickerProviderStateMixin , AnalyticsScreenMixin {
  
  @override
  String get screenName => 'AuthChoicescreen';
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

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
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6D9), // Brand background
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              SizedBox(height: 40.h),
              // Header
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      // Back button
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          onPressed: () => context.pop(),
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: const Color(0xFF482099),
                            size: 24.sp,
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      // Title
                      Text(
                        'سجّل وابدأ رحلتك التعليمية!',
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF482099),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'اختر الطريقة المناسبة لك للوصول لخدماتنا',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: const Color(0xFF8C6042),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 48.h),
              // Auth options
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        // Create Account Card
                        Transform.scale(
                          scale: _scaleAnimation.value,
                          child: _buildAuthCard(
                            title: 'إنشاء حساب جديد',
                            description: 'انضم إلينا وابدأ رحلتك التعليمية',
                            icon: Icons.person_add,
                            iconColor: const Color(0xFF1BA39C),
                            backgroundColor:
                                const Color(0xFF1BA39C).withOpacity(0.1),
                            borderColor: const Color(0xFF1BA39C),
                            onTap: () {
                              context.go('/signup/${widget.role}');
                            },
                          ),
                        ),
                        SizedBox(height: 24.h),
                        // Sign In Card
                        Transform.scale(
                          scale: _scaleAnimation.value,
                          child: _buildAuthCard(
                            title: 'تسجيل الدخول',
                            description: 'لديك حساب بالفعل؟ سجل دخولك',
                            icon: Icons.login,
                            iconColor: const Color(0xFF482099),
                            backgroundColor:
                                const Color(0xFF482099).withOpacity(0.1),
                            borderColor: const Color(0xFF482099),
                            onTap: () {
                              context.go('/signin');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: borderColor.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                icon,
                size: 32.sp,
                color: iconColor,
              ),
            ),
            SizedBox(width: 20.w),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF482099),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF8C6042),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(
              Icons.arrow_forward_ios,
              size: 20.sp,
              color: borderColor,
            ),
          ],
        ),
      ),
    );
  }
}
