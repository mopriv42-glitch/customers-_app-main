import 'dart:convert';
import 'dart:math';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:private_4t_app/app_config/api_keys.dart';
import 'package:private_4t_app/app_config/app_colors.dart';
import 'package:private_4t_app/app_config/app_global_keys.dart';
import 'package:private_4t_app/app_config/app_navigator.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/services/download_service.dart';

class NotificationController {
  static ReceivedAction? initialAction;
  static bool _notificationPermissionRequested = false;

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    try {
      final data = receivedAction.payload?['data'];
      if (data != null) {
        var json = jsonDecode(data) as Map<String, dynamic>;
        debugPrint(
            "From onActionReceivedMethod => ${receivedAction.buttonKeyPressed}");
        if (AppNavigator.navigatorKey.currentContext != null) {
          if (receivedAction.buttonKeyPressed == 'ACCEPT') {
            NotificationController.notificationNavigationHandler(
              AppNavigator.navigatorKey.currentContext!,
              json,
              receivedAction.actionLifeCycle.toString() != 'Terminated',
            );
          }
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  static Future<void> cancelAllNotifications() async {
    // await _notification.cancelAll();
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {}

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {}

  static Future<void> getAllNotifications() async {}

  static Future<void> handleURL(BuildContext context, Map<String, dynamic> json,
      [bool appOpened = false]) async {
    if (await CommonComponents.getSavedData(ApiKeys.userToken) == null) {
      return;
    }
    // if (json.containsKey('url')) {
    //   switch (json['url']) {
    //     case PATHS.chatScreen:
    //       if (json.containsKey('modelJson')) {
    //         // await context
    //         //     .read(ChatsProviders.chatProviderApis)
    //         //     .setChatUser(UserModel.fromMap(json['modelJson']));
    //         // AppNavigator.toRoute(PATHS.chatScreen);
    //       }
    //       break;
    //     case PATHS.lessonAndCourseDescriptionScreen:
    //       if (json.containsKey('order_id') && json['order_type'] != null) {
    //         final model = OrderDescriptionModel.fromJson(json['modelJson']);
    //         if (model.orderStatus == 'تم_الارسال_للمدرسين') {
    //           bool accepted = await context
    //               .read(OrdersProviders.ordersProvidersApis)
    //               .acceptOrder(
    //                 context: context,
    //                 orderID: "${json['order_id']}",
    //                 orderType: "${json['order_type']}",
    //                 showLoadingWidget: true,
    //               );
    //           if (appOpened && json.containsKey('live')) {
    //             if (accepted) {
    //               await context
    //                   .read(HomeProviders.orderDescriptionProvidersApis)
    //                   .setOrderSelectedDetails({
    //                 'orderID': "${model.orderID}",
    //                 'orderType': "${model.orderType}",
    //               });
    //               AppNavigator.toRoute(PATHS.lessonAndCourseDescriptionScreen);
    //             }
    //           }
    //         }
    //         if (model.orderStatus == 'تم_اختيار_مدرس' &&
    //             model.teacherApproved == 'تم_التأكيد_مع_الطالب') {
    //           if (json['order_type'] == 'كورس' || json['order_type'] == 'حصة') {
    //             await context
    //                 .read(HomeProviders.orderDescriptionProvidersApis)
    //                 .setOrderSelectedDetails({
    //               'orderID': "${model.orderID}",
    //               'orderType': model.orderType,
    //             });
    //             AppNavigator.toRouteAndReplaceAll(
    //               PATHS.mainScreen,
    //             );
    //
    //             AppNavigator.toRoute(
    //               PATHS.lessonAndCourseDescriptionScreen,
    //             );
    //           }
    //         }
    //       }
    //       break;
    //     default:
    //       if (json['url'] == PATHS.mainScreen) return;
    //       AppNavigator.toRouteAndReplaceAll(PATHS.mainScreen);
    //       AppNavigator.toRoute(json['url']);
    //       break;
    //   }
    // }
  }

  static Future<void> handleAction(String data, String buttonKeyPressed) async {
    try {
      var json = jsonDecode(data) as Map<String, dynamic>;
      switch (buttonKeyPressed) {
        case 'ACCEPT':
          final orderID = json['order_id'];
          final orderType = json['order_type'];
          Uri url = Uri.parse("${ApiKeys.baseUrl}orderaccept/$orderID");
          http.Response response = await http.put(
            url,
            headers: {
              "Accept": "application/json",
              "Accept-Language": "ar",
              "Authorization":
                  "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}"
            },
            body: {'order_type': orderType},
          );

          var bodyData = jsonDecode(response.body);
          await Fluttertoast.showToast(
            msg: "${bodyData?['orderupdates'] ?? bodyData?['message']}",
            toastLength: Toast.LENGTH_LONG,
          );

          break;
        case 'DENY':
          break;
        default:
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  static Future<void> init() async {
    await AwesomeNotifications().initialize(
      "resource://drawable/logo",
      [
        NotificationChannel(
          channelKey: AppGlobalKeys.ordersChannelKey,
          channelName: "Orders",
          channelDescription:
              "This channel will received all notifications these related with orders and course",
          importance: NotificationImportance.Max,
          playSound: true,
          channelShowBadge: true,
        ),
        NotificationChannel(
          channelKey: AppGlobalKeys.chatsChannelKey,
          channelName: "Chats",
          channelDescription:
              "This channel will received all notifications these related with chats",
          importance: NotificationImportance.Max,
          playSound: true,
          channelShowBadge: true,
        ),
        NotificationChannel(
          channelKey: AppGlobalKeys.otherNotificationsChannelKey,
          channelName: "Other notifications",
          channelDescription:
              "This channel will received all other notifications",
          importance: NotificationImportance.Max,
          playSound: true,
          channelShowBadge: true,
        ),
        NotificationChannel(
          channelKey: DownloadService.DOWNLOAD_NOTIFICATION_CHANNEL_ID,
          channelName: "Download notifications",
          channelDescription:
          "This channel will received all downloading notifications",
          importance: NotificationImportance.Max,
          playSound: true,
          channelShowBadge: true,
        ),
      ],
    );

    await AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
    );
  }

  static pushNotification(
    String channelKey, {
    String? title,
    String? body,
    RemoteMessage? remoteMessage,
    String? jsonPayload,
    ActionType notificationAction = ActionType.Default,
  }) async {
    if (await AwesomeNotifications().isNotificationAllowed()) {
      if (remoteMessage != null) {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: Random().nextInt(1000),
            channelKey: channelKey,
            displayOnBackground: true,
            displayOnForeground: true,
            actionType: notificationAction,
            wakeUpScreen: true,
            title: remoteMessage.notification != null
                ? remoteMessage.notification!.title
                : remoteMessage.data['title'],
            body: remoteMessage.notification != null
                ? remoteMessage.notification!.body
                : remoteMessage.data['body'],
            largeIcon: "resource://drawable/logo",
            roundedLargeIcon: true,
            payload: {
              "data": remoteMessage.data['data'] is String
                  ? remoteMessage.data['data']
                  : jsonEncode(
                      remoteMessage.data['data'],
                    ),
            },
          ),
        );
      } else {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: Random().nextInt(1000),
            channelKey: channelKey,
            displayOnBackground: true,
            displayOnForeground: true,
            actionType: notificationAction,
            wakeUpScreen: true,
            title: title,
            body: body,
            largeIcon: "resource://drawable/logo",
            roundedLargeIcon: true,
            payload: {
              "data": jsonPayload,
            },
          ),
        );
      }
    } else if (!_notificationPermissionRequested) {
      _notificationPermissionRequested = true;
      await AwesomeNotifications().requestPermissionToSendNotifications();
      // Reset flag after a delay to allow future requests if needed
      Future.delayed(const Duration(minutes: 10), () {
        _notificationPermissionRequested = false;
      });
    }
  }

  static pushNotificationWithButtons(
    String channelKey, {
    String? title,
    String? body,
    RemoteMessage? remoteMessage,
    String? jsonPayload,
  }) async {
    if (await AwesomeNotifications().isNotificationAllowed()) {
      if (remoteMessage != null) {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: remoteMessage.hashCode,
            actionType: ActionType.DisabledAction,
            channelKey: channelKey,
            displayOnBackground: true,
            displayOnForeground: true,
            wakeUpScreen: true,
            title: remoteMessage.notification != null
                ? remoteMessage.notification!.title
                : remoteMessage.data['title'],
            body: remoteMessage.notification != null
                ? remoteMessage.notification!.body
                : remoteMessage.data['body'],
            largeIcon: "resource://drawable/logo",
            roundedLargeIcon: true,
            payload: {
              "data": remoteMessage.data['data'] is String
                  ? remoteMessage.data['data']
                  : jsonEncode(
                      remoteMessage.data['data'],
                    ),
            },
            notificationLayout: NotificationLayout.BigText,
          ),
          actionButtons: [
            NotificationActionButton(
              key: "ACCEPT",
              label: 'قبول',
              actionType: ActionType.Default,
            ),
            NotificationActionButton(
              key: "DENY",
              label: 'رفض',
              actionType: ActionType.DismissAction,
            ),
          ],
        );
      } else {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: Random.secure().nextInt(10000),
            actionType: ActionType.DisabledAction,
            channelKey: channelKey,
            displayOnBackground: true,
            displayOnForeground: true,
            wakeUpScreen: true,
            title: title,
            body: body,
            largeIcon: "resource://drawable/logo",
            roundedLargeIcon: true,
            payload: {
              "data": jsonPayload,
            },
            notificationLayout: NotificationLayout.BigText,
          ),
          actionButtons: [
            NotificationActionButton(
              key: "ACCEPT",
              label: 'قبول',
              actionType: ActionType.Default,
            ),
            NotificationActionButton(
              key: "DENY",
              label: 'رفض',
              actionType: ActionType.DismissAction,
            ),
          ],
        );
      }
    } else if (!_notificationPermissionRequested) {
      _notificationPermissionRequested = true;
      await AwesomeNotifications().requestPermissionToSendNotifications();
      // Reset flag after a delay to allow future requests if needed
      Future.delayed(const Duration(minutes: 10), () {
        _notificationPermissionRequested = false;
      });
    }
  }

  static Future<void> notificationNavigationHandler(
      BuildContext context, Map<String, dynamic>? data,
      [bool appOpened = false]) async {
    if (data != null) {
      handleURL(context, data, appOpened);
    }
  }

  static Widget alertOfNewLessonNotification({
    required BuildContext context,
    required TextEditingController timeFromController,
    required TextEditingController timeToController,
    required GlobalKey<FormState> formKey,
  }) {
    return Container(
      padding: EdgeInsets.all(10.0.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0.r),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "orderData.procedure",
                style: TextStyle(
                  fontSize: 15.0.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(color: Colors.grey),
            SizedBox(height: 10.0.h),
            Text(
              "orderData.subjectName - orderData.gradeName",
              style: TextStyle(fontSize: 15.0.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0.h),
            Text(
              "محافظة : orderData.governoment- منطقة : orderData.region",
              style: TextStyle(fontSize: 15.0.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0.h),
            Text(
              "موعد الحصة orderData.date",
              style: TextStyle(fontSize: 15.0.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0.h),
            Text(
              "عدد الساعات المطلوبة   orderData.hoursCount",
              style: TextStyle(fontSize: 15.0.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0.h),
            Text(
              "من الساعة :orderData.timeFrom",
              style: TextStyle(fontSize: 15.0.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0.h),
            Text(
              "إلى الساعة: orderData.timeTo",
              style: TextStyle(fontSize: 15.0.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 15.0.h),
            const Divider(color: Colors.grey),
            Text(
              "\n orderData.note ملاحظات ومعلومات اضافية",
              style: TextStyle(fontSize: 15.0.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 15.0.h),
            ElevatedButton(
              onPressed: () async {
                timeFromController.clear();
                timeToController.clear();
                await _acceptAlertForNewLessonNotification(
                  context: context,
                  timeFromController: timeFromController,
                  timeToController: timeToController,
                  formKey: formKey,
                  timeFrom: "orderData.timeFrom!",
                  timeTo: "orderData.timeTo!",
                  orderID: "orderData.orderID".toString(),
                );
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.blueAppColor,
                minimumSize: Size(double.infinity, 40.0.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0.r)),
                textStyle:
                    TextStyle(fontSize: 15.0.sp, fontWeight: FontWeight.bold),
              ),
              child: const Text("قبول"),
            ),
            SizedBox(height: 10.0.h),
            ElevatedButton(
              onPressed: () {
// await _rejectAlertForNewLessonOrCourseWidget(context: context);
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
              child: const Text("رفض"),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _acceptAlertFieldsNotification({
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

  static Future<void> _acceptAlertForNewLessonNotification({
    required BuildContext context,
    required TextEditingController timeFromController,
    required TextEditingController timeToController,
    required GlobalKey<FormState> formKey,
    required String timeFrom,
    required String timeTo,
    required String orderID,
  }) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0.r),
        ),
        content: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                Text(
                  "تحديد التوقيت الخاص بالحصة",
                  style: TextStyle(
                    fontSize: 15.0.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(color: Colors.grey),
                Text(
                  "من فضلك قم بتحديد الوقت المناسب لك من بين الساعة $timeFrom الي الساعة $timeTo  ",
                  style: TextStyle(
                      fontSize: 15.0.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.redAppColor),
                ),
                SizedBox(height: 10.0.h),
                _acceptAlertFieldsNotification(
                    title: "من الساعة",
                    controller: timeFromController,
                    hint: "اختر من الساعة",
                    validate: "من فضلك اختر من الساعة",
                    type: TextInputType.text,
                    action: TextInputAction.next,
                    readOnly: true,
                    onPress: () async {
                      await showTimePicker(
                        builder: (context, child) => Theme(
                          data: ThemeData(
                            colorScheme: const ColorScheme(
                              brightness: Brightness.light,
                              primary: AppColors.blueAppColor,
                              onPrimary: AppColors.yellowAppColor,
                              secondary: AppColors.yellowAppColor,
                              onSecondary: AppColors.yellowAppColor,
                              error: AppColors.yellowAppColor,
                              onError: AppColors.yellowAppColor,
                              background: AppColors.yellowAppColor,
                              onBackground: AppColors.yellowAppColor,
                              surface: Colors.white,
                              onSurface: AppColors.blueAppColor,
                            ),
                          ),
                          child: child!,
                        ),
                        context: context,
                        initialTime: TimeOfDay.now(),
                      ).then((value) {
                        if (value != null) {
                          timeFromController.text = value.format(context);
                        }
                      });
                    }),
                SizedBox(height: 10.0.h),
                _acceptAlertFieldsNotification(
                    title: "إلى الساعة",
                    controller: timeToController,
                    hint: "اختر إلى الساعة",
                    validate: "من فضلك اختر إلى الساعة",
                    type: TextInputType.text,
                    action: TextInputAction.next,
                    readOnly: true,
                    onPress: () async {
                      await showTimePicker(
                        builder: (context, child) => Theme(
                          data: ThemeData(
                            colorScheme: const ColorScheme(
                              brightness: Brightness.light,
                              primary: AppColors.blueAppColor,
                              onPrimary: AppColors.yellowAppColor,
                              secondary: AppColors.yellowAppColor,
                              onSecondary: AppColors.yellowAppColor,
                              error: AppColors.yellowAppColor,
                              onError: AppColors.yellowAppColor,
                              background: AppColors.yellowAppColor,
                              onBackground: AppColors.yellowAppColor,
                              surface: Colors.white,
                              onSurface: AppColors.blueAppColor,
                            ),
                          ),
                          child: child!,
                        ),
                        context: context,
                        initialTime: TimeOfDay.now(),
                      ).then((value) {
                        if (value != null) {
                          timeToController.text = value.format(context);
                        }
                      });
                    }),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
// await context
//     .read(OrdersProviders.ordersProvidersApis)
//     .acceptOrder(
//       context: context,
//       orderID: orderID,
//       startTime: timeFromController.text,
//       endTime: timeToController.text,
//     );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.blueAppColor,
                minimumSize: Size(double.infinity, 40.0.h),
                textStyle:
                    TextStyle(fontSize: 15.0.sp, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0.r),
                )),
            child: const Text("حفظ الموعد"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.redAppColor,
                minimumSize: Size(double.infinity, 40.0.h),
                textStyle:
                    TextStyle(fontSize: 15.0.sp, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0.r),
                )),
            child: const Text("إلغاء"),
          ),
        ],
      ),
    );
  }
}
