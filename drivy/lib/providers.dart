import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storage_analyzer_pro/data/storage_repository.dart';
import 'package:storage_analyzer_pro/storage_utils.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint

// --- Global Refresh Signal ---
// A simple provider that acts as a global trigger for data refreshes.
// When its state is updated, any provider watching it will be re-evaluated.
final fileSystemChangeProvider = StateProvider<int>((ref) => 0);

// --- Repository Provider ---
final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return RealStorageRepository();
});

// --- Path Providers ---
final storagePathsProvider = FutureProvider<List<String>>((ref) async {
  debugPrint('Providers: storagePathsProvider - fetching paths...');
  ref.watch(fileSystemChangeProvider);
  final paths = await StorageUtils.getStoragePaths();
  debugPrint('Providers: storagePathsProvider - found paths: $paths');
  return paths;
});

final selectedStoragePathProvider = StateProvider<String?>((ref) {
  debugPrint('Providers: selectedStoragePathProvider - evaluating...');
  final paths = ref.watch(storagePathsProvider);
  return paths.when(
    data: (data) {
      final selected = data.isNotEmpty ? data[0] : null;
      debugPrint('Providers: selectedStoragePathProvider - selected: $selected');
      return selected;
    },
    error: (e, s) {
      debugPrint('Providers: selectedStoragePathProvider - error: $e');
      return null;
    },
    loading: () {
      debugPrint('Providers: selectedStoragePathProvider - loading...');
      return null;
    },
  );
});

// --- Data Providers (Now listening to the global refresh signal) ---

// Fetches the overall storage data for the dashboard.
final storageDataProvider = FutureProvider.family<StorageData, String>((ref, path) {
  debugPrint('Providers: storageDataProvider for path: $path');
  ref.watch(fileSystemChangeProvider);
  final repository = ref.watch(storageRepositoryProvider);
  return repository.getStorageData(path);
});

// Fetches the contents of a specific directory for the file explorer.
final fileExplorerProvider =
    FutureProvider.family<List<FileSystemEntityInfo>, String>((ref, path) async {
  debugPrint('Providers: fileExplorerProvider for path: $path - START');
  ref.watch(fileSystemChangeProvider);
  final repository = ref.watch(storageRepositoryProvider);
  final contents = await repository.getDirectoryContents(path);
  debugPrint('Providers: fileExplorerProvider for path: $path - END. Found ${contents.length} items.');
  return contents;
});
