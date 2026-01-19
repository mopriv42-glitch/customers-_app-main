# Firebase Remote Notifications with Image Support & WebView Implementation

## Overview

This implementation adds enhanced Firebase remote notification support with image metadata and a dedicated WebView screen for displaying URLs from notifications.

## Features Implemented

### 1. Enhanced Firebase Notifications with Image Support

The notification service now supports rich notifications with image metadata:

- **Big Picture Notifications**: Automatically displays the first image as a large preview
- **Multiple Images**: Supports multiple images in notification metadata
- **Image Gallery**: Users can view all attached images in a dedicated dialog

### 2. WebView Screen

A new WebView screen that provides:

- **URL Display**: Renders web content within the app
- **Image Attachments**: Shows attached images from notifications
- **Navigation Controls**: Back, forward, and refresh functionality
- **Localization**: Full Arabic/English language support
- **Error Handling**: Graceful error handling with retry options

## Implementation Details

### Notification Service Changes

**File**: `lib/core/services/notification_service.dart`

#### New Method: `_handleEnhancedDeepLinkNotification`

```dart
static Future<void> _handleEnhancedDeepLinkNotification(
    Map<String, dynamic> notification, Map<String, dynamic> metadata) async
```

**Features:**

- Processes `deep_link` type notifications
- Extracts images from metadata
- Creates rich notifications with BigPicture layout
- Adds action buttons for opening links

#### New Method: `_handleOpenLinkAction`

```dart
static Future<void> _handleOpenLinkAction(Map<String, dynamic> payload) async
```

**Features:**

- Handles notification action button taps
- Supports internal WebView navigation
- Parses and passes image data to WebView

### WebView Screen

**File**: `lib/features/webview/screens/webview_screen.dart`

**Features:**

- Full-featured WebView with navigation controls
- Image gallery for notification attachments
- Loading progress indicators
- Error handling with retry functionality
- Localized UI strings

### Router Integration

**File**: `lib/core/navigation/app_router.dart`

**New Route**: `/webview`

**Query Parameters:**

- `url`: The URL to display (required)
- `title`: Optional page title
- `images`: Comma-separated list of image URLs

**Example Usage:**

```
/webview?url=https://example.com&title=Course%20Details&images=img1.jpg,img2.jpg
```

## Usage

### Backend Notification Payload

When sending notifications from your backend, use this structure:

```json
{
  "notification": {
    "title": "Notification Title",
    "body": "Notification body text"
  },
  "data": {
    "type": "deep_link",
    "metadata": {
      "type": "deep_link",
      "url": "/webview?url=https://your-website.com/page",
      "link_type": "internal",
      "images": [
        "https://your-cdn.com/image1.jpg",
        "https://your-cdn.com/image2.jpg"
      ]
    }
  }
}
```

### PHP Backend Example

```php
'metadata' => [
    'type' => 'deep_link',
    'url' => '/webview?url=' . $url,
    'link_type' => 'internal',
    'images' => array_filter(array_map(function ($e) {
        return !$e['is_video'] ? $e['url'] : null;
    }, $mediaResources)),
],
```

## Localization

All UI strings are localized in:

- `languages/ar.json` (Arabic)
- `languages/en.json` (English)

**New Localization Keys:**

```json
"webview": {
  "title": "View Page",
  "loading_error": "Loading Error",
  "loading_error_message": "Failed to load the page. Please try again.",
  "close": "Close",
  "retry": "Retry",
  "attached_images": "Attached Images",
  "image_load_error": "Failed to load image",
  "invalid_url": "Invalid URL",
  "error": "Error",
  "refresh": "Refresh",
  "back": "Back",
  "forward": "Forward",
  "view_attached_images": "View Attached Images"
}
```

## Testing

### Example Notification Payload

See `example_notification_payload.json` for a complete example of the notification structure.

### Manual Testing

1. **Send Test Notification**: Use your backend to send a notification with the enhanced payload
2. **Tap Notification**: Verify it opens the WebView screen
3. **Check Images**: Verify image attachments are displayed and accessible
4. **Test Navigation**: Test back/forward/refresh functionality
5. **Test Localization**: Switch languages and verify all strings are translated

## Dependencies

The implementation uses these existing dependencies:

- `webview_flutter: ^4.13.0` (already in pubspec.yaml)
- `awesome_notifications: ^0.10.1` (already in pubspec.yaml)
- `firebase_messaging: ^16.0.0` (already in pubspec.yaml)
- `easy_localization: ^3.0.8` (already in pubspec.yaml)

## File Structure

```
lib/
├── core/
│   ├── navigation/
│   │   └── app_router.dart (WebView route added)
│   └── services/
│       └── notification_service.dart (Enhanced with image support)
├── features/
│   └── webview/
│       └── screens/
│           └── webview_screen.dart (New WebView screen)
└── languages/
    ├── ar.json (Arabic translations added)
    └── en.json (English translations added)
```

## Notes

- **Security**: WebView loads external URLs - ensure you trust the content sources
- **Performance**: Images are loaded on-demand with error handling
- **Accessibility**: All UI elements include proper accessibility labels
- **RTL Support**: Full RTL layout support for Arabic language
- **Error Handling**: Comprehensive error handling for network issues and invalid URLs
