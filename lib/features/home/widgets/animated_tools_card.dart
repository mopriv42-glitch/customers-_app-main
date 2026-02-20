import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';

class AnimatedToolsCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color gradientStart;
  final Color gradientEnd;
  final VoidCallback onTap;

  const AnimatedToolsCard({
    super.key,
    required this.title,
    required this.icon,
    required this.gradientStart,
    required this.gradientEnd,
    required this.onTap,
  });

  @override
  State<AnimatedToolsCard> createState() => _AnimatedToolsCardState();
}

class _AnimatedToolsCardState extends State<AnimatedToolsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.05,
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
                height: 110.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.gradientStart,
                      widget.gradientEnd,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: widget.gradientStart
                          .withOpacity(0.3 * _shadowAnimation.value),
                      blurRadius: 12 * _shadowAnimation.value,
                      offset: Offset(0, 6 * _shadowAnimation.value),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Background pattern
                    Positioned(
                      top: -20.h,
                      right: -20.w,
                      child: Container(
                        width: 80.w,
                        height: 80.h,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -10.h,
                      left: -10.w,
                      child: Container(
                        width: 60.w,
                        height: 60.h,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              widget.icon,
                              color: Colors.white,
                              size: 18.sp,
                            ),
                          ),
                          const Spacer(),
                          // Title and arrow in a row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.title,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white.withOpacity(0.8),
                                size: 10.sp,
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

class ToolsSection extends StatelessWidget {
  const ToolsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            'أدوات لتفوقك',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: context.primaryText,
            ),
          ),
          SizedBox(height: 16.h),
          // Tools Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 1.4,
            children: [
              AnimatedToolsCard(
                title: 'مذكرات',
                icon: Icons.note_alt,
                gradientStart: const Color(0xFF667eea),
                gradientEnd: const Color(0xFF764ba2),
                onTap: () {
                  context.push('/notes');
                },
              ),
              AnimatedToolsCard(
                title: 'كتب مدرسية',
                icon: Icons.menu_book,
                gradientStart: const Color(0xFFf093fb),
                gradientEnd: const Color(0xFFf5576c),
                onTap: () {
                  context.push('/notes',extra: 'كتب');
                },
              ),
              AnimatedToolsCard(
                title: 'حلول الكتب المدرسية',
                icon: Icons.assignment_turned_in,
                gradientStart: const Color(0xFF4facfe),
                gradientEnd: const Color(0xFF00f2fe),
                onTap: () {
                  context.push('/notes',extra: 'حلول');
                },
              ),
              AnimatedToolsCard(
                title: 'تقارير مدرسية',
                icon: Icons.assessment,
                gradientStart: const Color(0xFF43e97b),
                gradientEnd: const Color(0xFF38f9d7),
                onTap: () {
                  context.push('/notes',extra: 'تقارير');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
