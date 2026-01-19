import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:private_4t_app/core/models/user_model.dart';

/// Result class for Matrix authentication operations
class MatrixAuthResult {
  final bool success;
  final String? message;
  final String? matrixUserId;
  final String? accessToken;
  final Map<String, dynamic>? userData;

  MatrixAuthResult({
    required this.success,
    this.message,
    this.matrixUserId,
    this.accessToken,
    this.userData,
  });
}

/// Service for handling Matrix Admin API authentication flow
/// This service integrates Matrix user management with the app's authentication system
class MatrixAdminAuthService {
  static const String _matrixHomeserver = 'https://matrix.private-4t.com';
  static const String _adminApiBaseUrl = '$_matrixHomeserver/_synapse/admin/v1';

  // Admin credentials - These should be stored securely in production
  static const String _adminAccessToken = 'YOUR_ADMIN_ACCESS_TOKEN';
  static const String _defaultPassword =
      'Private4T@2024'; // Predefined password for users

  /// Convert phone number to Matrix user ID format
  /// Phone format: +1234567890 -> Matrix ID: @1234567890:matrix.private-4t.com
  static String _phoneToMatrixUserId(String phoneNumber) {
    // Remove all non-digit characters from phone number
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    // Extract domain from homeserver URL
    final domain = _matrixHomeserver
        .replaceFirst('https://', '')
        .replaceFirst('http://', '');
    return '@$cleanPhone:$domain';
  }

  /// Check if a Matrix user exists by user ID
  static Future<bool> _checkUserExists(String matrixUserId) async {
    try {
      final uri = Uri.parse('$_adminApiBaseUrl/users/$matrixUserId');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $_adminAccessToken',
          'Content-Type': 'application/json',
        },
      );

      // User exists if status is 200, doesn't exist if 404
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error checking user existence: $e');
      return false;
    }
  }

  /// Create a new Matrix user
  static Future<MatrixAuthResult> _createMatrixUser({
    required String matrixUserId,
    required String password,
    required String displayName,
    String? avatarUrl,
    bool admin = false,
  }) async {
    try {
      final uri = Uri.parse('$_adminApiBaseUrl/users/$matrixUserId');
      final body = {
        'password': password,
        'displayname': displayName,
        'admin': admin,
        'deactivated': false,
      };

      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        body['avatar_url'] = avatarUrl;
      }

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $_adminAccessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return MatrixAuthResult(
          success: true,
          message: 'User created successfully',
          matrixUserId: matrixUserId,
          userData: responseData,
        );
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return MatrixAuthResult(
          success: false,
          message:
              'Failed to create user: ${errorData['error'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      debugPrint('Error creating Matrix user: $e');
      return MatrixAuthResult(
        success: false,
        message: 'Network error while creating user: $e',
      );
    }
  }

  /// Update Matrix user password
  static Future<MatrixAuthResult> _updateUserPassword({
    required String matrixUserId,
    required String newPassword,
  }) async {
    try {
      final uri = Uri.parse('$_adminApiBaseUrl/users/$matrixUserId');
      final body = {
        'password': newPassword,
      };

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $_adminAccessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return MatrixAuthResult(
          success: true,
          message: 'Password updated successfully',
          matrixUserId: matrixUserId,
        );
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return MatrixAuthResult(
          success: false,
          message:
              'Failed to update password: ${errorData['error'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      debugPrint('Error updating user password: $e');
      return MatrixAuthResult(
        success: false,
        message: 'Network error while updating password: $e',
      );
    }
  }

  /// Login to Matrix with credentials
  static Future<MatrixAuthResult> _loginToMatrix({
    required String matrixUserId,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$_matrixHomeserver/_matrix/client/v3/login');
      final body = {
        'type': 'm.login.password',
        'identifier': {
          'type': 'm.id.user',
          'user': matrixUserId,
        },
        'password': password,
        'initial_device_display_name': 'Private 4T Mobile App',
      };

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return MatrixAuthResult(
          success: true,
          message: 'Login successful',
          matrixUserId: responseData['user_id'],
          accessToken: responseData['access_token'],
          userData: responseData,
        );
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return MatrixAuthResult(
          success: false,
          message:
              'Login failed: ${errorData['error'] ?? 'Invalid credentials'}',
        );
      }
    } catch (e) {
      debugPrint('Error logging in to Matrix: $e');
      return MatrixAuthResult(
        success: false,
        message: 'Network error during login: $e',
      );
    }
  }

  /// Main authentication flow that handles both existing and new users
  static Future<MatrixAuthResult> authenticateUser({
    required UserModel appUser,
  }) async {
    try {
      // Step 1: Convert phone number to Matrix user ID
      final matrixUserId = _phoneToMatrixUserId(appUser.phone ?? '');

      if (matrixUserId == '@:matrix.private-4t.com') {
        return MatrixAuthResult(
          success: false,
          message: 'Invalid phone number provided',
        );
      }

      debugPrint('Processing Matrix authentication for user: $matrixUserId');

      // Step 2: Check if user exists in Matrix
      final userExists = await _checkUserExists(matrixUserId);

      MatrixAuthResult operationResult;

      if (userExists) {
        debugPrint('User exists in Matrix, updating password');
        // Step 3a: User exists - update password
        operationResult = await _updateUserPassword(
          matrixUserId: matrixUserId,
          newPassword: _defaultPassword,
        );
      } else {
        debugPrint('User does not exist in Matrix, creating new user');
        // Step 3b: User doesn't exist - create new user
        operationResult = await _createMatrixUser(
          matrixUserId: matrixUserId,
          password: _defaultPassword,
          displayName: appUser.name ?? 'Unknown User',
          avatarUrl: appUser.imageUrl,
          admin: false,
        );
      }

      if (!operationResult.success) {
        return operationResult;
      }

      // Step 4: Login to Matrix with the credentials
      debugPrint('Attempting Matrix login for user: $matrixUserId');
      final loginResult = await _loginToMatrix(
        matrixUserId: matrixUserId,
        password: _defaultPassword,
      );

      if (loginResult.success) {
        debugPrint('Matrix authentication completed successfully');
        return MatrixAuthResult(
          success: true,
          message: userExists
              ? 'User password updated and logged in successfully'
              : 'User created and logged in successfully',
          matrixUserId: loginResult.matrixUserId,
          accessToken: loginResult.accessToken,
          userData: loginResult.userData,
        );
      } else {
        debugPrint('Matrix login failed: ${loginResult.message}');
        return loginResult;
      }
    } catch (e) {
      debugPrint('Unexpected error in Matrix authentication: $e');
      return MatrixAuthResult(
        success: false,
        message: 'Unexpected error during authentication: $e',
      );
    }
  }

  /// Convenience method to authenticate and directly login to Matrix client
  static Future<Map<String, dynamic>> authenticateAndLogin({
    required UserModel appUser,
  }) async {
    final authResult = await authenticateUser(appUser: appUser);

    return {
      'success': authResult.success,
      'message': authResult.message,
      'matrix_user_id': authResult.matrixUserId,
      'access_token': authResult.accessToken,
      'user_data': authResult.userData,
    };
  }

  /// Get Matrix user information
  static Future<Map<String, dynamic>?> getMatrixUserInfo(
      String matrixUserId) async {
    try {
      final uri = Uri.parse('$_adminApiBaseUrl/users/$matrixUserId');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $_adminAccessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting Matrix user info: $e');
      return null;
    }
  }

  /// Deactivate Matrix user (optional - for account deletion)
  static Future<bool> deactivateMatrixUser(String matrixUserId) async {
    try {
      final uri = Uri.parse('$_adminApiBaseUrl/users/$matrixUserId');
      final body = {
        'deactivated': true,
      };

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $_adminAccessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deactivating Matrix user: $e');
      return false;
    }
  }
}
