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
  final dir = Directory(path);
  if (!await dir.exists()) return 0.0;

  int totalBytes = 0;
  bool foundAnyFile = false; // Flag to indicate if any file was found
  try {
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        foundAnyFile = true; // Mark that a file was found
        try {
          totalBytes += await entity.length();
        } on FileSystemException {
          // File inaccessible, add a minimal size to indicate its presence
          totalBytes += 1; // Add 1 byte to indicate presence, if length cannot be read
        } catch (_) {
          totalBytes += 1; // Add 1 byte for other errors
        }
      }
    }
  } on FileSystemException {
    // If directory listing fails, return 0.0
    return 0.0;
  } catch (_) {
    // Catch any other unexpected errors
    return 0.0;
  }

  // If no files were found, but the directory exists, and it's not an error,
  // it might genuinely be empty of files.
  // However, if we found any file (even if its size was unreadable),
  // we should return at least a minimal size.
  if (foundAnyFile && totalBytes == 0) {
    return 1.0 / (1024 * 1024 * 1024); // Return a very small non-zero size (1 byte)
  }

  return totalBytes / (1024 * 1024 * 1024); // Convert to GB
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
    final pathTotalSpace = await compute(_calculateDirectorySize, path);

    // Calculate total size of documents within the selected path
    final documentsSize = await compute(_calculateDocumentSize, path);

    final imagesTotalSpace = picturesSize + dcimSize;
    
    // List of categories to be displayed
    final List<StorageCategory> categories = [];

    if (imagesTotalSpace > 0.01) {
      categories.add(StorageCategory(name: 'Images', size: imagesTotalSpace));
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

    // Calculate the sum of all explicitly categorized spaces
    double totalCategorizedSpace = categories.fold(0.0, (sum, category) => sum + category.size);

    // Calculate 'Other' size by subtracting all explicitly categorized space from the total path size
    // Ensure 'otherSize' is not negative due to potential overlaps or floating point inaccuracies
    final otherSize = pathTotalSpace > totalCategorizedSpace ? pathTotalSpace - totalCategorizedSpace : 0.0; // Renamed variable back

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
        throw FileSystemException('Directory does not exist or is not accessible', path);
      }

      final entities = await dir.list(followLinks: false).toList();

      for (final entity in entities) {
        double size = 0.0;
        if (entity is File) {
          try {
            final bytes = await entity.length();
            size = bytes / (1024 * 1024 * 1024); // Convert to GB
          } on FileSystemException {
            // File inaccessible, treat size as 0 but still include the file
            size = 0.0;
          } catch (e) {
            // Catch any other unexpected errors during length() call
            size = 0.0;
          }
          contents.add(FileSystemEntityInfo(entity: entity, size: size));
        } else if (entity is Directory) {
          // For directories, calculate their size recursively
          size = await compute(_calculateDirectorySize, entity.path);
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
    } on FileSystemException catch (e) {
      throw FileSystemException('Error accessing directory contents', path, e.osError);
    } catch (e) {
      throw FileSystemException('An unexpected error occurred while listing directory contents', path, null);
    }
  }
}
