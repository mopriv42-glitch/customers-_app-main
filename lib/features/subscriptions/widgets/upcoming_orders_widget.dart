import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/models/order_course_model.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/features/subscriptions/widgets/class_card.dart';

class UpcomingOrdersWidget extends ConsumerStatefulWidget {
  const UpcomingOrdersWidget({super.key});

  @override
  ConsumerState<UpcomingOrdersWidget> createState() =>
      _UpcomingOrdersWidgetState();
}

class _UpcomingOrdersWidgetState extends ConsumerState<UpcomingOrdersWidget> {
  List<OrderCourseModel> upcomingOrders = [];

  @override
  void initState() {
    super.initState();
    // Initialize booking data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ApiProviders.subscriptionsProvider).getUpcomingOrders(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionsProvider = ref.watch(ApiProviders.subscriptionsProvider);
    bool isLoading = subscriptionsProvider.isLoading;
    // Update the lists when data is loaded
    if (!isLoading) {
      upcomingOrders = subscriptionsProvider.upcomingOrdersList;
    }
    return isLoading
        ? CommonComponents.loadingDataFromServer()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'حصصي القادمة',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: context.primaryText,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 6.h),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                  itemCount: upcomingOrders.length,
                  itemBuilder: (BuildContext context, int index) {
                    var order = upcomingOrders[index];
                    return ClassCard(orderCourseModel: order);
                  },
                ),
              ),
            ],
          );
  }
}
