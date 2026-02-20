import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DownloadService {
  static const int DOWNLOAD_NOTIFICATION_ID =
      1000; // Unique ID for download notifications
  static const String DOWNLOAD_NOTIFICATION_CHANNEL_ID = "download_channel";

  /// Downloads a file and shows progress in a notification.
  /// Returns the path to the downloaded file on success, null otherwise.
  static Future<String?> downloadFileWithNotification(
    String url,
    String fileName,
  ) async {
    try {
      // Request proper permissions based on Android version
      bool hasPermission = await _requestStoragePermissions();
      if (!hasPermission) {
        await _showErrorNotification("تم رفض أذونات التخزين");
        return null;
      }

      // 1. Get the proper download directory
      Directory? downloadDir = await _getDownloadsDirectory();

      if (downloadDir == null) {
        await _showErrorNotification("لا يمكن تحديد مجلد التحميل");
        return null;
      }

      // Ensure the file name is safe and unique
      String safeFileName = _getSafeFileName(fileName);
      String savePath = '${downloadDir.path}/$safeFileName';

      // Check if file already exists and create unique name if needed
      savePath = await _getUniqueFilePath(savePath);

      // 2. Initialize Dio
      Dio dio = Dio();

      // 3. Show initial notification
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DOWNLOAD_NOTIFICATION_ID,
          channelKey: DOWNLOAD_NOTIFICATION_CHANNEL_ID,
          title: 'بدء التحميل...',
          notificationLayout: NotificationLayout.ProgressBar,
          body: fileName,
          largeIcon: "resource://drawable/logo",
          progress: 0,
          // Initial progress
          locked: true, // Prevent dismissal while downloading
          // Optional: Add an icon
          // bigPicture: 'asset://assets/images/download_icon.png',
          // notificationLayout: NotificationLayout.BigPicture,
        ),
      );

      // 4. Perform the download with progress tracking
      Response response = await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) async {
          if (total != -1) {
            int progress = (received / total * 100).toInt();
            // Update the notification with progress
            await AwesomeNotifications().createNotification(
              content: NotificationContent(
                id: DOWNLOAD_NOTIFICATION_ID,
                // Same ID to update
                channelKey: DOWNLOAD_NOTIFICATION_CHANNEL_ID,
                title: 'جاري التحميل...',
                body: '$fileName ($progress%)',
                progress: progress.toDouble(),
                notificationLayout: NotificationLayout.ProgressBar,
                largeIcon: "resource://drawable/logo",
                // Update progress
                locked: true,
              ),
            );
            if (kDebugMode) {
              print("Download progress: $progress%");
            }
          }
        },
        // Optional: Add headers if needed
        // options: Options(
        //   headers: {
        //     "Authorization": "Bearer YOUR_TOKEN",
        //   },
        // ),
      );

      // 5. Handle download completion
      if (response.statusCode == 200) {
        // Show success notification
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: DOWNLOAD_NOTIFICATION_ID,
            channelKey: DOWNLOAD_NOTIFICATION_CHANNEL_ID,
            title: 'تم التحميل بنجاح',
            body: 'تم حفظ الملف: $fileName',
            largeIcon: "resource://drawable/logo",
            locked: false,
            // Allow dismissal
          ),
        );

        if (kDebugMode) {
          print("Download completed successfully: $savePath");
        }
        return savePath;
      } else {
        await _showErrorNotification("فشل التحميل: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print("Download error: $e");
      }
      await _showErrorNotification("خطأ في التحميل: $e");
      return null;
    }
  }

  /// Show error notification
  static Future<void> _showErrorNotification(String message) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DOWNLOAD_NOTIFICATION_ID,
          // Update the same notification ID
          channelKey: DOWNLOAD_NOTIFICATION_CHANNEL_ID,
          title: 'فشل التحميل',
          body: message,
          largeIcon: "resource://drawable/logo",
          locked: false,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print("Failed to show error notification: $e");
      }
    }
  }

  /// Request storage permissions based on Android version
  static Future<bool> _requestStoragePermissions() async {
    if (Platform.isIOS) {
      // iOS doesn't need explicit storage permissions for downloads
      return true;
    }

    // For Android, handle different API levels
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      if (androidInfo.version.sdkInt >= 29) {
        // Android 10+ (API 29+) - No storage permission needed for Scoped Storage
        // Files are saved to app-specific directory which is accessible
        return true;
      } else {
        // Android 9 and below - Request traditional storage permission
        var status = await Permission.storage.request();
        return status.isGranted;
      }
    }

    return false;
  }

  /// Get the appropriate downloads directory
  static Future<Directory?> _getDownloadsDirectory() async {
    try {
      if (Platform.isAndroid) {
        // For Android 10+ (API 29+), use app-specific directory
        // This is accessible via Files app and doesn't require special permissions
        Directory? appDir = await getExternalStorageDirectory();
        if (appDir != null) {
          // Create a Downloads subdirectory in app documents
          String downloadsPath = '${appDir.path}/Private 4T/Documents';
          Directory downloadsDir = Directory(downloadsPath);

          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }

          return downloadsDir;
        }
      } else if (Platform.isIOS) {
        // iOS: Use the app's documents directory (accessible via Files app)
        return await getApplicationDocumentsDirectory();
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error getting downloads directory: $e");
      }
    }

    // Fallback to documents directory
    return await getApplicationDocumentsDirectory();
  }

  /// Create a safe file name by removing invalid characters
  static String _getSafeFileName(String fileName) {
    // Remove invalid characters for file names
    String safeFileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

    // Ensure the file has an extension
    if (!safeFileName.contains('.')) {
      safeFileName += '.pdf'; // Default to PDF if no extension
    }

    return safeFileName;
  }

  /// Get a unique file path to avoid overwriting existing files
  static Future<String> _getUniqueFilePath(String originalPath) async {
    File file = File(originalPath);

    if (!await file.exists()) {
      return originalPath;
    }

    // File exists, create unique name
    String dir = file.parent.path;
    String nameWithoutExtension = file.uri.pathSegments.last.split('.').first;
    String extension = file.uri.pathSegments.last.split('.').last;

    int counter = 1;
    String newPath;

    do {
      newPath = '$dir/${nameWithoutExtension}_($counter).$extension';
      file = File(newPath);
      counter++;
    } while (await file.exists());

    return newPath;
  }

  /// Get the path to the Downloads folder that's accessible to the user
  static String getDownloadsFolderPath() {
    if (Platform.isAndroid) {
      // For Android, return the app-specific Downloads folder path
      // This will be accessible via Files app
      return '/storage/emulated/0/Android/data/com.private_4t.app/files/Downloads';
    } else if (Platform.isIOS) {
      // For iOS, return the app documents directory path
      return '/Documents/Downloads';
    }
    return '';
  }

  /// Check if file exists in downloads folder
  static Future<bool> fileExistsInDownloads(String fileName) async {
    try {
      Directory? downloadDir = await _getDownloadsDirectory();
      if (downloadDir != null) {
        String filePath = '${downloadDir.path}/$fileName';
        return await File(filePath).exists();
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print("Error checking file existence: $e");
      }
      return false;
    }
  }

  /// Get list of downloaded files
  static Future<List<FileSystemEntity>> getDownloadedFiles() async {
    try {
      Directory? downloadDir = await _getDownloadsDirectory();
      if (downloadDir != null && await downloadDir.exists()) {
        return downloadDir
            .listSync()
            .where((entity) => entity is File)
            .toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print("Error getting downloaded files: $e");
      }
      return [];
    }
  }
}
