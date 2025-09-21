import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class StorageUtils {
  static const platform = MethodChannel('com.example.drivy/storage');

  static Future<List<String>> getStoragePaths() async {
    try {
      final List<dynamic> paths = await platform.invokeMethod('getStoragePaths');
      return paths.cast<String>();
    } on PlatformException catch (e) {
      // Use kDebugMode to ensure logs are only shown in development environments.
      if (kDebugMode) {
        print("Failed to get storage paths: '${e.message}'.");
      }
      return [];
    }
  }
}
