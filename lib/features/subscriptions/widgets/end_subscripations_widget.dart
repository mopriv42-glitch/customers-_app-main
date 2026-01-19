import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/models/learning_course_model.dart';
import 'package:private_4t_app/core/models/order_course_model.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/features/subscriptions/widgets/class_card.dart';
import 'package:private_4t_app/features/subscriptions/widgets/course_card.dart';

class EndSubscriptionsWidget extends ConsumerStatefulWidget {
  const EndSubscriptionsWidget({super.key});

  @override
  ConsumerState<EndSubscriptionsWidget> createState() =>
      _EndSubscriptionsWidgetState();
}

class _EndSubscriptionsWidgetState
    extends ConsumerState<EndSubscriptionsWidget> {
  List<OrderCourseModel> endOrders = [];
  List<OrderCourseModel> endCourses = [];
  List<LearningCourseModel> endPackages = [];

  @override
  void initState() {
    super.initState();
    // Initialize booking data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ApiProviders.subscriptionsProvider).getEndSubscriptions(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionsProvider = ref.watch(ApiProviders.subscriptionsProvider);
    bool isLoading = subscriptionsProvider.isLoading;
    // Update the lists when data is loaded

    if (!isLoading) {
      endOrders = subscriptionsProvider.endOrdersList;
      endCourses = subscriptionsProvider.endCoursesList;
      endPackages = subscriptionsProvider.endPackagesList;
    }

    return isLoading
        ? CommonComponents.loadingDataFromServer()
        : SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'إشتراكاتي المنتهية',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: context.primaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),

                // حصص
                _buildSubSectionTitle('حصص'),
                SizedBox(height: 6.h),
                ...endOrders.map((order) => ClassCard(
                      orderCourseModel: order,
                    )),

                SizedBox(height: 8.h),

                // باقات
                _buildSubSectionTitle('باقات'),
                SizedBox(height: 6.h),
                ...endCourses.map((order) => ClassCard(
                      orderCourseModel: order,
                    )),

                SizedBox(height: 8.h),

                // // دورات
                // _buildSubSectionTitle('دورات'),
                // SizedBox(height: 6.h),
                // ...endPackages.map(
                //   (package) => CourseCard(
                //     course: package,
                //   ),
                // ),
              ],
            ),
          );
  }

  Widget _buildSubSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15.sp,
        fontWeight: FontWeight.w600,
        color: context.secondaryText,
      ),
    );
  }
}
