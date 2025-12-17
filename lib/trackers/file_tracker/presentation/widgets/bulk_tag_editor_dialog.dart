import 'package:flutter/material.dart';
import '../../domain/entities/file_metadata.dart';
import '../bloc/file_cubit.dart';
import '../../../../widgets/bottom_sheet_helpers.dart';

/// Bottom sheet for adding tags to multiple files at once.
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
  late TextEditingController _tagsController;
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _tagsController = TextEditingController();
  }

  @override
  void dispose() {
    _tagsController.dispose();
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

  Future<void> _saveTags() async {
    _parseTags();
    
    if (_tags.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter at least one tag')),
        );
      }
      return;
    }

    try {
      // Add tags to all selected files
      for (final stableIdentifier in widget.fileStableIdentifiers) {
        // Get existing metadata
        final existingMetadata = await widget.cubit.getFileMetadata(stableIdentifier);
        
        // Merge tags (avoid duplicates)
        final existingTags = existingMetadata?.tags ?? [];
        final mergedTags = <String>{...existingTags, ..._tags}.toList();
        
        // Create or update metadata
        final updatedMetadata = existingMetadata?.copyWith(
          tags: mergedTags,
          lastUpdated: DateTime.now(),
        ) ?? FileMetadata(
          stableIdentifier: stableIdentifier,
          tags: mergedTags,
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
                'Add Tags to Files',
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
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveTags(),
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
                onPressed: _saveTags,
                child: const Text('Add Tags'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

