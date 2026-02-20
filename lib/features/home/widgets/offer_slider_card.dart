import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/models/offer_model.dart';

class OfferSliderCard extends StatefulWidget {
  final OfferModel offer;
  final VoidCallback? onTap;

  const OfferSliderCard({
    super.key,
    required this.offer,
    this.onTap,
  });

  @override
  State<OfferSliderCard> createState() => _OfferSliderCardState();
}

class _OfferSliderCardState extends State<OfferSliderCard>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 300.w,
        margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.primary.withOpacity(0.1),
              context.surface,
            ],
          ),
          border: Border.all(
            color: context.primary.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.primary.withOpacity(0.1),
            context.accent.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [context.primary, context.accent],
              ),
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: context.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.local_offer,
              color: context.surface,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Flexible(
            child: Text(
              widget.offer.nameOffer ?? "عرض مميز",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: context.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountBadge(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: context.success,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: context.success.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        'خصم',
        style: TextStyle(
          fontSize: 10.sp,
          color: context.surface,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 10.r),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildInfoRow(
            context,
            Icons.school,
            'عدد الحصص',
            '${widget.offer.numberOfSessions ?? 0} حصة',
            context.accent,
          ),
          _buildInfoRow(
            context,
            Icons.access_time,
            'مدة كل حصة',
            '${widget.offer.hours} ساعة',
            context.primary,
          ),
          _buildInfoRow(
            context,
            Icons.attach_money,
            'السعر الإجمالي',
            '${widget.offer.price} د.ك',
            context.success,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: context.secondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            color: context.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceBreakdown(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: context.background,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: context.surfaceLight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'سعر الحصة الواحدة',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: context.secondaryText,
                ),
              ),
              Text(
                '${(widget.offer.price / (int.tryParse(widget.offer.numberOfSessions ?? '1') ?? 1)).toStringAsFixed(1)} د.ك',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: context.primaryText,
                ),
              ),
            ],
          ),
          Container(
            height: 30.h,
            width: 1,
            color: context.surfaceLight,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'توفير',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: context.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(widget.offer.price * 0.2).toStringAsFixed(1)} د.ك',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: context.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: context.primary.withOpacity(0.05),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.touch_app,
            size: 16.sp,
            color: context.primary,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'اضغط للاستفادة من العرض',
              style: TextStyle(
                fontSize: 12.sp,
                color: context.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 14.sp,
            color: context.primary,
          ),
        ],
      ),
    );
  }
}
