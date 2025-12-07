import 'package:flutter/material.dart';
import '../../domain/entities/cloud_file.dart';
import '../../domain/entities/file_server_config.dart';
import 'file_thumbnail_widget.dart';

/// List item widget for displaying a file in list format.
class FileListItem extends StatelessWidget {
  final CloudFile file;
  final FileServerConfig config;
  final VoidCallback? onTap;

  const FileListItem({
    super.key,
    required this.file,
    required this.config,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SizedBox(
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
        ],
      ),
      trailing: file.isVideo
          ? const Icon(Icons.play_circle_filled)
          : file.isImage
              ? const Icon(Icons.image)
              : const Icon(Icons.insert_drive_file),
      onTap: onTap,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

