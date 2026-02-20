import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/core/models/user_model.dart';
import 'package:private_4t_app/core/services/matrix_admin_auth_service.dart';

/// Integration service to connect app authentication with Matrix authentication
/// This service should be called after successful app login/registration
class MatrixAuthIntegration {
  /// Automatically authenticate user with Matrix after app login
  static Future<bool> authenticateAfterAppLogin({
    required WidgetRef ref,
    required UserModel appUser,
  }) async {
    try {
      debugPrint('Starting Matrix authentication for user: ${appUser.phone}');

      // Get Matrix provider
      final matrixProvider = ref.read(ApiProviders.matrixChatProvider);

      // Ensure Matrix is initialized
      if (!matrixProvider.isInitialized) {
        await matrixProvider.init();
      }

      // Authenticate with Matrix Admin API
      final result =
          await matrixProvider.authenticateWithAdminAPI(appUser: appUser);

      if (result.success) {
        debugPrint(
            'Matrix authentication successful for user: ${result.matrixUserId}');
        return true;
      } else {
        debugPrint('Matrix authentication failed: ${result.message}');
        return false;
      }
    } catch (e) {
      debugPrint('Error during Matrix authentication integration: $e');
      return false;
    }
  }

  /// Check if user should be auto-authenticated with Matrix
  static Future<bool> shouldAutoAuthenticate(UserModel appUser) async {
    // Only auto-authenticate if user has a valid phone number
    return appUser.phone != null && appUser.phone!.isNotEmpty;
  }

  /// Get Matrix user ID from phone number
  static String getMatrixUserIdFromPhone(String phoneNumber) {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    return '@$cleanPhone:matrix.private-4t.com';
  }

  /// Integration hook for login provider
  static Future<void> onUserLoginSuccess({
    required WidgetRef ref,
    required UserModel user,
    bool autoAuthenticate = true,
  }) async {
    if (!autoAuthenticate || !await shouldAutoAuthenticate(user)) {
      return;
    }

    // Run Matrix authentication in background
    authenticateAfterAppLogin(ref: ref, appUser: user).then((success) {
      if (success) {
        debugPrint('Background Matrix authentication completed successfully');
      } else {
        debugPrint('Background Matrix authentication failed');
      }
    }).catchError((e) {
      debugPrint('Background Matrix authentication error: $e');
    });
  }

  /// Integration hook for registration
  static Future<void> onUserRegistrationSuccess({
    required WidgetRef ref,
    required UserModel user,
  }) async {
    // Always try to authenticate new users with Matrix
    await onUserLoginSuccess(ref: ref, user: user, autoAuthenticate: true);
  }

  /// Manual Matrix authentication trigger
  static Future<MatrixAuthResult> manualAuthenticate({
    required WidgetRef ref,
    required String phoneNumber,
    required String userName,
    String? avatarUrl,
  }) async {
    final matrixProvider = ref.read(ApiProviders.matrixChatProvider);

    // Ensure Matrix is initialized
    if (!matrixProvider.isInitialized) {
      await matrixProvider.init();
    }

    return await matrixProvider.authenticateWithPhone(
      phoneNumber: phoneNumber,
      userName: userName,
      avatarUrl: avatarUrl,
    );
  }

  /// Check Matrix authentication status
  static bool isMatrixAuthenticated(WidgetRef ref) {
    final matrixProvider = ref.read(ApiProviders.matrixChatProvider);
    return matrixProvider.isLoggedIn;
  }

  /// Get current Matrix user ID
  static String? getCurrentMatrixUserId(WidgetRef ref) {
    final matrixProvider = ref.read(ApiProviders.matrixChatProvider);
    return matrixProvider.client.userID;
  }
}

/// Extension to integrate Matrix auth with LoginProvider
extension LoginProviderMatrixExtension on UserModel {
  /// Get Matrix user ID for this user
  String? get matrixUserId {
    if (phone == null || phone!.isEmpty) return null;
    return MatrixAuthIntegration.getMatrixUserIdFromPhone(phone!);
  }

  /// Check if this user can be authenticated with Matrix
  bool get canAuthenticateWithMatrix {
    return phone != null && phone!.isNotEmpty;
  }
}

/// Usage Example:
/// 
/// In your LoginProvider after successful login:
/// ```dart
/// // After successful app login
/// if (loginSuccessful) {
///   loggedUser = UserModel.fromJson(data['user']);
///   
///   // Integrate with Matrix authentication
///   MatrixAuthIntegration.onUserLoginSuccess(
///     ref: ref,
///     user: loggedUser!,
///   );
///   
///   return true;
/// }
/// ```
/// 
/// In your Contact Screen:
/// ```dart
/// Consumer(builder: (context, ref, _) {
///   final isMatrixAuth = MatrixAuthIntegration.isMatrixAuthenticated(ref);
///   final currentUser = ref.read(ApiProviders.loginProvider).loggedUser;
///   
///   if (!isMatrixAuth && currentUser?.canAuthenticateWithMatrix == true) {
///     // Show option to authenticate with Matrix
///     return ElevatedButton(
///       onPressed: () async {
///         final result = await MatrixAuthIntegration.manualAuthenticate(
///           ref: ref,
///           phoneNumber: currentUser!.phone!,
///           userName: currentUser.name ?? 'User',
///           avatarUrl: currentUser.photoUrl,
///         );
///         // Handle result
///       },
///       child: Text('Connect to Matrix Chat'),
///     );
///   }
///   
///   return YourChatInterface();
/// })
/// ```