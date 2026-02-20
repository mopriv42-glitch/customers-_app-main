import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/providers/theme_provider.dart';
import 'package:private_4t_app/core/services/navigation_service.dart';
import 'package:private_4t_app/app_config/api_providers.dart';

class AppHeader extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? additionalActions;
  final bool showProfile;
  final bool showNotifications;
  final bool showMenu;
  final bool showCart;
  final bool showLogo;

  const AppHeader({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.onBackPressed,
    this.additionalActions,
    this.showProfile = true,
    this.showNotifications = true,
    this.showMenu = true,
    this.showCart = true,
    this.showLogo = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep router reference for navigation service (notifications taps)
    if (NavigationService.router == null) {
      NavigationService.initRouter(GoRouter.of(context));
    }

    final themeProviderNotifier = ref.read(ApiProviders.themeProvider.notifier);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: context.background,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 1),
              spreadRadius: 0,
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 72.h,
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
            child: Row(
              children: [
                // Right side (start in RTL): Actions or Back
                if (showBackButton)
                  _buildBackButton(context)
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showProfile) _buildCompactProfileIcon(context),
                      if (showCart) _buildCartIcon(context, ref),
                      if (showNotifications)
                        _buildCompactActionIcon(
                          icon: Icons.notifications_none_outlined,
                          onTap: () =>
                              NavigationService.navigateToNotifications(
                                  context),
                          margin: EdgeInsets.only(left: 10.w),
                        ),
                    ],
                  ),

                // Middle spacer (optional title can go here if needed)
                Expanded(
                  child: !showLogo
                      ? Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: context.primaryText,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                // Left side (end in RTL): Logo pinned to far left
                if (showLogo)
                  GestureDetector(
                    onTap: () {
                      NavigationService.navigateToHome(context);
                    },
                    child: Container(
                      height: themeProviderNotifier.currentBrand ==
                              BrandTheme.castle
                          ? 100.h
                          : 40.h,
                      width: 108.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        themeProviderNotifier.currentBrand == BrandTheme.castle
                            ? 'assets/images/castle-logo.png'
                            : 'assets/images/private-4t-logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                if (additionalActions != null) ...additionalActions!,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 8.w),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: onBackPressed ?? () => context.pop(),
          child: Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: context.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: context.primary.withOpacity(0.12),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.arrow_back_ios,
              color: context.primary,
              size: 16.sp,
            ),
          ),
        ),
      ),
    );
  }

  // Compact action icon to prevent overflow
  Widget _buildCompactActionIcon({
    required IconData icon,
    required VoidCallback onTap,
    required EdgeInsets margin,
  }) {
    return Builder(
      builder: (context) => Container(
        margin: margin,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18.r),
            onTap: onTap,
            child: Container(
              width: 40.w, // Smaller size
              height: 40.h,
              decoration: BoxDecoration(
                color: context.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: context.primary.withOpacity(0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.primary.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: context.primary,
                size: 18.sp, // Smaller icon
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Compact profile icon
  Widget _buildCompactProfileIcon(BuildContext context) {
    return Builder(
      builder: (context) => Container(
        margin: EdgeInsets.only(left: 8.w), // Smaller margin
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18.r),
            onTap: () => NavigationService.navigateToProfile(context),
            child: Container(
              width: 40.w, // Smaller size
              height: 40.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18.r),
                gradient: LinearGradient(
                  colors: [
                    context.primary.withOpacity(0.12),
                    context.accent.withOpacity(0.12),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                border: Border.all(
                  color: context.primary.withOpacity(0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.primary.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.person_outline,
                color: context.primary,
                size: 18.sp, // Smaller icon
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Cart icon with item count
  Widget _buildCartIcon(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final cartProvider = ref.watch(ApiProviders.cartProvider);
        final itemCount = cartProvider.cartModel.items?.length ?? 0;

        return Container(
          margin: EdgeInsets.only(left: 10.w),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18.r),
              onTap: () => NavigationService.navigateToCart(context),
              child: Stack(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: context.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(
                        color: context.primary.withOpacity(0.15),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: context.primary.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: context.primary,
                      size: 18.sp,
                    ),
                  ),
                  // Badge showing item count
                  if (itemCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 4.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: context.secondary,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16.w,
                          minHeight: 16.h,
                        ),
                        child: Text(
                          itemCount > 99 ? '99+' : itemCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(70.h); // Smaller height
}
