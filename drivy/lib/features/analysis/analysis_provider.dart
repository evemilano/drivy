import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:storage_analyzer_pro/features/analysis/file_categorizer.dart';
import 'package:path/path.dart' as p;

/// Provider that handles scanning and categorizing REAL files by extension for a given path.
final analysisResultProvider = FutureProvider.family<Map<String, List<FileSystemEntity>>, String>((ref, path) async {
  final status = await Permission.manageExternalStorage.request();

  if (!status.isGranted) {
    throw Exception('Storage permission is required to analyze files.');
  }

  final List<FileSystemEntity> allFiles = [];
  final Directory rootDir = Directory(path);

  if (!await rootDir.exists()) {
    return {};
  }

  // List of paths to exclude from recursive scanning
  final List<String> excludedPaths = [
    p.join(rootDir.path, 'Android', 'data'),
    p.join(rootDir.path, 'Android', 'obb'),
  ];

  // Custom recursive listing to skip protected directories
  Future<void> listDir(Directory dir) async { // Renamed _listDir to listDir
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is File) {
        allFiles.add(entity);
      } else if (entity is Directory) {
        // Check if the directory is in the excluded list
        if (!excludedPaths.any((excludedPath) => p.equals(entity.path, excludedPath))) {
          try {
            await listDir(entity); // Recursively call for subdirectories
          } catch (e) {
            // Continue scanning other directories even if one fails
          }
        } else {
          // Skipping excluded directory
        }
      }
    }
  }

  try {
    await listDir(rootDir); // Called listDir
  } catch (e) {
    return {};
  }

  final categorizer = FileCategorizer();
  final categorized = await categorizer.categorizeFilesByExtension(allFiles);
  return categorized;
});

/// Provider that calculates and provides the top 10 file extension summaries for a given path.
final extensionSummaryProvider = FutureProvider.family<List<ExtensionSummary>, String>((ref, path) async {
  final categorizedFiles = await ref.watch(analysisResultProvider(path).future);
  final List<ExtensionSummary> summaries = [];

  for (final entry in categorizedFiles.entries) {
    final extension = entry.key;
    final files = entry.value;
    int totalSize = 0;
    int fileCount = 0;

    for (final file in files) {
      if (file is File) {
        try {
          totalSize += await file.length();
          fileCount++;
        } catch (e) {
          // Handle cases where file might have been deleted or is inaccessible
        }
      }
    }
    if (fileCount > 0) { // Only add if there are files for this extension
      summaries.add(ExtensionSummary(
        extension: extension,
        totalSize: totalSize,
        fileCount: fileCount,
      ));
    }
  }

  // Sort by total size in descending order and take the top 10
  summaries.sort((a, b) => b.totalSize.compareTo(a.totalSize));
  return summaries.take(10).toList();
});
