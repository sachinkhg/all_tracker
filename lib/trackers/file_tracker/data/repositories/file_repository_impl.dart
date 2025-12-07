import '../../domain/entities/cloud_file.dart';
import '../../domain/entities/file_server_config.dart';
import '../../domain/entities/file_type.dart';
import '../../domain/repositories/file_repository.dart';
import '../datasources/file_remote_data_source.dart';

/// Concrete implementation of [FileRepository] using HTTP data source.
class FileRepositoryImpl implements FileRepository {
  final FileRemoteDataSource dataSource;

  FileRepositoryImpl(this.dataSource);

  @override
  Future<List<CloudFile>> getFiles(FileServerConfig config) async {
    return await dataSource.getFiles(config);
  }

  @override
  Future<List<CloudFile>> getFilesByType(
    FileServerConfig config,
    FileType? type,
  ) async {
    final allFiles = await dataSource.getFiles(config);
    if (type == null) {
      return allFiles;
    }
    return allFiles.where((file) => file.type == type).toList();
  }

  @override
  Future<List<CloudFile>> getFilesByFolder(
    FileServerConfig config,
    String? folder,
  ) async {
    final allFiles = await dataSource.getFiles(config);
    if (folder == null || folder.isEmpty) {
      return allFiles;
    }
    return allFiles.where((file) => file.folder == folder).toList();
  }

  @override
  Future<List<CloudFile>> searchFiles(
    FileServerConfig config,
    String? query,
  ) async {
    final allFiles = await dataSource.getFiles(config);
    if (query == null || query.isEmpty) {
      return allFiles;
    }
    final lowerQuery = query.toLowerCase();
    return allFiles
        .where((file) => file.name.toLowerCase().contains(lowerQuery))
        .toList();
  }
}

