# Matrix Auto-Provisioning Implementation Guide

This guide explains the automatic Matrix user provisioning system that uses admin credentials to seamlessly integrate Matrix authentication with your Flutter app.

## Overview

The auto-provisioning system automatically creates and authenticates Matrix users when they open the "التواصل" (Contact) screen. It uses admin credentials instead of a pre-existing admin token, making it easier to deploy and manage.

## How It Works

### Automatic Flow (No User Interaction Required)

1. **User opens Contact screen** → System detects logged-in app user
2. **Admin authentication** → System logs in as admin to get admin token
3. **User existence check** → Check if Matrix user exists using phone number
4. **User management**:
   - If user exists: Update password to predefined value
   - If user doesn't exist: Create new Matrix user with app user data
5. **Automatic login** → User is automatically logged into Matrix
6. **Chat ready** → User can now use Matrix features seamlessly

### Architecture Components

```
┌─────────────────┐    ┌──────────────────────┐    ┌─────────────────┐
│   Contact       │───▶│  MatrixChatProvider  │───▶│ Auto-Provisioning│
│   Screen        │    │                      │    │    Service       │
└─────────────────┘    └──────────────────────┘    └─────────────────┘
         │                        │                          │
         │                        │                          ▼
         │                        │                ┌─────────────────┐
         │                        │                │  Matrix Config  │
         │                        │                └─────────────────┘
         │                        │                          │
         │                        │                          ▼
         │                        └─────────────────▶┌─────────────────┐
         │                                          │ Matrix Admin API│
         └─────────────────────────────────────────▶│ Matrix Client API│
                                                    └─────────────────┘
```

## Setup Instructions

### 1. Configure Admin Credentials

Edit `lib/core/config/matrix_config.dart`:

```dart
class MatrixConfig {
  // Update these values for your Matrix server
  static const String homeserver = 'https://matrix.private-4t.com';
  static const String adminUsername = 'your_admin_username';
  static const String adminPassword = 'your_admin_password';
  static const String defaultUserPassword = 'Private4T@2024';
}
```

### 2. Required Admin Permissions

Your admin user must have the following permissions:

- User management (create, update users)
- Password management
- Access to Synapse Admin API

### 3. Verification

Check configuration status:

```dart
print(MatrixConfig.getConfigurationStatus());
print(MatrixConfig.isConfigured()); // Should return true
```

## Implementation Details

### Core Files

1. **`lib/core/config/matrix_config.dart`**

   - Centralized configuration
   - Admin credentials management
   - Utility methods

2. **`lib/core/services/matrix_auto_provisioning_service.dart`**

   - Admin authentication
   - User existence checking
   - User creation/password updates
   - Matrix login

3. **`lib/core/providers/matrix_chat_provider.dart`** (Enhanced)

   - Integration with auto-provisioning
   - Matrix SDK management
   - State management

4. **`lib/features/contact/screens/contact_screen.dart`** (Enhanced)
   - Automatic provisioning trigger
   - User interface updates
   - Progress indication

### API Endpoints Used

#### Admin Authentication

```http
POST /_matrix/client/v3/login
{
  "type": "m.login.password",
  "identifier": {"type": "m.id.user", "user": "admin"},
  "password": "admin_password"
}
```

#### User Management

```http
PUT /_synapse/admin/v1/users/@phone:domain
Authorization: Bearer admin_token
{
  "password": "user_password",
  "displayname": "User Name",
  "admin": false
}
```

#### User Login

```http
POST /_matrix/client/v3/login
{
  "type": "m.login.password",
  "identifier": {"type": "m.id.user", "user": "@phone:domain"},
  "password": "user_password"
}
```

## User Experience

### Seamless Integration

- **No additional login required**: Users are automatically authenticated
- **Transparent process**: Background provisioning with progress indication
- **Error handling**: Clear error messages with fallback options
- **Consistent experience**: Works across app restarts and sessions

### UI States

1. **Loading State**: "جاري ربط حسابك بـ Matrix..."
2. **Success State**: Automatic transition to chat interface
3. **Error State**: Error message with manual login option
4. **Fallback State**: Manual login form if auto-provisioning fails

## Security Considerations

### Token Management

- Admin tokens are cached securely
- Automatic token expiry (configurable duration)
- Token refresh on expiry
- Clear cached tokens on logout

### Password Security

- Predefined password system for consistency
- Secure password transmission (HTTPS)
- No plain text password storage
- Regular password rotation recommended

### Access Control

- Admin permissions are scoped appropriately
- User permissions are minimal by default
- Phone number validation before user creation
- Rate limiting considerations

## Error Handling

### Configuration Errors

```dart
if (!MatrixConfig.isConfigured()) {
  return "Matrix configuration incomplete"
}
```

### Network Errors

- Automatic retry with exponential backoff
- Graceful degradation to manual login
- Clear error messages for users

### Authentication Errors

- Admin authentication failure handling
- User creation/update error handling
- Matrix login error handling

## Debugging

### Enable Debug Logging

```dart
debugPrint('Starting automatic Matrix provisioning for user: ${loggedUser.phone}');
```

### Common Debug Points

1. Configuration validation
2. Admin token retrieval
3. User existence check
4. User creation/update
5. Matrix login
6. SDK initialization

### Debug Commands

```dart
// Clear cached admin token
MatrixAutoProvisioningService.clearAdminToken();

// Check user provisioning capability
final canProvision = MatrixAutoProvisioningService.canProvisionUser(user);

// Get Matrix user ID
final matrixId = MatrixAutoProvisioningService.getMatrixUserIdFromPhone(phone);
```

## Testing

### Unit Testing

```dart
test('should convert phone to Matrix user ID', () {
  final result = MatrixConfig.phoneToMatrixUserId('+1234567890');
  expect(result, '@1234567890:matrix.private-4t.com');
});
```

### Integration Testing

1. Test admin authentication
2. Test user creation flow
3. Test user update flow
4. Test automatic login
5. Test error scenarios

### Manual Testing Checklist

- [ ] Configure admin credentials
- [ ] Test with new user (should create Matrix account)
- [ ] Test with existing user (should update password)
- [ ] Test error scenarios (invalid credentials, network issues)
- [ ] Verify chat functionality works after auto-provisioning
- [ ] Test multiple users
- [ ] Test app restart scenarios

## Production Deployment

### Environment Variables

Consider using environment variables for sensitive data:

```dart
static final String adminUsername = dotenv.env['MATRIX_ADMIN_USERNAME']!;
static final String adminPassword = dotenv.env['MATRIX_ADMIN_PASSWORD']!;
```

### Monitoring

- Track auto-provisioning success/failure rates
- Monitor Matrix API response times
- Alert on authentication failures
- Log user creation patterns

### Performance

- Admin token caching reduces API calls
- Async operations don't block UI
- Background provisioning improves UX
- Efficient error handling

## Troubleshooting

### Common Issues

1. **"Matrix configuration incomplete"**

   - Solution: Update admin credentials in MatrixConfig

2. **"Failed to authenticate as admin"**

   - Check admin username/password
   - Verify Matrix server is accessible
   - Check admin user permissions

3. **"User phone number is required"**

   - Ensure logged user has valid phone number
   - Check UserModel.phone property

4. **Auto-provisioning takes too long**
   - Check network connectivity
   - Verify Matrix server performance
   - Consider increasing timeout values

### Support Information

For additional support:

1. Check Matrix server logs
2. Enable debug logging in app
3. Verify admin API access
4. Test with curl/Postman
5. Review Matrix Synapse documentation

## Migration from Previous Implementation

If migrating from the previous admin token implementation:

1. Remove hardcoded admin tokens
2. Update configuration to use admin credentials
3. Test the new flow thoroughly
4. Update any custom integrations
5. Monitor the transition period

The new system is designed to be a drop-in replacement with improved security and easier management.
