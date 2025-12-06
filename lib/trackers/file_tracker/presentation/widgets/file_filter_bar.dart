import 'package:flutter/material.dart';
import '../../domain/entities/file_type.dart';
import '../../core/app_icons.dart';

/// Filter bar widget for filtering files by type, folder, and search.
class FileFilterBar extends StatelessWidget {
  final FileType? selectedType;
  final String? selectedFolder;
  final String? searchQuery;
  final List<String> availableFolders;
  final ValueChanged<FileType?>? onTypeChanged;
  final ValueChanged<String?>? onFolderChanged;
  final ValueChanged<String?>? onSearchChanged;
  final VoidCallback? onClearFilters;

  const FileFilterBar({
    super.key,
    this.selectedType,
    this.selectedFolder,
    this.searchQuery,
    this.availableFolders = const [],
    this.onTypeChanged,
    this.onFolderChanged,
    this.onSearchChanged,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = selectedType != null ||
        (selectedFolder != null && selectedFolder!.isNotEmpty) ||
        (searchQuery != null && searchQuery!.isNotEmpty);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search files...',
              prefixIcon: const Icon(FileTrackerIcons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              onSearchChanged?.call(value.isEmpty ? null : value);
            },
            controller: TextEditingController(text: searchQuery ?? '')
              ..selection = TextSelection.collapsed(
                offset: searchQuery?.length ?? 0,
              ),
          ),
        ),

        // Type and folder filters
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            children: [
              // Type filter
              Expanded(
                child: DropdownButtonFormField<FileType?>(
                  value: selectedType,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem<FileType?>(
                      value: null,
                      child: Text('All'),
                    ),
                    DropdownMenuItem<FileType?>(
                      value: FileType.image,
                      child: Text('Images'),
                    ),
                    DropdownMenuItem<FileType?>(
                      value: FileType.video,
                      child: Text('Videos'),
                    ),
                  ],
                  onChanged: onTypeChanged,
                  isExpanded: true,
                ),
              ),
              const SizedBox(width: 8),

              // Folder filter
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: selectedFolder,
                  decoration: InputDecoration(
                    labelText: 'Folder',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Folders'),
                    ),
                    ...availableFolders.map((folder) {
                      return DropdownMenuItem<String?>(
                        value: folder,
                        child: Text(
                          folder.isEmpty ? '(root)' : folder,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }),
                  ],
                  onChanged: onFolderChanged,
                  isExpanded: true,
                ),
              ),

              // Clear filters button
              if (hasActiveFilters)
                IconButton(
                  icon: const Icon(FileTrackerIcons.filter),
                  tooltip: 'Clear filters',
                  onPressed: onClearFilters,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

