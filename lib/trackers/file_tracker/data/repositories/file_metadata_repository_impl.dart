import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/file_metadata.dart';
import '../../domain/repositories/file_metadata_repository.dart';
import '../models/file_metadata_model.dart';
import '../../core/constants.dart';

/// Implementation of FileMetadataRepository using Hive for persistence.
class FileMetadataRepositoryImpl implements FileMetadataRepository {
  Box<FileMetadataModel>? _box;

  /// Gets the Hive box for file metadata.
  Future<Box<FileMetadataModel>> _getBox() async {
    _box ??= await Hive.openBox<FileMetadataModel>(fileTrackerMetadataBoxName);
    return _box!;
  }

  @override
  Future<FileMetadata?> getMetadata(String stableIdentifier) async {
    final box = await _getBox();
    final model = box.get(stableIdentifier);
    if (model != null) {
      final entity = model.toEntity();
      print('[FILE_METADATA_REPO] Loading metadata for: $stableIdentifier');
      print('[FILE_METADATA_REPO] Loaded Tags: ${entity.tags} (count: ${entity.tags.length})');
      print('[FILE_METADATA_REPO] Loaded Cast: ${entity.cast} (count: ${entity.cast.length})');
      return entity;
    }
    return null;
  }

  @override
  Future<Map<String, FileMetadata>> getMetadataBatch(
      List<String> stableIdentifiers) async {
    final box = await _getBox();
    final Map<String, FileMetadata> result = {};

    for (final identifier in stableIdentifiers) {
      final model = box.get(identifier);
      if (model != null) {
        result[identifier] = model.toEntity();
      }
    }

    return result;
  }

  @override
  Future<void> saveMetadata(FileMetadata metadata) async {
    final box = await _getBox();
    final model = FileMetadataModel.fromEntity(metadata);
    
    // Debug: Verify tags and cast are present before saving
    print('[FILE_METADATA_REPO] Saving metadata for: ${metadata.stableIdentifier}');
    print('[FILE_METADATA_REPO] Tags: ${metadata.tags} (count: ${metadata.tags.length})');
    print('[FILE_METADATA_REPO] Cast: ${metadata.cast} (count: ${metadata.cast.length})');
    print('[FILE_METADATA_REPO] Model tags: ${model.tags} (count: ${model.tags.length})');
    print('[FILE_METADATA_REPO] Model cast: ${model.cast} (count: ${model.cast.length})');
    
    await box.put(metadata.stableIdentifier, model);
    // Ensure data is persisted to disk
    await box.flush();
    
    // Verify the save by reading back
    final savedModel = box.get(metadata.stableIdentifier);
    if (savedModel != null) {
      print('[FILE_METADATA_REPO] Verified save - Tags: ${savedModel.tags} (count: ${savedModel.tags.length})');
      print('[FILE_METADATA_REPO] Verified save - Cast: ${savedModel.cast} (count: ${savedModel.cast.length})');
    } else {
      print('[FILE_METADATA_REPO] ERROR: Saved model not found after save!');
    }
  }

  @override
  Future<void> deleteMetadata(String stableIdentifier) async {
    final box = await _getBox();
    await box.delete(stableIdentifier);
  }

  @override
  Future<List<FileMetadata>> getAllMetadata() async {
    final box = await _getBox();
    return box.values.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<String>> searchByTags(List<String> tags) async {
    final box = await _getBox();
    final List<String> result = [];

    for (final entry in box.values) {
      final entity = entry.toEntity();
      // Check if any of the search tags match any of the file's tags
      if (entity.tags.any((fileTag) => tags.any((searchTag) =>
          fileTag.toLowerCase().contains(searchTag.toLowerCase())))) {
        result.add(entity.stableIdentifier);
      }
    }

    return result;
  }
}

