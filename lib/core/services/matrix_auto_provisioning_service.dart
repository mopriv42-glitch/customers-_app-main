import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:private_4t_app/core/models/user_model.dart';
import 'package:private_4t_app/core/config/matrix_config.dart';

/// Result class for Matrix authentication operations
class MatrixProvisioningResult {
  final bool success;
  final String? message;
  final String? matrixUserId;
  final String? accessToken;
  final Map<String, dynamic>? userData;

  MatrixProvisioningResult({
    required this.success,
    this.message,
    this.matrixUserId,
    this.accessToken,
    this.userData,
  });
}

/// Service for automatic Matrix user provisioning using admin credentials
/// This service handles the complete flow from admin authentication to user login
class MatrixAutoProvisioningService {
  static const String _adminApiBaseUrl =
      '${MatrixConfig.homeserver}/_synapse/admin/v2';
  static const String _clientApiBaseUrl =
      '${MatrixConfig.homeserver}/_matrix/client/v3';

  // Use configuration from MatrixConfig
  static const String _adminUsername = MatrixConfig.adminUsername;
  static const String _adminPassword = MatrixConfig.adminPassword;
  static const String _defaultUserPassword = MatrixConfig.defaultUserPassword;

  // Cache admin token to avoid repeated authentication
  static String? _cachedAdminToken;
  static DateTime? _tokenExpiry;

  /// Convert phone number to Matrix user ID format
  /// Phone format: +1234567890 -> Matrix ID: @1234567890:matrix.private-4t.com
  static String _phoneToMatrixUserId(String phoneNumber) {
    return MatrixConfig.phoneToMatrixUserId(phoneNumber);
  }

  /// Authenticate with Matrix as admin and get admin access token
  static Future<String?> _getAdminToken() async {
    // Return cached token if still valid
    if (_cachedAdminToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      debugPrint('Using cached admin token');
      return _cachedAdminToken;
    }

    try {
      final uri = Uri.parse('$_clientApiBaseUrl/login');
      final body = {
        'type': 'm.login.password',
        'identifier': {
          'type': 'm.id.user',
          'user': _adminUsername,
        },
        'password': _adminPassword,
        'initial_device_display_name': MatrixConfig.adminDeviceName,
      };

      debugPrint('Authenticating admin user: $_adminUsername');
      debugPrint('Admin login URL: $uri');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      debugPrint('Admin auth response status: ${response.statusCode}');
      debugPrint('Admin auth response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        _cachedAdminToken = responseData['access_token'];
        // Set token expiry based on configuration
        _tokenExpiry = DateTime.now()
            .add(const Duration(hours: MatrixConfig.tokenCacheDurationHours));

        debugPrint('Admin authentication successful');
        debugPrint('Admin user ID: ${responseData['user_id']}');
        return _cachedAdminToken;
      } else {
        String errorMessage = 'Unknown error';
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          errorMessage =
              errorData['error'] ?? errorData['errcode'] ?? 'Unknown error';
          debugPrint('Admin auth error details: $errorData');
        } catch (e) {
          errorMessage = 'HTTP ${response.statusCode}: ${response.body}';
        }
        debugPrint('Admin authentication failed: $errorMessage');
        return null;
      }
    } catch (e) {
      debugPrint('Error during admin authentication: $e');
      return null;
    }
  }

  /// Check if a Matrix user exists by user ID
  static Future<bool> _checkUserExists(
      String matrixUserId, String adminToken) async {
    try {
      // Use v2 API for user existence check
      final uri = Uri.parse('$_adminApiBaseUrl/users/$matrixUserId');

      debugPrint('Checking user existence: $matrixUserId');
      debugPrint('User check URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $adminToken',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('User existence check response: ${response.statusCode}');
      debugPrint('User existence response body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error checking user existence: $e');
      return false;
    }
  }

  /// Create a new Matrix user using Admin API v2
  static Future<MatrixProvisioningResult> _createMatrixUserV2({
    required String matrixUserId,
    required String password,
    required String displayName,
    required String adminToken,
    String? avatarUrl,
    bool admin = false,
  }) async {
    try {
      final uri = Uri.parse('$_adminApiBaseUrl/users/$matrixUserId');
      final body = {
        'password': password,
        'displayname': displayName,
        'admin': admin,
        'username': admin,
        'deactivated': false,
      };

      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        body['avatar_url'] = avatarUrl;
      }

      debugPrint('Creating Matrix user (v2 API): $matrixUserId');
      debugPrint('V2 API URL: $uri');
      debugPrint('V2 Request body: ${jsonEncode(body)}');

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $adminToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      debugPrint('V2 Create user response status: ${response.statusCode}');
      debugPrint('V2 Create user response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return MatrixProvisioningResult(
          success: true,
          message: 'User created successfully (v2 API)',
          matrixUserId: matrixUserId,
          userData: responseData,
        );
      } else {
        String errorMessage = 'Unknown error';
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          errorMessage =
              errorData['error'] ?? errorData['errcode'] ?? 'Unknown error';
          debugPrint('V2 Error details: $errorData');
        } catch (e) {
          errorMessage = 'HTTP ${response.statusCode}: ${response.body}';
        }

        return MatrixProvisioningResult(
          success: false,
          message: 'Failed to create user (v2 API): $errorMessage',
        );
      }
    } catch (e) {
      debugPrint('Error creating Matrix user (v2 API): $e');
      return MatrixProvisioningResult(
        success: false,
        message: 'Network error while creating user (v2 API): $e',
      );
    }
  }

  /// Update Matrix user password
  static Future<MatrixProvisioningResult> _updateUserPassword({
    required String matrixUserId,
    required String newPassword,
    required String adminToken,
  }) async {
    try {
      // Use v2 API for password updates as well
      final uri = Uri.parse('$_adminApiBaseUrl/users/$matrixUserId');
      final body = {
        'password': newPassword,
      };

      debugPrint('Updating Matrix user password: $matrixUserId');
      debugPrint('Password update URL: $uri');

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $adminToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      debugPrint('Password update response status: ${response.statusCode}');
      debugPrint('Password update response body: ${response.body}');

      if (response.statusCode == 200) {
        return MatrixProvisioningResult(
          success: true,
          message: 'Password updated successfully',
          matrixUserId: matrixUserId,
        );
      } else {
        String errorMessage = 'Unknown error';
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          errorMessage =
              errorData['error'] ?? errorData['errcode'] ?? 'Unknown error';
        } catch (e) {
          errorMessage = 'HTTP ${response.statusCode}: ${response.body}';
        }

        return MatrixProvisioningResult(
          success: false,
          message: 'Failed to update password: $errorMessage',
        );
      }
    } catch (e) {
      debugPrint('Error updating user password: $e');
      return MatrixProvisioningResult(
        success: false,
        message: 'Network error while updating password: $e',
      );
    }
  }

  /// Test Matrix server capabilities and admin API availability
  static Future<MatrixProvisioningResult> _testServerCapabilities() async {
    try {
      // Test if Matrix server is reachable
      final versionUri =
          Uri.parse('${MatrixConfig.homeserver}/_matrix/client/versions');
      debugPrint('Testing Matrix server connectivity: $versionUri');

      final versionResponse = await http.get(versionUri);
      debugPrint(
          'Server version response: ${versionResponse.statusCode} ${versionResponse.body}');

      if (versionResponse.statusCode != 200) {
        return MatrixProvisioningResult(
          success: false,
          message: 'Matrix server is not reachable or not responding correctly',
        );
      }

      // Test if admin API is available
      final adminHealthUri = Uri.parse(
          '${MatrixConfig.homeserver}/_synapse/admin/v1/server_version');
      debugPrint('Testing Admin API availability: $adminHealthUri');

      final adminResponse = await http.get(adminHealthUri);
      debugPrint(
          'Admin API response: ${adminResponse.statusCode} ${adminResponse.body}');

      if (adminResponse.statusCode == 404) {
        return MatrixProvisioningResult(
          success: false,
          message:
              'Matrix Admin API is not available on this server. Please check if Synapse Admin API is enabled.',
        );
      }

      return MatrixProvisioningResult(
          success: true, message: 'Server capabilities OK');
    } catch (e) {
      return MatrixProvisioningResult(
        success: false,
        message: 'Failed to test server capabilities: $e',
      );
    }
  }

  /// Main automatic provisioning flow - this is the entry point
  static Future<MatrixProvisioningResult> provisionUser({
    required UserModel appUser,
    required dynamic matrixChatProvider,
  }) async {
    try {
      // Validate configuration
      if (!MatrixConfig.isConfigured()) {
        return MatrixProvisioningResult(
          success: false,
          message: MatrixConfig.getConfigurationStatus(),
        );
      }

      // Validate input
      if (appUser.phone == null || appUser.phone!.isEmpty) {
        return MatrixProvisioningResult(
          success: false,
          message: 'User phone number is required for Matrix provisioning',
        );
      }

      // Step 0: Test server capabilities
      debugPrint('Step 0: Testing Matrix server capabilities...');
      final capabilitiesResult = await _testServerCapabilities();
      if (!capabilitiesResult.success) {
        return capabilitiesResult;
      }

      // Step 1: Get admin token
      debugPrint('Step 1: Authenticating as admin...');
      final adminToken = await _getAdminToken();
      if (adminToken == null) {
        return MatrixProvisioningResult(
          success: false,
          message:
              'Failed to authenticate as admin. Check admin credentials and permissions.',
        );
      }

      // Step 2: Convert phone to Matrix user ID
      final matrixUserId = _phoneToMatrixUserId(appUser.phone!);
      debugPrint('Step 2: Matrix user ID for provisioning: $matrixUserId');

      // Step 3: Check if user exists
      debugPrint('Step 3: Checking if user exists...');
      final userExists = await _checkUserExists(matrixUserId, adminToken);

      MatrixProvisioningResult operationResult;

      if (userExists) {
        debugPrint('Step 4a: User exists, updating password...');
        // Step 4a: User exists - update password
        operationResult = await _updateUserPassword(
          matrixUserId: matrixUserId,
          newPassword: _defaultUserPassword,
          adminToken: adminToken,
        );
      } else {
        debugPrint('Step 4b: User does not exist, creating new user...');
        // Step 4b: User doesn't exist - create new user
        // Use v2 API as primary (v1 doesn't work on this server)
        operationResult = await _createMatrixUserV2(
          matrixUserId: matrixUserId,
          password: _defaultUserPassword,
          displayName: appUser.name ?? 'Unknown User',
          adminToken: adminToken,
          avatarUrl: appUser.imageUrl,
          admin: false,
        );
      }

      if (!operationResult.success) {
        return operationResult;
      }

      // Step 5: Login user to Matrix using MatrixChatProvider
      debugPrint('Step 5: Logging user into Matrix via MatrixChatProvider...');

      try {
        await matrixChatProvider.loginWithPassword(
          usernameOrUserId: matrixUserId,
          password: _defaultUserPassword,
        );

        debugPrint('Matrix user provisioning completed successfully');
        return MatrixProvisioningResult(
          success: true,
          message: userExists
              ? 'User password updated and logged in successfully'
              : 'User created and logged in successfully',
          matrixUserId: matrixUserId,
          accessToken: matrixChatProvider.clientNullable?.accessToken,
          userData: {'user_id': matrixUserId},
        );
      } catch (e) {
        debugPrint('Matrix login failed: $e');
        return MatrixProvisioningResult(
          success: false,
          message: 'Failed to login to Matrix: $e',
        );
      }
    } catch (e) {
      debugPrint('Unexpected error in Matrix user provisioning: $e');
      return MatrixProvisioningResult(
        success: false,
        message: 'Unexpected error during provisioning: $e',
      );
    }
  }

  /// Clear cached admin token (useful for testing or token refresh)
  static void clearAdminToken() {
    _cachedAdminToken = null;
    _tokenExpiry = null;
  }

  /// Get Matrix user ID from phone number (utility method)
  static String getMatrixUserIdFromPhone(String phoneNumber) {
    return MatrixConfig.phoneToMatrixUserId(phoneNumber);
  }

  /// Check if provisioning is possible for a user
  static bool canProvisionUser(UserModel user) {
    return user.phone != null && user.phone!.isNotEmpty;
  }
}
