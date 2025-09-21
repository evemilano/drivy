import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storage_analyzer_pro/data/storage_repository.dart';
import 'package:storage_analyzer_pro/core/utils/storage_utils.dart';

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
  ref.watch(fileSystemChangeProvider);
  final paths = await StorageUtils.getStoragePaths();
  return paths;
});

final selectedStoragePathProvider = StateProvider<String?>((ref) {
  final paths = ref.watch(storagePathsProvider);
  return paths.when(
    data: (data) {
      final selected = data.isNotEmpty ? data[0] : null;
      return selected;
    },
    error: (e, s) {
      return null;
    },
    loading: () {
      return null;
    },
  );
});

// --- Data Providers (Now listening to the global refresh signal) ---

// Fetches the overall storage data for the dashboard.
final storageDataProvider = FutureProvider.family<StorageData, String>((ref, path) {
  ref.watch(fileSystemChangeProvider);
  final repository = ref.watch(storageRepositoryProvider);
  return repository.getStorageData(path);
});

// Fetches the contents of a specific directory for the file explorer.
final fileExplorerProvider =
    FutureProvider.family<List<FileSystemEntityInfo>, String>((ref, path) async {
  ref.watch(fileSystemChangeProvider);
  final repository = ref.watch(storageRepositoryProvider);
  final contents = await repository.getDirectoryContents(path);
  return contents;
});
