// Applying fixes for BuildContext warnings and const correctness.
import 'dart:io';
import 'package:storage_analyzer_pro/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

class FileExplorerScreen extends ConsumerWidget {
  final String path;

  const FileExplorerScreen({super.key, required this.path});

  String _getFormattedSize(double sizeInGB) {
    if (sizeInGB <= 0) return '0 B';
    if (sizeInGB * 1024 * 1024 < 1) {
      return '${(sizeInGB * 1024 * 1024).toStringAsFixed(1)} KB';
    } else if (sizeInGB < 1) {
      return '${(sizeInGB * 1024).toStringAsFixed(1)} MB';
    } else {
      return '${sizeInGB.toStringAsFixed(2)} GB';
    }
  }

  // --- Updated Delete Logic with Global Refresh ---
  Future<void> _deleteEntity(BuildContext context, WidgetRef ref, FileSystemEntity entity) async {
    try {
      HapticFeedback.heavyImpact();
      if (entity is Directory) {
        await entity.delete(recursive: true);
      } else if (entity is File) {
        await entity.delete();
      }

      // Trigger the global refresh by updating the change provider.
      ref.read(fileSystemChangeProvider.notifier).state++;

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted ${p.basename(entity.path)}')),
      );
    } on FileSystemException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting file: ${e.message}')),
      );
    }
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context, WidgetRef ref, FileSystemEntity entity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${entity is Directory ? 'Folder' : 'File'}?'),
        content: Text(
            'Are you sure you want to delete "${p.basename(entity.path)}"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      await _deleteEntity(context, ref, entity);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final directoryContentsAsync = ref.watch(fileExplorerProvider(path));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text(path),
        ),
      ),
      body: directoryContentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (contents) {
          if (contents.isEmpty) {
            return const Center(child: Text('This folder is empty or cannot be read.'));
          }

          final totalSizeOnScreen = contents.fold<double>(0.0, (sum, item) => sum + item.size);

          return ListView.builder(
            itemCount: contents.length,
            itemBuilder: (context, index) {
              final info = contents[index];
              final entity = info.entity;
              final isDirectory = entity is Directory;
              final percentage = totalSizeOnScreen > 0 ? (info.size / totalSizeOnScreen) : 0.0;

              return ListTile(
                leading: Icon(isDirectory ? Icons.folder_outlined : Icons.insert_drive_file_outlined, color: colorScheme.secondary),
                title: Text(p.basename(entity.path)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(_getFormattedSize(info.size)),
                    const SizedBox(height: 4),
                    if (percentage > 0.01)
                      LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: colorScheme.surface.withAlpha(128),
                        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, color: colorScheme.error),
                  tooltip: 'Delete',
                  onPressed: () => _showDeleteConfirmationDialog(context, ref, entity),
                ),
                onTap: isDirectory
                    ? () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => FileExplorerScreen(path: entity.path),
                          ),
                        );
                      }
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
