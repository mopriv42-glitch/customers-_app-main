import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/models/customer_booking_model.dart';
import 'package:private_4t_app/core/models/user_model.dart';
import 'package:riverpod_context/riverpod_context.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class DataConfirmationScreen extends StatefulWidget {
  const DataConfirmationScreen({super.key});

  @override
  State<DataConfirmationScreen> createState() => _DataConfirmationScreenState();
}

class _DataConfirmationScreenState extends State<DataConfirmationScreen> with AnalyticsScreenMixin {
  
  @override
  String get screenName => 'DataConfirmationscreen';
  
  late CustomerBookingModel _customerBooking;
  late UserModel _loggedUser;

  @override
  void initState() {
    super.initState();

    _loggedUser = context.read(ApiProviders.loginProvider).loggedUser!;
    _customerBooking =
        context.read(ApiProviders.bookingProvider).customerBooking;
  }

  @override
  Widget build(BuildContext context) {
    _loggedUser = context.watch(ApiProviders.loginProvider).loggedUser!;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.background,
        appBar: _buildAppBar(),
        body: _buildBody(),
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
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'تأكيد البيانات والدفع',
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      actions: [
        _buildCartIcon(),
      ],
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            _buildHeaderBanner(),
            SizedBox(height: 16.h),
            _buildBookingSummaryCard(),
            SizedBox(height: 24.h),
            _buildPayNowButton(),
            SizedBox(height: 12.h),
            _buildSecurityDisclaimer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: context.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Text(
            'كل شيء جاهز... بقي الدفع فقط!',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: context.primaryText,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [context.accentSecondary, context.accent],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              'الخطوة الأخيرة ٢/٢',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingSummaryCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.checklist,
                color: context.primary,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'ملخص الحجز',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: context.primaryText,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  context.pop();
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit,
                      size: 16.sp,
                      color: context.primary,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'تعديل',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: context.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          if (_customerBooking.offerId != null)
            _buildSummaryItem(
              icon: Icons.edit,
              iconColor: context.accent,
              label: 'العرض',
              value: _customerBooking.offer?.nameOffer ?? 'عرض مميز',
            ),
          if (_customerBooking.offerId == null)
            _buildSummaryItem(
              icon: Icons.edit,
              iconColor: context.accent,
              label: 'نوع الخدمة',
              value: 'حصتك بالمنزل',
            ),
          SizedBox(height: 16.h),
          _buildSummaryItem(
            icon: Icons.book,
            iconColor: context.accentSecondary,
            label: 'الصف والمادة',
            value:
                '${_customerBooking.grade?.grade} - ${_customerBooking.subject?.subject}',
          ),
          SizedBox(height: 16.h),
          _buildSummaryItem(
            icon: Icons.access_time,
            iconColor: context.accentSecondary,
            label: 'الموعد',
            value: _customerBooking.formattedBookingTime,
          ),
          SizedBox(height: 16.h),
          _buildSummaryItem(
            icon: Icons.account_balance_wallet,
            iconColor: context.accent,
            label: 'السعر',
            value: '${_customerBooking.price} د.ك',
          ),
          SizedBox(height: 16.h),
          _buildSummaryItem(
            icon: Icons.phone,
            iconColor: context.primary,
            label: 'رقم التواصل',
            value: _loggedUser.phone.toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 32.w,
          height: 32.h,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            icon,
            size: 16.sp,
            color: iconColor,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: context.secondaryText,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: context.primaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPayNowButton() {
    return Column(
      children: [
        // زر أضف إلى السلة
        if (!_customerBooking.isInCart && _customerBooking.offerId == null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primary,
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
            onPressed: _navigateToPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.secondary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 0,
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
    );
  }

  Widget _buildSecurityDisclaimer() {
    return Text(
      'سيتم تحويلك لبوابة الدفع لإتمام العملية بأمان.',
      style: TextStyle(
        fontSize: 12.sp,
        color: context.secondaryText,
      ),
      textAlign: TextAlign.center,
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
          _customerBooking.isInCart = true; // Update local copy
          context.read(ApiProviders.bookingProvider).notifyListeners();
          setState(() {}); // Rebuild UI to hide button
          
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
