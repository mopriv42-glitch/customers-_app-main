import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _UPaymentScreenState();
}

class _UPaymentScreenState extends ConsumerState<PaymentScreen> with AnalyticsScreenMixin {
  WebViewController? _controller; // بدل late final
  
  @override
  String get screenName => 'Paymentscreen';
  

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final paymentURL =
          await ref.read(ApiProviders.bookingProvider).getPaymentLink(context);
      if (paymentURL != null) {
        final controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(NavigationDelegate(
            onPageFinished: (String url) {
              if (url.contains('knet/success/booking')) {
                final booking =
                    ref.read(ApiProviders.bookingProvider).customerBooking;
                var message = booking.offerId == null
                    ? "لقد تم حجز الحصة بنجاح"
                    : "لقد تم حجز العرض بنجاح";
                Future.microtask(() {
                  CommonComponents.showCustomizedSnackBar(
                    context: context,
                    title: message,
                  );

                  // توجيه باستخدام go_router
                  context.go('/home');
                });
              }

              if (url.contains('knet/cancel')) {
                CommonComponents.showCustomizedSnackBar(
                  context: context,
                  title: "لقد تم الغاء الدفع",
                );
                context.pop(); // يستخدم go_router بدل Navigator.pop
              }
            },
          ))
          ..loadRequest(Uri.parse(paymentURL));

        setState(() {
          _controller = controller;
        });
      } else {
        if (mounted && context.canPop()) {
          context.pop();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.background,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: _controller != null
              ? WebViewWidget(controller: _controller!)
              : const Center(child: CircularProgressIndicator()),
        ), // مؤقتًا حمّل
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
        'الدفع',
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
    );
  }
}
