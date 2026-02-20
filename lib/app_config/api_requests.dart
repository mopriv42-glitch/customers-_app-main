import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:private_4t_app/core/analytics/analytics_http_wrapper.dart';
import 'package:private_4t_app/core/services/navigation_service.dart';

import 'api_keys.dart';
import 'common_components.dart';

class ApiRequests {
  static Future<dynamic> postApiRequest({
    BuildContext? context,
    required String baseUrl,
    required String apiUrl,
    required Map<String, String> headers,
    required dynamic body,
    bool showLoadingWidget = true,
  }) async {
    if (context == null &&
        NavigationService.rootNavigatorKey.currentContext != null) {
      context = NavigationService.rootNavigatorKey.currentContext!;
    }
    try {
      if (await CommonComponents.checkConnectivity()) {
        if (context != null && context.mounted) {
          if (showLoadingWidget) CommonComponents.loading(context);
        }

        String url = "$baseUrl$apiUrl";

        http.Response response = await AnalyticsHttpWrapper.post(
          Uri.parse(url),
          body: body,
          headers: {
            "Accept": "application/json",
            "Accept-Language": "ar",
            "X-Cart-Token":
                "${await CommonComponents.getSavedData(ApiKeys.userCartToken)}"
          }..addAll(headers),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (context != null && context.mounted) {
            if (showLoadingWidget) Navigator.pop(context);
          }
          var successDecodedData = jsonDecode(response.body);
          return successDecodedData;
        } else {
          if (context != null && context.mounted) {
            if (showLoadingWidget) Navigator.pop(context);
          }
          debugPrint("POST METHOD=> status Code !=200 or 201");
          var failedDecodedData = jsonDecode(response.body);
          debugPrint(failedDecodedData.toString());
          return failedDecodedData;
        }
      } else {
        if (context != null && context.mounted) {
          await CommonComponents.notConnectionAlert(context);
        } else {
          return;
        }
      }
    } on TimeoutException catch (error) {
      if (context != null && context.mounted) {
        Navigator.pop(context);
        await CommonComponents.timeOutExceptionAlert(context);
      }
      debugPrint("Time Out Exception is::=>$error");
    } on SocketException catch (error) {
      if (context != null && context.mounted) {
        Navigator.pop(context);
      }
      debugPrint("Socket Exception is::=>$error");
      if (context != null && context.mounted) {
        await CommonComponents.socketExceptionAlert(context);
      }
    } catch (error, s) {
      if (context != null && context.mounted) {
        Navigator.pop(context);
      }
      debugPrintStack(label: "General Exception is::=> $error", stackTrace: s);
    }
  }

  static Future<dynamic> getApiRequests({
    BuildContext? context,
    required String baseUrl,
    required String apiUrl,
    required Map<String, String> headers,
  }) async {
    if (context == null &&
        NavigationService.rootNavigatorKey.currentContext != null) {
      context = NavigationService.rootNavigatorKey.currentContext!;
    }
    try {
      if (await CommonComponents.checkConnectivity()) {
        String url = "$baseUrl$apiUrl";
        http.Response response = await AnalyticsHttpWrapper.get(
          Uri.parse(url),
          headers: {
            "Accept": "application/json",
            "Accept-Language": "ar",
            "X-Cart-Token":
                "${await CommonComponents.getSavedData(ApiKeys.userCartToken)}"
          }..addAll(headers),
        );

        if (response.statusCode == 200) {
          debugPrint(response.body);
          var successDecodedData = jsonDecode(response.body);

          return successDecodedData;
        } else {
          debugPrint("GET METHOD status Code => != 200");
          var failedDecodedData = jsonDecode(response.body);
          debugPrint(failedDecodedData.toString());
          return failedDecodedData;
        }
      } else {
        if (context != null && context.mounted) {
          await CommonComponents.notConnectionAlert(context);
        }
      }
    } on TimeoutException catch (error) {
      debugPrint("Time Out Exception is::=> $error");
      if (context != null && context.mounted) {
        await CommonComponents.timeOutExceptionAlert(context);
      }
    } on SocketException catch (error) {
      debugPrint("Socket Exception is::=> $error");
      if (context != null && context.mounted) {
        await CommonComponents.socketExceptionAlert(context);
      }
    } catch (error, s) {
      debugPrintStack(label: "General Exception is::=> $error", stackTrace: s);
    }
  }

  static Future<dynamic> putRequests({
    required BuildContext context,
    required String apiUrl,
    Object? body,
    bool showLoadingWidget = true,
  }) async {
    try {
      if (await CommonComponents.checkConnectivity()) {
        if (showLoadingWidget) {
          if (context.mounted) {
            CommonComponents.loading(context);
          }
        }
        String url = "${ApiKeys.baseUrl}$apiUrl";

        if (context.mounted) {
          http.Response response = await AnalyticsHttpWrapper.put(
            Uri.parse(url),
            headers: {
              "Accept": "application/json",
              "Accept-Language": "ar",
              "X-Cart-Token":
                  "${await CommonComponents.getSavedData(ApiKeys.userCartToken)}",
              "Authorization":
                  "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}"
            },
            body: body,
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            if (context.mounted) {
              if (showLoadingWidget) Navigator.pop(context);
            }
            var successDecodedData = jsonDecode(response.body);
            return successDecodedData;
          } else {
            if (context.mounted) {
              if (showLoadingWidget) Navigator.pop(context);
            }
            debugPrint("PUT METHOD=> status Code !=200 or 201");
            var failedDecodedData = jsonDecode(response.body);
            debugPrint(failedDecodedData.toString());
            return failedDecodedData;
          }
        }
      } else {
        if (context.mounted) {
          await CommonComponents.notConnectionAlert(context);
        }
      }
    } on TimeoutException catch (error) {
      if (context.mounted) {
        if (showLoadingWidget) {
          Navigator.pop(context);
        }
        await CommonComponents.timeOutExceptionAlert(context);
      }

      debugPrint("Time Out Exception is::=>$error");
    } on SocketException catch (error) {
      if (context.mounted) {
        if (showLoadingWidget) {
          Navigator.pop(context);
        }
        await CommonComponents.socketExceptionAlert(context);
      }

      debugPrint("Socket Exception is::=>$error");
    } catch (error) {
      if (context.mounted) {
        if (showLoadingWidget) {
          Navigator.pop(context);
        }
      }

      debugPrint("General Exception is::=>$error");
    }
  }

  static Future<dynamic> deleteRequest({
    required BuildContext context,
    required String baseUrl,
    required String apiUrl,
    required Map<String, String> headers,
    bool showLoadingWidget = true,
  }) async {
    try {
      if (await CommonComponents.checkConnectivity()) {
        if (context.mounted) {
          if (showLoadingWidget) CommonComponents.loading(context);
        } else {
          return;
        }
        String url = "$baseUrl$apiUrl";
        if (context.mounted) {
          http.Response response =
              await AnalyticsHttpWrapper.delete(Uri.parse(url),
                  headers: {
                    "Accept-Language": "ar",
                    "X-Cart-Token":
                        "${await CommonComponents.getSavedData(ApiKeys.userCartToken)}"
                  }..addAll(headers));
          if (response.statusCode == 200 || response.statusCode == 201) {
            if (context.mounted) {
              if (showLoadingWidget) Navigator.pop(context);
            } else {
              return;
            }

            var succeedDcodedData = jsonDecode(response.body);

            return succeedDcodedData;
          } else {
            if (context.mounted) {
              if (showLoadingWidget) Navigator.pop(context);
            } else {
              return;
            }
            var failedDecodedData = jsonDecode(response.body);
            debugPrint("DELETE METHOD status Code !=200 or 201");
            return failedDecodedData;
          }
        } else {
          return;
        }
      } else {
        if (context.mounted) {
          await CommonComponents.notConnectionAlert(context);
        } else {
          return;
        }
      }
    } on TimeoutException catch (error) {
      if (context.mounted) {
        if (showLoadingWidget) {
          Navigator.pop(context);
        }
        await CommonComponents.timeOutExceptionAlert(context);
      }

      debugPrint("Time Out Exception is::=>$error");
    } on SocketException catch (error) {
      if (context.mounted) {
        if (showLoadingWidget) {
          Navigator.pop(context);
        }
        await CommonComponents.socketExceptionAlert(context);
      }

      debugPrint("Socket Exception is::=>$error");
    } catch (error) {
      if (context.mounted) {
        if (showLoadingWidget) {
          Navigator.pop(context);
        }
      }

      debugPrint("General Exception is::=>$error");
    }
  }
}
