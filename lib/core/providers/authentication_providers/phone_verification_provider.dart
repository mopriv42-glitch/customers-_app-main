import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_4t_app/app_config/api_keys.dart';
import 'package:private_4t_app/app_config/api_requests.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/models/grade_model.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/core/services/navigation_service.dart';

// State class for phone verification
class PhoneVerificationState {
  final List<GradeModel> grades;
  final bool isLoadingGrades;
  final bool isLoadingOtp;
  final String? error;

  PhoneVerificationState({
    this.grades = const [],
    this.isLoadingGrades = false,
    this.isLoadingOtp = false,
    this.error,
  });

  PhoneVerificationState copyWith({
    List<GradeModel>? grades,
    bool? isLoadingGrades,
    bool? isLoadingOtp,
    String? error,
  }) {
    return PhoneVerificationState(
      grades: grades ?? this.grades,
      isLoadingGrades: isLoadingGrades ?? this.isLoadingGrades,
      isLoadingOtp: isLoadingOtp ?? this.isLoadingOtp,
      error: error ?? this.error,
    );
  }
}

// Provider for phone verification
final phoneVerificationProvider =
    StateNotifierProvider<PhoneVerificationNotifier, PhoneVerificationState>(
        (ref) {
  return PhoneVerificationNotifier(ref);
});

// Notifier for phone verification
class PhoneVerificationNotifier extends StateNotifier<PhoneVerificationState> {
  final Ref _ref;

  PhoneVerificationNotifier(this._ref) : super(PhoneVerificationState());

  // Load grades from existing login provider
  Future<void> loadGrades() async {
    state = state.copyWith(isLoadingGrades: true, error: null);

    try {
      // Get grades from the existing login provider
      final loginProvider = _ref.read(ApiProviders.loginProvider);
      await loginProvider.initAuth(NavigationService.rootNavigatorKey.currentContext!);
      if (loginProvider.gradesList.isNotEmpty) {
        state = state.copyWith(
          grades: loginProvider.gradesList,
          isLoadingGrades: false,
        );
      } else {
        // If grades are not loaded yet, wait for them to be loaded
        await Future.delayed(const Duration(milliseconds: 500));
        if (loginProvider.gradesList.isNotEmpty) {
          state = state.copyWith(
            grades: loginProvider.gradesList,
            isLoadingGrades: false,
          );
        } else {
          state = state.copyWith(
            isLoadingGrades: false,
            error: 'فشل في تحميل الصفوف الدراسية',
          );
        }
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingGrades: false,
        error: 'خطأ في الاتصال: $e',
      );
    }
  }

  // Send OTP to phone number
  Future<bool> sendOtp({
    required String phone,
    required String gradeId,
    required BuildContext context,
  }) async {
    state = state.copyWith(isLoadingOtp: true, error: null);

    try {
      final response = await ApiRequests.postApiRequest(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'phone-verification/send-otp',
        headers: {
          'Authorization':
          "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}",
        },
        body: {
          'phone': phone,
        },
      );

      if (response != null && response['status'] == 'success') {
        state = state.copyWith(isLoadingOtp: false);
        return true;
      } else {
        final errorMessage = response?['message'] ?? 'فشل في إرسال رمز التحقق';
        state = state.copyWith(
          isLoadingOtp: false,
          error: errorMessage,
        );
        CommonComponents.showCustomizedSnackBar(context: context, title: errorMessage);
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingOtp: false,
        error: 'خطأ في الاتصال: $e',
      );
      return false;
    }
  }

  // Verify OTP
  Future<bool> verifyOtp({
    required String phone,
    required String otp,
    required String gradeId,
    required BuildContext context,
  }) async {
    state = state.copyWith(isLoadingOtp: true, error: null);

    try {
      final response = await ApiRequests.postApiRequest(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'phone-verification/verify-otp',
        headers: {
          'Authorization':
          "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}",
        },
        body: {
          'phone': phone,
          'otp': otp,
          'grade_id': gradeId,
        },
      );

      if (response != null && response['status'] == 'success') {
        state = state.copyWith(isLoadingOtp: false);
        return true;
      } else {
        final errorMessage = response?['message'] ?? 'فشل في التحقق من الرمز';
        CommonComponents.showCustomizedSnackBar(context: context, title: errorMessage);
        state = state.copyWith(
          isLoadingOtp: false,
          error: errorMessage,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingOtp: false,
        error: 'خطأ في الاتصال: $e',
      );
      return false;
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}
