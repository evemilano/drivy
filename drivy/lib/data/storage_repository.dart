import 'dart:io';
import 'package:disk_space/disk_space.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

// --- Data Models ---
class StorageData {
  final double totalSpace;
  final double usedSpace;
  final double freeSpace;
  final List<StorageCategory> categories;

  StorageData({
    required this.totalSpace,
    required this.usedSpace,
    required this.freeSpace,
    required this.categories,
  });
}

class StorageCategory {
  final String name;
  final double size;

  StorageCategory({required this.name, required this.size});
}

class FileSystemEntityInfo {
  final FileSystemEntity entity;
  final double size; // in GB

  FileSystemEntityInfo({required this.entity, required this.size});
}

// --- Global constants for document extensions ---
const List<String> _documentExtensions = [
  '.pdf', '.doc', '.docx', '.txt', '.odt', '.rtf', '.xls', '.xlsx', '.ppt', '.pptx',
  '.csv', '.json', '.xml', '.html', '.htm', '.md', '.log', '.epub', '.mobi',
];

// --- Top-level function for Isolate to calculate total directory size ---
Future<double> _calculateDirectorySize(String path) async {
  try {
    final dir = Directory(path);
    if (!await dir.exists()) return 0.0;

    int totalBytes = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        try {
          totalBytes += await entity.length();
        } catch (_) {
          // Ignore files that can't be accessed
        }
      }
    }
    return totalBytes / (1024 * 1024 * 1024); // Convert to GB
  } catch (_) {
    return 0.0; // Return 0 if directory can't be accessed
  }
}

// --- Top-level function for Isolate to calculate document size ---
Future<double> _calculateDocumentSize(String rootPath) async {
  double documentBytes = 0.0;
  try {
    final dir = Directory(rootPath);
    if (!await dir.exists()) return 0.0;

    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        try {
          final fileExtension = p.extension(entity.path).toLowerCase();
          if (_documentExtensions.contains(fileExtension)) {
            documentBytes += await entity.length();
          }
        } catch (_) {
          // Ignore files that can't be accessed
        }
      }
    }
  } catch (_) {
    return 0.0;
  }
  return documentBytes / (1024 * 1024 * 1024); // Convert to GB
}

// --- Abstract Repository ---
abstract class StorageRepository {
  Future<StorageData> getStorageData(String path);
  Future<List<FileSystemEntityInfo>> getDirectoryContents(String path);
}

// --- Real Implementation ---
class RealStorageRepository implements StorageRepository {
  @override
  Future<StorageData> getStorageData(String path) async {
    final total = await DiskSpace.getTotalDiskSpace ?? 0.0;
    final free = await DiskSpace.getFreeDiskSpace ?? 0.0;
    final used = total - free;

    final totalGB = total / 1024;
    final usedGB = used / 1024;
    final freeGB = free / 1024;

    final downloadsPath = '$path/Download';
    final picturesPath = '$path/Pictures';
    final dcimPath = '$path/DCIM';
    final moviesPath = '$path/Movies';
    final androidPath = '$path/Android';

    // Calculate sizes for predefined folders
    final downloadsSize = await compute(_calculateDirectorySize, downloadsPath);
    final picturesSize = await compute(_calculateDirectorySize, picturesPath);
    final dcimSize = await compute(_calculateDirectorySize, dcimPath);
    final moviesSize = await compute(_calculateDirectorySize, moviesPath);
    final appsSize = await compute(_calculateDirectorySize, androidPath);
    
    // Calculate total size of the selected path
    final pathTotalSize = await compute(_calculateDirectorySize, path);

    // Calculate total size of documents within the selected path
    final documentsSize = await compute(_calculateDocumentSize, path);

    final imagesTotalSize = picturesSize + dcimSize;
    
    // List of categories to be displayed
    final List<StorageCategory> categories = [];

    if (imagesTotalSize > 0.01) {
      categories.add(StorageCategory(name: 'Images', size: imagesTotalSize));
    }
    if (moviesSize > 0.01) {
      categories.add(StorageCategory(name: 'Videos', size: moviesSize));
    }
    if (appsSize > 0.01) {
      categories.add(StorageCategory(name: 'Apps (Data)', size: appsSize));
    }
    if (downloadsSize > 0.01) {
      categories.add(StorageCategory(name: 'Downloads', size: downloadsSize));
    }
    if (documentsSize > 0.01) {
      categories.add(StorageCategory(name: 'Documents', size: documentsSize));
    }

    // Calculate the sum of all explicitly categorized sizes
    double totalCategorizedSpace = categories.fold(0.0, (sum, category) => sum + category.size);

    // Calculate 'Other' size by subtracting all explicitly categorized space from the total path size
    // Ensure 'otherSize' is not negative due to potential overlaps or floating point inaccuracies
    final otherSize = pathTotalSize > totalCategorizedSpace ? pathTotalSize - totalCategorizedSpace : 0.0;

    if (otherSize > 0.01) {
      categories.add(StorageCategory(name: 'Other', size: otherSize));
    }

    categories.sort((a, b) => b.size.compareTo(a.size));

    return StorageData(
      totalSpace: totalGB,
      usedSpace: usedGB,
      freeSpace: freeGB,
      categories: categories,
    );
  }

  @override
  Future<List<FileSystemEntityInfo>> getDirectoryContents(String path) async {
    final dir = Directory(path);
    final List<FileSystemEntityInfo> contents = [];
    try {
      // Check if the directory exists and is accessible
      if (!await dir.exists()) {
        debugPrint('Directory does not exist or is not accessible: $path');
        return [];
      }

      final entities = await dir.list(followLinks: false).toList();

      for (final entity in entities) {
        double size = 0.0;
        if (entity is File) {
          try {
            final bytes = await entity.length();
            size = bytes / (1024 * 1024 * 1024); // Convert to GB
          } catch (e) {
            debugPrint('Error getting size for file ${entity.path}: $e');
            // If file size cannot be obtained, treat as 0
            size = 0.0;
          }
        } else if (entity is Directory) {
          // For directories, we initially set size to 0 to avoid deep recursive calculation
          // This prevents the UI from freezing on initial load for large directories.
          // The actual size can be calculated when navigating into the directory or on demand.
          size = 0.0; // Placeholder size for directories
        }
        // Only add entities with a size greater than 0 or directories (even with 0 size)
        // to ensure all items are listed.
        if (size > 0 || entity is Directory) {
          contents.add(FileSystemEntityInfo(entity: entity, size: size));
        }
      }

      // Sort directories first, then files, then by size (descending)
      contents.sort((a, b) {
        final isADirectory = a.entity is Directory;
        final isBDirectory = b.entity is Directory;

        if (isADirectory && !isBDirectory) return -1; // A (dir) comes before B (file)
        if (!isADirectory && isBDirectory) return 1;  // B (dir) comes before A (file)

        // If both are same type, sort by size
        return b.size.compareTo(a.size);
      });

      return contents;
    } catch (e) {
      debugPrint('Error reading directory $path: $e');
      return [];
    }
  }
}
