import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/injection.dart';
import '../../core/app_icons.dart';
import '../../data/services/file_server_config_service.dart';
import '../../domain/entities/file_server_config.dart';
import '../../domain/entities/cloud_file.dart';
import '../../domain/entities/file_metadata.dart';
import 'file_viewer_page.dart';
import '../bloc/file_cubit.dart';
import '../bloc/file_state.dart';
import '../widgets/file_server_config_dialog.dart';
import '../widgets/file_gallery_grid.dart';
import '../widgets/file_list_item.dart';
import '../widgets/file_tag_editor_dialog.dart';
import '../widgets/bulk_tag_editor_dialog.dart';
import '../../../../widgets/primary_app_bar.dart';
import '../../../../widgets/loading_view.dart';
import '../../../../widgets/error_view.dart';
import '../../../../widgets/app_drawer.dart';
import '../../../../widgets/bottom_sheet_helpers.dart';
import '../../../../pages/app_home_page.dart';
import 'package:provider/provider.dart';
import '../../../../core/organization_notifier.dart';

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
  final _configService = FileServerConfigService();
  String? _currentServerName;
  bool _isLoadingConfig = true;
  bool _isMultiSelectMode = false;
  final Set<String> _selectedFileIds = {}; // Store stable identifiers of selected files
  final Set<String> _selectedFilterTags = {}; // Tags selected for filtering
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = createFileCubit();
        // Load saved config after first frame when cubit is available
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadSavedConfig(cubit);
        });
        return cubit;
      },
      child: Scaffold(
        drawer: const AppDrawer(currentPage: AppPage.fileTracker),
        appBar: PrimaryAppBar(
          title: _currentServerName != null 
              ? 'File Tracker - $_currentServerName'
              : 'File Tracker',
          actions: [
            Consumer<OrganizationNotifier>(
              builder: (context, orgNotifier, _) {
                // Only show home icon if default home page is app_home
                if (orgNotifier.defaultHomePage == 'app_home') {
                  return IconButton(
                    tooltip: 'Home Page',
                    icon: const Icon(Icons.home),
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AppHomePage()),
                        (route) => false,
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            BlocBuilder<FileCubit, FileState>(
              builder: (context, state) {
            if (state is FilesInitial) {
              // Show loading while checking for saved config
              if (_isLoadingConfig) {
                return const LoadingView(message: 'Loading server configuration...');
              }
              
              // Show "No server configured" only if config loading is complete and no config found
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
                onRetry: () async {
                  final cubit = context.read<FileCubit>();
                  var config = cubit.currentConfig;
                  
                  // If no config in cubit, try to load from config service
                  if (config == null) {
                    try {
                      final activeConfig = await _configService.getActiveConfig();
                      if (activeConfig != null) {
                        config = activeConfig;
                        if (mounted) {
                          setState(() {
                            _currentServerName = activeConfig.serverName;
                          });
                        }
                      }
                    } catch (e) {
                      // Failed to load config
                    }
                  }
                  
                  if (config != null) {
                    cubit.loadFiles(config);
                  } else {
                    _showConfigDialog(context);
                  }
                },
              );
            }

            if (state is FilesLoaded) {
              var files = state.files;
              final cubit = context.read<FileCubit>();
              
              // Get metadata for all files
              final metadataMap = <String, FileMetadata>{};
              for (final file in files) {
                final metadata = cubit.getMetadataForFile(file);
                if (metadata != null) {
                  metadataMap[file.stableIdentifier] = metadata;
                }
              }

              // Filter files by selected tags
              if (_selectedFilterTags.isNotEmpty) {
                files = files.where((file) {
                  final metadata = metadataMap[file.stableIdentifier];
                  if (metadata == null || metadata.tags.isEmpty) {
                    return false; // Files without tags don't match
                  }
                  // File must have at least one of the selected tags
                  return metadata.tags.any((tag) => _selectedFilterTags.contains(tag));
                }).toList();
              }

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
                  // Current path and file count / Multi-select toolbar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _isMultiSelectMode
                        ? Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _isMultiSelectMode = false;
                                    _selectedFileIds.clear();
                                  });
                                },
                                tooltip: 'Cancel selection',
                              ),
                              Expanded(
                                child: Text(
                                  '${_selectedFileIds.length} file${_selectedFileIds.length != 1 ? 's' : ''} selected',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              if (_selectedFileIds.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.label),
                                  onPressed: () => _showBulkTagEditor(context, cubit),
                                  tooltip: 'Edit metadata for selected files',
                                ),
                            ],
                          )
                        : Row(
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
                                    Row(
                                      children: [
                                        Text(
                                          '${files.length} item${files.length != 1 ? 's' : ''}',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                        if (_selectedFilterTags.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            '(filtered)',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    // Show active filter tags
                                    if (_selectedFilterTags.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                        children: _selectedFilterTags.map((tag) {
                                          return Chip(
                                            label: Text(tag),
                                            onDeleted: () {
                                              setState(() {
                                                _selectedFilterTags.remove(tag);
                                              });
                                            },
                                            deleteIcon: const Icon(Icons.close, size: 18),
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            visualDensity: VisualDensity.compact,
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.checklist),
                                onPressed: () {
                                  setState(() {
                                    _isMultiSelectMode = true;
                                    _selectedFileIds.clear();
                                  });
                                },
                                tooltip: 'Select files',
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
                                fileMetadata: metadataMap,
                                isMultiSelectMode: _isMultiSelectMode,
                                selectedFileIds: _selectedFileIds,
                                onFileTap: (file) {
                                  if (_isMultiSelectMode) {
                                    if (!file.isFolder) {
                                      setState(() {
                                        if (_selectedFileIds.contains(file.stableIdentifier)) {
                                          _selectedFileIds.remove(file.stableIdentifier);
                                        } else {
                                          _selectedFileIds.add(file.stableIdentifier);
                                        }
                                      });
                                    }
                                  } else {
                                    if (file.isFolder) {
                                      // Navigate into folder
                                      cubit.navigateToFolder(file);
                                    } else {
                                      // Open full-screen viewer
                                      _openFileViewer(context, file, files, state.config!);
                                    }
                                  }
                                },
                                onFileLongPress: (file) {
                                  if (!file.isFolder) {
                                    if (_isMultiSelectMode) {
                                      setState(() {
                                        if (_selectedFileIds.contains(file.stableIdentifier)) {
                                          _selectedFileIds.remove(file.stableIdentifier);
                                        } else {
                                          _selectedFileIds.add(file.stableIdentifier);
                                        }
                                      });
                                    } else {
                                      _showTagEditor(context, file, cubit);
                                    }
                                  }
                                },
                              )
                            : ListView.builder(
                                itemCount: files.length,
                                itemBuilder: (context, index) {
                                  final file = files[index];
                                  final isSelected = _selectedFileIds.contains(file.stableIdentifier);
                                  return FileListItem(
                                    file: file,
                                    config: state.config!,
                                    metadata: metadataMap[file.stableIdentifier],
                                    isMultiSelectMode: _isMultiSelectMode,
                                    isSelected: isSelected,
                                    onTap: () {
                                      if (_isMultiSelectMode) {
                                        if (!file.isFolder) {
                                          setState(() {
                                            if (isSelected) {
                                              _selectedFileIds.remove(file.stableIdentifier);
                                            } else {
                                              _selectedFileIds.add(file.stableIdentifier);
                                            }
                                          });
                                        }
                                      } else {
                                        if (file.isFolder) {
                                          // Navigate into folder
                                          cubit.navigateToFolder(file);
                                        } else {
                                          // Open full-screen viewer
                                          _openFileViewer(context, file, files, state.config!);
                                        }
                                      }
                                    },
                                    onLongPress: () {
                                      if (!file.isFolder) {
                                        if (_isMultiSelectMode) {
                                          setState(() {
                                            if (isSelected) {
                                              _selectedFileIds.remove(file.stableIdentifier);
                                            } else {
                                              _selectedFileIds.add(file.stableIdentifier);
                                            }
                                          });
                                        } else {
                                          _showTagEditor(context, file, cubit);
                                        }
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
          ],
        ),
        floatingActionButton: Builder(
          builder: (builderContext) => Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // First row: File options and Server configuration (both with dns icons)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // File options button (dns icon with settings overlay)
                  Builder(
                    builder: (fabContext) => FloatingActionButton.small(
                      heroTag: 'fileOptionsFab',
                      tooltip: 'File Options',
                      backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
                      onPressed: () => _showFileOptionsBottomSheet(fabContext),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            Icons.dns,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.settings,
                                size: 12,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Server configuration button
                  Builder(
                    builder: (fabContext) => FloatingActionButton.small(
                      heroTag: 'serverConfigFab',
                      tooltip: _currentServerName != null ? 'Edit Server Configuration' : 'Add Server Configuration',
                      backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
                      onPressed: () => _showCurrentServerConfigForm(fabContext),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            Icons.dns,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          if (_currentServerName != null)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.edit,
                                  size: 12,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Second row: Filter and View toggle
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Filter button
                  Builder(
                    builder: (filterContext) {
                      final filterCubit = filterContext.read<FileCubit>();
                      return FloatingActionButton.small(
                        heroTag: 'filterFab',
                        tooltip: 'Filter by tags',
                        backgroundColor: _selectedFilterTags.isNotEmpty
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
                        onPressed: () => _showFilterBottomSheet(filterContext, filterCubit),
                        child: Icon(
                          Icons.filter_list,
                          color: _selectedFilterTags.isNotEmpty
                              ? Theme.of(context).colorScheme.onPrimary
                              : null,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  // View toggle button
                  _ActionsFab(
                    isGridView: _isGridView,
                    onToggleView: () {
                      setState(() {
                        _isGridView = !_isGridView;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Future<void> _showConfigDialog(BuildContext context) async {
    // Use BlocProvider.of to ensure we get the correct cubit
    final cubit = BlocProvider.of<FileCubit>(context);
    final currentConfig = cubit.currentConfig;

    final config = await FileServerConfigDialog.show(
      context,
      currentConfig,
    );

    if (config != null && mounted) {
      // Save config using the service
      await _configService.saveConfig(config);
      // Set as active server
      await _configService.setActiveServerName(config.serverName);
      setState(() {
        _currentServerName = config.serverName;
      });
      // Load files with new config
      cubit.loadFiles(config);
    }
  }

  Future<void> _showServerSelectionDialog(BuildContext context) async {
    final cubit = BlocProvider.of<FileCubit>(context);
    final allConfigs = await _configService.getAllConfigs();
    
    if (allConfigs.isEmpty) {
      // No servers configured, show config bottom sheet instead
      _showConfigDialog(context);
      return;
    }
    
    final selectedConfig = await showAppBottomSheet<FileServerConfig>(
      context,
      _ServerSelectionBottomSheet(
        allConfigs: allConfigs,
        currentServerName: _currentServerName,
        onAddNew: () {
          Navigator.of(context).pop();
          // Use widget's context via Builder
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showAddServerDialog(this.context);
            }
          });
        },
        onEdit: (config) async {
          // Close the server selection sheet first
          Navigator.of(context).pop();
          // Wait a frame to ensure the sheet is closed
          await Future.delayed(const Duration(milliseconds: 100));
          // Use widget's context via Builder
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showEditServerDialog(this.context, config);
            }
          });
        },
        onDelete: (config) async {
          print('[FILE_TRACKER] Delete callback called for server: ${config.serverName}');
          print('[FILE_TRACKER] Widget mounted: $mounted');
          
          // Store config before closing bottom sheet
          final configToDelete = config;
          
          // Close the server selection sheet first
          print('[FILE_TRACKER] Popping server selection bottom sheet...');
          Navigator.of(context).pop();
          
          // Wait a frame to ensure the sheet is closed
          await Future.delayed(const Duration(milliseconds: 200));
          
          print('[FILE_TRACKER] After delay, mounted: $mounted');
          // Use widget's context via Builder to ensure we have a valid context
          WidgetsBinding.instance.addPostFrameCallback((_) {
            print('[FILE_TRACKER] In postFrameCallback, mounted: $mounted');
            // Get context from scaffold key if available, otherwise use current context
            final scaffoldContext = _scaffoldKey.currentContext;
            if (scaffoldContext != null) {
              print('[FILE_TRACKER] Using scaffold context for delete dialog');
              _showDeleteServerDialog(scaffoldContext, configToDelete);
            } else if (mounted) {
              print('[FILE_TRACKER] Scaffold context not available, using mounted context');
              // Try to get context from the widget tree
              _showDeleteServerDialog(context, configToDelete);
            } else {
              print('[FILE_TRACKER] No valid context available, skipping delete dialog');
            }
          });
        },
      ),
    );

    if (selectedConfig != null && mounted) {
      await _configService.setActiveServerName(selectedConfig.serverName);
      setState(() {
        _currentServerName = selectedConfig.serverName;
      });
      cubit.loadFiles(selectedConfig);
    }
  }

  Future<void> _showAddServerDialog(BuildContext context) async {
    final config = await FileServerConfigDialog.show(
      context,
      null,
    );

    if (config != null && mounted) {
      await _configService.saveConfig(config);
      await _configService.setActiveServerName(config.serverName);
      setState(() {
        _currentServerName = config.serverName;
      });
      final cubit = BlocProvider.of<FileCubit>(context);
      cubit.loadFiles(config);
    }
  }

  Future<void> _showFileOptionsBottomSheet(BuildContext context) async {
    await showAppBottomSheet<void>(
      context,
      _FileOptionsBottomSheet(
        onFileConfiguration: () {
          Navigator.of(context).pop();
          _showServerSelectionDialog(context);
        },
        onRefresh: () {
          Navigator.of(context).pop();
          context.read<FileCubit>().refreshFiles();
        },
      ),
    );
  }

  Future<void> _showCurrentServerConfigForm(BuildContext context) async {
    // Get the current active server config
    final currentConfig = await _configService.getActiveConfig();
    
    if (currentConfig != null) {
      // If there's a current server, open edit form dialog
      await _showEditServerDialog(context, currentConfig);
    } else {
      // If no current server, open server selection (which will show add dialog if no servers exist)
      await _showServerSelectionDialog(context);
    }
  }

  Future<void> _showEditServerDialog(BuildContext context, FileServerConfig config) async {
    final updatedConfig = await FileServerConfigDialog.show(
      context,
      config,
      onDelete: () {
        // Use post-frame callback to ensure config dialog is fully closed
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Get fresh context after dialog is closed
            final scaffoldContext = _scaffoldKey.currentContext ?? context;
            _showDeleteServerDialog(scaffoldContext, config);
          }
        });
      },
    );

    if (updatedConfig != null && mounted) {
      try {
        final oldServerName = config.serverName;
        final newServerName = updatedConfig.serverName;
        final wasActive = _currentServerName == oldServerName;
        
        // If server name changed, delete the old entry first
        if (oldServerName != newServerName) {
          await _configService.deleteConfig(oldServerName);
          // Verify old entry is deleted
          final oldConfig = await _configService.getConfig(oldServerName);
          if (oldConfig != null) {
            throw Exception('Old server entry still exists after deletion');
          }
        }
        
        // Save the updated config (with potentially new server name)
        await _configService.saveConfig(updatedConfig);
        
        // Verify the config was saved
        final savedConfig = await _configService.getConfig(newServerName);
        if (savedConfig == null) {
          throw Exception('Failed to save server configuration');
        }
        
        // Update active server name if it was the active server
        if (wasActive) {
          await _configService.setActiveServerName(newServerName);
          if (mounted) {
            setState(() {
              _currentServerName = newServerName;
            });
            // Reload files with updated config
            final cubit = BlocProvider.of<FileCubit>(context);
            cubit.loadFiles(updatedConfig);
          }
        }
        
        // Show success message
        if (mounted) {
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Server "${newServerName}" updated successfully'),
                duration: const Duration(seconds: 2),
              ),
            );
          } catch (_) {
            // Context might be invalid, ignore
          }
        }
      } catch (e) {
        if (mounted) {
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update server: $e')),
            );
          } catch (_) {
            // Context might be invalid, ignore
          }
        }
      }
    }
  }

  Future<void> _showDeleteServerDialog(BuildContext context, FileServerConfig config) async {
    print('[FILE_TRACKER] _showDeleteServerDialog called');
    print('[FILE_TRACKER] Server to delete: ${config.serverName}');
    print('[FILE_TRACKER] Widget mounted: $mounted');
    print('[FILE_TRACKER] Context: $context');
    
    if (!mounted) {
      print('[FILE_TRACKER] Widget not mounted, returning early');
      return;
    }
    
    // Store the server name before showing dialog
    final serverNameToDelete = config.serverName;
    
    print('[FILE_TRACKER] Showing delete confirmation bottom sheet...');
    // Use showAppBottomSheet to match other dialogs and prevent navigation issues
    // The context passed should be the parent context (from the widget, not from closed bottom sheet)
    final confirm = await showAppBottomSheet<bool>(
      context,
      _DeleteServerBottomSheet(serverName: serverNameToDelete),
    );

    print('[FILE_TRACKER] Delete confirmation result: $confirm');
    print('[FILE_TRACKER] Widget still mounted: $mounted');

    // Only proceed if user confirmed
    if (confirm != true) {
      print('[FILE_TRACKER] Delete cancelled by user, returning');
      return;
    }
    
    print('[FILE_TRACKER] Proceeding with delete operation...');
    print('[FILE_TRACKER] Re-checking mounted state: $mounted');

    // Perform delete operation - wrap in try-catch to prevent navigation issues
    try {
      print('[FILE_TRACKER] Calling deleteConfig for: $serverNameToDelete');
      // Simply delete the server configuration (no checks, just delete)
      await _configService.deleteConfig(serverNameToDelete);
      print('[FILE_TRACKER] deleteConfig completed successfully');
      
      // Check if we deleted the active server and handle accordingly
      // Use scaffold context if available, otherwise use passed context
      final scaffoldContext = _scaffoldKey.currentContext ?? context;
      print('[FILE_TRACKER] Using scaffold context: ${_scaffoldKey.currentContext != null}');
      
      // Try to update UI - check mounted but don't fail if false
      try {
        print('[FILE_TRACKER] Checking active server...');
        print('[FILE_TRACKER] Getting active server name...');
        final activeName = await _configService.getActiveServerName();
        print('[FILE_TRACKER] Active server name: $activeName');
        print('[FILE_TRACKER] Server to delete: $serverNameToDelete');
        
        if (activeName == serverNameToDelete) {
          print('[FILE_TRACKER] Deleted server was active, switching to another...');
          // Deleted the active server, load first available or show empty state
          final allConfigs = await _configService.getAllConfigs();
          print('[FILE_TRACKER] Remaining configs: ${allConfigs.length}');
          
          if (allConfigs.isNotEmpty) {
            print('[FILE_TRACKER] Switching to first available server: ${allConfigs.first.serverName}');
            // Switch to the first available server
            await _configService.setActiveServerName(allConfigs.first.serverName);
            print('[FILE_TRACKER] Updating state and loading files...');
            // Use post-frame callback to ensure widget is still in tree
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                // Get fresh context inside callback
                final validContext = _scaffoldKey.currentContext ?? context;
                setState(() {
                  _currentServerName = allConfigs.first.serverName;
                  _isLoadingConfig = false;
                });
                // Only access BlocProvider if widget is still mounted
                try {
                  final cubit = BlocProvider.of<FileCubit>(validContext);
                  cubit.loadFiles(allConfigs.first);
                  print('[FILE_TRACKER] Files loaded for new server');
                } catch (e) {
                  print('[FILE_TRACKER] Could not access cubit to load files: $e');
                }
              } else {
                print('[FILE_TRACKER] Widget not mounted, skipping server switch');
              }
            });
          } else {
            print('[FILE_TRACKER] No servers left, clearing active server');
            // No servers left, clear the active server
            await _configService.setActiveServerName(null);
            print('[FILE_TRACKER] Resetting cubit...');
            // Use post-frame callback to ensure widget is still in tree
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                // Get fresh context inside callback
                final validContext = _scaffoldKey.currentContext ?? context;
                setState(() {
                  _currentServerName = null;
                  _isLoadingConfig = false; // Ensure empty state is shown
                });
                // Only access BlocProvider if widget is still mounted
                try {
                  final cubit = BlocProvider.of<FileCubit>(validContext);
                  // Reset to initial state
                  cubit.reset();
                  print('[FILE_TRACKER] Cubit reset complete');
                } catch (e) {
                  print('[FILE_TRACKER] Could not access cubit to reset: $e');
                }
              } else {
                print('[FILE_TRACKER] Widget not mounted, skipping state update');
              }
            });
          }
        } else {
          print('[FILE_TRACKER] Deleted server was not active, no switch needed');
        }
        
        // Show success message only if widget is still mounted
        if (mounted) {
          print('[FILE_TRACKER] Showing success message...');
          try {
            final validContext = _scaffoldKey.currentContext ?? context;
            ScaffoldMessenger.of(validContext).showSnackBar(
              SnackBar(
                content: Text('Server "$serverNameToDelete" deleted successfully'),
                duration: const Duration(seconds: 2),
              ),
            );
            print('[FILE_TRACKER] Success message shown');
          } catch (e) {
            print('[FILE_TRACKER] Could not show success message: $e');
          }
        } else {
          print('[FILE_TRACKER] Widget not mounted, skipping success message');
        }
      } catch (e, stackTrace) {
        print('[FILE_TRACKER] ERROR handling active server: $e');
        print('[FILE_TRACKER] Stack trace: $stackTrace');
        // Error handling active server, but deletion succeeded
        // Just show a message
        try {
          ScaffoldMessenger.of(scaffoldContext).showSnackBar(
            SnackBar(
              content: Text('Server deleted, but error updating active server: $e'),
              duration: const Duration(seconds: 3),
            ),
          );
        } catch (_) {
          print('[FILE_TRACKER] Could not show error message');
        }
      }
    } catch (e, stackTrace) {
      print('[FILE_TRACKER] ERROR during delete operation: $e');
      print('[FILE_TRACKER] Stack trace: $stackTrace');
      // Handle error - show message to user, but don't let it cause navigation
      final scaffoldContext = _scaffoldKey.currentContext ?? context;
      try {
        print('[FILE_TRACKER] Showing error message...');
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            content: Text('Failed to delete server: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      } catch (err) {
        print('[FILE_TRACKER] Could not show error message: $err');
      }
    }
    
    print('[FILE_TRACKER] _showDeleteServerDialog completed');
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

  /// Helper function to load saved config
  Future<void> _loadSavedConfig(FileCubit cubit) async {
    if (!mounted) return;
    try {
      final activeConfig = await _configService.getActiveConfig();
      if (mounted) {
        setState(() {
          _isLoadingConfig = false;
          if (activeConfig != null) {
            _currentServerName = activeConfig.serverName;
            cubit.loadFiles(activeConfig);
          }
        });
      }
    } catch (e) {
      // Failed to load saved config
      if (mounted) {
        setState(() {
          _isLoadingConfig = false;
        });
      }
    }
  }

  /// Shows the tag editor dialog for a file
  Future<void> _showTagEditor(BuildContext context, CloudFile file, FileCubit cubit) async {
    if (!mounted) return;
    
    try {
      await FileTagEditorDialog.show(context, file, cubit);
      // Refresh the UI to show updated tags
      if (mounted) {
        setState(() {
          // Trigger rebuild to show updated tags
        });
      }
    } catch (e) {
      // Error showing tag editor - ignore
    }
  }

  Future<void> _showBulkTagEditor(BuildContext context, FileCubit cubit) async {
    if (_selectedFileIds.isEmpty) return;
    
    final result = await BulkTagEditorDialog.show(
      context,
      _selectedFileIds.toList(),
      cubit,
    );
    
    if (result == true && mounted) {
      // Refresh UI to show updated tags
      setState(() {
        _isMultiSelectMode = false;
        _selectedFileIds.clear();
      });
      // Trigger a refresh to show updated tags
      cubit.refreshFiles();
    }
  }

  Future<void> _showFilterBottomSheet(BuildContext context, FileCubit cubit) async {
    // Get all available tags from all files
    final allTags = <String>{};
    final currentState = cubit.state;
    if (currentState is FilesLoaded) {
      final files = currentState.files;
      for (final file in files) {
        final metadata = cubit.getMetadataForFile(file);
        if (metadata != null && metadata.tags.isNotEmpty) {
          allTags.addAll(metadata.tags);
        }
      }
    }

    final selectedTags = await showAppBottomSheet<Set<String>>(
      context,
      _FilterBottomSheet(
        availableTags: allTags.toList()..sort(),
        selectedTags: Set<String>.from(_selectedFilterTags),
      ),
    );

    if (selectedTags != null && mounted) {
      setState(() {
        _selectedFilterTags.clear();
        _selectedFilterTags.addAll(selectedTags);
      });
    }
  }
}

/// ---------------------------------------------------------------------------
/// _ActionsFab
///
/// Floating action button group for file tracker actions.
/// Similar to goal tracker's _ActionsFab pattern.
/// ---------------------------------------------------------------------------
class _ActionsFab extends StatelessWidget {
  const _ActionsFab({
    required this.isGridView,
    required this.onToggleView,
  });

  final bool isGridView;
  final VoidCallback onToggleView;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return FloatingActionButton.small(
      heroTag: 'viewToggleFab',
      tooltip: isGridView ? 'Switch to list view' : 'Switch to grid view',
      backgroundColor: cs.surface.withValues(alpha: 0.85),
      onPressed: onToggleView,
      child: Icon(isGridView ? Icons.list : Icons.grid_view),
    );
  }
}

/// Server selection bottom sheet widget.
class _ServerSelectionBottomSheet extends StatelessWidget {
  final List<FileServerConfig> allConfigs;
  final String? currentServerName;
  final VoidCallback onAddNew;
  final Function(FileServerConfig) onEdit;
  final Function(FileServerConfig) onDelete;

  const _ServerSelectionBottomSheet({
    required this.allConfigs,
    required this.currentServerName,
    required this.onAddNew,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Server',
                style: textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Server list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: allConfigs.length + 1, // +1 for "Add New" option
              itemBuilder: (context, index) {
                if (index == allConfigs.length) {
                  return ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Add New Server'),
                    onTap: () {
                      onAddNew();
                    },
                  );
                }
                
                final config = allConfigs[index];
                final isActive = config.serverName == currentServerName;
                
                return ListTile(
                  leading: Icon(
                    isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isActive ? cs.primary : null,
                  ),
                  title: Text(config.serverName),
                  subtitle: Text(
                    config.baseUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // trailing: PopupMenuButton(
                  //   itemBuilder: (popupContext) => [
                  //     PopupMenuItem(
                  //       child: const Text('Edit'),
                  //       onTap: () async {
                  //         Navigator.of(popupContext).pop();
                  //         // Small delay to ensure popup menu closes
                  //         await Future.delayed(const Duration(milliseconds: 100));
                  //         onEdit(config);
                  //       },
                  //     ),
                  //     PopupMenuItem(
                  //       child: const Text('Delete'),
                  //       onTap: () async {
                  //         print('[FILE_TRACKER] PopupMenu Delete tapped for: ${config.serverName}');
                  //         print('[FILE_TRACKER] Popping popup menu...');
                  //         Navigator.of(popupContext).pop();
                  //         // Small delay to ensure popup menu closes
                  //         await Future.delayed(const Duration(milliseconds: 100));
                  //         print('[FILE_TRACKER] Calling onDelete callback...');
                  //         onDelete(config);
                  //       },
                  //     ),
                  //   ],
                  // ),
                  onTap: () {
                    Navigator.of(context).pop(config);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Filter bottom sheet widget for selecting tags to filter files.
class _FilterBottomSheet extends StatefulWidget {
  final List<String> availableTags;
  final Set<String> selectedTags;

  const _FilterBottomSheet({
    required this.availableTags,
    required this.selectedTags,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late Set<String> _selectedTags;

  @override
  void initState() {
    super.initState();
    _selectedTags = Set<String>.from(widget.selectedTags);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter by Tags',
                style: textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Select tags to filter files. Files with at least one selected tag will be shown.',
            style: textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // Tags list
          if (widget.availableTags.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.label_off, size: 48, color: cs.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text(
                      'No tags available',
                      style: textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add tags to files to filter by them',
                      style: textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.availableTags.length,
                itemBuilder: (context, index) {
                  final tag = widget.availableTags[index];
                  final isSelected = _selectedTags.contains(tag);
                  
                  return CheckboxListTile(
                    title: Text(tag),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                  );
                },
              ),
            ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedTags.clear();
                  });
                },
                child: const Text('Clear All'),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_selectedTags),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Delete server confirmation bottom sheet widget.
class _DeleteServerBottomSheet extends StatelessWidget {
  final String serverName;

  const _DeleteServerBottomSheet({
    required this.serverName,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Delete Server',
                style: textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(false),
                tooltip: 'Close',
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Message
          Text(
            'Are you sure you want to delete "$serverName"?',
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'This action cannot be undone.',
            style: textTheme.bodySmall?.copyWith(
              color: cs.error,
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  print('[FILE_TRACKER] Delete bottom sheet: Cancel button pressed');
                  Navigator.of(context).pop(false);
                },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  print('[FILE_TRACKER] Delete bottom sheet: Delete button pressed for: $serverName');
                  Navigator.of(context).pop(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.error,
                  foregroundColor: cs.onError,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// File options bottom sheet widget.
class _FileOptionsBottomSheet extends StatelessWidget {
  final VoidCallback onFileConfiguration;
  final VoidCallback onRefresh;

  const _FileOptionsBottomSheet({
    required this.onFileConfiguration,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'File Options',
                style: textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Options list
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('File Configuration'),
            subtitle: const Text('Select or configure file server'),
            onTap: onFileConfiguration,
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Refresh File Server'),
            subtitle: const Text('Reload files from server'),
            onTap: onRefresh,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}


