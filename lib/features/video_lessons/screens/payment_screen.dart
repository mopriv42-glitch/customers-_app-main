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
      final paymentURL = await ref
          .read(ApiProviders.videoCoursesProvider)
          .getPaymentLink(context);
      if (paymentURL != null) {
        final controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(NavigationDelegate(
            onPageFinished: (String url) {
              if (url.contains('knet/success/booking')) {
                Future.microtask(() {
                  CommonComponents.showCustomizedSnackBar(
                    context: context,
                    title: "لقد تم شراء الكورس بنجاح",
                  );

                  // توجيه باستخدام go_router
                  context.go('/home');
                });
              }

              if (url.contains('knet/cancel')) {
                context.pop(); // يستخدم go_router بدل Navigator.pop
              }
            },
          ))
          ..loadRequest(Uri.parse(paymentURL));

        setState(() {
          _controller = controller;
        });
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
        body: _controller != null
            ? WebViewWidget(controller: _controller!)
            : const Center(child: CircularProgressIndicator()), // مؤقتًا حمّل
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
      actions: [
        Container(
          margin: EdgeInsets.only(right: 16.w),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Text(
            'English',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: context.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final PaymentMethodData method;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.method,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
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
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: method.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    method.icon,
                    color: method.color,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.name,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: context.primaryText,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        method.description,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: context.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16.sp,
                  color: context.secondaryText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PaymentMethodData {
  final String name;
  final IconData icon;
  final Color color;
  final String description;

  PaymentMethodData({
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });
}
