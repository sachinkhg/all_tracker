import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/cloud_file.dart';
import '../../domain/entities/file_server_config.dart';
import '../../domain/entities/file_type.dart';
import '../../domain/entities/file_metadata.dart';
import '../../domain/repositories/file_metadata_repository.dart';
import '../../domain/usecases/get_files.dart';
import '../../domain/usecases/get_files_by_type.dart';
import '../../domain/usecases/get_files_by_folder.dart';
import '../../domain/usecases/search_files.dart';
import 'file_state.dart';

/// Cubit for managing file operations and state.
///
/// Handles fetching files from the server, filtering by type/folder,
/// searching files by filename, and managing file metadata (tags, notes).
class FileCubit extends Cubit<FileState> {
  final GetFiles getFiles;
  final GetFilesByType getFilesByType;
  final GetFilesByFolder getFilesByFolder;
  final SearchFiles searchFiles;
  final FileMetadataRepository metadataRepository;

  FileServerConfig? _currentConfig;
  String? _originalBaseUrl; // Store original base URL (never changes)
  List<CloudFile> _allFiles = [];
  FileType? _currentTypeFilter;
  String? _currentFolderFilter;
  String? _currentSearchQuery;
  List<String> _navigationStack = []; // Track folder navigation path
  Map<String, FileMetadata> _metadataCache = {}; // Cache metadata by stable identifier

  FileCubit({
    required this.getFiles,
    required this.getFilesByType,
    required this.getFilesByFolder,
    required this.searchFiles,
    required this.metadataRepository,
  }) : super(FilesInitial());

  /// Loads files from the server using the provided config.
  /// [folderPath] - Optional folder path to navigate into (e.g., "photos/2024")
  Future<void> loadFiles(FileServerConfig config, {String? folderPath}) async {
    if (!config.isValid) {
      emit(FilesError('Invalid server configuration: baseUrl is required'));
      return;
    }

    _currentConfig = config;
    
    // Store or update original base URL
    if (_originalBaseUrl == null) {
      // First load - store original base URL
      _originalBaseUrl = config.baseUrl;
    } else if (_originalBaseUrl != config.baseUrl) {
      // Config changed - reset navigation and update original base URL
      _originalBaseUrl = config.baseUrl;
      _navigationStack.clear();
    }
    
    // Build the URL with folder path if provided
    String urlToFetch = _originalBaseUrl!;
    if (folderPath != null && folderPath.isNotEmpty) {
      // Clean up folder path (remove leading/trailing slashes)
      String cleanPath = folderPath.replaceAll(RegExp(r'^/+|/+$'), '');
      
      // Build URL relative to original base URL
      if (!urlToFetch.endsWith('/')) {
        urlToFetch = '$urlToFetch/';
      }
      urlToFetch = '$urlToFetch$cleanPath/';
    } else {
      // Ensure base URL ends with / for root directory listing
      if (!urlToFetch.endsWith('/')) {
        urlToFetch = '$urlToFetch/';
      }
    }
    
    // Create a modified config with the folder path for fetching
    final configWithPath = config.copyWith(baseUrl: urlToFetch);

    emit(FilesLoading());

    try {
      _allFiles = await getFiles(configWithPath);
      
      // Load metadata for all files using their stable identifiers
      await _loadMetadataForFiles(_allFiles);
      
      // Update navigation stack after successful load
      if (folderPath != null && folderPath.isNotEmpty) {
        // Split path into segments and update stack
        String cleanPath = folderPath.replaceAll(RegExp(r'^/+|/+$'), '');
        _navigationStack = cleanPath.split('/').where((s) => s.isNotEmpty).toList();
      } else {
        _navigationStack.clear();
      }
      
      emit(FilesLoaded(_allFiles, config: config, currentPath: _getCurrentPath()));
    } catch (e) {
      emit(FilesError('Failed to load files: $e'));
    }
  }

  /// Loads metadata for the given files and caches it.
  Future<void> _loadMetadataForFiles(List<CloudFile> files) async {
    try {
      final stableIdentifiers = files.map((f) => f.stableIdentifier).toList();
      final metadataMap = await metadataRepository.getMetadataBatch(stableIdentifiers);
      _metadataCache = metadataMap;
    } catch (e) {
      // If metadata loading fails, continue without metadata
      _metadataCache = {};
    }
  }
  
  /// Navigates into a folder.
  Future<void> navigateToFolder(CloudFile folder) async {
    if (!folder.isFolder) return;
    
    if (_currentConfig == null || _originalBaseUrl == null) return;
    
    // Get the folder name (remove trailing slash)
    String folderName = folder.name.replaceAll('/', '');
    
    // Build the full path by adding the folder name to current path
    List<String> newPath = List.from(_navigationStack);
    newPath.add(folderName);
    
    await loadFiles(_currentConfig!, folderPath: newPath.join('/'));
  }
  
  /// Navigates back to parent folder.
  Future<void> navigateBack() async {
    if (_navigationStack.isEmpty || _currentConfig == null) return;
    
    _navigationStack.removeLast();
    
    final parentPath = _navigationStack.isEmpty 
        ? null 
        : _navigationStack.join('/');
    
    await loadFiles(_currentConfig!, folderPath: parentPath);
  }
  
  /// Gets the current navigation path as a display string.
  String _getCurrentPath() {
    if (_navigationStack.isEmpty) return '/';
    return '/${_navigationStack.join('/')}';
  }
  
  /// Gets the current navigation path.
  String get currentPath => _getCurrentPath();
  
  /// Returns true if we can navigate back.
  bool canNavigateBack() => _navigationStack.isNotEmpty;

  /// Refreshes the file list (reloads current directory).
  Future<void> refreshFiles() async {
    if (_currentConfig == null) {
      emit(FilesError('No server configuration set'));
      return;
    }

    // Refresh current directory (preserve navigation)
    final currentPath = _navigationStack.isEmpty 
        ? null 
        : _navigationStack.join('/');
    await loadFiles(_currentConfig!, folderPath: currentPath);
  }

  /// Filters files by type.
  void filterByType(FileType? type) {
    _currentTypeFilter = type;
    _applyFilters();
  }

  /// Filters files by folder.
  void filterByFolder(String? folder) {
    _currentFolderFilter = folder;
    _applyFilters();
  }

  /// Searches files by filename.
  void searchByQuery(String? query) {
    _currentSearchQuery = query;
    _applyFilters();
  }

  /// Applies all active filters to the file list.
  void _applyFilters() {
    if (_currentConfig == null || _allFiles.isEmpty) {
      return;
    }

    var filtered = List<CloudFile>.from(_allFiles);

    // Apply type filter
    if (_currentTypeFilter != null) {
      filtered = filtered.where((f) => f.type == _currentTypeFilter).toList();
    }

    // Apply folder filter
    if (_currentFolderFilter != null && _currentFolderFilter!.isNotEmpty) {
      filtered = filtered
          .where((f) => f.folder == _currentFolderFilter)
          .toList();
    }

    // Apply search query
    if (_currentSearchQuery != null && _currentSearchQuery!.isNotEmpty) {
      final query = _currentSearchQuery!.toLowerCase();
      filtered = filtered
          .where((f) => f.name.toLowerCase().contains(query))
          .toList();
    }

    emit(FilesLoaded(filtered, config: _currentConfig, currentPath: _getCurrentPath()));
  }

  /// Gets a list of all unique folders from the current files.
  List<String> getAvailableFolders() {
    final folders = _allFiles
        .map((f) => f.folder)
        .where((f) => f.isNotEmpty)
        .toSet()
        .toList();
    folders.sort();
    return folders;
  }

  /// Clears all filters and shows all files.
  void clearFilters() {
    _currentTypeFilter = null;
    _currentFolderFilter = null;
    _currentSearchQuery = null;
    if (_currentConfig != null) {
      emit(FilesLoaded(_allFiles, config: _currentConfig, currentPath: _getCurrentPath()));
    }
  }

  /// Gets the current config.
  FileServerConfig? get currentConfig => _currentConfig;

  /// Gets metadata for a file by its stable identifier.
  Future<FileMetadata?> getFileMetadata(String stableIdentifier) async {
    // Check cache first
    if (_metadataCache.containsKey(stableIdentifier)) {
      return _metadataCache[stableIdentifier];
    }
    
    // Load from repository if not in cache
    final metadata = await metadataRepository.getMetadata(stableIdentifier);
    if (metadata != null) {
      _metadataCache[stableIdentifier] = metadata;
    }
    return metadata;
  }

  /// Gets metadata for a CloudFile.
  FileMetadata? getMetadataForFile(CloudFile file) {
    return _metadataCache[file.stableIdentifier];
  }

  /// Saves or updates metadata for a file.
  Future<void> saveFileMetadata(FileMetadata metadata) async {
    await metadataRepository.saveMetadata(metadata);
    _metadataCache[metadata.stableIdentifier] = metadata;
    
    // Emit updated state to refresh UI
    if (state is FilesLoaded) {
      final currentState = state as FilesLoaded;
      emit(FilesLoaded(_allFiles, config: currentState.config, currentPath: currentState.currentPath));
    }
  }

  /// Deletes metadata for a file.
  Future<void> deleteFileMetadata(String stableIdentifier) async {
    await metadataRepository.deleteMetadata(stableIdentifier);
    _metadataCache.remove(stableIdentifier);
    
    // Emit updated state to refresh UI
    if (state is FilesLoaded) {
      final currentState = state as FilesLoaded;
      emit(FilesLoaded(_allFiles, config: currentState.config, currentPath: currentState.currentPath));
    }
  }

  /// Searches for files by tags.
  Future<List<String>> searchFilesByTags(List<String> tags) async {
    return await metadataRepository.searchByTags(tags);
  }
}

