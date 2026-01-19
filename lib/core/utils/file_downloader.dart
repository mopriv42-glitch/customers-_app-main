import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class FileDownloader {
  // Downloads a file and saves it with the given name in the app's documents directory.
  // Returns the full path of the saved file on success, null on failure.
  static Future<String?> downloadFile(
      String url,
      String fileName,
      ) async {
    try {
      // 1. Get the desired directory to save the file
      // Options: getTemporaryDirectory(), getApplicationDocumentsDirectory(), getExternalStorageDirectory() (Android only)
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String filePath = '${appDocDir.path}/$fileName';

      // Optional: Check if file already exists and handle accordingly
      // File file = File(filePath);
      // if (await file.exists()) {
      //   print("File already exists at $filePath");
      //   // You can choose to overwrite, skip, or append
      //   // For now, we'll overwrite
      // }

      // 2. Initialize Dio
      Dio dio = Dio();

      // Optional: Track download progress
      // dio.interceptors.add(InterceptorsWrapper(
      //   onResponse: (response, handler) {
      //     // Handle response
      //     return handler.next(response);
      //   },
      // ));

      // 3. Perform the download
      Response response = await dio.download(
        url,
        filePath,
        // Options for headers, etc.
        // options: Options(
        //   headers: {
        //     "Authorization": "Bearer YOUR_TOKEN", // If needed
        //   },
        // ),
        // onReceiveProgress: (received, total) {
        //   if (total != -1) {
        //     double progress = received / total;
        //     print("Download progress: ${progress.toStringAsFixed(2)}%");
        //     // You can update a UI progress indicator here
        //   }
        // },
      );

      if (response.statusCode == 200) {
        print("File downloaded successfully to: $filePath");
        return filePath; // Return the path where the file is saved
      } else {
        print("Download failed with status code: ${response.statusCode}");
        return null;
      }
    } on DioException catch (e) {
      // Handle Dio-specific errors (network issues, timeouts, etc.)
      print("Dio error during download: $e");
      if (kDebugMode) {
        print("Dio error info: ${e.message}, ${e.response?.statusCode}, ${e.response?.data}");
      }
      return null;
    } catch (e) {
      // Handle other potential errors (like issues with path_provider)
      print("General error during download: $e");
      return null;
    }
  }
}