import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../widgets/primary_app_bar.dart';
import '../../../../widgets/app_drawer.dart';
import '../../../../pages/app_home_page.dart';
import '../../../../core/organization_notifier.dart';
import 'package:provider/provider.dart';
import '../../core/injection.dart';
import '../../data/services/file_server_config_service.dart';
import '../../domain/entities/file_server_config.dart';
import '../../domain/entities/cloud_file.dart';
import '../../domain/entities/file_metadata.dart';
import '../bloc/file_cubit.dart';
import '../bloc/file_state.dart';
import '../widgets/file_tag_editor_dialog.dart';
import '../widgets/bulk_tag_editor_dialog.dart';
import '../widgets/file_server_config_dialog.dart';
import '../../../../widgets/loading_view.dart';
import '../../../../widgets/error_view.dart';
import '../../../../widgets/bottom_sheet_helpers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import '../widgets/file_thumbnail_widget.dart';
import '../widgets/file_gallery_grid.dart';
import '../widgets/file_list_item.dart';
import 'file_tracker_manage_tags_page.dart';
import 'file_viewer_page.dart';

/// Instagram Reels-like view for File Tracker.
///
/// Displays files with portrait view mode in a vertical scrollable format.
/// Shows cast name as user, notes as description, and tags as hashtags.
class FileTrackerInstaViewPage extends StatefulWidget {
  const FileTrackerInstaViewPage({super.key});

  @override
  State<FileTrackerInstaViewPage> createState() => _FileTrackerInstaViewPageState();
}

class _FileTrackerInstaViewPageState extends State<FileTrackerInstaViewPage> {
  final _configService = FileServerConfigService();
  String? _currentServerName;
  bool _isLoadingConfig = true;
  int _currentTabIndex = 0; // 0 = Reels, 1 = Posts, 2 = Gallery
  List<CloudFile>? _shuffledReelsFiles; // Shuffled files for Reels session
  List<CloudFile>? _shuffledPostsFiles; // Shuffled files for Posts session
  List<CloudFile>? _shuffledGalleryFiles; // Shuffled files for Gallery session
  final Random _random = Random();
  bool _isMultiSelectMode = false;
  final Set<String> _selectedFileIds = {}; // Store stable identifiers of selected files
  final Set<String> _selectedFilterTags = {}; // Tags selected for filtering in Gallery
  bool _isGalleryGridView = true; // Gallery view mode (grid or list)

  @override
  void initState() {
    super.initState();
    // Reset shuffled files when entering a new session
    _shuffledReelsFiles = null;
    _shuffledPostsFiles = null;
    _shuffledGalleryFiles = null;
  }

  /// Shuffles a list of files randomly and non-repeating
  List<CloudFile> _shuffleFiles(List<CloudFile> files) {
    final shuffled = List<CloudFile>.from(files);
    // Fisher-Yates shuffle algorithm
    for (int i = shuffled.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final temp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = temp;
    }
    return shuffled;
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
          title: _currentTabIndex == 0
              ? (_currentServerName != null 
                  ? 'Reels - $_currentServerName'
                  : 'Reels')
              : _currentTabIndex == 1
                  ? (_currentServerName != null 
                      ? 'Posts - $_currentServerName'
                      : 'Posts')
                  : (_currentServerName != null 
                      ? 'Gallery - $_currentServerName'
                      : 'Gallery'),
          actions: [
            // Checklist button for multi-select mode (only in Gallery tab)
            if (_currentTabIndex == 2 && !_isMultiSelectMode)
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
            Consumer<OrganizationNotifier>(
              builder: (context, orgNotifier, _) {
                if (orgNotifier.defaultHomePage == 'app_home') {
                  return IconButton(
                    tooltip: 'App Home',
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
        body: BlocBuilder<FileCubit, FileState>(
          builder: (context, state) {
            if (state is FilesInitial) {
              if (_isLoadingConfig) {
                return const LoadingView(message: 'Loading server configuration...');
              }
              
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.video_library,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text('No server configured'),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.settings),
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
              final cubit = context.read<FileCubit>();
              var files = state.files;
              
              // Get metadata for all files
              final metadataMap = <String, FileMetadata>{};
              for (final file in files) {
                final metadata = cubit.getMetadataForFile(file);
                if (metadata != null) {
                  metadataMap[file.stableIdentifier] = metadata;
                }
              }

              // Filter files based on tab
              List<CloudFile> filteredFiles;
              if (_currentTabIndex == 0) {
                // Reels: portrait files
                filteredFiles = files.where((file) {
                  if (!file.isImage && !file.isVideo) return false;
                  final metadata = metadataMap[file.stableIdentifier];
                  return metadata?.viewMode == 'portrait';
                }).toList();
                
                // Shuffle files for this session if not already shuffled
                if (_shuffledReelsFiles == null && filteredFiles.isNotEmpty) {
                  _shuffledReelsFiles = _shuffleFiles(filteredFiles);
                }
                // Use shuffled files if available, otherwise use filtered files
                filteredFiles = _shuffledReelsFiles ?? filteredFiles;
              } else if (_currentTabIndex == 1) {
                // Posts: landscape files
                filteredFiles = files.where((file) {
                  if (!file.isImage && !file.isVideo) return false;
                  final metadata = metadataMap[file.stableIdentifier];
                  return metadata?.viewMode == 'landscape';
                }).toList();
                
                // Shuffle files for this session if not already shuffled
                if (_shuffledPostsFiles == null && filteredFiles.isNotEmpty) {
                  _shuffledPostsFiles = _shuffleFiles(filteredFiles);
                }
                // Use shuffled files if available, otherwise use filtered files
                filteredFiles = _shuffledPostsFiles ?? filteredFiles;
              } else {
                // Gallery: all images and videos
                filteredFiles = files.where((file) {
                  if (!file.isImage && !file.isVideo) return false;
                  
                  // Apply tag filter if any tags are selected
                  if (_selectedFilterTags.isNotEmpty) {
                    final metadata = metadataMap[file.stableIdentifier];
                    if (metadata == null || metadata.tags.isEmpty) return false;
                    // File must have at least one of the selected tags
                    return _selectedFilterTags.any((tag) => metadata.tags.contains(tag));
                  }
                  
                  return true;
                }).toList();
                
                // Shuffle files for this session if not already shuffled
                if (_shuffledGalleryFiles == null && filteredFiles.isNotEmpty) {
                  _shuffledGalleryFiles = _shuffleFiles(filteredFiles);
                }
                // Use shuffled files if available, otherwise use filtered files
                filteredFiles = _shuffledGalleryFiles ?? filteredFiles;
              }

              // Show appropriate view based on selected tab
              if (_currentTabIndex == 0) {
                // Reels view
                if (filteredFiles.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.portrait,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No portrait files found',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Files with portrait view mode will appear here.\n'
                            'Set view mode to "portrait" in the gallery to see them here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return _ReelPageView(
                  files: filteredFiles,
                  metadataMap: metadataMap,
                  config: state.config!,
                  cubit: cubit,
                  onRefresh: () async {
                    await cubit.refreshFiles();
                  },
                );
              } else if (_currentTabIndex == 1) {
                // Posts view
                if (filteredFiles.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.landscape,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No landscape files found',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Files with landscape view mode will appear here.\n'
                            'Set view mode to "landscape" in the gallery to see them here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return _PostsView(
                  files: filteredFiles,
                  metadataMap: metadataMap,
                  config: state.config!,
                  cubit: cubit,
                );
              } else {
                // Gallery view
                if (filteredFiles.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.photo_library,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No files found',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Images and videos will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    // Multi-select toolbar
                    if (_isMultiSelectMode)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
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
                        ),
                      ),
                    // Gallery content
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          await cubit.refreshFiles();
                        },
                        child: _isGalleryGridView
                            ? FileGalleryGrid(
                                files: filteredFiles,
                                config: state.config!,
                                fileMetadata: metadataMap,
                                crossAxisCount: 3,
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
                                    // Open file viewer when file is tapped
                                    final index = filteredFiles.indexOf(file);
                                    if (index >= 0) {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => FileViewerPage(
                                            files: filteredFiles,
                                            initialIndex: index,
                                            config: state.config!,
                                          ),
                                        ),
                                      );
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
                                padding: const EdgeInsets.all(8),
                                itemCount: filteredFiles.length,
                                itemBuilder: (context, index) {
                                  final file = filteredFiles[index];
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
                                        // Open file viewer when file is tapped
                                        final fileIndex = filteredFiles.indexOf(file);
                                        if (fileIndex >= 0) {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => FileViewerPage(
                                                files: filteredFiles,
                                                initialIndex: fileIndex,
                                                config: state.config!,
                                              ),
                                            ),
                                          );
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
                              ),
                      ),
                    ),
                  ],
                );
              }
            }

            return const Center(child: Text('Unknown state'));
          },
        ),
        floatingActionButton: _currentTabIndex == 2
            ? Builder(
                builder: (builderContext) => Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // First row: File options and Server configuration
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // File options button
                        Builder(
                          builder: (fabContext) {
                            final cubit = fabContext.read<FileCubit>();
                            return FloatingActionButton.small(
                              heroTag: 'fileOptionsFab',
                              tooltip: 'File Options',
                              backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
                              onPressed: () => _showFileOptionsBottomSheet(fabContext, cubit),
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
                            );
                          },
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
                            final cubit = filterContext.read<FileCubit>();
                            return FloatingActionButton.small(
                              heroTag: 'filterFab',
                              tooltip: 'Filter by tags',
                              backgroundColor: _selectedFilterTags.isNotEmpty
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
                              onPressed: () => _showFilterBottomSheet(filterContext, cubit),
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
                        FloatingActionButton.small(
                          heroTag: 'viewToggleFab',
                          tooltip: _isGalleryGridView ? 'Switch to list view' : 'Switch to grid view',
                          backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
                          onPressed: () {
                            setState(() {
                              _isGalleryGridView = !_isGalleryGridView;
                            });
                          },
                          child: Icon(_isGalleryGridView ? Icons.list : Icons.grid_view),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: (index) {
            setState(() {
              _currentTabIndex = index;
              // Exit multi-select mode when switching tabs
              if (_currentTabIndex != 2) {
                _isMultiSelectMode = false;
                _selectedFileIds.clear();
              }
            });
          },
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.video_library),
              label: 'Reels',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view),
              label: 'Posts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.photo_library),
              label: 'Gallery',
            ),
          ],
        ),
      ),
    );
  }

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
      if (mounted) {
        setState(() {
          _isLoadingConfig = false;
        });
      }
    }
  }

  Future<void> _showFileOptionsBottomSheet(BuildContext context, FileCubit cubit) async {
    await showAppBottomSheet<void>(
      context,
      _FileOptionsBottomSheet(
        onFileConfiguration: () {
          Navigator.of(context).pop();
          _showServerSelectionDialog(context);
        },
        onRefresh: () {
          Navigator.of(context).pop();
          cubit.refreshFiles();
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
    );

    if (updatedConfig != null && mounted) {
      try {
        final oldServerName = config.serverName;
        final newServerName = updatedConfig.serverName;
        final wasActive = _currentServerName == oldServerName;
        
        // If server name changed, delete the old entry first
        if (oldServerName != newServerName) {
          await _configService.deleteConfig(oldServerName);
        }
        
        // Save the updated config
        await _configService.saveConfig(updatedConfig);
        
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
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating server: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _showServerSelectionDialog(BuildContext context) async {
    final allConfigs = await _configService.getAllConfigs();
    
    if (allConfigs.isEmpty) {
      // No servers exist, show add dialog
      final config = await FileServerConfigDialog.show(context, null);
      if (config != null && mounted) {
        await _configService.saveConfig(config);
        await _configService.setActiveServerName(config.serverName);
        setState(() {
          _currentServerName = config.serverName;
        });
        final cubit = BlocProvider.of<FileCubit>(context);
        cubit.loadFiles(config);
      }
      return;
    }

    final selectedConfig = await showAppBottomSheet<FileServerConfig>(
      context,
      _ServerSelectionBottomSheet(
        allConfigs: allConfigs,
        currentServerName: _currentServerName,
        onAddNew: () async {
          Navigator.of(context).pop();
          final config = await FileServerConfigDialog.show(context, null);
          if (config != null && mounted) {
            await _configService.saveConfig(config);
            await _configService.setActiveServerName(config.serverName);
            setState(() {
              _currentServerName = config.serverName;
            });
            final cubit = BlocProvider.of<FileCubit>(context);
            cubit.loadFiles(config);
          }
        },
        onEdit: (config) async {
          Navigator.of(context).pop();
          await _showEditServerDialog(context, config);
        },
        onDelete: (config) async {
          Navigator.of(context).pop();
          final confirm = await showAppBottomSheet<bool>(
            context,
            _DeleteServerBottomSheet(serverName: config.serverName),
          );
          if (confirm == true && mounted) {
            await _configService.deleteConfig(config.serverName);
            if (_currentServerName == config.serverName) {
              setState(() {
                _currentServerName = null;
              });
            }
          }
        },
      ),
    );

    if (selectedConfig != null && mounted) {
      await _configService.setActiveServerName(selectedConfig.serverName);
      setState(() {
        _currentServerName = selectedConfig.serverName;
      });
      final cubit = BlocProvider.of<FileCubit>(context);
      cubit.loadFiles(selectedConfig);
    }
  }

  Future<void> _showTagEditor(BuildContext context, CloudFile file, FileCubit cubit) async {
    if (!mounted) return;
    
    try {
      final result = await FileTagEditorDialog.show(context, file, cubit);
      // Refresh the UI to show updated tags and cast
      if (mounted && result != null) {
        // Force a refresh of files to reload metadata from repository
        await cubit.refreshFiles();
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
      // Clear selection first
      setState(() {
        _isMultiSelectMode = false;
        _selectedFileIds.clear();
      });
      // Force a refresh of files to reload metadata from repository
      await cubit.refreshFiles();
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
        // Reset shuffled files when filter changes
        _shuffledGalleryFiles = null;
      });
    }
  }

  Future<void> _showConfigDialog(BuildContext context) async {
    final cubit = BlocProvider.of<FileCubit>(context);
    final currentConfig = cubit.currentConfig;

    final config = await FileServerConfigDialog.show(
      context,
      currentConfig,
    );

    if (config != null && mounted) {
      await _configService.saveConfig(config);
      await _configService.setActiveServerName(config.serverName);
      setState(() {
        _currentServerName = config.serverName;
      });
      cubit.loadFiles(config);
    }
  }
}

/// Reel PageView widget that manages video playback.
class _ReelPageView extends StatefulWidget {
  final List<CloudFile> files;
  final Map<String, FileMetadata> metadataMap;
  final FileServerConfig config;
  final FileCubit cubit;
  final Future<void> Function() onRefresh;

  const _ReelPageView({
    required this.files,
    required this.metadataMap,
    required this.config,
    required this.cubit,
    required this.onRefresh,
  });

  @override
  State<_ReelPageView> createState() => _ReelPageViewState();
}

class _ReelPageViewState extends State<_ReelPageView> {
  final PageController _pageController = PageController();
  VideoPlayerController? _currentVideoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoForIndex(0);
  }

  @override
  void dispose() {
    _currentVideoController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _initializeVideoForIndex(int index) {
    // Dispose previous video controller
    _currentVideoController?.dispose();
    _currentVideoController = null;
    _isVideoInitialized = false;

    if (index >= widget.files.length) return;

    final file = widget.files[index];
    if (!file.isVideo) return;

    // Build headers for authentication if needed
    final headers = <String, String>{};
    if (widget.config.username.isNotEmpty && widget.config.password.isNotEmpty) {
      final credentials = '${widget.config.username}:${widget.config.password}';
      final encoded = base64Encode(utf8.encode(credentials));
      headers['Authorization'] = 'Basic $encoded';
    }

    // Initialize video player
    try {
      _currentVideoController = headers.isNotEmpty
          ? VideoPlayerController.networkUrl(
              Uri.parse(file.url),
              httpHeaders: headers,
              videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
            )
          : VideoPlayerController.networkUrl(
              Uri.parse(file.url),
              videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
            );

      _currentVideoController!.initialize().then((_) {
        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
          });
          // Auto-play video and set looping
          _currentVideoController!.setLooping(true);
          _currentVideoController!.play();
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _isVideoInitialized = false;
          });
        }
      });

      // Listen to video player state changes
      _currentVideoController!.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: widget.files.length,
      onPageChanged: (index) {
        _initializeVideoForIndex(index);
      },
      itemBuilder: (context, index) {
        final file = widget.files[index];
        final metadata = widget.metadataMap[file.stableIdentifier];
        return _ReelItem(
          file: file,
          metadata: metadata,
          config: widget.config,
          cubit: widget.cubit,
          videoController: file.isVideo ? _currentVideoController : null,
          isVideoInitialized: file.isVideo ? _isVideoInitialized : true,
          onEdit: () async {
            final updatedMetadata = await FileTagEditorDialog.show(
              context,
              file,
              widget.cubit,
            );
            if (updatedMetadata != null && mounted) {
              await widget.onRefresh();
            }
          },
        );
      },
    );
  }
}

/// Individual reel item widget.
class _ReelItem extends StatefulWidget {
  final CloudFile file;
  final FileMetadata? metadata;
  final FileServerConfig config;
  final FileCubit cubit;
  final VideoPlayerController? videoController;
  final bool isVideoInitialized;
  final VoidCallback onEdit;

  const _ReelItem({
    required this.file,
    this.metadata,
    required this.config,
    required this.cubit,
    this.videoController,
    required this.isVideoInitialized,
    required this.onEdit,
  });

  @override
  State<_ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<_ReelItem> {
  @override
  void initState() {
    super.initState();
    // Listen to video controller updates
    widget.videoController?.addListener(_onVideoUpdate);
  }

  @override
  void didUpdateWidget(_ReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle controller changes
    if (oldWidget.videoController != widget.videoController) {
      oldWidget.videoController?.removeListener(_onVideoUpdate);
      widget.videoController?.addListener(_onVideoUpdate);
    }
  }

  @override
  void dispose() {
    widget.videoController?.removeListener(_onVideoUpdate);
    super.dispose();
  }

  void _onVideoUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    // Get user (cast) - show first cast member or "unknown"
    final user = widget.metadata?.cast.isNotEmpty == true 
        ? widget.metadata!.cast.first 
        : 'unknown';
    
    // Get description (notes)
    final description = widget.metadata?.notes ?? '';
    
    // Get hashtags (tags)
    final hashtags = widget.metadata?.tags ?? [];

    // Get video progress if it's a video
    final isVideo = widget.file.isVideo;
    final hasActiveVideo = isVideo && widget.videoController != null && widget.isVideoInitialized;
    final videoValue = widget.videoController?.value;
    final duration = videoValue?.duration ?? Duration.zero;
    final position = videoValue?.position ?? Duration.zero;
    final buffered = videoValue?.buffered ?? [];
    final progress = duration.inMilliseconds > 0 
        ? position.inMilliseconds / duration.inMilliseconds 
        : 0.0;

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image/Video - fill the screen
          widget.file.isImage
              ? CachedNetworkImage(
                  imageUrl: widget.file.url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(
                      Icons.error,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                )
              : widget.videoController != null && widget.isVideoInitialized
                  ? SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: widget.videoController!.value.size.width,
                          height: widget.videoController!.value.size.height,
                          child: VideoPlayer(widget.videoController!),
                        ),
                      ),
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
          
          // Video progress line at the bottom (only for videos)
          if (hasActiveVideo)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  if (duration.inMilliseconds > 0 && widget.videoController != null) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final localX = details.localPosition.dx.clamp(0.0, screenWidth);
                    final seekPosition = (localX / screenWidth) * duration.inMilliseconds;
                    widget.videoController!.seekTo(Duration(milliseconds: seekPosition.round()));
                  }
                },
                onPanUpdate: (details) {
                  if (duration.inMilliseconds > 0 && widget.videoController != null) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final localX = details.localPosition.dx.clamp(0.0, screenWidth);
                    final seekPosition = (localX / screenWidth) * duration.inMilliseconds;
                    widget.videoController!.seekTo(Duration(milliseconds: seekPosition.round()));
                  }
                },
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                  child: Stack(
                    children: [
                      // Buffered progress
                      if (buffered.isNotEmpty)
                        ...buffered.map((range) {
                          final startPercent = duration.inMilliseconds > 0
                              ? range.start.inMilliseconds / duration.inMilliseconds
                              : 0.0;
                          final endPercent = duration.inMilliseconds > 0
                              ? range.end.inMilliseconds / duration.inMilliseconds
                              : 0.0;
                          return Positioned(
                            left: MediaQuery.of(context).size.width * startPercent,
                            width: MediaQuery.of(context).size.width * (endPercent - startPercent),
                            child: Container(
                              height: 5,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          );
                        }),
                      // Played progress
                      Positioned(
                        left: 0,
                        width: MediaQuery.of(context).size.width * progress,
                        child: Container(
                          height: 5,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Bottom overlay with user, description, and hashtags
          Positioned(
            bottom: hasActiveVideo ? 4 : 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // User name
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: cs.primary,
                        child: Text(
                          user.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        user,
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Description (notes)
                  if (description.isNotEmpty) ...[
                    Text(
                      description,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Hashtags (tags)
                  if (hashtags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: hashtags.map((tag) {
                        return Text(
                          '#$tag',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.blue[300],
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),
          
          // Edit button at top right
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.edit),
              color: Colors.white,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
              ),
              onPressed: widget.onEdit,
              tooltip: 'Edit metadata',
            ),
          ),
        ],
      ),
    );
  }
}

/// Posts view widget - displays landscape files in Instagram post style.
/// Vertical scrolling feed where each post takes full screen.
class _PostsView extends StatefulWidget {
  final List<CloudFile> files;
  final Map<String, FileMetadata> metadataMap;
  final FileServerConfig config;
  final FileCubit cubit;

  const _PostsView({
    required this.files,
    required this.metadataMap,
    required this.config,
    required this.cubit,
  });

  @override
  State<_PostsView> createState() => _PostsViewState();
}

class _PostsViewState extends State<_PostsView> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, VideoPlayerController?> _videoControllers = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Dispose all video controllers
    for (final controller in _videoControllers.values) {
      controller?.dispose();
    }
    _videoControllers.clear();
    super.dispose();
  }

  Future<void> _initializeVideoForIndex(int index) async {
    if (index < 0 || index >= widget.files.length) return;
    
    final file = widget.files[index];
    if (!file.isVideo) return;
    
    // Don't reinitialize if already exists
    if (_videoControllers.containsKey(index) && _videoControllers[index] != null) {
      return;
    }
    
    // Build headers for authentication if needed
    final headers = <String, String>{};
    if (widget.config.username.isNotEmpty && widget.config.password.isNotEmpty) {
      final credentials = '${widget.config.username}:${widget.config.password}';
      final encoded = base64Encode(utf8.encode(credentials));
      headers['Authorization'] = 'Basic $encoded';
    }

    try {
      final controller = headers.isNotEmpty
          ? VideoPlayerController.networkUrl(
              Uri.parse(file.url),
              httpHeaders: headers,
              videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
            )
          : VideoPlayerController.networkUrl(
              Uri.parse(file.url),
              videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
            );

      await controller.initialize();
      // Ensure video is paused and at the first frame to show thumbnail
      await controller.pause();
      await controller.seekTo(Duration.zero);
      // Don't auto-play - videos start paused
      if (mounted) {
        setState(() {
          _videoControllers[index] = controller;
        });
        // Force a rebuild after a short delay to ensure frame is rendered
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {});
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _videoControllers[index] = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await widget.cubit.refreshFiles();
      },
      child: ListView.builder(
        controller: _scrollController,
        itemCount: widget.files.length,
        itemBuilder: (context, index) {
          final file = widget.files[index];
          final metadata = widget.metadataMap[file.stableIdentifier];
          return _PostItem(
            key: ValueKey(file.stableIdentifier),
            file: file,
            metadata: metadata,
            config: widget.config,
            cubit: widget.cubit,
            videoController: _videoControllers[index],
            onInitRequested: () => _initializeVideoForIndex(index),
          );
        },
      ),
    );
  }
}

/// Individual post item widget - Instagram post style.
class _PostItem extends StatelessWidget {
  final CloudFile file;
  final FileMetadata? metadata;
  final FileServerConfig config;
  final FileCubit cubit;
  final VideoPlayerController? videoController;
  final VoidCallback? onInitRequested;

  const _PostItem({
    super.key,
    required this.file,
    this.metadata,
    required this.config,
    required this.cubit,
    this.videoController,
    this.onInitRequested,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return _PostItemContent(
      file: file,
      metadata: metadata,
      config: config,
      cubit: cubit,
      screenHeight: screenHeight,
      videoController: videoController,
      onInitRequested: onInitRequested,
    );
  }
}

/// Post item content widget that handles dynamic sizing for videos.
class _PostItemContent extends StatefulWidget {
  final CloudFile file;
  final FileMetadata? metadata;
  final FileServerConfig config;
  final FileCubit cubit;
  final double screenHeight;
  final VideoPlayerController? videoController;
  final VoidCallback? onInitRequested;

  const _PostItemContent({
    required this.file,
    this.metadata,
    required this.config,
    required this.cubit,
    required this.screenHeight,
    this.videoController,
    this.onInitRequested,
  });

  @override
  State<_PostItemContent> createState() => _PostItemContentState();
}

class _PostItemContentState extends State<_PostItemContent> {
  double? _videoAspectRatio;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    if (widget.file.isVideo) {
      if (widget.videoController != null) {
        _videoAspectRatio = widget.videoController!.value.aspectRatio;
        _isVideoInitialized = widget.videoController!.value.isInitialized;
        _isPlaying = widget.videoController!.value.isPlaying;
        // Listen to controller changes
        widget.videoController!.addListener(_onVideoUpdate);
      } else {
        // Request initialization
        widget.onInitRequested?.call();
        // Use default 16:9 while waiting
        _videoAspectRatio = 16 / 9;
      }
    }
  }

  @override
  void didUpdateWidget(_PostItemContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoController != widget.videoController) {
      oldWidget.videoController?.removeListener(_onVideoUpdate);
      if (widget.videoController != null) {
        widget.videoController!.addListener(_onVideoUpdate);
        _videoAspectRatio = widget.videoController!.value.aspectRatio;
        _isVideoInitialized = widget.videoController!.value.isInitialized;
        _isPlaying = widget.videoController!.value.isPlaying;
      }
    }
  }

  @override
  void dispose() {
    widget.videoController?.removeListener(_onVideoUpdate);
    super.dispose();
  }

  void _onVideoUpdate() {
    if (mounted && widget.videoController != null) {
      setState(() {
        _videoAspectRatio = widget.videoController!.value.aspectRatio;
        _isVideoInitialized = widget.videoController!.value.isInitialized;
        _isPlaying = widget.videoController!.value.isPlaying;
      });
    }
  }

  void _togglePlayPause() {
    if (widget.videoController == null || !_isVideoInitialized) {
      // Initialize if not already done
      widget.onInitRequested?.call();
      return;
    }

    setState(() {
      if (_isPlaying) {
        widget.videoController!.pause();
        _isPlaying = false;
      } else {
        widget.videoController!.play();
        _isPlaying = true;
      }
    });
  }

  Widget _buildVideoProgressLine() {
    if (widget.videoController == null || !_isVideoInitialized) {
      return const SizedBox.shrink();
    }

    final videoValue = widget.videoController!.value;
    final duration = videoValue.duration;
    final position = videoValue.position;
    final buffered = videoValue.buffered;
    final progress = duration.inMilliseconds > 0 
        ? position.inMilliseconds / duration.inMilliseconds 
        : 0.0;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) {
          if (duration.inMilliseconds > 0 && widget.videoController != null) {
            final screenWidth = MediaQuery.of(context).size.width;
            final localX = details.localPosition.dx.clamp(0.0, screenWidth);
            final seekPosition = (localX / screenWidth) * duration.inMilliseconds;
            widget.videoController!.seekTo(Duration(milliseconds: seekPosition.round()));
          }
        },
        onPanUpdate: (details) {
          if (duration.inMilliseconds > 0 && widget.videoController != null) {
            final screenWidth = MediaQuery.of(context).size.width;
            final localX = details.localPosition.dx.clamp(0.0, screenWidth);
            final seekPosition = (localX / screenWidth) * duration.inMilliseconds;
            widget.videoController!.seekTo(Duration(milliseconds: seekPosition.round()));
          }
        },
        child: Container(
          height: 5,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
          ),
          child: Stack(
            children: [
              // Buffered progress
              if (buffered.isNotEmpty)
                ...buffered.map((range) {
                  final startPercent = duration.inMilliseconds > 0
                      ? range.start.inMilliseconds / duration.inMilliseconds
                      : 0.0;
                  final endPercent = duration.inMilliseconds > 0
                      ? range.end.inMilliseconds / duration.inMilliseconds
                      : 0.0;
                  return Positioned(
                    left: MediaQuery.of(context).size.width * startPercent,
                    width: MediaQuery.of(context).size.width * (endPercent - startPercent),
                    child: Container(
                      height: 5,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  );
                }),
              // Played progress
              Positioned(
                left: 0,
                width: MediaQuery.of(context).size.width * progress,
                child: Container(
                  height: 5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _enterFullscreen(BuildContext context) async {
    if (widget.videoController == null || !_isVideoInitialized) {
      return;
    }

    // Lock orientation to landscape
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Hide system UI for immersive fullscreen
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // Show fullscreen dialog
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (context) => _FullscreenVideoDialog(
        videoController: widget.videoController!,
        file: widget.file,
        config: widget.config,
        isPlaying: _isPlaying,
        onPlayPause: (playing) {
          if (mounted) {
            setState(() {
              _isPlaying = playing;
            });
          }
        },
        onClose: () async {
          // Force portrait orientation first
          await SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]);
          // Restore system UI
          await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
          // Close dialog
          if (context.mounted) {
            Navigator.of(context).pop();
          }
          // After a brief delay, allow all orientations again (for app flexibility)
          Future.delayed(const Duration(milliseconds: 500), () {
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]);
          });
        },
      ),
    );

    // Orientation restoration is handled by the dialog's onClose callback
    // This is just a backup in case dialog closes unexpectedly
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Get user (cast) - show first cast member or "unknown"
    final user = widget.metadata?.cast.isNotEmpty == true 
        ? widget.metadata!.cast.first 
        : 'unknown';
    
    // Get description (notes)
    final description = widget.metadata?.notes ?? '';
    
    // Get hashtags (tags)
    final hashtags = widget.metadata?.tags ?? [];

    // Calculate video height based on aspect ratio (default to 16:9)
    double videoHeight;
    if (widget.file.isVideo && _videoAspectRatio != null) {
      videoHeight = screenWidth / _videoAspectRatio!;
    } else if (widget.file.isVideo && !_isVideoInitialized) {
      // Use 16:9 as default while loading
      videoHeight = screenWidth / (16 / 9);
    } else {
      // For images, use a standard height
      videoHeight = widget.screenHeight * 0.5;
    }

    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image/Video section with dynamic height
          Container(
            width: double.infinity,
            height: videoHeight,
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image/Video
                widget.file.isImage
                    ? CachedNetworkImage(
                        imageUrl: widget.file.url,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(
                            Icons.error,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      )
                    : widget.videoController != null && _isVideoInitialized
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              // Show thumbnail when paused
                              if (!_isPlaying)
                                FileThumbnailWidget(
                                  file: widget.file,
                                  config: widget.config,
                                  fit: BoxFit.cover,
                                ),
                              // Show video player (always present, but only visible when playing)
                              _PostVideoPlayer(
                                file: widget.file,
                                config: widget.config,
                                videoController: widget.videoController!,
                                aspectRatio: _videoAspectRatio ?? (16 / 9),
                                isPlaying: _isPlaying,
                              ),
                              // Video progress line at the bottom (only for videos when playing)
                              if (_isPlaying && widget.videoController != null)
                                _buildVideoProgressLine(),
                            ],
                          )
                        : FileThumbnailWidget(
                            file: widget.file,
                            config: widget.config,
                            fit: BoxFit.cover,
                          ),
              ],
            ),
          ),
          
          // Content section (user, description, hashtags)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User name with Edit icon
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: cs.primary,
                      child: Text(
                        user.isNotEmpty ? user.substring(0, 1).toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        user,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    // Play/Pause button (only for videos)
                    if (widget.file.isVideo && widget.videoController != null && _isVideoInitialized)
                      IconButton(
                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                        color: Colors.black87,
                        onPressed: _togglePlayPause,
                        tooltip: _isPlaying ? 'Pause' : 'Play',
                      ),
                    // Fullscreen button (only for videos)
                    if (widget.file.isVideo && widget.videoController != null && _isVideoInitialized)
                      IconButton(
                        icon: const Icon(Icons.fullscreen),
                        color: Colors.black87,
                        onPressed: () => _enterFullscreen(context),
                        tooltip: 'Fullscreen',
                      ),
                    // Edit button
                    IconButton(
                      icon: const Icon(Icons.edit),
                      color: Colors.black87,
                      onPressed: () async {
                        final updatedMetadata = await FileTagEditorDialog.show(
                          context,
                          widget.file,
                          widget.cubit,
                        );
                        if (updatedMetadata != null) {
                          await widget.cubit.refreshFiles();
                        }
                      },
                      tooltip: 'Edit tags and notes',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Description (notes)
                if (description.isNotEmpty) ...[
                  Text(
                    description,
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Hashtags (tags)
                if (hashtags.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: hashtags.map((tag) {
                      return Text(
                        '#$tag',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}


/// Video player widget for posts.
class _PostVideoPlayer extends StatefulWidget {
  final CloudFile file;
  final FileServerConfig config;
  final VideoPlayerController videoController;
  final double aspectRatio;
  final bool isPlaying;

  const _PostVideoPlayer({
    required this.file,
    required this.config,
    required this.videoController,
    required this.aspectRatio,
    required this.isPlaying,
  });

  @override
  State<_PostVideoPlayer> createState() => _PostVideoPlayerState();
}

class _PostVideoPlayerState extends State<_PostVideoPlayer> {
  @override
  void initState() {
    super.initState();
    widget.videoController.addListener(_onVideoUpdate);
    // Videos start paused by default
  }

  @override
  void didUpdateWidget(_PostVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoController != widget.videoController) {
      oldWidget.videoController.removeListener(_onVideoUpdate);
      widget.videoController.addListener(_onVideoUpdate);
    }
  }

  @override
  void dispose() {
    widget.videoController.removeListener(_onVideoUpdate);
    super.dispose();
  }

  void _onVideoUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.videoController.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final controller = widget.videoController;
    
    // Only show video player when playing, otherwise it's hidden (thumbnail is shown instead)
    return Opacity(
      opacity: widget.isPlaying ? 1.0 : 0.0,
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: VideoPlayer(controller),
      ),
    );
  }
}

/// Fullscreen video dialog widget.
class _FullscreenVideoDialog extends StatefulWidget {
  final VideoPlayerController videoController;
  final CloudFile file;
  final FileServerConfig config;
  final bool isPlaying;
  final Function(bool) onPlayPause;
  final VoidCallback onClose;

  const _FullscreenVideoDialog({
    required this.videoController,
    required this.file,
    required this.config,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onClose,
  });

  @override
  State<_FullscreenVideoDialog> createState() => _FullscreenVideoDialogState();
}

class _FullscreenVideoDialogState extends State<_FullscreenVideoDialog> {
  bool _isPlaying = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.isPlaying;
    widget.videoController.addListener(_onVideoUpdate);
    // Auto-hide controls after 3 seconds
    _hideControlsAfterDelay();
  }

  @override
  void dispose() {
    widget.videoController.removeListener(_onVideoUpdate);
    super.dispose();
  }

  void _onVideoUpdate() {
    if (mounted) {
      setState(() {
        _isPlaying = widget.videoController.value.isPlaying;
      });
    }
  }

  void _hideControlsAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls && _isPlaying) {
      _hideControlsAfterDelay();
    }
  }

  void _togglePlayPause() {
    setState(() {
      if (_isPlaying) {
        widget.videoController.pause();
        _isPlaying = false;
      } else {
        widget.videoController.play();
        _isPlaying = true;
        _hideControlsAfterDelay();
      }
    });
    widget.onPlayPause(_isPlaying);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleControls,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Video player
            Center(
              child: AspectRatio(
                aspectRatio: widget.videoController.value.aspectRatio,
                child: VideoPlayer(widget.videoController),
              ),
            ),
            // Controls overlay
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.5),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Top bar with close button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: widget.onClose,
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Center play/pause button
                        Center(
                          child: IconButton(
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 64,
                            ),
                            onPressed: _togglePlayPause,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
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

          // Servers list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: allConfigs.length + 1, // +1 for "Add New" option
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Add new server option
                  return ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Add New Server'),
                    onTap: onAddNew,
                  );
                }
                
                final config = allConfigs[index - 1];
                final isActive = config.serverName == currentServerName;
                
                return ListTile(
                  leading: Icon(
                    isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isActive ? cs.primary : null,
                  ),
                  title: Text(config.serverName),
                  subtitle: Text(config.baseUrl),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => onEdit(config),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => onDelete(config),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                  onTap: () => Navigator.of(context).pop(config),
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
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
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

/// Filter bottom sheet widget.
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.label),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FileTrackerManageTagsPage(),
                        ),
                      );
                    },
                    tooltip: 'Manage Tags',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                ],
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
