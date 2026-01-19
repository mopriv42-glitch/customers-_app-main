import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/core/models/user_model.dart';
import 'package:riverpod_context/riverpod_context.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class InstituteBookingSummaryScreen extends StatefulWidget {
  final String serviceType;
  final String subject;
  final String grade;
  final DateTime date;
  final TimeOfDay time;
  final String duration;
  final double price;

  const InstituteBookingSummaryScreen({
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
  State<InstituteBookingSummaryScreen> createState() =>
      _InstituteBookingSummaryScreenState();
}

class _InstituteBookingSummaryScreenState
    extends State<InstituteBookingSummaryScreen> with AnalyticsScreenMixin {
  
  @override
  String get screenName => 'InstituteBookingSummaryscreen';
  
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final ValueNotifier<bool> isFormValid = ValueNotifier(false);
  late UserModel _loggedUser;

  void _validateForm() {
    isFormValid.value =
        fullNameController.text.isNotEmpty && emailController.text.isNotEmpty;
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    fullNameController.addListener(_validateForm);
    emailController.addListener(_validateForm);

    _loggedUser = context.read(ApiProviders.loginProvider).loggedUser!;
    fullNameController.text = _loggedUser.name ?? '';
    emailController.text = _loggedUser.email ?? '';
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
                _buildHeader(),
                SizedBox(height: 24.h),
                _buildBookingSummaryCard(),
                SizedBox(height: 20.h),
                // _buildPersonalInfoSection(),
                // SizedBox(height: 32.h),
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
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'ملخص الحجز',
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: context.surface,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: Text(
            'تعديل',
            style: TextStyle(
              color: context.surface,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.school, color: context.primary, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'حصة في المعهد',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: context.primary,
              ),
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

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المعلومات الشخصية',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: context.primaryText,
          ),
        ),
        SizedBox(height: 12.h),
        _buildTextField(
          controller: fullNameController,
          label: 'الاسم الكامل',
          placeholder: 'أدخل اسمك الكامل',
          keyboardType: TextInputType.name,
        ),
        SizedBox(height: 16.h),
        _buildTextField(
          controller: emailController,
          label: 'البريد الإلكتروني',
          placeholder: 'example@email.com',
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    required TextInputType keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: context.primaryText,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(
              color: context.secondaryText,
              fontSize: 14.sp,
            ),
            filled: true,
            fillColor: context.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: context.secondary.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: context.secondary.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: context.primary),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          ),
        ),
      ],
    );
  }

  Widget _buildPayNowButton() {
    final booking = context.watch(ApiProviders.bookingProvider).customerBooking;
    return ValueListenableBuilder<bool>(
      valueListenable: isFormValid,
      builder: (context, isValid, _) {
        return Column(
          children: [
            // زر أضف إلى السلة
            if (!booking.isInCart &&booking.offerId == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isValid ? _addToCart : null,
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
                onPressed: isValid ? _navigateToPayment : null,
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
        );
      },
    );
  }

  void _navigateToPayment() async {
    final result = await context
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
      final result = await context
          .read(ApiProviders.bookingProvider)
          .sendBookingSummary(context, fullNameController.text.toString(),
              emailController.text.toLowerCase());

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
}
