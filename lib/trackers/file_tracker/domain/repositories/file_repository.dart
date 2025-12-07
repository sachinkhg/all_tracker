import '../entities/cloud_file.dart';
import '../entities/file_server_config.dart';
import '../entities/file_type.dart';

/// Abstract repository interface for file operations.
///
/// This interface defines the contract for accessing files from a remote server.
/// Implementations should handle HTTP requests, authentication, and parsing.
abstract class FileRepository {
  /// Fetches all files from the server.
  ///
  /// Uses the provided [config] to connect to the server.
  /// Returns a list of all files found on the server.
  /// Throws an exception if the server cannot be accessed or files cannot be retrieved.
  Future<List<CloudFile>> getFiles(FileServerConfig config);

  /// Fetches files filtered by type.
  ///
  /// Returns only files that match the specified [type].
  /// If [type] is null, returns all files.
  Future<List<CloudFile>> getFilesByType(
    FileServerConfig config,
    FileType? type,
  );

  /// Fetches files filtered by folder/path.
  ///
  /// Returns only files in the specified [folder].
  /// If [folder] is empty or null, returns all files.
  Future<List<CloudFile>> getFilesByFolder(
    FileServerConfig config,
    String? folder,
  );

  /// Searches for files by filename.
  ///
  /// Returns files whose names contain the [query] string (case-insensitive).
  /// If [query] is empty or null, returns all files.
  Future<List<CloudFile>> searchFiles(
    FileServerConfig config,
    String? query,
  );
}

