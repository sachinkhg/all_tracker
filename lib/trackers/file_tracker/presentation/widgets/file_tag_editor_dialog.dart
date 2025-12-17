import 'package:flutter/material.dart';
import '../../domain/entities/cloud_file.dart';
import '../../domain/entities/file_metadata.dart';
import '../bloc/file_cubit.dart';
import '../../../../widgets/bottom_sheet_helpers.dart';

/// Dialog for adding/editing tags and notes for a file.
///
/// This dialog allows users to:
/// - Add/remove tags (comma-separated or individual)
/// - Add/edit notes
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
  late TextEditingController _tagsController;
  late TextEditingController _notesController;
  List<String> _tags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tagsController = TextEditingController();
    _notesController = TextEditingController();
    _loadExistingMetadata();
  }

  Future<void> _loadExistingMetadata() async {
    try {
      final metadata = await widget.cubit.getFileMetadata(widget.file.stableIdentifier);
      if (metadata != null) {
        setState(() {
          _tags = List<String>.from(metadata.tags);
          _tagsController.text = _tags.join(', ');
          _notesController.text = metadata.notes ?? '';
        });
      }
    } catch (e) {
      // Error loading metadata, start with empty
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tagsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _parseTags() {
    final text = _tagsController.text.trim();
    if (text.isEmpty) {
      _tags = [];
      return;
    }
    
    // Split by comma and clean up
    _tags = text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  Future<void> _saveMetadata() async {
    _parseTags();
    
    final metadata = FileMetadata(
      stableIdentifier: widget.file.stableIdentifier,
      tags: _tags,
      notes: _notesController.text.trim().isEmpty 
          ? null 
          : _notesController.text.trim(),
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
          SnackBar(content: Text('Failed to save tags: $e')),
        );
      }
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      _tagsController.text = _tags.join(', ');
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
            'Edit Tags & Notes',
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            widget.file.name,
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
          TextField(
            controller: _tagsController,
            decoration: InputDecoration(
              hintText: 'Enter tags separated by commas (e.g., vacation, beach, 2024)',
              border: const OutlineInputBorder(),
              suffixIcon: _tagsController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _tagsController.clear();
                          _tags.clear();
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (_) {
              _parseTags();
              setState(() {});
            },
            textInputAction: TextInputAction.next,
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
            textInputAction: TextInputAction.done,
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

