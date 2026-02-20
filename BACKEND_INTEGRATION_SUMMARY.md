# 📱 Flutter App - Backend Integration Summary

**For Backend Developer Verification**  
Generated: 2026-02-06

---

## 🔐 Authentication Flow

### Laravel API Endpoints Used

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `POST /api/v3/login` | POST | Email/password login |
| `POST /api/v3/login-phone` | POST | Request OTP for phone login |
| `POST /api/v3/confirm-otp` | POST | Verify OTP code |
| `POST /api/v3/login/google` | POST | Google Sign-In |
| `POST /api/v3/logout` | POST | Logout user |
| `POST /api/v3/delete-account` | POST | Delete user account |
| `GET /api/v3/user` | GET | Get logged user info |
| `GET /api/v3/auth` | GET | Get auth init data (grades, roles) |
| `GET /api/v3/profile` | GET | Get user profile |
| `PUT /api/v3/me/update-name` | PUT | Update user name |
| `POST /api/v3/profile` | POST | Update profile with avatar |

### Expected Login Response (NEW FORMAT)

```json
{
    "user": {
        "id": 1,
        "name": "User Name",
        "phone": "12345678",
        "email": "user@example.com",
        "photo_url": "https://...",
        "matrix_user_support_id": "support",
        "is_existing_customer": false,
        "profile": { ... },
        "map_address": { ... }
    },
    "token": "LARAVEL_API_TOKEN",
    "is_new": false,
    "matrix": {
        "user_id": "@private_4t_c_12345678:matrix.private-4t.com",
        "access_token": "syt_...",
        "homeserver": "https://matrix.private-4t.com"
    }
}
```

> **⚠️ IMPORTANT:** The `matrix` object is **NEW** and expected by the app for token-based Matrix login.

---

## 🗨️ Matrix Integration

### Configuration

| Setting | Value |
|---------|-------|
| Homeserver | `https://matrix.private-4t.com` |
| Admin API | `/_synapse/admin/v1/` and `/_synapse/admin/v2/` |
| User ID Format | `@private_4t_c_{phone}:matrix.private-4t.com` |
| Default Password | `Private4T@@2024` (used by old provisioning) |

### Matrix User ID Format

```
Phone: 12345678
Matrix ID: @private_4t_c_12345678:matrix.private-4t.com
```

### Matrix API Endpoints Used by App

| Endpoint | Purpose |
|----------|---------|
| `POST /_matrix/client/v3/login` | Matrix login |
| `GET /_synapse/admin/v1/users/{userId}` | Check user exists |
| `PUT /_synapse/admin/v1/users/{userId}` | Create/update user |
| `GET /_synapse/admin/v1/server_version` | Verify server |

### Laravel Matrix Endpoints

| Endpoint | Purpose |
|----------|---------|
| `GET /api/v3/me/matrix/help-room` | Get help room ID |

---

## 📊 Main API Endpoints Used

### Dashboard & Content
- `GET /api/v3/dashboard` - Home dashboard data
- `GET /api/v3/our-teachers` - List teachers
- `GET /api/v3/regions-governorates` - Location data

### Notifications
- `GET /api/v3/notifications/history` - Notification history
- `PUT /api/v3/notifications/mark-read/{id}` - Mark as read
- `PUT /api/v3/notifications/mark-all-read` - Mark all read
- `DELETE /api/v3/notifications/{id}` - Delete notification
- `POST /api/v3/notifications/fcm-token` - Register FCM token

### Teachers & Courses
- `GET /api/v3/me/teachers` - My teachers
- `POST /api/v3/me/teachers/{id}/rate` - Rate teacher
- `GET /api/v3/me/upcoming-orders` - Upcoming bookings
- `GET /api/v3/me/upcoming-courses` - Upcoming courses
- `GET /api/v3/me/end-subscriptions` - Ended subscriptions

### Wishlist
- `GET /api/v3/me/wishlists` - Get wishlist
- `POST /api/v3/me/wishlists` - Add to wishlist
- `DELETE /api/v3/me/wishlists/{id}` - Remove from wishlist

### Library
- `GET /api/v3/library/items` - Library items

---

## 🔄 Authentication Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    NEW Token-Based Flow                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. User enters phone → App calls /api/v3/login-phone          │
│                               ↓                                 │
│  2. Server sends OTP → User enters OTP                         │
│                               ↓                                 │
│  3. App calls /api/v3/confirm-otp                              │
│                               ↓                                 │
│  4. Server returns: { token, user, matrix: {...} }             │
│                               ↓                                 │
│  5. App uses matrix.access_token for Matrix login directly     │
│                               ↓                                 │
│  6. Matrix chat ready!                                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                   OLD Fallback Flow (if matrix field missing)  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Steps 1-4 same, but without matrix field                      │
│                               ↓                                 │
│  5. App calls Synapse Admin API to create/update Matrix user   │
│                               ↓                                 │
│  6. App logs into Matrix with password: Private4T@@2024        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## ✅ Backend Checklist

- [ ] `/api/v3/confirm-otp` returns `matrix` object with `user_id`, `access_token`, `homeserver`
- [ ] Matrix token is obtained via Synapse Admin API impersonation
- [ ] User ID format matches: `@private_4t_c_{phone}:matrix.private-4t.com`
- [ ] Token is valid for Matrix `/login` endpoint
- [ ] Homeserver URL is `https://matrix.private-4t.com`

---

## 📝 Notes

1. **Base URL:** `https://private-4t.com/api/v3/`
2. **Auth Header:** `Authorization: Bearer {token}`
3. **Matrix SDK:** `matrix: ^1.1.1` (from pub.dev)
4. **Local DB:** SQLite via `sqflite` for Matrix SDK cache
