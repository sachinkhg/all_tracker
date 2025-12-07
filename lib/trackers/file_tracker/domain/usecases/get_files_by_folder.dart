import '../entities/cloud_file.dart';
import '../entities/file_server_config.dart';
import '../repositories/file_repository.dart';

/// Use case for fetching files filtered by folder/path.
class GetFilesByFolder {
  final FileRepository repository;

  GetFilesByFolder(this.repository);

  /// Executes the use case to fetch files filtered by folder.
  ///
  /// If [folder] is empty or null, returns all files.
  Future<List<CloudFile>> call(
    FileServerConfig config,
    String? folder,
  ) {
    return repository.getFilesByFolder(config, folder);
  }
}

