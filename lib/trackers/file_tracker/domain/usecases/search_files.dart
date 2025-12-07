import '../entities/cloud_file.dart';
import '../entities/file_server_config.dart';
import '../repositories/file_repository.dart';

/// Use case for searching files by filename.
class SearchFiles {
  final FileRepository repository;

  SearchFiles(this.repository);

  /// Executes the use case to search files by filename.
  ///
  /// Returns files whose names contain the [query] string (case-insensitive).
  /// If [query] is empty or null, returns all files.
  Future<List<CloudFile>> call(
    FileServerConfig config,
    String? query,
  ) {
    return repository.searchFiles(config, query);
  }
}

