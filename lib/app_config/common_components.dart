import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/app_colors.dart';
import 'package:private_4t_app/app_config/app_global_keys.dart';
import 'package:riverpod_context/riverpod_context.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
class CommonComponents {
  static String placeHolderImages = "assets/images/logo_opacity.png";

  static Widget backgroundIamgeWithScreens({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: ResizeImage(
            AssetImage('assets/images/background_app.png'),
            height: 973,
            width: 973,
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: child,
    );
  }

  static void showCustomizedSnackBar(
      {required BuildContext context, required String title}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.0.h,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.blueAppColor,
      ),
    );
  }

  static Widget _acceptAlertFieldsWidgets({
    required String title,
    required TextEditingController controller,
    required String hint,
    required String validate,
    required TextInputType type,
    required TextInputAction action,
    Function()? onPress,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(fontSize: 15.0.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 10.0.h),
        TextFormField(
          controller: controller,
          keyboardType: type,
          textInputAction: action,
          validator: (value) => value!.isEmpty ? validate : null,
          style: TextStyle(fontSize: 14.0.sp, color: Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 15.0.sp),
            errorStyle: TextStyle(fontSize: 14.0.sp),
            border: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.black),
              borderRadius: BorderRadius.circular(7.0.r),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.black),
              borderRadius: BorderRadius.circular(7.0.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.black),
              borderRadius: BorderRadius.circular(7.0.r),
            ),
            disabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.black),
              borderRadius: BorderRadius.circular(7.0.r),
            ),
            contentPadding: EdgeInsets.all(8.0.h),
            isDense: true,
            filled: true,
            fillColor: AppColors.textFiledAppColor,
          ),
          readOnly: readOnly,
          onTap: onPress,
        ),
      ],
    );
  }

  static Future<void> deleteAccountWidget(
      {required BuildContext context}) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0.r),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              (!kIsWeb && Platform.isAndroid)
                  ? "سبب الإستقالة"
                  : "سبب حذف الحساب",
              style: TextStyle(fontSize: 15.0.sp, fontWeight: FontWeight.bold),
            ),
            const Divider(color: Colors.grey),
            SizedBox(height: 10.0.h),
            SizedBox(
              height: 300.0.h,
              width: 300.0.w,
              child: ListView.separated(
                physics: const ScrollPhysics(),
                separatorBuilder: (context, index) =>
                    const Divider(color: Colors.grey),
                itemCount: rejectionList.length,
                itemBuilder: (context, index) => TextButton(
                  onPressed: () async {
                    await context
                        .read(ApiProviders.loginProvider)
                        .deleteAccount(
                            context: context, notes: rejectionList[index]);
                  },
                  style: TextButton.styleFrom(
                      alignment: Alignment.centerRight,
                      foregroundColor: Colors.black,
                      textStyle: TextStyle(fontSize: 15.0.sp)),
                  child: Text(rejectionList[index]),
                ),
              ),
            ),
            SizedBox(height: 10.0.h),
            Text((!kIsWeb && Platform.isAndroid)
                ? "ملاحظة: عند تقديم طلب الاستقالة سيتم منعك من تسجيل الدخول الي التطبيق وسيتم أيضاً حذف حسابك بجميع بيانات وخصوصاً معاملاتك المالية."
                : "ملاحظة: عند حذف الحساب سيتم منعك من تسجيل الدخول الي التطبيق وسيتم أيضاً حذف حسابك بجميع بيانات وخصوصاً معاملاتك المالية."),
            SizedBox(
              height: 10.0.h,
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.redAppColor,
                minimumSize: Size(double.infinity, 40.0.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0.r)),
                textStyle:
                    TextStyle(fontSize: 15.0.sp, fontWeight: FontWeight.bold),
              ),
              child: const Text("إلغاء"),
            ),
          ],
        ),
      ),
    );
  }

//TODO THIS FOR TESTING UI ONLY
  static List<String> rejectionList = [
    "الوقت غير مناسب",
    "عدد الطلبات غير كافي",
    'غير متاح الان',
    "أسباب خاصة",
  ];

  static List<String> rejectionOrdersAndCoursesList = [
    'الوقت غير مناسب',
    'غير قادر للوصول للمكان',
    'قبلتها بالخطأ',
    'لا أريد تدريس هذا الطالب',
    'غير متاح الان',
    "أسباب خاصة",
  ];

  static Future showCustomizedAlert({
    required BuildContext context,
    required String title,
    required String subTitle,
  }) async {
    return await showGeneralDialog(
      context: context,
      pageBuilder: (context, animation1, animation2) => Container(),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, animation1, animation2, child) =>
          ScaleTransition(
        scale: animation1,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                "assets/images/logo_with_color.svg",
                height: 50.0.h,
              ),
              SizedBox(height: 5.0.h),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.blueAppColor,
                  fontSize: 16.0.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            subTitle,
            style: TextStyle(
              color: AppColors.redAppColor,
              fontSize: 16.0.sp,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.green),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                "موافق",
                style: TextStyle(fontSize: 18.0.sp),
              ),
            )
          ],
        ),
      ),
    );
  }

  static Future showLocationSettingDialog({
    required BuildContext context,
  }) async {
    return await showGeneralDialog(
      context: context,
      pageBuilder: (context, animation1, animation2) => Container(),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, animation1, animation2, child) =>
          ScaleTransition(
        scale: animation1,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                "assets/images/logo_with_color.svg",
                height: 50.0.h,
              ),
              SizedBox(height: 5.0.h),
              Text(
                "تفعيل الموقع الجعرافي",
                style: TextStyle(
                  color: AppColors.blueAppColor,
                  fontSize: 16.0.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            "الرجاء السماح للتطبيق بإستخدام خدمة الموقع الجغرافي ( GPS ) لضمان عمل مميزات التطبيق بكفاءة عالية يرجى تفعيلها",
            style: TextStyle(
              color: AppColors.redAppColor,
              fontSize: 16.0.sp,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.green),
              onPressed: () async {
                await Geolocator.openLocationSettings();
                Navigator.pop(context);
              },
              child: Text(
                "الموقع",
                style: TextStyle(fontSize: 18.0.sp),
              ),
            )
          ],
        ),
      ),
    );
  }

  static Future<void> loading(BuildContext context) async {
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => Center(
        child: SizedBox(
          height: 50.0.h,
          width: 50.0.w,
          child: CircularProgressIndicator(
            valueColor: const AlwaysStoppedAnimation(AppColors.blueAppColor),
            strokeWidth: 5.0.w,
          ),
        ),
      ),
    );
  }

  static Widget loadingDataFromServer({Color? color}) => Center(
        child: CircularProgressIndicator(
          valueColor:
              AlwaysStoppedAnimation<Color>(color ?? AppColors.blueAppColor),
        ),
      );

  static Future<bool> checkConnectivity() async {
    // var result = await Connectivity().checkConnectivity();
    // if (result.isEmpty || result.contains(ConnectivityResult.none)) {
    //   return false;
    // } else if (result.contains(ConnectivityResult.wifi) ||
    //     result.contains(ConnectivityResult.mobile)) {
    //   return true;
    // }
    // return false;

    try {
      final result = await InternetAddress.lookup('private-4t.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future notConnectionAlert(BuildContext context) async {
    await showCustomizedAlert(
      context: context,
      title: "لا يوجد اتصال بالشبكة",
      subTitle: "يرجى الاتصال بالشبكة بشبكة Wifi أو بيانات الهاتف المحمول",
    );
  }

  static Future timeOutExceptionAlert(BuildContext context) async {
    await showCustomizedAlert(
      context: context,
      title: "الخادم مشغول",
      subTitle: "الخادم مشغول حاول مرة أخرى لاحقا",
    );
  }

  static Future socketExceptionAlert(BuildContext context) async {
    await showCustomizedAlert(
      context: context,
      title: "خطأ في الإتصال",
      subTitle: "الرجاء التأكد من اتصال خادم قاعدة البيانات الخاص بك",
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> saveData(
      {required String key, required dynamic value}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (value is String) {
      return await prefs.setString(key, value);
    } else if (value is bool) {
      return await prefs.setBool(key, value);
    } else {
      return prefs.setInt(key, value);
    }
  }

  @pragma('vm:entry-point')
  static Future getSavedData(key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.get(key);
  }

  @pragma('vm:entry-point')
  static Future<void> deleteSavedData(key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove(key);
  }

  static List<int> generatePaginationPagesNumbersList({
    required currentPage,
    required int lastPage,
    required int jumpRange,
  }) {
    List<int> pagesList = [1];
    if (lastPage == 0) {
      pagesList = [];
    } else if (lastPage == 1) {
      pagesList = [1];
    } else if (lastPage == 2) {
      pagesList = [1, 2];
    } else if (lastPage == 3) {
      pagesList = [1, 2, 3];
    } else if (lastPage == 4) {
      pagesList = [1, 2, 3, 4];
    } else {
      for (int i = 0; i <= 4; i++) {
        if (i + jumpRange < lastPage) {
          if (i + jumpRange != 1 && i + jumpRange != lastPage) {
            pagesList.add(i + jumpRange);
          }
        }
      }
      int beforeLastPage = pagesList.last;
      if (currentPage > beforeLastPage && currentPage < lastPage) {
        pagesList[pagesList.indexOf(beforeLastPage)] = currentPage;
      }
      pagesList.add(lastPage);
    }
    return pagesList;
  }

  static DateTime getCurrentDateTime([DateTime? dateTime]) {
    final kuwaitLocation = tz.getLocation('Asia/Kuwait');
    return tz.TZDateTime.from(dateTime ?? DateTime.now(), kuwaitLocation);
  }

  static String getNotificationChannelKey([String? url]) {
    switch (url) {
      default:
        return AppGlobalKeys.otherNotificationsChannelKey;
    }
  }
}
