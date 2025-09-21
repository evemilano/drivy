import 'dart:io';
import 'dart:math'; // For log and pow in _getFormattedSize
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storage_analyzer_pro/features/analysis/analysis_provider.dart';
import 'package:open_filex/open_filex.dart'; // Import open_filex
import 'package:path/path.dart' as p; // Import path package

class FileDetailScreen extends ConsumerStatefulWidget {
  final String extension;
  final String selectedPath;

  const FileDetailScreen({super.key, required this.extension, required this.selectedPath});

  @override
  ConsumerState<FileDetailScreen> createState() => _FileDetailScreenState();
}

class _FileDetailScreenState extends ConsumerState<FileDetailScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedFiles = {}; // Store file paths

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedFiles.clear(); // Clear selection when exiting selection mode
      }
    });
  }

  void _toggleFileSelection(String filePath) {
    setState(() {
      if (_selectedFiles.contains(filePath)) {
        _selectedFiles.remove(filePath);
      } else {
        _selectedFiles.add(filePath);
      }
    });
  }

  // Synchronous wrapper for multiple file deletion
  void _deleteSelectedFilesWrapper() {
    _performDeleteSelectedFiles();
  }

  Future<void> _performDeleteSelectedFiles() async {
    final bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete ${_selectedFiles.length} selected files?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirmDelete) {
      int deletedCount = 0;
      for (final filePath in _selectedFiles) {
        try {
          final file = File(filePath);
          if (await file.exists()) {
            await file.delete();
            deletedCount++;
          }
        } catch (e) {
          if (mounted) { // Check mounted directly before using context
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete $filePath: $e')),
            );
          }
        }
      }
      // Invalidate the provider to trigger a refresh of the file list
      ref.refresh(analysisResultProvider(widget.selectedPath));
      if (mounted) { // Check mounted directly before using context
        setState(() {
          _selectedFiles.clear();
          _isSelectionMode = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$deletedCount files deleted.')),
        );
      }
    }
  }

  // Async helper for single file deletion
  Future<void> _handleSingleFileDelete(File file) async {
    final bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete ${file.path.split('/').last}?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirmDelete) {
      try {
        await file.delete();
        // Invalidate the provider to trigger a refresh of the file list
        ref.refresh(analysisResultProvider(widget.selectedPath));
        if (mounted) { // Check mounted directly before using context
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${file.path.split('/').last} deleted.')),
          );
        }
      } catch (e) {
        if (mounted) { // Check mounted directly before using context
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete ${file.path.split('/').last}: $e')),
          );
        }
      }
    }
  }

  // Helper to format file size
  String _getFormattedSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    int i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final analysisResultAsync = ref.watch(analysisResultProvider(widget.selectedPath));

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedFiles.length} selected')
            : Text('Files with ${widget.extension.toUpperCase()}'), // Fixed string interpolation
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _selectedFiles.isNotEmpty ? _deleteSelectedFilesWrapper : null,
                ),
              ]
            : [],
      ),
      body: analysisResultAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: ${err.toString()}')),
        data: (categorizedFiles) {
          final filesForExtension = categorizedFiles[widget.extension] ?? [];

          if (filesForExtension.isEmpty) {
            return Center(
              child: Text('No files found for extension ${widget.extension.toUpperCase()}'), // Fixed string interpolation
            );
          }

          return ListView.builder(
            itemCount: filesForExtension.length,
            itemBuilder: (context, index) {
              final FileSystemEntity fileSystemEntity = filesForExtension[index];
              final isDirectory = fileSystemEntity is Directory;
              // For directories, we'll show 0 B for simplicity here. A more complex solution would recursively calculate directory size.
              final int size = isDirectory ? 0 : (fileSystemEntity as File).lengthSync();

              return ListTile(
                leading: Icon(isDirectory ? Icons.folder_outlined : Icons.insert_drive_file_outlined, color: Theme.of(context).colorScheme.secondary),
                title: Text(p.basename(fileSystemEntity.path)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(_getFormattedSize(size)),
                    const SizedBox(height: 4),
                    // if (percentage > 0.01) // percentage is not defined
                    //   LinearProgressIndicator(
                    //     value: percentage,
                    //     backgroundColor: Theme.of(context).colorScheme.surface.withAlpha(128),
                    //     valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                    //   ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete',
                  onPressed: () {
                    if (!isDirectory) { // Only allow deleting files, not directories directly from this button
                      _handleSingleFileDelete(fileSystemEntity as File);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Cannot delete directories directly from here.')),
                      );
                    }
                  },
                ),
                onTap: () async {
                  if (_isSelectionMode) {
                    _toggleFileSelection(fileSystemEntity.path);
                  } else {
                    // Open the file when tapped
                    final result = await OpenFilex.open(fileSystemEntity.path);
                    if (!mounted) return; // Check mounted directly
                    if (result.type != ResultType.done) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not open file: ${result.message}')),
                      );
                    }
                  }
                },
                onLongPress: () {
                  _toggleSelectionMode();
                  _toggleFileSelection(fileSystemEntity.path); // Select the file that was long-pressed
                },
              );
            },
          );
        },
      ),
    );
  }
}
