import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import '../../domain/entities/cloud_file.dart';
import '../../domain/entities/file_metadata.dart';
import '../bloc/file_cubit.dart';
import '../../../../widgets/bottom_sheet_helpers.dart';

/// Dialog for adding/editing tags, notes, cast, and view mode for a file.
///
/// This dialog allows users to:
/// - Add/remove tags (comma-separated or individual)
/// - Add/edit notes
/// - Add/remove cast members (comma-separated)
/// - Set view mode (portrait/landscape) with auto-detection option
/// - Tags are saved using the file's stable identifier (server-independent)
class FileTagEditorDialog extends StatefulWidget {
  final CloudFile file;
  final FileCubit cubit;

  const FileTagEditorDialog({
    super.key,
    required this.file,
    required this.cubit,
  });

  /// Shows the tag editor dialog and returns the updated metadata if saved.
  static Future<FileMetadata?> show(
    BuildContext context,
    CloudFile file,
    FileCubit cubit,
  ) async {
    return await showAppBottomSheet<FileMetadata>(
      context,
      FileTagEditorDialog(file: file, cubit: cubit),
    );
  }

  @override
  State<FileTagEditorDialog> createState() => _FileTagEditorDialogState();
}

class _FileTagEditorDialogState extends State<FileTagEditorDialog> {
  late TextEditingController _notesController;
  List<String> _tags = [];
  List<String> _cast = [];
  String? _viewMode;
  bool _isLoading = true;
  bool _isDetectingViewMode = false;
  Set<String> _allAvailableTags = {}; // All tags from all files
  Set<String> _allAvailableCast = {}; // All cast members from all files

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _loadExistingMetadata();
  }

  Future<void> _loadExistingMetadata() async {
    try {
      // Load current file's metadata
      final metadata = await widget.cubit.getFileMetadata(widget.file.stableIdentifier);
      if (metadata != null) {
        setState(() {
          _tags = List<String>.from(metadata.tags);
          _notesController.text = metadata.notes ?? '';
          _cast = List<String>.from(metadata.cast);
          _viewMode = metadata.viewMode;
        });
      }
      
      // Load all available tags and cast from all files
      await _loadAllAvailableTags();
      await _loadAllAvailableCast();
    } catch (e) {
      // Error loading metadata, start with empty
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAllAvailableTags() async {
    try {
      final allTags = await widget.cubit.getAllAvailableTags();
      setState(() {
        _allAvailableTags = allTags;
      });
    } catch (e) {
      // Error loading tags, continue with empty set
      setState(() {
        _allAvailableTags = {};
      });
    }
  }

  Future<void> _loadAllAvailableCast() async {
    try {
      final allCast = await widget.cubit.getAllAvailableCast();
      setState(() {
        _allAvailableCast = allCast;
      });
    } catch (e) {
      // Error loading cast, continue with empty set
      setState(() {
        _allAvailableCast = {};
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }



  /// Detects view mode (portrait/landscape) from image dimensions.
  /// Returns null if detection fails or file is not an image.
  Future<String?> _detectViewMode() async {
    if (!widget.file.isImage) {
      return null;
    }

    setState(() {
      _isDetectingViewMode = true;
    });

    try {
      // Fetch the image
      final response = await http.get(Uri.parse(widget.file.url));
      if (response.statusCode != 200) {
        return null;
      }

      // Decode the image to get dimensions
      final codec = await ui.instantiateImageCodec(response.bodyBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final width = image.width;
      final height = image.height;

      // Determine orientation based on dimensions
      // Portrait: height > width, Landscape: width > height
      final detectedMode = height > width ? 'portrait' : 'landscape';

      image.dispose();

      return detectedMode;
    } catch (e) {
      // Detection failed, return null
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isDetectingViewMode = false;
        });
      }
    }
  }

  Future<void> _autoDetectViewMode() async {
    final detectedMode = await _detectViewMode();
    if (detectedMode != null && mounted) {
      setState(() {
        _viewMode = detectedMode;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('View mode detected: $detectedMode'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not detect view mode. Please set manually.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveMetadata() async {
    
    final metadata = FileMetadata(
      stableIdentifier: widget.file.stableIdentifier,
      tags: _tags,
      notes: _notesController.text.trim().isEmpty 
          ? null 
          : _notesController.text.trim(),
      cast: _cast,
      viewMode: _viewMode,
      lastUpdated: DateTime.now(),
    );

    try {
      await widget.cubit.saveFileMetadata(metadata);
      if (mounted) {
        Navigator.of(context).pop(metadata);
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
          Text(
            'Edit File Metadata',
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            widget.file.decodedName,
            style: textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),

          // Tags input
          Text(
            'Tags',
            style: textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          
          // Show current file's tags
          if (_tags.isNotEmpty) ...[
            Text(
              'Current tags:',
              style: textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
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
            const SizedBox(height: 12),
          ],
          
          // Searchable tag input with autocomplete
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                // Show all available tags when field is empty
                return _allAvailableTags.toList()..sort();
              } else {
                // Filter tags based on input
                final query = textEditingValue.text.toLowerCase();
                return _allAvailableTags
                    .where((tag) => tag.toLowerCase().contains(query))
                    .toList()
                  ..sort();
              }
            },
            onSelected: (String tag) {
              // Add tag if not already present
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
                      // Update suffix icon visibility
                      setState(() {});
                    },
                    onSubmitted: (String value) {
                      // If user types a new tag and presses enter, add it
                      final trimmedValue = value.trim();
                      if (trimmedValue.isNotEmpty && !_tags.contains(trimmedValue)) {
                        this.setState(() {
                          _tags.add(trimmedValue);
                          // Also add to available tags for future use
                          _allAvailableTags.add(trimmedValue);
                        });
                      }
                      textEditingController.clear();
                      setState(() {});
                    },
                    textInputAction: TextInputAction.done,
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
          Text(
            '${_allAvailableTags.length} tag${_allAvailableTags.length != 1 ? 's' : ''} available',
            style: textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),

          // Notes input
          Text(
            'Notes',
            style: textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              hintText: 'Add notes about this file...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 24),

          // Cast input
          Text(
            'Cast',
            style: textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          
          // Show current file's cast
          if (_cast.isNotEmpty) ...[
            Text(
              'Current cast:',
              style: textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
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
            const SizedBox(height: 12),
          ],
          
          // Searchable cast input with autocomplete
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                // Show all available cast when field is empty
                return _allAvailableCast.toList()..sort();
              } else {
                // Filter cast based on input
                final query = textEditingValue.text.toLowerCase();
                return _allAvailableCast
                    .where((name) => name.toLowerCase().contains(query))
                    .toList()
                  ..sort();
              }
            },
            onSelected: (String name) {
              // Add cast member if not already present
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
                      // Update suffix icon visibility
                      setState(() {});
                    },
                    onSubmitted: (String value) {
                      // If user types a new cast member and presses enter, add it
                      final trimmedValue = value.trim();
                      if (trimmedValue.isNotEmpty && !_cast.contains(trimmedValue)) {
                        this.setState(() {
                          _cast.add(trimmedValue);
                          // Also add to available cast for future use
                          _allAvailableCast.add(trimmedValue);
                        });
                      }
                      textEditingController.clear();
                      setState(() {});
                    },
                    textInputAction: TextInputAction.done,
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
          Text(
            '${_allAvailableCast.length} cast member${_allAvailableCast.length != 1 ? 's' : ''} available',
            style: textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),

          // View Mode input
          Text(
            'View Mode',
            style: textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _viewMode,
                  decoration: const InputDecoration(
                    hintText: 'Select view mode',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'portrait', child: Text('Portrait')),
                    DropdownMenuItem(value: 'landscape', child: Text('Landscape')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _viewMode = value;
                    });
                  },
                ),
              ),
              if (widget.file.isImage) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Auto-detect view mode from image dimensions',
                  child: IconButton(
                    icon: _isDetectingViewMode
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_fix_high),
                    onPressed: _isDetectingViewMode ? null : _autoDetectViewMode,
                  ),
                ),
              ],
            ],
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

