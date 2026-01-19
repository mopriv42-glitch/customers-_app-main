import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/core/models/user_model.dart';
import 'package:riverpod_context/riverpod_context.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class ExistingCustomerOnlineConfirmationScreen extends StatefulWidget {
  final String serviceType;
  final String subject;
  final String grade;
  final DateTime date;
  final TimeOfDay time;
  final String duration;
  final double price;

  const ExistingCustomerOnlineConfirmationScreen({
    super.key,
    required this.serviceType,
    required this.subject,
    required this.grade,
    required this.date,
    required this.time,
    required this.duration,
    required this.price,
  });

  @override
  State<ExistingCustomerOnlineConfirmationScreen> createState() =>
      _ExistingCustomerOnlineConfirmationScreenState();
}

class _ExistingCustomerOnlineConfirmationScreenState
    extends State<ExistingCustomerOnlineConfirmationScreen> with AnalyticsScreenMixin {
  
  @override
  String get screenName => 'ExistingCustomerOnlineConfirmationscreen';
  
  late UserModel _loggedUser;

  @override
  void initState() {
    super.initState();
    _loggedUser = context.read(ApiProviders.loginProvider).loggedUser!;
  }

  @override
  Widget build(BuildContext context) {
    _loggedUser = context.watch(ApiProviders.loginProvider).loggedUser!;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.background,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderBanner(),
                SizedBox(height: 24.h),
                _buildBookingSummaryCard(),
                // SizedBox(height: 20.h),
                // _buildPersonalInfoCard(),
                SizedBox(height: 32.h),
                _buildPayNowButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: context.primary,
      elevation: 0,
      toolbarHeight: 60.h,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
          onPressed: () => context.pop(),
        ),
      ),
      title: Text(
        'تأكيد البيانات والدفع',
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: context.surface,
        ),
      ),
      actions: [
        _buildCartIcon(),
      ],
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.primary, context.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(Icons.laptop, color: Colors.white, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حصة أونلاين',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'تأكد من صحة البيانات قبل الدفع',
                  style: TextStyle(
                    fontSize: 12.sp,
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

  Widget _buildBookingSummaryCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.secondary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize, color: context.primary, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'تفاصيل الحجز',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: context.primaryText,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildSummaryRow('نوع الخدمة', widget.serviceType),
          SizedBox(height: 8.h),
          _buildSummaryRow('المادة الدراسية', widget.subject),
          SizedBox(height: 8.h),
          _buildSummaryRow('الصف الدراسي', widget.grade),
          SizedBox(height: 8.h),
          _buildSummaryRow('التاريخ',
              '${widget.date.day}/${widget.date.month}/${widget.date.year}'),
          SizedBox(height: 8.h),
          _buildSummaryRow('الوقت',
              '${widget.time.hour}:${widget.time.minute.toString().padLeft(2, '0')}'),
          SizedBox(height: 8.h),
          _buildSummaryRow('مدة الحصة', widget.duration),
          SizedBox(height: 16.h),
          Divider(color: context.secondary.withOpacity(0.3)),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'السعر الإجمالي',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: context.primaryText,
                ),
              ),
              Text(
                '${widget.price} د.ك',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: context.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: context.secondaryText,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: context.primaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.secondary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: context.primary, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'المعلومات الشخصية',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: context.primaryText,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildInfoRow('الاسم الكامل', _loggedUser.name ?? ''),
          SizedBox(height: 8.h),
          _buildInfoRow('البريد الإلكتروني', _loggedUser.email ?? ''),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: context.secondaryText,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: context.primaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildPayNowButton() {
    final booking = context.read(ApiProviders.bookingProvider).customerBooking;
    return Builder(
      builder: (context) => Column(
        children: [
          // زر أضف إلى السلة
          if (!booking.isInCart && booking.offerId == null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _addToCart(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.secondary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                icon: Icon(
                  Icons.shopping_cart,
                  size: 20.w,
                ),
                label: Text(
                  'أضف إلى السلة',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          SizedBox(height: 12.h),
          // زر الدفع
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _navigateToPayment(),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primary,
                foregroundColor: context.surface,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'ادفع الآن',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPayment() async {
    final result = await context
        .read(ApiProviders.bookingProvider)
        .sendBookingSummary(
            context, _loggedUser.name ?? '', _loggedUser.email ?? '');

    if (mounted && result) {
      context.push('/booking-payment');
    }
  }

  /// إضافة الحجز إلى السلة
  void _addToCart() async {
    try {
      // إنشاء الحجز أولاً
      final result = await context
          .read(ApiProviders.bookingProvider)
          .sendBookingSummary(
              context, _loggedUser.name ?? '', _loggedUser.email ?? '');

      if (mounted && result) {
        // الحصول على معرف الحجز
        final booking =
            context.read(ApiProviders.bookingProvider).customerBooking;
        final bookingId = booking.id.toString();

        // إضافة الحجز إلى السلة
        final cartResult = await context
            .read(ApiProviders.cartProvider)
            .addBookingIntoCart(context, bookingId);

        if (mounted && cartResult) {
          // Update booking isInCart status
          booking.isInCart = true;
          context.read(ApiProviders.bookingProvider).notifyListeners();
          
          CommonComponents.showCustomizedSnackBar(
            context: context,
            title: 'تم إضافة الحجز إلى السلة بنجاح',
          );
        } else {
          CommonComponents.showCustomizedSnackBar(
            context: context,
            title: 'فشل في إضافة الحجز إلى السلة',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CommonComponents.showCustomizedSnackBar(
          context: context,
          title: 'حدث خطأ أثناء إضافة الحجز إلى السلة',
        );
      }
    }
  }

  /// أيقونة السلة مع عدد العناصر
  Widget _buildCartIcon() {
    return Consumer(
      builder: (context, ref, child) {
        final cartProvider = ref.watch(ApiProviders.cartProvider);
        final itemCount = cartProvider.cartModel.items?.length ?? 0;

        return GestureDetector(
          onTap: () => context.push('/cart'),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(10.r),
                child: Icon(
                  Icons.shopping_cart,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              // Badge يعرض عدد العناصر
              if (itemCount > 0)
                Positioned(
                  right: 5.r,
                  top: 5.r,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.red,
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
        );
      },
    );
  }
}
