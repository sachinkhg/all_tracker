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
    return model?.toEntity();
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
    await box.put(metadata.stableIdentifier, model);
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

