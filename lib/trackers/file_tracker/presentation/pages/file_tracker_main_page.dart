import 'package:flutter/material.dart';
import '../../../../widgets/primary_app_bar.dart';
import '../../../../widgets/app_drawer.dart';
import '../../../../pages/app_home_page.dart';
import '../../../../core/organization_notifier.dart';
import 'package:provider/provider.dart';
import '../../core/app_icons.dart';
import '../../data/services/file_server_config_service.dart';
import '../../domain/entities/file_server_config.dart';
import '../widgets/file_server_config_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/injection.dart';
import '../../../../widgets/bottom_sheet_helpers.dart';
import 'file_tracker_gallery_page.dart';
import 'file_tracker_insta_view_page.dart';
import 'file_tracker_manage_tags_page.dart';

/// Main home page for the File Tracker feature.
///
/// Displays four main options:
/// 1. Gallery - Browse files in gallery view
/// 2. Insta View - Instagram-like view (dummy page for now)
/// 3. File Configuration - Configure file server settings
/// 4. Manage Tags - CRUD operations for tags
class FileTrackerMainPage extends StatelessWidget {
  const FileTrackerMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentPage: AppPage.fileTracker),
      appBar: PrimaryAppBar(
        title: 'File Tracker',
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Gallery option
              _OptionCard(
                icon: Icons.photo_library,
                title: 'Gallery',
                subtitle: 'Browse images and videos in gallery view',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const FileTrackerGalleryPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // Insta View option
              _OptionCard(
                icon: Icons.grid_view,
                title: 'Insta View',
                subtitle: 'Instagram-like grid view (coming soon)',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const FileTrackerInstaViewPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // File Configuration option
              _OptionCard(
                icon: FileTrackerIcons.settings,
                title: 'File Configuration',
                subtitle: 'Configure server settings and refresh files',
                onTap: () => _showFileConfiguration(context),
              ),
              const SizedBox(height: 24),
              
              // Manage Tags option
              _OptionCard(
                icon: Icons.label,
                title: 'Manage Tags',
                subtitle: 'Create, rename, and delete tags',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const FileTrackerManageTagsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showFileConfiguration(BuildContext context) async {
    final configService = FileServerConfigService();
    
    // Show the file options bottom sheet
    await showAppBottomSheet<void>(
      context,
      _FileOptionsBottomSheet(
        onFileConfiguration: () async {
          Navigator.of(context).pop();
          // Show server selection or configuration
          await _showServerSelection(context, configService);
        },
        onRefresh: () async {
          Navigator.of(context).pop();
          // Refresh files if a server is configured
          final activeConfig = await configService.getActiveConfig();
          if (activeConfig != null && context.mounted) {
            // Navigate to gallery page and refresh
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (_) {
                    final cubit = createFileCubit();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      cubit.loadFiles(activeConfig);
                    });
                    return cubit;
                  },
                  child: const FileTrackerGalleryPage(),
                ),
              ),
            );
          } else {
            // No server configured, show config dialog
            if (context.mounted) {
              await _showServerSelection(context, configService);
            }
          }
        },
      ),
    );
  }

  Future<void> _showServerSelection(
    BuildContext context,
    FileServerConfigService configService,
  ) async {
    final allConfigs = await configService.getAllConfigs();
    final activeConfig = await configService.getActiveConfig();
    
    if (allConfigs.isEmpty) {
      // No servers configured, show add dialog
      final config = await FileServerConfigDialog.show(context, null);
      if (config != null && context.mounted) {
        await configService.saveConfig(config);
        await configService.setActiveServerName(config.serverName);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Server "${config.serverName}" configured successfully'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
      return;
    }
    
    // Show server selection
    final selectedConfig = await showAppBottomSheet<FileServerConfig>(
      context,
      _ServerSelectionBottomSheet(
        allConfigs: allConfigs,
        currentServerName: activeConfig?.serverName,
        onAddNew: () async {
          Navigator.of(context).pop();
          final config = await FileServerConfigDialog.show(context, null);
          if (config != null && context.mounted) {
            await configService.saveConfig(config);
            await configService.setActiveServerName(config.serverName);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Server "${config.serverName}" added successfully'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        },
        onEdit: (config) async {
          Navigator.of(context).pop();
          final updatedConfig = await FileServerConfigDialog.show(
            context,
            config,
          );
          if (updatedConfig != null && context.mounted) {
            final oldServerName = config.serverName;
            final newServerName = updatedConfig.serverName;
            final wasActive = activeConfig?.serverName == oldServerName;
            
            if (oldServerName != newServerName) {
              await configService.deleteConfig(oldServerName);
            }
            
            await configService.saveConfig(updatedConfig);
            
            if (wasActive) {
              await configService.setActiveServerName(newServerName);
            }
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Server "$newServerName" updated successfully'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        },
        onSelect: (config) {
          Navigator.of(context).pop(config);
        },
      ),
    );
    
    if (selectedConfig != null && context.mounted) {
      await configService.setActiveServerName(selectedConfig.serverName);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to server "${selectedConfig.serverName}"'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

/// Option card widget for the home page
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 20,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
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
  final Function(FileServerConfig) onSelect;

  const _ServerSelectionBottomSheet({
    required this.allConfigs,
    required this.currentServerName,
    required this.onAddNew,
    required this.onEdit,
    required this.onSelect,
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
                  trailing: PopupMenuButton(
                    itemBuilder: (popupContext) => [
                      PopupMenuItem(
                        child: const Text('Edit'),
                        onTap: () async {
                          Navigator.of(popupContext).pop();
                          await Future.delayed(const Duration(milliseconds: 100));
                          onEdit(config);
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    onSelect(config);
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

