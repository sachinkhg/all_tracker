import '../entities/cloud_file.dart';
import '../entities/file_server_config.dart';
import '../entities/file_type.dart';
import '../repositories/file_repository.dart';

/// Use case for fetching files filtered by type.
class GetFilesByType {
  final FileRepository repository;

  GetFilesByType(this.repository);

  /// Executes the use case to fetch files filtered by type.
  ///
  /// If [type] is null, returns all files.
  Future<List<CloudFile>> call(
    FileServerConfig config,
    FileType? type,
  ) {
    return repository.getFilesByType(config, type);
  }
}

