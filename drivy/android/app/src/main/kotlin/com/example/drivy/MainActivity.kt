package com.example.drivy

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.core.content.ContextCompat
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.drivy/storage"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "getStoragePaths") {
                result.success(getStoragePaths())
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getStoragePaths(): List<String> {
        val paths = mutableListOf<String>()
        val externalStorageFiles = ContextCompat.getExternalFilesDirs(this, null)
        for (file in externalStorageFiles) {
            if (file != null) {
                val path = file.path.substringBefore("/Android")
                if (!paths.contains(path)) {
                    paths.add(path)
                }
            }
        }
        return paths
    }
}
