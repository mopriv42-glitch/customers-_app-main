import 'package:flutter/material.dart';
import 'package:private_4t_app/app_config/api_keys.dart';
import 'package:private_4t_app/app_config/api_requests.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/models/teacher_model.dart';
import 'package:private_4t_app/core/services/navigation_service.dart';

class TeachersProvider extends ChangeNotifier {
  bool isLoading = false;
  List<TeacherModel> teachersList = TeacherModel.getSampleTeachers();

  Future<void> init() async {
    try {
      isLoading = true;
      notifyListeners();

      Map<String, dynamic>? data = await ApiRequests.getApiRequests(
          baseUrl: ApiKeys.baseUrl,
          apiUrl: 'me/teachers',
          headers: {
            "Authorization":
                "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}",
          });

      if (data != null && data.containsKey('data')) {
        var teachers = data['data'] as List;

        if (teachers.isNotEmpty) {
          teachersList.clear();
          teachersList.addAll(teachers.map((t) => TeacherModel.fromJson(t)));
        }
      }
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: e.toString());
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> getTeacherRate(String teacherId) async {
    try {
      Map<String, dynamic>? data = await ApiRequests.getApiRequests(
          baseUrl: ApiKeys.baseUrl,
          apiUrl: 'me/teachers/$teacherId/rate',
          headers: {
            "Authorization":
                "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}",
          });

      if (data != null && data.containsKey('data')) {
        var dataMap = data['data'];
        return dataMap['rate'];
      }
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: e.toString());
    }

    return null;
  }

  Future<bool> addTeacherRate(String teacherId, String rate) async {
    try {
      Map<String, dynamic>? data = await ApiRequests.postApiRequest(
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'me/teachers/$teacherId/rate',
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}",
        },
        body: {'rate': rate},
        showLoadingWidget: true,
      );

      if (data != null) {
        if (data['message']) {
          CommonComponents.showCustomizedSnackBar(
              context: NavigationService.rootNavigatorKey.currentContext!,
              title: data['message'] ?? 'حدث خطا ما');
        }

        if (data.containsKey('success') && data['success']) return true;
      }
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: e.toString());
    }

    return false;
  }

  /// Get list of teacher diagnostics
  Future<List<Map<String, dynamic>>?> getTeacherDiagnostics({
    required BuildContext context,
  }) async {
    try {
      Map<String, dynamic>? data = await ApiRequests.getApiRequests(
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'me/teacher-diagnostics',
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}",
        },
      );

      if (data != null && data.containsKey('data')) {
        var diagnostics = data['data'] as List;
        return diagnostics.map((d) => d as Map<String, dynamic>).toList();
      }
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: e.toString());
    }
    return [];
  }

  /// Get teacher diagnostic detail
  Future<Map<String, dynamic>?> getTeacherDiagnosticDetail({
    required BuildContext context,
    required String diagnosticId,
  }) async {
    try {
      Map<String, dynamic>? data = await ApiRequests.getApiRequests(
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'me/teacher-diagnostics/$diagnosticId',
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}",
        },
      );

      if (data != null && data.containsKey('data')) {
        return data['data'] as Map<String, dynamic>;
      }
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: e.toString());
    }
    return null;
  }

  /// Get list of teacher follow-ups
  Future<List<Map<String, dynamic>>?> getTeacherFollowUps({
    required BuildContext context,
  }) async {
    try {
      Map<String, dynamic>? data = await ApiRequests.getApiRequests(
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'me/teacher-follow-ups',
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}",
        },
      );

      if (data != null && data.containsKey('data')) {
        var followUps = data['data'] as List;
        return followUps.map((f) => f as Map<String, dynamic>).toList();
      }
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: e.toString());
    }
    return [];
  }

  /// Get teacher follow-up detail
  Future<Map<String, dynamic>?> getTeacherFollowUpDetail({
    required BuildContext context,
    required String followUpId,
  }) async {
    try {
      Map<String, dynamic>? data = await ApiRequests.getApiRequests(
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'me/teacher-follow-ups/$followUpId',
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}",
        },
      );

      if (data != null && data.containsKey('data')) {
        return data['data'] as Map<String, dynamic>;
      }
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: e.toString());
    }
    return null;
  }
}
