import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/app_config/api_keys.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';
import 'package:private_4t_app/app_config/api_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin, AnalyticsScreenMixin {

  @override
  String get screenName => 'Splashscreen';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut)),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut)),
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut)),
    );
    _startAnimation();
  }

  void _navigate(String destination) {
    if (_hasNavigated) return;
    if (!mounted) return;
    _hasNavigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(destination);
    });
  }

  void _startAnimation() async {
    await _animationController.forward();
    if (!mounted) return;
    try {
      final loginProvider = ref.read(ApiProviders.loginProvider);
      bool isLoggedIn = false;
      try {
        isLoggedIn = await loginProvider.getLoggedUser()
            .timeout(const Duration(seconds: 6));
      } catch (e) {
        debugPrint('getLoggedUser timeout/error: $e');
        isLoggedIn = false;
      }
      _navigate(isLoggedIn ? '/home' : '/welcome');
    } catch (e) {
      debugPrint('Splash error: $e');
      _navigate('/welcome');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6D9),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: _scaleAnimation.value,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100.w, height: 100.h,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: Image.asset('assets/images/castle-logo.png',
                              width: 100.w, height: 100.h, fit: BoxFit.contain,
                              errorBuilder: (c, e, s) => Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFFa30218), Color(0xFFc3021f)]),
                                  borderRadius: BorderRadius.circular(12.r)),
                                child: Icon(Icons.castle, size: 25.sp, color: Colors.white))),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Container(
                          width: 50.w, height: 50.h,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: Image.asset('assets/images/private-4t-logo.png',
                              width: 40.w, height: 40.h, fit: BoxFit.contain,
                              errorBuilder: (c, e, s) => Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF482099), Color(0xFF1BA39C)]),
                                  borderRadius: BorderRadius.circular(12.r)),
                                child: Icon(Icons.school, size: 25.sp, color: Colors.white))),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(parent: _animationController,
                      curve: const Interval(0.6, 1.0, curve: Curves.easeInOut))),
                  child: Text('تعليم ذكي لمستقبل مشرق',
                    style: TextStyle(fontSize: 17.sp, color: const Color(0xFF8C6042), fontWeight: FontWeight.bold)),
                ),
                SizedBox(height: 48.h),
                FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(parent: _animationController,
                      curve: const Interval(0.8, 1.0, curve: Curves.easeInOut))),
                  child: SizedBox(
                    width: 40.w, height: 40.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.w,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFB547)))),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
