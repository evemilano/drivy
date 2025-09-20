package com.example.disk_space;

import android.os.Environment;
import android.os.StatFs;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class DiskSpacePlugin implements FlutterPlugin, MethodCallHandler {
  private MethodChannel channel;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "disk_space");
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("getTotalDiskSpace")) {
      StatFs stat = new StatFs(Environment.getDataDirectory().getPath());
      long bytesAvailable = stat.getBlockSizeLong() * stat.getBlockCountLong();
      result.success((double)bytesAvailable / (1024 * 1024));
    } else if (call.method.equals("getFreeDiskSpace")) {
      StatFs stat = new StatFs(Environment.getDataDirectory().getPath());
      long bytesAvailable = stat.getBlockSizeLong() * stat.getAvailableBlocksLong();
      result.success((double)bytesAvailable / (1024 * 1024));
    } else {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }
}
