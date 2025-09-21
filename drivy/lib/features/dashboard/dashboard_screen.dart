import 'package:device_info_plus/device_info_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:storage_analyzer_pro/features/file_explorer/file_explorer_screen.dart';
import 'package:storage_analyzer_pro/core/providers/providers.dart';
import 'package:storage_analyzer_pro/features/dashboard/widgets/top_extensions_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  Future<void> _checkAndRequestPermissions() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    Permission permission;

    if (androidInfo.version.sdkInt >= 30) {
      permission = Permission.manageExternalStorage;
    } else {
      permission = Permission.storage;
    }

    final status = await permission.status;

    if (status.isDenied) {
      final newStatus = await permission.request();
      if (newStatus.isPermanentlyDenied) {
        _showPermissionDeniedDialog();
      }
    } else if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
            'Storage access is required to analyze files. Please enable it in the app settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _showStorageSelectionDialog(
      BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();
    final storagePathsAsync = ref.read(storagePathsProvider);

    final storagePaths = storagePathsAsync.when(
      data: (paths) => paths,
      loading: () => [],
      error: (e, s) => [],
    );

    if (!context.mounted) return;

    if (storagePaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No external storage found or permission denied.')),
      );
      return;
    }

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Storage Device'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: storagePaths.length,
            itemBuilder: (context, index) {
              final path = storagePaths[index];
              return ListTile(
                leading: const Icon(Icons.storage),
                title: Text(path),
                onTap: () => Navigator.of(context).pop(path),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );

    if (selected != null) {
      ref.read(selectedStoragePathProvider.notifier).state = selected;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedPath = ref.watch(selectedStoragePathProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Storage Analyzer Pro', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_special_outlined),
            onPressed: () => _showStorageSelectionDialog(context, ref),
            tooltip: 'Select Storage',
            color: colorScheme.onSurface,
          ),
        ],
      ),
      body: selectedPath == null
          ? _buildSelectStoragePrompt(context, textTheme, ref)
          : ref.watch(storageDataProvider(selectedPath)).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: ${err.toString()}')),
                data: (storageData) {
                  return SingleChildScrollView(
                    padding:
                        const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 96.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStorageOverviewCard(
                            context, storageData, textTheme, colorScheme),
                        const SizedBox(height: 24),
                        TopExtensionsCard(selectedPath: selectedPath), // Pass selectedPath to TopExtensionsCard
                      ],
                    ),
                  );
                },
              ),
      bottomNavigationBar: _buildBottomActionBar(context, ref, selectedPath),
    );
  }

  Widget _buildBottomActionBar(
      BuildContext context, WidgetRef ref, String? selectedPath) {
    final isEnabled = selectedPath != null;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
          16.0, 12.0, 16.0, 12.0 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.1).round()),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor.withAlpha((255 * 0.5).round()), width: 0.5)),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            onPressed: isEnabled
                ? () {
                    HapticFeedback.mediumImpact();
                    ref.refresh(storageDataProvider(selectedPath));
                  }
                : null,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              side: BorderSide(color: colorScheme.primary),
              foregroundColor: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton.icon(
              icon: const Icon(Icons.folder_open),
              label: const Text('Browse Files'),
              onPressed: isEnabled
                  ? () {
                      HapticFeedback.mediumImpact();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              FileExplorerScreen(path: selectedPath),
                        ),
                      );
                    }
                  : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectStoragePrompt(
      BuildContext context, TextTheme textTheme, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 8.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_special_outlined,
                    size: 80, color: colorScheme.primary),
                const SizedBox(height: 24),
                Text(
                  'Select a Storage Device',
                  style: textTheme.headlineSmall?.copyWith(color: colorScheme.onSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Tap the button below to choose a storage device to analyze.',
                  style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Select Storage'),
                  onPressed: () => _showStorageSelectionDialog(context, ref),
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStorageOverviewCard(BuildContext context, dynamic storageData,
      TextTheme textTheme, ColorScheme colorScheme) {
    final usedPercentage = storageData.totalSpace > 0
        ? (storageData.usedSpace / storageData.totalSpace) * 100
        : 0.0;

    return Card(
      elevation: 8.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Storage Overview', style: textTheme.headlineMedium?.copyWith(color: colorScheme.onSurface)),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 80,
                      startDegreeOffset: -90,
                      sections: [
                        PieChartSectionData(
                          value: storageData.usedSpace,
                          color: colorScheme.primary,
                          radius: 25,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          value: storageData.freeSpace,
                          color: colorScheme.secondary.withAlpha((255 * 0.6).round()),
                          radius: 25,
                          showTitle: false,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${usedPercentage.toStringAsFixed(1)}%',
                        style: textTheme.headlineLarge
                            ?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                      ),
                      Text('Used', style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSpaceInfo('Used',
                    '${storageData.usedSpace.toStringAsFixed(1)} GB', colorScheme.primary, textTheme),
                _buildSpaceInfo('Free',
                    '${storageData.freeSpace.toStringAsFixed(1)} GB',
                    colorScheme.secondary.withAlpha((255 * 0.6).round()),
                    textTheme),
                _buildSpaceInfo('Total',
                    '${storageData.totalSpace.toStringAsFixed(1)} GB',
                    colorScheme.onSurface,
                    textTheme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpaceInfo(
      String title, String value, Color color, TextTheme textTheme) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(title, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
      ],
    );
  }
}
