# Matrix Auto-Provisioning Troubleshooting Guide

## Current Issue: "Unrecognized request" Error

### Problem Description

Getting error: **"Auto-provisioning failed: Failed to create user: Unrecognized request"**

### Possible Causes & Solutions

#### 1. **Matrix Admin API Not Enabled**

**Symptoms:** 404 errors, "Unrecognized request"
**Solution:** Enable Synapse Admin API in homeserver configuration

**Check:** Look for these in your Matrix homeserver config (`homeserver.yaml`):

```yaml
# Enable admin API endpoints
enable_registration: false
registration_shared_secret: "your_secret_here"

# Admin API configuration
experimental_features:
  synapse_admin: true
```

#### 2. **Wrong API Version**

**Symptoms:** "Unrecognized request" with 400/404 status
**Current Implementation:** We now try both v1 and v2 Admin API endpoints

**Check debug logs for:**

```
Creating Matrix user: @phone:domain
API URL: https://matrix.private-4t.com/_synapse/admin/v1/users/@phone:domain
```

#### 3. **Admin User Permissions**

**Symptoms:** Authentication succeeds but user creation fails
**Solution:** Ensure admin user has proper server admin permissions

**Check:** In your Matrix server, the admin user should be:

- A server administrator (not just room admin)
- Have `admin: true` in the database user table

#### 4. **Homeserver Configuration Issues**

**Symptoms:** Server responses but Admin API unavailable
**Solution:** Verify Matrix homeserver setup

**Check these Matrix server endpoints:**

- `/_matrix/client/versions` - Should return supported versions
- `/_synapse/admin/v1/server_version` - Should return server info (requires auth)

### Debug Steps

#### Step 1: Check Server Connectivity

```bash
curl https://matrix.private-4t.com/_matrix/client/versions
```

**Expected:** JSON response with supported versions

#### Step 2: Check Admin API Availability

```bash
curl https://matrix.private-4t.com/_synapse/admin/v1/server_version
```

**Expected:** Either 401 (needs auth) or 404 (not available)

#### Step 3: Test Admin Authentication

```bash
curl -X POST https://matrix.private-4t.com/_matrix/client/v3/login \
  -H "Content-Type: application/json" \
  -d '{
    "type": "m.login.password",
    "identifier": {"type": "m.id.user", "user": "abdullah"},
    "password": "EngAbdullah100@@"
  }'
```

**Expected:** JSON with `access_token`

#### Step 4: Test User Creation with Admin Token

```bash
curl -X PUT "https://matrix.private-4t.com/_synapse/admin/v1/users/@testuser:matrix.private-4t.com" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "password": "testpass",
    "displayname": "Test User",
    "admin": false,
    "deactivated": false
  }'
```

### Enhanced Debug Output

The updated implementation now provides detailed debug information:

```dart
// Debug output you should see:
Step 0: Testing Matrix server capabilities...
Testing Matrix server connectivity: https://matrix.private-4t.com/_matrix/client/versions
Server version response: 200 {"versions":["r0.0.1","r0.1.0","r0.2.0",...]}
Testing Admin API availability: https://matrix.private-4t.com/_synapse/admin/v1/server_version
Admin API response: 200 {"server_version":"1.x.x"}

Step 1: Authenticating as admin...
Authenticating admin user: abdullah
Admin login URL: https://matrix.private-4t.com/_matrix/client/v3/login
Admin auth response status: 200
Admin auth response body: {"user_id":"@abdullah:matrix.private-4t.com","access_token":"..."}

Step 2: Matrix user ID for provisioning: @1234567890:matrix.private-4t.com

Step 3: Checking if user exists...

Step 4b: User does not exist, creating new user...
Creating Matrix user: @1234567890:matrix.private-4t.com
API URL: https://matrix.private-4t.com/_synapse/admin/v1/users/@1234567890:matrix.private-4t.com
Request body: {"password":"Private4T@@2024","displayname":"User Name","admin":false,"deactivated":false}
Create user response status: XXX
Create user response body: {...}
```

### Common Error Codes

| Status Code | Error          | Likely Cause               | Solution                       |
| ----------- | -------------- | -------------------------- | ------------------------------ |
| 404         | Not Found      | Admin API disabled         | Enable Synapse Admin API       |
| 401         | Unauthorized   | Invalid admin token        | Check admin credentials        |
| 403         | Forbidden      | User not admin             | Grant server admin permissions |
| 400         | Bad Request    | Invalid request format     | Check API version/format       |
| 500         | Internal Error | Server configuration issue | Check homeserver logs          |

### Matrix Homeserver Requirements

Your Matrix server must support:

1. **Synapse Admin API** (not available on all Matrix servers)
2. **Admin user permissions** (server-level admin, not just room admin)
3. **Proper CORS configuration** (for web clients)
4. **HTTPS with valid certificates**

### Alternative Solutions

If Admin API is not available:

#### Option 1: Registration Tokens

Use Matrix registration tokens for user creation:

```dart
// Create registration token first, then register user
POST /_synapse/admin/v1/registration_tokens
POST /_matrix/client/v3/register
```

#### Option 2: Manual Registration

Enable open registration temporarily:

```yaml
# In homeserver.yaml
enable_registration: true
registration_requires_token: false
```

#### Option 3: Shared Secret Registration

Use registration shared secret:

```python
# Use matrix-synapse registration script
python -m synapse.app.register_new_matrix_user \
  -c homeserver.yaml \
  http://localhost:8008
```

### Next Steps

1. **Run debug version** with enhanced logging
2. **Check Matrix server logs** for detailed errors
3. **Verify Admin API availability** using curl commands above
4. **Check homeserver configuration** for Admin API settings
5. **Test with different API versions** (v1/v2)

### Getting More Help

If issues persist:

1. Check Matrix homeserver logs: `/var/log/matrix-synapse/homeserver.log`
2. Verify Matrix server version: Some features require newer versions
3. Test with Matrix Admin Panel (if available): `https://your-domain.com/_synapse/admin/`
4. Join Matrix support rooms for help with server configuration

### Quick Fix Commands

```bash
# Test basic connectivity
curl -I https://matrix.private-4t.com

# Test Matrix client API
curl https://matrix.private-4t.com/_matrix/client/versions

# Test admin API (should return 401 if available, 404 if not)
curl https://matrix.private-4t.com/_synapse/admin/v1/server_version
```

The enhanced implementation now includes automatic fallback to v2 API and comprehensive error reporting to help identify the exact issue.
