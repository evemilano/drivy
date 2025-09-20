import 'dart:async';

import 'package:flutter/services.dart';

class DiskSpace {
  static const MethodChannel _channel = MethodChannel('disk_space');

  static Future<double?> get getTotalDiskSpace async {
    final double? totalSpace = await _channel.invokeMethod('getTotalDiskSpace');
    return totalSpace;
  }

  static Future<double?> get getFreeDiskSpace async {
    final double? freeSpace = await _channel.invokeMethod('getFreeDiskSpace');
    return freeSpace;
  }
}
