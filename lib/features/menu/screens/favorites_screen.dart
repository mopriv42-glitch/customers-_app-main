import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/core/models/learning_course_model.dart';
import 'package:private_4t_app/core/widgets/app_header.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/features/menu/widgets/wishlist_course_card.dart';
import 'package:private_4t_app/core/widgets/loading_spinner.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> with AnalyticsScreenMixin {
  
  @override
  String get screenName => 'Favoritesscreen';
  
  @override
  void initState() {
    super.initState();
    // Fetch wishlist courses when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(ApiProviders.wishlistProvider.notifier)
          .fetchWishlistCourses(context: context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.background,
        appBar: const AppHeader(
          title: 'المفضلة',
          showBackButton: true,
          showLogo: false,
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                SizedBox(height: 24.h),
                _buildFavoritesList(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.accent, context.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Icon(Icons.favorite, size: 32.sp, color: Colors.white),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المحتوى المفضل',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'دروسك وملفاتك المحفوظة',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList(BuildContext context) {
    return Expanded(
      child: Consumer(
        builder: (context, ref, child) {
          final wishlistProvider = ref.watch(ApiProviders.wishlistProvider);

          if (wishlistProvider.isLoading) {
            return const Center(
              child: LoadingSpinner(),
            );
          }

          if (wishlistProvider.error != null) {
            return _buildErrorWidget(context, wishlistProvider);
          }

          if (wishlistProvider.wishlistCourses.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref
                  .read(ApiProviders.wishlistProvider.notifier)
                  .refreshWishlist(context: context);
            },
            child: ListView.builder(
              itemCount: wishlistProvider.wishlistCourses.length,
              itemBuilder: (context, index) {
                final course = wishlistProvider.wishlistCourses[index];
                return WishlistCourseCard(
                  course: course,
                  onRemoveFromWishlist: () =>
                      _removeFromWishlist(context, course.id!),
                  onTap: () => _onCourseTap(context, course),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, wishlistProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.sp,
            color: context.error,
          ),
          SizedBox(height: 16.h),
          Text(
            'حدث خطأ في تحميل المفضلة',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: context.primaryText,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            wishlistProvider.error ?? 'يرجى المحاولة مرة أخرى',
            style: TextStyle(
              fontSize: 14.sp,
              color: context.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {
              ref.read(ApiProviders.wishlistProvider.notifier).clearError();
              ref
                  .read(ApiProviders.wishlistProvider.notifier)
                  .fetchWishlistCourses(context: context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.accent,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'إعادة المحاولة',
              style: TextStyle(fontSize: 16.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64.sp,
            color: context.accent.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            'لا توجد دورات في المفضلة',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: context.primaryText,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'أضف الدورات التي تريد حفظها إلى المفضلة',
            style: TextStyle(
              fontSize: 14.sp,
              color: context.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _removeFromWishlist(BuildContext context, int courseId) async {
    // Show confirmation dialog
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'إزالة من المفضلة',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'هل أنت متأكد من إزالة هذه الدورة من المفضلة؟',
          style: TextStyle(fontSize: 16.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'إلغاء',
              style: TextStyle(color: context.secondaryText),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(ApiProviders.wishlistProvider.notifier)
                  .removeFromWishlist(courseId, context: context);

              if (context.mounted) Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('إزالة'),
          ),
        ],
      ),
    );

    if (shouldRemove == true) {
      final success = await ref
          .read(ApiProviders.wishlistProvider.notifier)
          .removeFromWishlist(courseId, context: context);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم إزالة الدورة من المفضلة'),
            backgroundColor: context.success,
          ),
        );
      }
    }
  }

  void _onCourseTap(BuildContext context, LearningCourseModel course) {
    if (context.mounted) {
      if ((course.isEnrolled ?? false)) {
        context.push('/course-viewing', extra: {
          'courseId': course.id.toString(),
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("لا يمكنك المشاهدة لأنك لم تشتري هذه الدورة"),
            backgroundColor: context.accent,
          ),
        );
      }
    }
  }
}
