import '../entities/file_metadata.dart';

/// Repository interface for managing file metadata (tags, notes).
///
/// This repository handles persistence of file metadata keyed by stable identifiers,
/// allowing tags to persist even when server URLs change.
abstract class FileMetadataRepository {
  /// Gets metadata for a file by its stable identifier.
  ///
  /// Returns null if no metadata exists for this file.
  Future<FileMetadata?> getMetadata(String stableIdentifier);

  /// Gets metadata for multiple files by their stable identifiers.
  ///
  /// Returns a map of stableIdentifier -> FileMetadata.
  Future<Map<String, FileMetadata>> getMetadataBatch(List<String> stableIdentifiers);

  /// Saves or updates metadata for a file.
  ///
  /// If metadata already exists for this stable identifier, it will be updated.
  /// Otherwise, a new metadata entry will be created.
  Future<void> saveMetadata(FileMetadata metadata);

  /// Deletes metadata for a file by its stable identifier.
  Future<void> deleteMetadata(String stableIdentifier);

  /// Gets all metadata entries.
  ///
  /// Useful for migration or bulk operations.
  Future<List<FileMetadata>> getAllMetadata();

  /// Searches for files by tags.
  ///
  /// Returns a list of stable identifiers that match any of the provided tags.
  Future<List<String>> searchByTags(List<String> tags);
}

