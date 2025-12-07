import '../entities/cloud_file.dart';
import '../entities/file_server_config.dart';
import '../repositories/file_repository.dart';

/// Use case for fetching all files from the server.
class GetFiles {
  final FileRepository repository;

  GetFiles(this.repository);

  /// Executes the use case to fetch all files.
  ///
  /// Throws an exception if the server cannot be accessed or files cannot be retrieved.
  Future<List<CloudFile>> call(FileServerConfig config) {
    return repository.getFiles(config);
  }
}

