import 'package:flutter/material.dart';
import 'package:private_4t_app/app_config/api_keys.dart';
import 'package:private_4t_app/app_config/api_requests.dart';
import 'package:private_4t_app/app_config/common_components.dart';

class SettingProvider extends ChangeNotifier {
  Future<void> reportBug({BuildContext? context, required String bug}) async {
    try {
      Map<String, dynamic>? data = await ApiRequests.postApiRequest(
          context: context,
          baseUrl: ApiKeys.baseUrl,
          apiUrl: "/me/report-bug",
          headers: {
            "Authorization":
                "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}",
          },
          body: {
            "bug": bug,
          });
    } catch (_) {}
  }
}
