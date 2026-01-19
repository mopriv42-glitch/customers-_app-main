import 'package:flutter/material.dart';
import 'package:private_4t_app/app_config/api_keys.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/api_requests.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/models/cart_model.dart';
import 'package:riverpod_context/riverpod_context.dart';

class CartProvider extends ChangeNotifier {
  CartModel cartModel = CartModel();
  bool isLoading = false;

  Future<void> getCart(BuildContext context) async {
    try {
      isLoading = true;
      notifyListeners();

      Map<String, dynamic>? data = await ApiRequests.getApiRequests(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'cart',
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}",
        },
      );
      if (data != null && data.containsKey('data')) {
        var dataMap = data['data'];
        cartModel = CartModel.fromJson(dataMap['cart']);
        if (dataMap['token'] != null) {
          await CommonComponents.saveData(
            key: ApiKeys.userCartToken,
            value: dataMap['token'],
          );
        }
      }
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: "Get cart error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addLearningCourseIntoCart(
    BuildContext context,
    String learningCourseId,
  ) async {
    try {
      Map<String, dynamic>? data = await ApiRequests.postApiRequest(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'cart/items',
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}",
        },
        body: {
          "model_type": r"App\Models\LearningCourse",
          "model_id": learningCourseId,
          "unit_price": "1",
          "qty": "1",
        },
      );

      if (data != null) {
        if (data.containsKey('data')) {
          var dataMap = data['data'];
          cartModel = CartModel.fromJson(dataMap['cart']);
          if (dataMap['token'] != null) {
            await CommonComponents.saveData(
              key: ApiKeys.userCartToken,
              value: dataMap['token'],
            );
          }
        }
        if (context.mounted) {
          CommonComponents.showCustomizedSnackBar(
              context: context, title: data['message'] ?? 'Something wrong');
        }

        if (data.containsKey('status') && data['status'] == 'success') {

          return true;
        }
      }
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: e.toString());
      debugPrint("Add learning Course into cart error: $e");
    } finally {
      notifyListeners();
    }

    return false;
  }

  Future<bool> addBookingIntoCart(
    BuildContext context,
    String bookingId,
  ) async {
    try {
      Map<String, dynamic>? data = await ApiRequests.postApiRequest(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'cart/items',
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}",
        },
        body: {
          "model_type": r"App\Models\CustomerBooking",
          "model_id": bookingId,
          "unit_price": "1",
          "qty": "1",
        },
      );

      if (data != null) {
        if (data.containsKey('data')) {
          var dataMap = data['data'];
          cartModel = CartModel.fromJson(dataMap['cart']);
          if (dataMap['token'] != null) {
            await CommonComponents.saveData(
              key: ApiKeys.userCartToken,
              value: dataMap['token'],
            );
          }
        }

        if (data.containsKey('status') && data['status'] == 'success') {
          notifyListeners();
          return true;
        }

        if (context.mounted) {
          CommonComponents.showCustomizedSnackBar(
              context: context, title: data['message'] ?? 'Something wrong');
        }
      }
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: e.toString());
      debugPrint("Add Booking into cart error: $e");
    } finally {
      notifyListeners();
    }

    return false;
  }

  Future<bool> deleteCartItem(
    BuildContext context,
    String cartItemId,
  ) async {
    try {
      Map<String, dynamic>? data = await ApiRequests.deleteRequest(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'cart/items/$cartItemId',
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}",
        },
      );

      if (data != null) {
        if (data.containsKey('data')) {
          var cart = data['data'];
          cartModel = CartModel.fromJson(cart);
        }
        if (context.mounted) {
          CommonComponents.showCustomizedSnackBar(
              context: context, title: data['message'] ?? 'Something wrong');
        }

        if (data.containsKey('status') && data['status'] == 'success') {

          return true;
        }
      }
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: e.toString());
      debugPrint("Delete cart item error: $e");
    } finally {
      notifyListeners();
    }

    return false;
  }

  Future<bool> applyCoupon(
    BuildContext context,
    String couponCode,
  ) async {
    try {
      Map<String, dynamic>? data = await ApiRequests.postApiRequest(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'cart/coupon',
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}",
        },
        body: {
          "coupon_code": couponCode,
        },
      );

      if (data != null) {
        if (data.containsKey('data')) {
          var cart = data['data'];
          cartModel = CartModel.fromJson(cart);
        }
        if (context.mounted) {
          CommonComponents.showCustomizedSnackBar(
              context: context, title: data['message'] ?? 'Something wrong');
        }

        if (data.containsKey('status') && data['status'] == 'success') {
          notifyListeners();
          return true;
        }
      }
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: e.toString());
      debugPrint("Apply coupon error: $e");
    } finally {
      notifyListeners();
    }

    return false;
  }

  Future<bool> removeCoupon(
    BuildContext context,
  ) async {
    try {
      Map<String, dynamic>? data = await ApiRequests.deleteRequest(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'cart/coupon',
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}",
        },
      );

      if (data != null) {
        if (data.containsKey('data')) {
          var cart = data['data'];
          cartModel = CartModel.fromJson(cart);
        }

        if (context.mounted) {
          CommonComponents.showCustomizedSnackBar(
              context: context, title: data['message'] ?? 'Something wrong');
        }

        if (data.containsKey('status') && data['status'] == 'success') {
          notifyListeners();
          return true;
        }
      }
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: e.toString());
      debugPrint("Remove coupon error: $e");
    } finally {
      notifyListeners();
    }

    return false;
  }

  Future<String?> getPaymentLink(BuildContext context) async {
    try {
      isLoading = true;
      notifyListeners();
      final loginProvider = context.read(ApiProviders.loginProvider);
      final loggedUser = loginProvider.loggedUser;
      var name = loggedUser?.name.toString();
      var email = loggedUser?.email.toString();
      if (loggedUser?.email == null ||
          loggedUser!.email!.isEmpty ||
          loggedUser.email!.startsWith('client') ||
          loggedUser.email!.startsWith("teacher")) {
        final googleUserData = await loginProvider.googleAuthentication();

        if (googleUserData != null) {
          name = googleUserData.displayName.toString();
          email = googleUserData.email.toString();
        }
      }

      Map<String, dynamic>? data = await ApiRequests.postApiRequest(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'cart/payment',
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}",
        },
        body: {
          "name": name,
          "email": email,
        },
      );

      if (data != null) {
        if (data.containsKey('data') && data['status'] == 'success') {
          var dataMap = data['data'];
          return dataMap['link'];
        }

        if (context.mounted) {
          CommonComponents.showCustomizedSnackBar(
              context: context,
              title: data['message'] ?? "حدث خطأ ما يرجى المحاولة لاحثاً");
        }
      }
    } catch (e,s) {
      debugPrintStack(label: "Get cart payment link error: $e",stackTrace: s);
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return null;
  }
}
