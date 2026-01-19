import 'package:flutter/material.dart';
import 'package:private_4t_app/app_config/api_keys.dart';
import 'package:private_4t_app/app_config/api_requests.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/models/course_category_model.dart';
import 'package:private_4t_app/core/models/learning_course_model.dart';

class VideoCoursesProvider extends ChangeNotifier {
  final List<CourseCategoryModel> categoriesList = [];
  final List<LearningCourseModel> coursesList = [];
  LearningCourseModel? currentCourseModel;
  bool isLoading = false;

  Future<void> getCourses(BuildContext context) async {
    try {
      isLoading = true;
      notifyListeners();

      Map<String, dynamic>? data = await ApiRequests.getApiRequests(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: "packages",
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}"
        },
      );

      if (data != null && data.containsKey('data')) {
        var dataMap = data['data'];

        var courses = (dataMap['courses'] ?? []) as List;
        var categories = (dataMap['categories'] ?? []) as List;

        if (courses.isNotEmpty) {
          coursesList.clear();
          coursesList.addAll(courses
              .map((e) =>
                  LearningCourseModel.fromJson(e as Map<String, dynamic>))
              .toList());
        }

        if (categories.isNotEmpty) {
          categoriesList.clear();
          categoriesList.addAll(categories
              .map((e) =>
                  CourseCategoryModel.fromJson(e as Map<String, dynamic>))
              .toList());
        }
      }
    } catch (e, stack) {
      debugPrintStack(
          stackTrace: stack,
          label: "Get learning courses api error => ${e.toString()}");
    } finally {
      isLoading = false;
      notifyListeners();
    }
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

        currentCourseModel = LearningCourseModel.fromJson(
            dataMap['course'] as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint("Get learning courses api error => ${e.toString()}");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> getPaymentLink(BuildContext context) async {
    try {
      isLoading = true;
      notifyListeners();

      Map<String, dynamic>? data = await ApiRequests.postApiRequest(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'booking/${currentCourseModel?.id}/payment',
        headers: {
          "Authorization":
          "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}"
        },
        body: {},
      );
      debugPrint(data.toString());
      if (data != null && data.containsKey('data')) {
        var dataMap = data['data'];
        return dataMap['link'];
      }
    } catch (e) {
      debugPrint("Get payment link error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return null;
  }
}
