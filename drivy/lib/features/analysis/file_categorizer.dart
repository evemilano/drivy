import 'dart:io';
import 'package:path/path.dart' as p;

// New data class to hold summary information for each file extension
class ExtensionSummary {
  final String extension;
  final int totalSize; // in bytes
  final int fileCount;

  ExtensionSummary({
    required this.extension,
    required this.totalSize,
    required this.fileCount,
  });

  // Helper to format size into human-readable format
  String get formattedSize {
    if (totalSize < 1024) return '$totalSize B';
    if (totalSize < 1024 * 1024) return '${(totalSize / 1024).toStringAsFixed(2)} KB';
    if (totalSize < 1024 * 1024 * 1024) return '${(totalSize / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

class FileCategorizer {
  // This method will now categorize files by their extension
  Future<Map<String, List<FileSystemEntity>>> categorizeFilesByExtension(
      List<FileSystemEntity> files) async {
    final Map<String, List<FileSystemEntity>> categorized = {};

    for (final file in files) {
      if (file is File) {
        final extension = p.extension(file.path).replaceAll('.', '').toLowerCase();
        categorized.putIfAbsent(extension, () => []).add(file);
      }
    }
    return categorized;
  }
}
