import 'package:flutter/material.dart';
import '../../domain/entities/cloud_file.dart';
import '../../domain/entities/file_server_config.dart';
import '../../domain/entities/file_metadata.dart';
import 'file_thumbnail_widget.dart';

/// Grid view widget for displaying files in a gallery format.
class FileGalleryGrid extends StatelessWidget {
  final List<CloudFile> files;
  final FileServerConfig config;
  final Function(CloudFile)? onFileTap;
  final Function(CloudFile)? onFileLongPress;
  final Map<String, FileMetadata>? fileMetadata;
  final bool isMultiSelectMode;
  final Set<String> selectedFileIds;
  final int crossAxisCount;

  const FileGalleryGrid({
    super.key,
    required this.files,
    required this.config,
    this.onFileTap,
    this.onFileLongPress,
    this.fileMetadata,
    this.isMultiSelectMode = false,
    this.selectedFileIds = const {},
    this.crossAxisCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return const Center(
        child: Text('No files found'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        final metadata = fileMetadata?[file.stableIdentifier];
        final isSelected = selectedFileIds.contains(file.stableIdentifier);
        return _FileGridItem(
          file: file,
          config: config,
          metadata: metadata,
          isMultiSelectMode: isMultiSelectMode,
          isSelected: isSelected,
          onTap: () => onFileTap?.call(file),
          onLongPress: () => onFileLongPress?.call(file),
        );
      },
    );
  }
}

class _FileGridItem extends StatelessWidget {
  final CloudFile file;
  final FileServerConfig config;
  final FileMetadata? metadata;
  final bool isMultiSelectMode;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _FileGridItem({
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
    
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Selection overlay
          if (isMultiSelectMode)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? cs.primary.withValues(alpha: 0.3)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? cs.primary : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: file.isFolder
                ? Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder,
                            size: 48,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            file.name.replaceAll('/', ''),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  )
                : FileThumbnailWidget(
                    file: file,
                    config: config,
                    fit: BoxFit.cover,
                  ),
          ),
          // Folder indicator overlay
          if (file.isFolder)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.folder,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          // Video indicator overlay
          if (file.isVideo && !file.isFolder)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.play_circle_filled,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          // Selection checkbox
          if (isMultiSelectMode && !file.isFolder)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? cs.primary : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? cs.primary : Colors.grey,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: cs.onPrimary,
                      )
                    : null,
              ),
            ),
          // Tags indicator (if any and not in multi-select mode)
          if (!isMultiSelectMode && metadata != null && metadata!.hasTags && !file.isFolder)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.label,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${metadata!.tags.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // File name overlay at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Text(
                file.isFolder ? file.name.replaceAll('/', '') : file.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

