import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storage_analyzer_pro/features/analysis/analysis_provider.dart';
import 'package:storage_analyzer_pro/features/analysis/file_categorizer.dart'; // Import ExtensionSummary
import 'package:storage_analyzer_pro/features/analysis/file_detail_screen.dart'; // Import the new screen

class TopExtensionsCard extends ConsumerWidget {
  final String selectedPath;

  const TopExtensionsCard({super.key, required this.selectedPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extensionSummariesAsync = ref.watch(extensionSummaryProvider(selectedPath));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top 10 Extensions by Size',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            extensionSummariesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: ${err.toString()}')),
              data: (summaries) {
                if (summaries.isEmpty) {
                  return const Center(child: Text('No files found or storage is empty.'));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: summaries.length,
                  itemBuilder: (context, index) {
                    final summary = summaries[index];
                    return ExtensionTile(
                      summary: summary,
                      onTap: () {
                        // Implement navigation to a detailed file list screen
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => FileDetailScreen(
                              extension: summary.extension,
                              selectedPath: selectedPath, // Pass selectedPath here
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ExtensionTile extends StatelessWidget {
  const ExtensionTile({
    super.key,
    required this.summary,
    required this.onTap,
  });

  final ExtensionSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            // Icon for the extension (can be improved with specific icons later)
            const Icon(Icons.insert_drive_file),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '.${summary.extension}',
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${summary.fileCount} files - ${summary.formattedSize}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
