import 'package:flutter/material.dart';
import 'package:private_4t_app/app_config/api_keys.dart';
import 'package:private_4t_app/app_config/api_requests.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/models/customer_booking_model.dart';
import 'package:private_4t_app/core/models/learning_course_model.dart';
import 'package:private_4t_app/core/models/order_course_model.dart';
import 'package:private_4t_app/core/models/rate_teacher_model.dart';

class SubscriptionsProvider extends ChangeNotifier {
  List<OrderCourseModel> upcomingOrdersList = [];
  List<OrderCourseModel> upcomingCoursesList = [];
  List<LearningCourseModel> upcomingPackagesList = [];
  List<OrderCourseModel> endOrdersList = [];
  List<OrderCourseModel> endCoursesList = [];
  List<LearningCourseModel> endPackagesList = [];
  LearningCourseModel? learningCourseModel;
  OrderCourseModel orderCourseModel = OrderCourseModel();
  bool isLoading = false;
  bool hasNextPage = false;

  Future<void> getUpcomingOrders(BuildContext context, {int page = 1}) async {
    try {
      isLoading = true;
      notifyListeners();

      Map<String, dynamic>? data = await ApiRequests.getApiRequests(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: "me/upcoming-orders",
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}"
        },
      );

      if (data != null && data.containsKey('data')) {
        var dataMap = data['data'];

        var orders = (dataMap['orders'] ?? []) as List;

        if (orders.isNotEmpty) {
          upcomingOrdersList.clear();
          upcomingOrdersList.addAll(orders
              .map((e) => OrderCourseModel.fromJson(e as Map<String, dynamic>))
              .toList());
        }

        if (data.containsKey('meta')) {
          hasNextPage =
              data['meta']['current_page'] < data['meta']['last_page'];
        }
      }
    } catch (e, stack) {
      debugPrintStack(
          stackTrace: stack,
          label: "Get upcoming orders api error => ${e.toString()}");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getBookingDetails(
      BuildContext context, String orderCourseId) async {
    try {
      isLoading = true;
      notifyListeners();

      Map<String, dynamic>? data = await ApiRequests.getApiRequests(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: "me/get-booking-details?id=$orderCourseId",
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}"
        },
      );

      if (data != null && data.containsKey('data')) {
        var dataMap = data['data'];
        if (dataMap['booking'] != null) {
          orderCourseModel = OrderCourseModel.fromJson(dataMap['booking']);
        }
      }
    } catch (e, stack) {
      debugPrintStack(
          stackTrace: stack,
          label: "Get booking details api error => ${e.toString()}");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getUpcomingCourses(BuildContext context) async {
    try {
      isLoading = true;
      notifyListeners();

      Map<String, dynamic>? data = await ApiRequests.getApiRequests(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: "me/upcoming-courses",
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}"
        },
      );

      debugPrint(data.toString());

      if (data != null && data.containsKey('data')) {
        var dataMap = data['data'];

        var courses = (dataMap['courses'] ?? []) as List;

        if (courses.isNotEmpty) {
          upcomingCoursesList.clear();
          upcomingCoursesList.addAll(courses
              .map((e) => OrderCourseModel.fromJson(e as Map<String, dynamic>))
              .toList());
        }

        if (data.containsKey('meta')) {
          hasNextPage =
              data['meta']['current_page'] < data['meta']['last_page'];
        }
      }
    } catch (e, stack) {
      debugPrintStack(
          stackTrace: stack,
          label: "Get upcoming courses api error => ${e.toString()}");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getUpcomingPackages(BuildContext context) async {
    try {
      isLoading = true;
      notifyListeners();

      Map<String, dynamic>? data = await ApiRequests.getApiRequests(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: "me/upcoming-packages",
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}"
        },
      );

      if (data != null && data.containsKey('data')) {
        var dataMap = data['data'];

        var packages = (dataMap['packages'] ?? []) as List;

        if (packages.isNotEmpty) {
          upcomingPackagesList.clear();
          upcomingPackagesList.addAll(packages
              .map((e) =>
                  LearningCourseModel.fromJson(e as Map<String, dynamic>))
              .toList());
        }
      }
    } catch (e, stack) {
      debugPrintStack(
          stackTrace: stack,
          label: "Get upcoming packages api error => ${e.toString()}");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getEndSubscriptions(BuildContext context) async {
    try {
      isLoading = true;
      notifyListeners();

      Map<String, dynamic>? data = await ApiRequests.getApiRequests(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: "me/end-subscriptions",
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}"
        },
      );

      if (data != null && data.containsKey('data')) {
        var dataMap = data['data'];

        var orders = (dataMap['orders'] ?? []) as List;
        var courses = (dataMap['courses'] ?? []) as List;
        var packages = (dataMap['packages'] ?? []) as List;

        if (orders.isNotEmpty) {
          endOrdersList.clear();
          endOrdersList.addAll(orders
              .map((e) => OrderCourseModel.fromJson(e as Map<String, dynamic>))
              .toList());
        }

        if (courses.isNotEmpty) {
          endCoursesList.clear();
          endCoursesList.addAll(orders
              .map((e) => OrderCourseModel.fromJson(e as Map<String, dynamic>))
              .toList());
        }

        if (packages.isNotEmpty) {
          endPackagesList.clear();
          endPackagesList.addAll(packages
              .map((e) =>
                  LearningCourseModel.fromJson(e as Map<String, dynamic>))
              .toList());
        }
      }
    } catch (e, stack) {
      debugPrintStack(
          stackTrace: stack,
          label: "Get upcoming orders api error => ${e.toString()}");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateOrder({
    required BuildContext context,
    required int orderId,
    required String orderType,
    required String address,
    required DateTime date,
    required TimeOfDay time,
    required double numberOfHours,
  }) async {
    try {
      Map<String, dynamic>? data = await ApiRequests.postApiRequest(
          context: context,
          baseUrl: ApiKeys.baseUrl,
          apiUrl: "me/update-order",
          headers: {
            "Authorization":
                "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}"
          },
          body: {
            "order_id": orderId.toString(),
            "order_type": orderType,
            "map_address": address,
            "booking_date": date.toIso8601String(),
            "time_from":
                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
            "number_of_hours": numberOfHours.toString(),
          });

      if (data != null) {
        if (data.containsKey('data')) {
          var dataMap = data['data'] as Map? ?? {};

          if (dataMap.containsKey('order')) {
            var order = OrderCourseModel.fromJson(
                dataMap['order'] as Map<String, dynamic>);
            if (order.orderType == 'كورس') {
              var upcomingCourseIndex =
                  upcomingCoursesList.indexWhere((c) => c.id == order.id);
              var endCourseIndex =
                  endCoursesList.indexWhere((c) => c.id == order.id);

              upcomingCoursesList[upcomingCourseIndex] = order;
              endCoursesList[endCourseIndex] = order;
            } else {
              var upcomingOrderIndex =
                  upcomingOrdersList.indexWhere((c) => c.id == order.id);
              var endOrderIndex =
                  endOrdersList.indexWhere((c) => c.id == order.id);

              upcomingOrdersList[upcomingOrderIndex] = order;
              endOrdersList[endOrderIndex] = order;
            }
          }
        }

        if (data.containsKey('message')) {
          if (context.mounted) {
            CommonComponents.showCustomizedSnackBar(
                context: context, title: data['message']);
          }
        }
      }
    } catch (e, stack) {
      debugPrintStack(
          stackTrace: stack,
          label: "Get upcoming orders api error => ${e.toString()}");
    } finally {
      notifyListeners();
    }
  }

  Future<void> rateTeacher({
    required BuildContext context,
    required int orderId,
    required int rate,
    required String notes,
  }) async {
    try {
      Map<String, dynamic>? data = await ApiRequests.postApiRequest(
          context: context,
          baseUrl: ApiKeys.baseUrl,
          apiUrl: "me/rate-teacher",
          headers: {
            "Authorization":
                "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}"
          },
          body: {
            "order_id": orderId.toString(),
            "rate": rate.toString(),
            "notes": notes,
          });

      if (data != null) {
        if (data.containsKey('data')) {
          var dataMap = data['data'];

          var order = OrderCourseModel.fromJson(
              dataMap['order'] as Map<String, dynamic>);

          if (order.orderType == 'كورس') {
            var upcomingCourseIndex =
                upcomingCoursesList.indexWhere((c) => c.id == order.id);
            var endCourseIndex =
                endCoursesList.indexWhere((c) => c.id == order.id);

            upcomingCoursesList[upcomingCourseIndex] = order;
            endCoursesList[endCourseIndex] = order;
          } else {
            var upcomingOrderIndex =
                upcomingOrdersList.indexWhere((c) => c.id == order.id);
            var endOrderIndex =
                endOrdersList.indexWhere((c) => c.id == order.id);

            upcomingOrdersList[upcomingOrderIndex] = order;
            endOrdersList[endOrderIndex] = order;
          }
        }

        if (data.containsKey('message')) {
          if (context.mounted) {
            CommonComponents.showCustomizedSnackBar(
                context: context, title: data['message']);
          }
        }
      }
    } catch (e, stack) {
      debugPrintStack(
          stackTrace: stack,
          label: "Get upcoming orders api error => ${e.toString()}");
    } finally {
      notifyListeners();
    }
  }

  Future<void> saveCourse({
    required BuildContext context,
    required String courseId,
  }) async {
    try {
      Map<String, dynamic>? data = await ApiRequests.postApiRequest(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: "me/save-course/$courseId",
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}"
        },
        body: {},
      );

      if (data != null) {
        if (data.containsKey('data')) {
          var dataMap = data['data'];
          learningCourseModel =
              LearningCourseModel.fromJson(dataMap['course'] ?? {});
        }

        if (data.containsKey('message')) {
          if (context.mounted) {
            CommonComponents.showCustomizedSnackBar(
                context: context, title: data['message']);
          }
        }
      }
    } catch (e, stack) {
      debugPrintStack(
          stackTrace: stack,
          label: "Get upcoming orders api error => ${e.toString()}");
    } finally {
      notifyListeners();
    }
  }

  Future<RateTeacherModel?> getRateTeacher({
    required BuildContext context,
    required int orderId,
  }) async {
    try {
      Map<String, dynamic>? data = await ApiRequests.getApiRequests(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: "me/rate-teacher?order_id=$orderId",
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}"
        },
      );

      debugPrint(data.toString());

      if (data != null) {
        if (data.containsKey('data')) {
          var dataMap = data['data'];

          if (dataMap['rate'] != null) {
            return RateTeacherModel.fromJson(dataMap['rate']);
          }
        }

        if (data.containsKey('message')) {
          CommonComponents.showCustomizedSnackBar(
              context: context, title: data['message']);
        }
      }
    } catch (e, stack) {
      debugPrintStack(
          stackTrace: stack,
          label: "Get rate teacher api error => ${e.toString()}");
    }

    return null;
  }

  Future<void> getCourse(BuildContext context, int courseId) async {
    try {
      isLoading = true;
      notifyListeners();

      Map<String, dynamic>? data = await ApiRequests.getApiRequests(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: "packages/$courseId",
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}"
        },
      );

      if (data != null && data.containsKey('data')) {
        var dataMap = data['data'];

        learningCourseModel = LearningCourseModel.fromJson(
            dataMap['course'] as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint("Get learning courses api error => ${e.toString()}");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Renew an existing order/booking
  Future<CustomerBookingModel?> renewOrder({
    required BuildContext context,
    required int orderId,
    required DateTime bookingDate,
    required TimeOfDay bookingTime,
    String? purpose,
  }) async {
    try {
      isLoading = true;
      notifyListeners();

      Map<String, dynamic>? data = await ApiRequests.postApiRequest(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: "me/orders/$orderId/renew",
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}"
        },
        body: {
          "booking_date": bookingDate.toIso8601String(),
          "time_from":
              '${bookingTime.hour.toString().padLeft(2, '0')}:${bookingTime.minute.toString().padLeft(2, '0')}',
          if (purpose != null && purpose.isNotEmpty) "purpose": purpose,
        },
      );

      if (data != null) {
        if (data.containsKey('message')) {
          if (context.mounted) {
            CommonComponents.showCustomizedSnackBar(
              context: context,
              title: data['message'],
            );
          }
        }

        if (data.containsKey('data')) {
          debugPrint("Renew order data => ${data.toString()}");
          var dataMap = data['data'];
          if (dataMap.containsKey('booking')) {
            // Return the renewed booking
            debugPrint(
                "Renew order booking => ${dataMap['booking'].toString()}");
            return CustomerBookingModel.fromJson(
              dataMap['booking'] as Map<String, dynamic>,
            );
          }
        }
      }
    } catch (e, stack) {
      debugPrintStack(
        stackTrace: stack,
        label: "Renew order api error => ${e.toString()}",
      );
      if (context.mounted) {
        CommonComponents.showCustomizedSnackBar(
          context: context,
          title: "حدث خطأ أثناء تجديد الحجز",
        );
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }

    return null;
  }

  Future<void> saveStudentNote({
    required BuildContext context,
    required int orderCourseId,
    required String note,
  }) async {
    try {
      Map<String, dynamic>? data = await ApiRequests.postApiRequest(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: "me/student-notes",
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}"
        },
        body: {
          "order_course_id": orderCourseId.toString(),
          "note": note,
        },
      );

      if (data != null) {
        if (data.containsKey('data')) {
          // Update the local order course model with the new note
          var dataMap = data['data'];
          if (dataMap != null && dataMap.containsKey('order_course')) {
            var updatedOrder = OrderCourseModel.fromJson(
              dataMap['order_course'] as Map<String, dynamic>,
            );

            // Update the order in the appropriate list
            _updateOrderInLists(updatedOrder);
          }
        }

        if (data.containsKey('message')) {
          if (context.mounted) {
            CommonComponents.showCustomizedSnackBar(
                context: context, title: data['message']);
          }
        }
      }
    } catch (e, stack) {
      debugPrintStack(
          stackTrace: stack,
          label: "Save student note api error => ${e.toString()}");

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("خطأ في حفظ الملاحظة. حاول مرة أخرى."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      notifyListeners();
    }
  }

  void _updateOrderInLists(OrderCourseModel updatedOrder) {
    // Update in upcoming orders list
    final upcomingIndex =
        upcomingOrdersList.indexWhere((o) => o.id == updatedOrder.id);
    if (upcomingIndex != -1) {
      upcomingOrdersList[upcomingIndex] = updatedOrder;
    }

    // Update in upcoming courses list
    final upcomingCourseIndex =
        upcomingCoursesList.indexWhere((o) => o.id == updatedOrder.id);
    if (upcomingCourseIndex != -1) {
      upcomingCoursesList[upcomingCourseIndex] = updatedOrder;
    }

    // Update in end orders list
    final endIndex = endOrdersList.indexWhere((o) => o.id == updatedOrder.id);
    if (endIndex != -1) {
      endOrdersList[endIndex] = updatedOrder;
    }

    // Update in end courses list
    final endCourseIndex =
        endCoursesList.indexWhere((o) => o.id == updatedOrder.id);
    if (endCourseIndex != -1) {
      endCoursesList[endCourseIndex] = updatedOrder;
    }
  }
}
