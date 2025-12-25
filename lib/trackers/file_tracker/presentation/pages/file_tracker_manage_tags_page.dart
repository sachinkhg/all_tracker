import 'package:flutter/material.dart';
import '../../../../widgets/primary_app_bar.dart';
import '../../../../widgets/app_drawer.dart';
import '../../../../core/organization_notifier.dart';
import 'file_tracker_main_page.dart';
import 'package:provider/provider.dart';
import '../../domain/repositories/file_metadata_repository.dart';
import '../../data/repositories/file_metadata_repository_impl.dart';
import '../../../../widgets/bottom_sheet_helpers.dart';

/// Page for managing tags with CRUD operations.
///
/// Allows users to:
/// - View all tags used across files
/// - Create new tags (by adding them to files)
/// - Rename tags (updates all files using the tag)
/// - Delete tags (removes from all files using the tag)
class FileTrackerManageTagsPage extends StatefulWidget {
  const FileTrackerManageTagsPage({super.key});

  @override
  State<FileTrackerManageTagsPage> createState() => _FileTrackerManageTagsPageState();
}

class _FileTrackerManageTagsPageState extends State<FileTrackerManageTagsPage> {
  final FileMetadataRepository _metadataRepository = FileMetadataRepositoryImpl();
  List<String> _allTags = [];
  Map<String, int> _tagUsageCount = {}; // Tag -> number of files using it
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allMetadata = await _metadataRepository.getAllMetadata();
      final tagSet = <String>{};
      final usageCount = <String, int>{};

      // Collect all unique tags and count usage
      for (final metadata in allMetadata) {
        for (final tag in metadata.tags) {
          tagSet.add(tag);
          usageCount[tag] = (usageCount[tag] ?? 0) + 1;
        }
      }

      setState(() {
        _allTags = tagSet.toList()..sort();
        _tagUsageCount = usageCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading tags: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _createTag() async {
    final result = await showAppBottomSheet<String>(
      context,
      _CreateTagBottomSheet(),
    );

    if (result != null && result.isNotEmpty) {
      final tagName = result.trim();
      
      // Check if tag already exists
      if (_allTags.contains(tagName)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tag "$tagName" already exists'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }

      // Tag creation is informational - tags are actually created when assigned to files
      // So we just refresh the list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tag "$tagName" will be created when you assign it to a file'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _renameTag(String oldTag) async {
    final result = await showAppBottomSheet<String>(
      context,
      _RenameTagBottomSheet(oldTag: oldTag),
    );

    if (result != null && result.isNotEmpty) {
      final newTag = result.trim();
      
      // Check if new tag already exists
      if (_allTags.contains(newTag)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tag "$newTag" already exists'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }

      // Find all metadata entries that use this tag
      try {
        final allMetadata = await _metadataRepository.getAllMetadata();
        int updatedCount = 0;

        for (final metadata in allMetadata) {
          if (metadata.tags.contains(oldTag)) {
            // Create updated tags list with renamed tag
            final updatedTags = metadata.tags.map((tag) {
              return tag == oldTag ? newTag : tag;
            }).toList();

            // Update metadata
            final updatedMetadata = metadata.copyWith(
              tags: updatedTags,
              lastUpdated: DateTime.now(),
            );

            await _metadataRepository.saveMetadata(updatedMetadata);
            updatedCount++;
          }
        }

        // Refresh the tags list
        await _loadTags();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tag renamed: "$oldTag" → "$newTag" ($updatedCount files updated)'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error renaming tag: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteTag(String tag) async {
    final usageCount = _tagUsageCount[tag] ?? 0;
    
    final confirm = await showAppBottomSheet<bool>(
      context,
      _DeleteTagBottomSheet(
        tag: tag,
        usageCount: usageCount,
      ),
    );

    if (confirm == true) {
      try {
        // Find all metadata entries that use this tag
        final allMetadata = await _metadataRepository.getAllMetadata();
        int updatedCount = 0;

        for (final metadata in allMetadata) {
          if (metadata.tags.contains(tag)) {
            // Remove the tag from the tags list
            final updatedTags = metadata.tags.where((t) => t != tag).toList();

            // Update metadata
            final updatedMetadata = metadata.copyWith(
              tags: updatedTags,
              lastUpdated: DateTime.now(),
            );

            await _metadataRepository.saveMetadata(updatedMetadata);
            updatedCount++;
          }
        }

        // Refresh the tags list
        await _loadTags();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tag "$tag" deleted from $updatedCount files'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting tag: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentPage: AppPage.fileTracker),
      appBar: PrimaryAppBar(
        title: 'Manage Tags',
        actions: [
          Consumer<OrganizationNotifier>(
            builder: (context, orgNotifier, _) {
              if (orgNotifier.defaultHomePage == 'app_home') {
                return IconButton(
                  tooltip: 'File Tracker Home',
                  icon: const Icon(Icons.home),
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const FileTrackerMainPage()),
                      (route) => false,
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadTags,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allTags.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.label_off,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tags found',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tags will appear here once you add them to files',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Tag to File'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Header with create button
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_allTags.length} tag${_allTags.length != 1 ? 's' : ''}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Create Tag'),
                            onPressed: _createTag,
                          ),
                        ],
                      ),
                    ),
                    // Tags list
                    Expanded(
                      child: ListView.builder(
                        itemCount: _allTags.length,
                        itemBuilder: (context, index) {
                          final tag = _allTags[index];
                          final usageCount = _tagUsageCount[tag] ?? 0;
                          
                          return ListTile(
                            leading: Icon(
                              Icons.label,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(tag),
                            subtitle: Text(
                              '$usageCount file${usageCount != 1 ? 's' : ''}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  tooltip: 'Rename tag',
                                  onPressed: () => _renameTag(tag),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  tooltip: 'Delete tag',
                                  color: Theme.of(context).colorScheme.error,
                                  onPressed: () => _deleteTag(tag),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createTag,
        tooltip: 'Create new tag',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Bottom sheet for creating a new tag.
class _CreateTagBottomSheet extends StatefulWidget {
  @override
  State<_CreateTagBottomSheet> createState() => _CreateTagBottomSheetState();
}

class _CreateTagBottomSheetState extends State<_CreateTagBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _tagController = TextEditingController();

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
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
      child: Form(
        key: _formKey,
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
                  'Create Tag',
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
            
            Text(
              'Note: Tags are created when you assign them to files. This is for informational purposes.',
              style: textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            
            // Tag name input
            TextFormField(
              controller: _tagController,
              decoration: const InputDecoration(
                labelText: 'Tag Name',
                hintText: 'Enter tag name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Tag name cannot be empty';
                }
                return null;
              },
              autofocus: true,
              textCapitalization: TextCapitalization.none,
            ),
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.of(context).pop(_tagController.text.trim());
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for renaming a tag.
class _RenameTagBottomSheet extends StatefulWidget {
  final String oldTag;

  const _RenameTagBottomSheet({
    required this.oldTag,
  });

  @override
  State<_RenameTagBottomSheet> createState() => _RenameTagBottomSheetState();
}

class _RenameTagBottomSheetState extends State<_RenameTagBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tagController;

  @override
  void initState() {
    super.initState();
    _tagController = TextEditingController(text: widget.oldTag);
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
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
      child: Form(
        key: _formKey,
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
                  'Rename Tag',
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
            
            // Tag name input
            TextFormField(
              controller: _tagController,
              decoration: const InputDecoration(
                labelText: 'New Tag Name',
                hintText: 'Enter new tag name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Tag name cannot be empty';
                }
                if (value.trim() == widget.oldTag) {
                  return 'New name must be different from current name';
                }
                return null;
              },
              autofocus: true,
              textCapitalization: TextCapitalization.none,
            ),
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.of(context).pop(_tagController.text.trim());
                    }
                  },
                  child: const Text('Rename'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for confirming tag deletion.
class _DeleteTagBottomSheet extends StatelessWidget {
  final String tag;
  final int usageCount;

  const _DeleteTagBottomSheet({
    required this.tag,
    required this.usageCount,
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
                'Delete Tag',
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
            'Are you sure you want to delete the tag "$tag"?',
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'This will remove the tag from $usageCount file${usageCount != 1 ? 's' : ''}. This action cannot be undone.',
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

