import 'package:flutter/material.dart';
import '../../domain/entities/cloud_file.dart';
import '../../domain/entities/file_server_config.dart';
import '../../domain/entities/file_metadata.dart';
import 'file_thumbnail_widget.dart';

/// List item widget for displaying a file in list format.
class FileListItem extends StatelessWidget {
  final CloudFile file;
  final FileServerConfig config;
  final FileMetadata? metadata;
  final bool isMultiSelectMode;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const FileListItem({
    super.key,
    required this.file,
    required this.config,
    this.metadata,
    this.isMultiSelectMode = false,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return ListTile(
      selected: isSelected && isMultiSelectMode,
      selectedTileColor: cs.primaryContainer.withValues(alpha: 0.3),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMultiSelectMode && !file.isFolder)
            Checkbox(
              value: isSelected,
              onChanged: null, // Handled by onTap
            ),
          SizedBox(
            width: 60,
            height: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: FileThumbnailWidget(
                file: file,
                config: config,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
      title: Text(file.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (file.folder.isNotEmpty) Text('Folder: ${file.folder}'),
          if (file.size != null) Text(file.formattedSize),
          if (file.modifiedDate != null)
            Text(
              'Modified: ${_formatDate(file.modifiedDate!)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          // Display tags if available
          if (metadata != null && metadata!.hasTags) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: metadata!.tags.take(3).map((tag) {
                return Chip(
                  label: Text(
                    tag,
                    style: const TextStyle(fontSize: 11),
                  ),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: cs.primaryContainer,
                  labelStyle: TextStyle(color: cs.onPrimaryContainer),
                );
              }).toList(),
            ),
            if (metadata!.tags.length > 3)
              Text(
                '+${metadata!.tags.length - 3} more',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (metadata != null && metadata!.hasTags)
            Icon(
              Icons.label,
              size: 18,
              color: cs.primary,
            ),
          const SizedBox(width: 8),
          file.isVideo
              ? const Icon(Icons.play_circle_filled)
              : file.isImage
                  ? const Icon(Icons.image)
                  : const Icon(Icons.insert_drive_file),
        ],
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

