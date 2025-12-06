import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/injection.dart';
import '../../core/app_icons.dart';
import '../../core/constants.dart';
import '../../data/models/file_server_config_model.dart';
import '../../domain/entities/file_server_config.dart';
import '../../domain/entities/cloud_file.dart';
import 'file_viewer_page.dart';
import '../bloc/file_cubit.dart';
import '../bloc/file_state.dart';
import '../widgets/file_server_config_dialog.dart';
import '../widgets/file_gallery_grid.dart';
import '../widgets/file_list_item.dart';
import '../../../../widgets/primary_app_bar.dart';
import '../../../../widgets/loading_view.dart';
import '../../../../widgets/error_view.dart';

/// Main page for the File Tracker feature.
///
/// Displays files from a configured HTTPS file server in a gallery view
/// with filtering capabilities.
class FileTrackerHomePage extends StatefulWidget {
  const FileTrackerHomePage({super.key});

  @override
  State<FileTrackerHomePage> createState() => _FileTrackerHomePageState();
}

class _FileTrackerHomePageState extends State<FileTrackerHomePage> {
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = createFileCubit();
        _loadSavedConfig(cubit);
        return cubit;
      },
      child: Scaffold(
        appBar: PrimaryAppBar(
          title: 'File Tracker',
          actions: [
            IconButton(
              icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
              tooltip: _isGridView ? 'Switch to list view' : 'Switch to grid view',
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
              },
            ),
            Builder(
              builder: (builderContext) => IconButton(
                icon: const Icon(FileTrackerIcons.settings),
                tooltip: 'Configure server',
                onPressed: () => _showConfigDialog(builderContext),
              ),
            ),
            Builder(
              builder: (builderContext) => IconButton(
                icon: const Icon(FileTrackerIcons.refresh),
                tooltip: 'Refresh',
                onPressed: () {
                  builderContext.read<FileCubit>().refreshFiles();
                },
              ),
            ),
          ],
        ),
        body: BlocBuilder<FileCubit, FileState>(
          builder: (context, state) {
            if (state is FilesInitial) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      FileTrackerIcons.file,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text('No server configured'),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(FileTrackerIcons.settings),
                      label: const Text('Configure Server'),
                      onPressed: () => _showConfigDialog(context),
                    ),
                  ],
                ),
              );
            }

            if (state is FilesLoading) {
              return const LoadingView(message: 'Loading files...');
            }

            if (state is FilesError) {
              return ErrorView(
                message: state.message,
                onRetry: () {
                  final cubit = context.read<FileCubit>();
                  final config = cubit.currentConfig;
                  if (config != null) {
                    cubit.loadFiles(config);
                  } else {
                    _showConfigDialog(context);
                  }
                },
              );
            }

            if (state is FilesLoaded) {
              final files = state.files;
              final cubit = context.read<FileCubit>();

              // Show message if no files found (might be folders only or empty)
              if (files.isEmpty) {
                final canGoBack = state.currentPath != '/' && cubit.canNavigateBack();
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          FileTrackerIcons.file,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No images or videos found',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'The current directory may only contain folders.\n'
                          'File listings are loaded from the server\'s HTML.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 32),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          alignment: WrapAlignment.center,
                          children: [
                            // Go to Home button
                            ElevatedButton.icon(
                              icon: const Icon(Icons.home),
                              label: const Text('Go to Home'),
                              onPressed: () {
                                // Navigate to root
                                cubit.loadFiles(cubit.currentConfig!);
                              },
                            ),
                            // Go Back button (only if we can go back)
                            if (canGoBack)
                              OutlinedButton.icon(
                                icon: const Icon(Icons.arrow_back),
                                label: const Text('Go Back'),
                                onPressed: () {
                                  cubit.navigateBack();
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  // Current path and file count
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        // Breadcrumb navigation
                        if (state.currentPath != '/' && cubit.canNavigateBack())
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => cubit.navigateBack(),
                            tooltip: 'Go back',
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Path: ${state.currentPath}',
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${files.length} item${files.length != 1 ? 's' : ''}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Files list or grid
                  Expanded(
                    child: state.config != null
                        ? _isGridView
                            ? FileGalleryGrid(
                                files: files,
                                config: state.config!,
                                onFileTap: (file) {
                                  if (file.isFolder) {
                                    // Navigate into folder
                                    cubit.navigateToFolder(file);
                                  } else {
                                    // Open full-screen viewer
                                    _openFileViewer(context, file, files, state.config!);
                                  }
                                },
                              )
                            : ListView.builder(
                                itemCount: files.length,
                                itemBuilder: (context, index) {
                                  return FileListItem(
                                    file: files[index],
                                    config: state.config!,
                                    onTap: () {
                                      final file = files[index];
                                      if (file.isFolder) {
                                        // Navigate into folder
                                        cubit.navigateToFolder(file);
                                      } else {
                                        // Open full-screen viewer
                                        _openFileViewer(context, file, files, state.config!);
                                      }
                                    },
                                  );
                                },
                              )
                        : const Center(
                            child: Text('No server configuration'),
                          ),
                  ),
                ],
              );
            }

            return const Center(child: Text('Unknown state'));
          },
        ),
      ),
    );
  }

  Future<void> _showConfigDialog(BuildContext context) async {
    // Use BlocProvider.of to ensure we get the correct cubit
    final cubit = BlocProvider.of<FileCubit>(context);
    final currentConfig = cubit.currentConfig;

    final config = await showDialog<FileServerConfig>(
      context: context,
      builder: (dialogContext) => FileServerConfigDialog(
        initialConfig: currentConfig,
      ),
    );

    if (config != null && mounted) {
      // Save config to Hive
      await _saveConfig(config);
      // Load files with new config
      cubit.loadFiles(config);
    }
  }

  Future<void> _saveConfig(FileServerConfig config) async {
    try {
      if (Hive.isBoxOpen(fileTrackerConfigBoxName)) {
        final box = Hive.box<FileServerConfigModel>(fileTrackerConfigBoxName);
        final model = FileServerConfigModel.fromEntity(config);
        await box.put('config', model);
      }
    } catch (e) {
      // Failed to save config
    }
  }

  void _openFileViewer(
    BuildContext context,
    CloudFile file,
    List<CloudFile> allFiles,
    FileServerConfig config,
  ) {
    // Filter to only image/video files
    final mediaFiles = allFiles.where((f) => f.isImage || f.isVideo).toList();
    
    if (mediaFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No images or videos to display')),
      );
      return;
    }

    // Find the index of the tapped file
    final index = mediaFiles.indexWhere((f) => f.url == file.url);
    if (index == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File not found')),
      );
      return;
    }

    // Navigate to viewer page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FileViewerPage(
          files: mediaFiles,
          initialIndex: index,
          config: config,
        ),
      ),
    );
  }
}

/// Helper function to load saved config
Future<void> _loadSavedConfig(FileCubit cubit) async {
  try {
    if (Hive.isBoxOpen(fileTrackerConfigBoxName)) {
      final box = Hive.box<FileServerConfigModel>(fileTrackerConfigBoxName);
      final model = box.get('config');
      if (model != null) {
        final config = model.toEntity();
        cubit.loadFiles(config);
      }
    }
  } catch (e) {
    // Failed to load saved config
  }
}

