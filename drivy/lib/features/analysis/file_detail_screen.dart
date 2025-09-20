import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storage_analyzer_pro/features/analysis/analysis_provider.dart';
import 'package:storage_analyzer_pro/features/analysis/file_categorizer.dart'; // For ExtensionSummary and FileSystemEntityInfo
import 'package:open_filex/open_filex.dart'; // Import open_filex

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

  Future<void> _deleteSelectedFiles() async {
    final bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete ${_selectedFiles.length} selected files?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },\n    ) ?? false;

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete $filePath: $e')),
          );
        }
      }
      // Invalidate the provider to trigger a refresh of the file list
      ref.refresh(analysisResultProvider(widget.selectedPath));
      setState(() {
        _selectedFiles.clear();
        _isSelectionMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$deletedCount files deleted.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysisResultAsync = ref.watch(analysisResultProvider(widget.selectedPath));

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedFiles.length} selected')
            : Text('Files with '.toUpperCase() + '.' + widget.extension.toUpperCase()),
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
                  onPressed: _selectedFiles.isNotEmpty ? _deleteSelectedFiles : null,
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
              child: Text('No files found for extension '.toUpperCase() + '.' + widget.extension.toUpperCase()),
            );
          }

          return ListView.builder(
            itemCount: filesForExtension.length,
            itemBuilder: (context, index) {
              final file = filesForExtension[index];
              final isSelected = _selectedFiles.contains(file.path);
              return ListTile(
                leading: _isSelectionMode
                    ? Checkbox(
                        value: isSelected,
                        onChanged: (bool? value) {
                          _toggleFileSelection(file.path);
                        },
                      )
                    : const Icon(Icons.insert_drive_file),
                title: Text(file.path.split('/').last), // Display file name
                subtitle: Text(file.path), // Display full path as subtitle
                onTap: () async {
                  if (_isSelectionMode) {
                    _toggleFileSelection(file.path);
                  } else {
                    // Open the file when tapped
                    final result = await OpenFilex.open(file.path);
                    if (result.type != ResultType.done) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not open file: ${result.message}')),
                      );
                    }
                  }
                },
                onLongPress: () {
                  _toggleSelectionMode();
                  _toggleFileSelection(file.path); // Select the file that was long-pressed
                },
                trailing: _isSelectionMode
                    ? null // Hide single delete button in selection mode
                    : IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final bool confirmDelete = await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Confirm Delete'),
                                content: Text('Are you sure you want to delete ${file.path.split('/').last}?'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${file.path.split('/').last} deleted.')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to delete ${file.path.split('/').last}: $e')),
                              );
                            }
                          }
                        },
                      ),
              );
            },
          );
        },
      ),
    );
  }
}
