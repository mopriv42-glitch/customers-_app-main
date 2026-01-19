import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/models/customer_booking_model.dart';
import 'package:private_4t_app/core/models/user_address_model.dart';
import 'package:private_4t_app/core/widgets/app_header.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class BookingSummaryScreen extends ConsumerStatefulWidget {
  const BookingSummaryScreen({super.key});

  @override
  ConsumerState<BookingSummaryScreen> createState() =>
      _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends ConsumerState<BookingSummaryScreen> with AnalyticsScreenMixin {
  
  @override
  String get screenName => 'BookingSummaryscreen';
  
  final ValueNotifier<bool> isFormValid = ValueNotifier(false);
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  late UserAddressModel _userAddressModel;
  late CustomerBookingModel _customerBooking;

  void _validateForm() {
    isFormValid.value =
        fullNameController.text.isNotEmpty && emailController.text.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    // Initialize booking data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ApiProviders.bookingProvider).getSummaryBooking(context);
    });

    fullNameController.addListener(_validateForm);
    emailController.addListener(_validateForm);
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = ref.watch(ApiProviders.bookingProvider);
    final loggedUser = ref.watch(ApiProviders.loginProvider).loggedUser;

    bool isLoading = bookingProvider.isLoading;

    if (!isLoading) {
      _userAddressModel = bookingProvider.userAddressModel;
      _customerBooking = bookingProvider.customerBooking;
      fullNameController.text = loggedUser?.name ?? '';
      emailController.text = loggedUser?.email ?? '';
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.background,
        appBar: const AppHeader(
          title: 'ملخص الحجز',
          showBackButton: true,
          showLogo: false,
        ),
        body: SafeArea(
          child: isLoading
              ? CommonComponents.loadingDataFromServer(color: context.primary)
              : _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          _buildBookingSummaryCard(),
          SizedBox(height: 16.h),
          // _buildPaymentInfoCard(),
          // SizedBox(height: 24.h),
          _buildPayNowButton(),
          SizedBox(height: 12.h),
          _buildSecurityDisclaimer(),
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
                '${_customerBooking.grade?.grade ?? ''} - ${_customerBooking.subject?.subject ?? ''}',
          ),
          SizedBox(height: 16.h),
          _buildSummaryItem(
            icon: Icons.home,
            iconColor: context.primary,
            label: 'العنوان',
            value:
                '${_userAddressModel.governorate?.governorate} - ${_userAddressModel.region?.region} - ق ${_userAddressModel.blockNumber} - ش ${_userAddressModel.streetNumber} - ${_userAddressModel.houseNumber} م',
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
          SizedBox(height: 20.h),
          _buildEditButton(),
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

  Widget _buildEditButton() {
    return GestureDetector(
      onTap: () {
        // Navigate back to edit booking details
        context.pop();
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
    );
  }

  Widget _buildPaymentInfoCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.background,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: context.secondary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            label: 'الاسم الكامل',
            controller: fullNameController,
            placeholder: 'أدخل اسمك الكامل',
          ),
          SizedBox(height: 20.h),
          _buildTextField(
            label: 'البريد الإلكتروني',
            controller: emailController,
            placeholder: 'example@email.com',
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: context.primary,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(
              fontSize: 14.sp,
              color: context.secondaryText,
            ),
            filled: true,
            fillColor: context.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: context.secondary.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: context.secondary.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: context.primary,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
            ),
          ),
          style: TextStyle(
            fontSize: 14.sp,
            color: context.primaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildPayNowButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: isFormValid,
      builder: (context, isValid, _) {
        return Column(
          children: [
            // زر أضف إلى السلة
            if (!_customerBooking.isInCart && _customerBooking.offerId == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isValid ? _addToCart : null,
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
                onPressed: isValid ? _navigateToPayment : null,
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
      },
    );
  }

  Widget _buildSecurityDisclaimer() {
    return Text(
      'سيتم تحويلك البوابة الدفع لإتمام العملية بأمان.',
      style: TextStyle(
        fontSize: 12.sp,
        color: context.secondaryText,
      ),
      textAlign: TextAlign.center,
    );
  }

  void _navigateToPayment() async {
    final result = await ref
        .read(ApiProviders.bookingProvider)
        .sendBookingSummary(context, fullNameController.text.toString(),
            emailController.text.toLowerCase());

    if (mounted && result) {
      context.push('/booking-payment');
    }
  }

  /// إضافة الحجز إلى السلة
  void _addToCart() async {
    try {
      // إنشاء الحجز أولاً
      final result = await ref
          .read(ApiProviders.bookingProvider)
          .sendBookingSummary(context, fullNameController.text.toString(),
              emailController.text.toLowerCase());

      if (mounted && result) {
        // الحصول على معرف الحجز
        final booking = ref.read(ApiProviders.bookingProvider).customerBooking;
        final bookingId = booking.id.toString();

        // إضافة الحجز إلى السلة
        final cartResult = await ref
            .read(ApiProviders.cartProvider)
            .addBookingIntoCart(context, bookingId);

        if (mounted && cartResult) {
          // Update booking isInCart status
          booking.isInCart = true;
          ref.read(ApiProviders.bookingProvider).notifyListeners();

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
