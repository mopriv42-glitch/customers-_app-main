import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/services/price_calculation_service.dart';

class PriceDisplayWidget extends StatelessWidget {
  final int price;
  final double numberOfHours;
  final String? subject;
  final String? grade;
  final VoidCallback? onNextPressed;
  final bool isLoading;

  const PriceDisplayWidget({
    super.key,
    required this.price,
    required this.numberOfHours,
    this.subject,
    this.grade,
    this.onNextPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return // عرض السعر
        Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.background,
            context.background.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'السعر',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: context.primaryText,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            PriceCalculationService.formatPrice(price),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: context.primaryText,
            ),
          ),
          // SizedBox(height: 4.h),
          // Text(
          //   PriceCalculationService.getHoursText(numberOfHours),
          //   style: TextStyle(
          //     fontSize: 14.sp,
          //     fontWeight: FontWeight.w500,
          //     color: Colors.white.withOpacity(0.9),
          //   ),
          // ),
        ],
      ),
    );
  }
}
