/// Matrix configuration for automatic user provisioning
///
/// IMPORTANT: Update these values for your Matrix server setup
class MatrixConfig {
  // Matrix homeserver configuration
  static const String homeserver = 'https://matrix.private-4t.com';

  // Admin credentials for automatic user provisioning
  static const String adminUsername = 'private-4t';
  static const String adminPassword = 'HgINXGYU3VNPoeEPHIR1';

  // Default password for all provisioned users
  // This will be set for all users created/updated through the system
  static const String defaultUserPassword = 'Private4T@@2024';

  // Device name for admin authentication
  static const String adminDeviceName = 'Private 4T Admin Client';

  // Device name for user authentication
  static const String userDeviceName = 'Private 4T Mobile App';

  // Token cache duration (in hours)
  static const int tokenCacheDurationHours = 1;

  /// Validate configuration
  static bool isConfigured() {
    return adminUsername.isNotEmpty &&
        adminPassword.isNotEmpty &&
        homeserver.isNotEmpty;
  }

  /// Get configuration status message
  static String getConfigurationStatus() {
    if (!isConfigured()) {
      return 'Matrix configuration incomplete. Please update admin credentials in MatrixConfig.';
    }
    return 'Matrix configuration is ready.';
  }

  /// Convert phone number to Matrix user ID format
  static String phoneToMatrixUserId(String phoneNumber) {
    // Remove all non-digit characters from phone number
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    // Extract domain from homeserver URL
    final domain =
        homeserver.replaceFirst('https://', '').replaceFirst('http://', '');
    return '@private_4t_c_$cleanPhone:$domain';
  }
}

/// Instructions for setup:
/// 
/// 1. Update the admin credentials:
///    - adminUsername: Your Matrix admin username
///    - adminPassword: Your Matrix admin password
/// 
/// 2. Verify the homeserver URL is correct
/// 
/// 3. Optionally customize the default user password
/// 
/// 4. Test the configuration using the debug methods:
///    ```dart
///    print(MatrixConfig.getConfigurationStatus());
///    print(MatrixConfig.isConfigured());
///    ```
/// 
/// Example configuration:
/// ```dart
/// static const String adminUsername = 'matrix_admin';
/// static const String adminPassword = 'SecureAdminPassword123!';
/// static const String homeserver = 'https://matrix.yourdomain.com';
/// ```