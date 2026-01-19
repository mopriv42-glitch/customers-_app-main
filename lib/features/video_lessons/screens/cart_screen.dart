import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/models/cart_model.dart';
import 'package:private_4t_app/core/models/learning_course_model.dart';
import 'package:private_4t_app/core/widgets/app_header.dart';
import 'package:private_4t_app/core/widgets/optimized_cached_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen>
    with AnalyticsScreenMixin {
  @override
  String get screenName => 'CartScreen';

  final TextEditingController couponController = TextEditingController();
  bool hasCoupon = false;
  double originalAmount = 0.0;
  double couponDiscount = 0.0;
  double totalAmount = 0.0;
  CartModel _cartModel = CartModel();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ApiProviders.cartProvider).getCart(context);
    });
  }

  @override
  void dispose() {
    couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(ApiProviders.cartProvider);
    bool isLoading = provider.isLoading;
    _cartModel = provider.cartModel;

    if (_cartModel.couponId != null) {
      hasCoupon = true;
      couponDiscount = _cartModel.discountTotal().toDouble();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(ApiProviders.cartProvider).getCart(context);
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: context.background,
          appBar: const AppHeader(
            title: 'سلتي',
            showBackButton: true,
          ),
          body: isLoading
              ? CommonComponents.loadingDataFromServer()
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    children: [
                      _buildBreadcrumb(),
                      SizedBox(height: 24.h),
                      if (_cartModel.items!.isEmpty) _buildEmptyCartMessage(),
                      if (_cartModel.items!.isNotEmpty) _buildCartItems(),
                      SizedBox(height: 24.h),
                      if (_cartModel.items!.isNotEmpty &&
                          _cartModel.couponId == null) ...[
                        _buildCouponSection(),
                        SizedBox(height: 24.h),
                      ],
                      if (_cartModel.items!.isNotEmpty &&
                          _cartModel.couponId != null) ...[
                        _buildAppliedCouponSection(),
                        SizedBox(height: 24.h),
                      ],
                      if (_cartModel.items!.isNotEmpty) _buildCartSummary(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return Row(
      children: [
        Text(
          'الرئيسية',
          style: TextStyle(
            fontSize: 14.sp,
            color: context.secondaryText,
          ),
        ),
        SizedBox(width: 8.w),
        Icon(Icons.chevron_left, size: 16.sp, color: context.secondaryText),
        SizedBox(width: 8.w),
        Text(
          'الكورسات',
          style: TextStyle(
            fontSize: 14.sp,
            color: context.secondaryText,
          ),
        ),
        SizedBox(width: 8.w),
        Icon(Icons.chevron_left, size: 16.sp, color: context.secondaryText),
        SizedBox(width: 8.w),
        Text(
          'سلة المشتريات',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: context.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildCartItems() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.secondary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: _cartModel.items!
            .map(
              (item) => Padding(
                padding: EdgeInsets.symmetric(vertical: 10.r),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (item.model is LearningCourseModel)
                      OptimizedCachedImage(
                          imageUrl: item.model?.thumbnailUrl.toString() ?? ''),
                    // Arabic Title
                    if (item.qty != null && item.qty! > 1)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.r),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              "X ${item.qty}",
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.r),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            (item.model != null
                                    ? item.model?.title
                                    : item.name) ??
                                '',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Centered Number
                    Expanded(
                      child: Center(
                        child: Text(
                          "${item.unitPrice.toString()} د.ك",
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        logButtonClick('remove_from_cart', data: {
                          'item_id': item.id.toString(),
                          'item_name': 'Course',
                          'price': item.unitPrice,
                          'cart_size': _cartModel.items!.length,
                        });

                        await ref
                            .read(ApiProviders.cartProvider)
                            .deleteCartItem(
                              context,
                              item.id.toString(),
                            );
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.pink[100],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 20.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildEmptyCartMessage() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.secondary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64.sp,
            color: context.secondaryText,
          ),
          SizedBox(height: 16.h),
          Text(
            'ستلك فاضية مليها بالكورسات من عنا',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: context.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.secondary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: couponController,
              decoration: InputDecoration(
                hintText: 'COUPON CODE',
                hintStyle: TextStyle(
                  fontSize: 14.sp,
                  color: context.secondaryText,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide:
                      BorderSide(color: context.secondary.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide:
                      BorderSide(color: context.secondary.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: context.border),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          ElevatedButton(
            onPressed: _applyCoupon,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primary,
              foregroundColor: context.surface,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'Apply coupon',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppliedCouponSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.success.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_offer,
            color: context.success,
            size: 24.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'كوبون مطبق',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: context.success,
                  ),
                ),
                if (_cartModel.coupon != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    _cartModel.coupon!.code ?? '',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: context.primaryText,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'خصم: KWD ${_cartModel.discountTotal().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: context.secondaryText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: _removeCoupon,
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: context.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.close,
                color: context.error,
                size: 20.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartSummary() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.secondary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مجموع السلة',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: context.primaryText,
            ),
          ),
          SizedBox(height: 16.h),
          _buildSummaryRow('المبلغ الأصلي',
              'KWD ${_cartModel.subtotal().toStringAsFixed(2)}'),
          if (hasCoupon)
            _buildSummaryRow('خصم الكوبون',
                'KWD ${_cartModel.discountTotal().toStringAsFixed(2)}',
                isDiscount: true),
          Divider(height: 24.h, color: context.secondary.withOpacity(0.3)),
          _buildSummaryRow(
              'الإجمالي', 'KWD ${_cartModel.grandTotal().toStringAsFixed(2)}',
              isTotal: true),
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _proceedToCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.success,
                foregroundColor: context.surface,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Checkout',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'من خلال إكمال عملية الشراء الخاصة بك، فإنك توافق على هذه الشروط والأحكام',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              color: context.secondaryText,
            ),
          ),
          SizedBox(height: 8.h),
          Center(
            child: GestureDetector(
              onTap: _showTermsAndConditions,
              child: Text(
                'الشروط والأحكام',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: context.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isDiscount = false, bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: context.primaryText,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              color: isDiscount
                  ? context.error
                  : (isTotal ? context.primary : context.primaryText),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _applyCoupon() async {
    final couponCode = couponController.text.toString();
    if (couponCode.isNotEmpty) {
      logButtonClick('apply_coupon', data: {
        'coupon_code': couponCode,
        'cart_subtotal': _cartModel.subtotal(),
        'items_count': _cartModel.items!.length,
      });

      await ref
          .read(ApiProviders.cartProvider)
          .applyCoupon(context, couponCode);
      // The cart will be updated automatically through the provider
    }
  }

  void _removeCoupon() async {
    logButtonClick('remove_coupon', data: {
      'coupon_code': couponController.text,
      'discount_amount': couponDiscount,
    });

    final result =
        await ref.read(ApiProviders.cartProvider).removeCoupon(context);

    if (result) {
      logStep('coupon_removed_success');
      setState(() {
        hasCoupon = false;
        couponDiscount = 0.0;
        couponController.clear();
      });
    }
  }

  void _proceedToCheckout() {
    logButtonClick('proceed_to_checkout', data: {
      'items_count': _cartModel.items!.length,
      'subtotal_amount': _cartModel.subtotal(),
      'has_coupon': _cartModel.couponId != null,
      'discount_amount': couponDiscount,
      'final_amount': _cartModel.subtotal() - couponDiscount,
    });

    logStep('checkout_initiated', data: {
      'cart_value': _cartModel.subtotal(),
    });

    // Navigate to payment screen
    context.push('/cart-payment');
  }

  void _showTermsAndConditions() async {
    logButtonClick('view_terms_and_conditions');

    const String termsUrl = 'https://private-4t.com/terms';
    final Uri uri = Uri.parse(termsUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
