import 'package:flutter/material.dart';
import 'package:private_4t_app/app_config/api_keys.dart';
import 'package:private_4t_app/app_config/api_requests.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/models/learning_course_model.dart';

class WishlistProvider extends ChangeNotifier {
  List<LearningCourseModel> _wishlistCourses = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<LearningCourseModel> get wishlistCourses => _wishlistCourses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch wishlist courses from the API
  Future<void> fetchWishlistCourses({required BuildContext context}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final token = await CommonComponents.getSavedData(ApiKeys.userToken);
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final headers = {
        'Authorization': 'Bearer $token',
      };

      // Debug: Print the request details
      debugPrint('Fetching wishlist from: ${ApiKeys.baseUrl}me/wishlists');
      debugPrint('Headers: $headers');

      Map<String, dynamic>? data = await ApiRequests.getApiRequests(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'me/wishlists',
        headers: headers,
      );

      // Debug: Print the response
      debugPrint('Response data: $data');

      if (data != null && data.containsKey('data')) {
        var dataMap = data['data'];
        // Check if the response has the expected structure
        if (dataMap.containsKey('wishlists')) {
          final List<dynamic> coursesData = dataMap['wishlists'];
          _wishlistCourses = coursesData
              .map((courseJson) => LearningCourseModel.fromJson(courseJson))
              .toList();
        } else if (dataMap is List) {
          // If data is directly a list
          _wishlistCourses = dataMap
              .map((courseJson) => LearningCourseModel.fromJson(courseJson))
              .toList();
        } else {
          debugPrint('Unexpected data structure: $dataMap');
          _wishlistCourses = [];
        }
      } else {
        debugPrint('No data or unexpected response structure: $data');
        _wishlistCourses = [];
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching wishlist courses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Remove a course from wishlist
  Future<bool> removeFromWishlist(int courseId,
      {required BuildContext context}) async {
    try {
      final token = await CommonComponents.getSavedData(ApiKeys.userToken);
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final data = await ApiRequests.deleteRequest(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'me/wishlists/$courseId',
        headers: headers,
      );

      if (data != null && data['success'] == true) {
        // Remove from local list
        _wishlistCourses.removeWhere((course) => course.id == courseId);
        notifyListeners();
        return true;
      } else {
        throw Exception('Failed to remove course from wishlist');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error removing course from wishlist: $e');
      notifyListeners();
      return false;
    }
  }

  /// Add a course to wishlist
  Future<bool> addToWishlist(int courseId,
      {required BuildContext context}) async {
    try {
      final token = await CommonComponents.getSavedData(ApiKeys.userToken);
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final body = {'course_id': courseId};

      final data = await ApiRequests.postApiRequest(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'me/wishlists',
        headers: headers,
        body: body,
      );

      if (data != null &&
          (data['status'] == true || data['status'] == 'success')) {
        // Refresh the wishlist to get the updated data
        await fetchWishlistCourses(context: context);
        return true;
      } else {
        throw Exception('Failed to add course to wishlist');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding course to wishlist: $e');
      notifyListeners();
      return false;
    }
  }

  /// Check if a course is in wishlist
  bool isInWishlist(int courseId) {
    return _wishlistCourses.any((course) => course.id == courseId);
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh wishlist
  Future<void> refreshWishlist({required BuildContext context}) async {
    await fetchWishlistCourses(context: context);
  }
}
