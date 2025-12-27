import 'package:flutter/material.dart';
import '../../domain/entities/file_metadata.dart';
import '../bloc/file_cubit.dart';
import '../../../../widgets/bottom_sheet_helpers.dart';

/// Bottom sheet for editing metadata (tags, cast, view mode) for multiple files at once.
class BulkTagEditorDialog extends StatefulWidget {
  final List<String> fileStableIdentifiers;
  final FileCubit cubit;

  const BulkTagEditorDialog({
    super.key,
    required this.fileStableIdentifiers,
    required this.cubit,
  });

  /// Shows the bulk tag editor bottom sheet.
  static Future<bool?> show(
    BuildContext context,
    List<String> fileStableIdentifiers,
    FileCubit cubit,
  ) async {
    return await showAppBottomSheet<bool>(
      context,
      BulkTagEditorDialog(
        fileStableIdentifiers: fileStableIdentifiers,
        cubit: cubit,
      ),
    );
  }

  @override
  State<BulkTagEditorDialog> createState() => _BulkTagEditorDialogState();
}

class _BulkTagEditorDialogState extends State<BulkTagEditorDialog> {
  final List<String> _tags = [];
  final List<String> _cast = [];
  String? _viewMode;
  bool _isLoading = true;
  Set<String> _allAvailableTags = {}; // All tags from all files
  Set<String> _allAvailableCast = {}; // All cast members from all files

  @override
  void initState() {
    super.initState();
    _loadAllAvailableData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadAllAvailableData() async {
    try {
      final allTags = await widget.cubit.getAllAvailableTags();
      final allCast = await widget.cubit.getAllAvailableCast();
      setState(() {
        _allAvailableTags = allTags;
        _allAvailableCast = allCast;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _allAvailableTags = {};
        _allAvailableCast = {};
        _isLoading = false;
      });
    }
  }

  Future<void> _saveMetadata() async {
    // At least one field should have data
    if (_tags.isEmpty && _cast.isEmpty && _viewMode == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter at least one field to update')),
        );
      }
      return;
    }

    try {
      // Update metadata for all selected files
      for (final stableIdentifier in widget.fileStableIdentifiers) {
        // Get existing metadata
        final existingMetadata = await widget.cubit.getFileMetadata(stableIdentifier);
        
        // Merge tags (avoid duplicates) if tags are provided
        final existingTags = existingMetadata?.tags ?? [];
        final mergedTags = _tags.isNotEmpty
            ? <String>{...existingTags, ..._tags}.toList()
            : existingTags;
        
        // Merge cast (avoid duplicates) if cast is provided
        final existingCast = existingMetadata?.cast ?? [];
        final mergedCast = _cast.isNotEmpty
            ? <String>{...existingCast, ..._cast}.toList()
            : existingCast;
        
        // Update view mode if provided (overwrite existing)
        final updatedViewMode = _viewMode ?? existingMetadata?.viewMode;
        
        // Create or update metadata
        final updatedMetadata = existingMetadata?.copyWith(
          tags: mergedTags,
          cast: mergedCast,
          viewMode: updatedViewMode,
          lastUpdated: DateTime.now(),
        ) ?? FileMetadata(
          stableIdentifier: stableIdentifier,
          tags: mergedTags,
          cast: mergedCast,
          viewMode: updatedViewMode,
          lastUpdated: DateTime.now(),
        );
        
        await widget.cubit.saveFileMetadata(updatedMetadata);
      }
      
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save metadata: $e')),
        );
      }
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _removeCast(String name) {
    setState(() {
      _cast.remove(name);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

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
                'Edit File Metadata',
                style: textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(false),
                tooltip: 'Close',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.fileStableIdentifiers.length} file${widget.fileStableIdentifiers.length != 1 ? 's' : ''} selected',
            style: textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Tags input
          Text(
            'Tags (will be added to existing tags)',
            style: textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          
          // Searchable tag input with autocomplete
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return _allAvailableTags.toList()..sort();
              } else {
                final query = textEditingValue.text.toLowerCase();
                return _allAvailableTags
                    .where((tag) => tag.toLowerCase().contains(query))
                    .toList()
                  ..sort();
              }
            },
            onSelected: (String tag) {
              if (!_tags.contains(tag)) {
                setState(() {
                  _tags.add(tag);
                });
              }
            },
            fieldViewBuilder: (
              BuildContext context,
              TextEditingController textEditingController,
              FocusNode focusNode,
              VoidCallback onFieldSubmitted,
            ) {
              return StatefulBuilder(
                builder: (context, setState) {
                  return TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: 'Type to search existing tags or enter new tag',
                      border: const OutlineInputBorder(),
                      suffixIcon: textEditingController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                textEditingController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                    onSubmitted: (String value) {
                      final trimmedValue = value.trim();
                      if (trimmedValue.isNotEmpty && !_tags.contains(trimmedValue)) {
                        this.setState(() {
                          _tags.add(trimmedValue);
                          _allAvailableTags.add(trimmedValue);
                        });
                      }
                      textEditingController.clear();
                      setState(() {});
                    },
                    textInputAction: TextInputAction.next,
                  );
                },
              );
            },
            optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final option = options.elementAt(index);
                        final isSelected = _tags.contains(option);
                        return InkWell(
                          onTap: () => onSelected(option),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      color: isSelected ? cs.onSurfaceVariant : null,
                                      fontStyle: isSelected ? FontStyle.italic : null,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check,
                                    size: 18,
                                    color: cs.primary,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          
          // Current tags display
          if (_tags.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  onDeleted: () => _removeTag(tag),
                  deleteIcon: const Icon(Icons.close, size: 18),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 24),

          // Cast input
          Text(
            'Cast (will be added to existing cast)',
            style: textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          
          // Searchable cast input with autocomplete
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return _allAvailableCast.toList()..sort();
              } else {
                final query = textEditingValue.text.toLowerCase();
                return _allAvailableCast
                    .where((name) => name.toLowerCase().contains(query))
                    .toList()
                  ..sort();
              }
            },
            onSelected: (String name) {
              if (!_cast.contains(name)) {
                setState(() {
                  _cast.add(name);
                });
              }
            },
            fieldViewBuilder: (
              BuildContext context,
              TextEditingController textEditingController,
              FocusNode focusNode,
              VoidCallback onFieldSubmitted,
            ) {
              return StatefulBuilder(
                builder: (context, setState) {
                  return TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: 'Type to search existing cast or enter new name',
                      border: const OutlineInputBorder(),
                      suffixIcon: textEditingController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                textEditingController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                    onSubmitted: (String value) {
                      final trimmedValue = value.trim();
                      if (trimmedValue.isNotEmpty && !_cast.contains(trimmedValue)) {
                        this.setState(() {
                          _cast.add(trimmedValue);
                          _allAvailableCast.add(trimmedValue);
                        });
                      }
                      textEditingController.clear();
                      setState(() {});
                    },
                    textInputAction: TextInputAction.next,
                  );
                },
              );
            },
            optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final option = options.elementAt(index);
                        final isSelected = _cast.contains(option);
                        return InkWell(
                          onTap: () => onSelected(option),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      color: isSelected ? cs.onSurfaceVariant : null,
                                      fontStyle: isSelected ? FontStyle.italic : null,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check,
                                    size: 18,
                                    color: cs.primary,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          
          // Current cast display
          if (_cast.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _cast.map((name) {
                return Chip(
                  label: Text(name),
                  onDeleted: () => _removeCast(name),
                  deleteIcon: const Icon(Icons.close, size: 18),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 24),

          // View Mode input
          Text(
            'View Mode (will overwrite existing)',
            style: textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            initialValue: _viewMode,
            decoration: const InputDecoration(
              hintText: 'Select view mode (optional)',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem<String?>(value: null, child: Text('No change')),
              DropdownMenuItem<String?>(value: 'portrait', child: Text('Portrait')),
              DropdownMenuItem<String?>(value: 'landscape', child: Text('Landscape')),
            ],
            onChanged: (value) {
              setState(() {
                _viewMode = value;
              });
            },
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
                onPressed: _saveMetadata,
                child: const Text('Save'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

