import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/models/learning_course_model.dart';
import 'package:private_4t_app/core/widgets/optimized_cached_image.dart';

class WishlistCourseCard extends StatelessWidget {
  final LearningCourseModel course;
  final VoidCallback? onRemoveFromWishlist;
  final VoidCallback? onTap;

  const WishlistCourseCard({
    super.key,
    required this.course,
    this.onRemoveFromWishlist,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: context.accent.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Course thumbnail
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
              ),
              clipBehavior: Clip.hardEdge,
              child: course.thumbnailUrl != null
                  ? OptimizedCachedImage(
                      imageUrl: course.thumbnailUrl!,
                      fit: BoxFit.cover,
                      placeholder: Container(
                        color: context.accent.withOpacity(0.1),
                        child: Icon(
                          Icons.school,
                          size: 32.sp,
                          color: context.accent,
                        ),
                      ),
                    )
                  : Container(
                      color: context.accent.withOpacity(0.1),
                      child: Icon(
                        Icons.school,
                        size: 32.sp,
                        color: context.accent,
                      ),
                    ),
            ),
            SizedBox(width: 16.w),
            // Course details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: context.primaryText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  if (course.shortDescription != null)
                    Text(
                      course.shortDescription!,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: context.secondaryText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      // Rating
                      if (course.averageRating > 0)
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 16.sp,
                              color: Colors.amber,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              course.averageRating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: context.secondaryText,
                              ),
                            ),
                            SizedBox(width: 8.w),
                          ],
                        ),
                      // Duration
                      if (course.duration != null && course.duration != 0)
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16.sp,
                              color: context.accent,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '${course.duration} دقيقة',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: context.secondaryText,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  // Price
                  if (course.price > 0)
                    Row(
                      children: [
                        Text(
                          '${course.price.toStringAsFixed(0)} د.ك ',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: context.accent,
                          ),
                        ),
                        if (course.discountPrice != null &&
                            course.discountPrice! < course.price)
                          Padding(
                            padding: EdgeInsets.only(left: 8.w),
                            child: Text(
                              '${course.discountPrice!.toStringAsFixed(0)} د.ك',
                              style: TextStyle(
                                fontSize: 12.sp,
                                decoration: TextDecoration.lineThrough,
                                color: context.secondaryText,
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            // Remove from wishlist button
            IconButton(
              onPressed: onRemoveFromWishlist,
              icon: Icon(
                Icons.favorite,
                color: context.accent,
                size: 24.sp,
              ),
              tooltip: 'إزالة من المفضلة',
            ),
          ],
        ),
      ),
    );
  }
}
