import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';

class EducationalServiceCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color gradientStart;
  final Color gradientEnd;
  final String subtitle;
  final VoidCallback onTap;

  const EducationalServiceCard({
    super.key,
    required this.title,
    required this.icon,
    required this.gradientStart,
    required this.gradientEnd,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<EducationalServiceCard> createState() => _EducationalServiceCardState();
}

class _EducationalServiceCardState extends State<EducationalServiceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _shadowAnimation;
  late Animation<double> _iconAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.03,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _shadowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _iconAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: GestureDetector(
              onTapDown: (_) => _animationController.forward(),
              onTapUp: (_) => _animationController.reverse(),
              onTapCancel: () => _animationController.reverse(),
              onTap: widget.onTap,
              child: Container(
                width: 160.w,
                height: 95.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10 * _shadowAnimation.value,
                      offset: Offset(0, 3 * _shadowAnimation.value),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Background decorative elements - much smaller
                    Positioned(
                      top: -10.h,
                      right: -10.w,
                      child: Container(
                        width: 60.w,
                        height: 60.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.gradientStart.withOpacity(0.25),
                              widget.gradientEnd.withOpacity(0.15),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -16.h,
                      left: -16.w,
                      child: Container(
                        width: 80.w,
                        height: 80.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.gradientEnd.withOpacity(0.2),
                              widget.gradientStart.withOpacity(0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Content with extremely tight layout
                    Padding(
                      padding: EdgeInsets.all(10.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon and text in a row for more space efficiency
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Icon - extremely compact
                              Transform.scale(
                                scale: _iconAnimation.value,
                                child: Container(
                                  padding: EdgeInsets.all(6.w),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        widget.gradientStart,
                                        widget.gradientEnd,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Icon(
                                    widget.icon,
                                    color: Colors.white,
                                    size: 16.sp,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              // Title and subtitle
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: context.primaryText,
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w700,
                                        height: 1.1,
                                      ),
                                    ),
                                    Text(
                                      widget.subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: context.secondaryText,
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w500,
                                        height: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Arrow indicator - on the right
                              Icon(
                                Icons.arrow_forward_ios,
                                color: context.secondaryText,
                                size: 12.sp,
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
          ),
        );
      },
    );
  }
}

class EducationalServicesSection extends StatelessWidget {
  const EducationalServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            'كل اللي تحتاجه للتعليم... تلقاه هني',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: context.primaryText,
            ),
          ),
          SizedBox(height: 12.h),
          // Services Grid with tight spacing
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 8.w, // Very tight spacing
            mainAxisSpacing: 8.h, // Very tight spacing
            childAspectRatio: 1.8, // Even wider aspect ratio for smaller height
            children: [
              EducationalServiceCard(
                title: 'معاهد تعليمية',
                subtitle: 'دورات متخصصة',
                icon: Icons.school,
                gradientStart: const Color(0xFF667eea),
                gradientEnd: const Color(0xFF764ba2),
                onTap: () {
                  context.push('/education-institutes');
                },
              ),
              EducationalServiceCard(
                title: 'المدارس',
                subtitle: 'مناهج دراسية',
                icon: Icons.account_balance,
                gradientStart: const Color(0xFFf093fb),
                gradientEnd: const Color(0xFFf5576c),
                onTap: () {
                  context.push('/schools');
                },
              ),
              EducationalServiceCard(
                title: 'الحضانات',
                subtitle: 'رعاية وتعليم',
                icon: Icons.child_care,
                gradientStart: const Color(0xFF4facfe),
                gradientEnd: const Color(0xFF00f2fe),
                onTap: () {
                  context.push('/kindergartens');
                },
              ),
              EducationalServiceCard(
                title: 'المكتبات',
                subtitle: 'كتب ومراجع',
                icon: Icons.local_library,
                gradientStart: const Color(0xFF43e97b),
                gradientEnd: const Color(0xFF38f9d7),
                onTap: () {
                  context.push('/libraries');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
