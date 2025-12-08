import 'package:hive/hive.dart';
import '../../domain/entities/file_metadata.dart';

part 'file_metadata_model.g.dart';

/// Hive model for FileMetadata entity.
///
/// TypeId: 31 (check migration_notes.md for typeId assignments)
@HiveType(typeId: 31)
class FileMetadataModel extends HiveObject {
  @HiveField(0)
  final String stableIdentifier;

  @HiveField(1)
  final List<String> tags;

  @HiveField(2)
  final String? notes;

  @HiveField(3)
  final DateTime lastUpdated;

  FileMetadataModel({
    required this.stableIdentifier,
    required this.tags,
    this.notes,
    required this.lastUpdated,
  });

  /// Creates a model from a domain entity.
  factory FileMetadataModel.fromEntity(FileMetadata entity) {
    return FileMetadataModel(
      stableIdentifier: entity.stableIdentifier,
      tags: List<String>.from(entity.tags),
      notes: entity.notes,
      lastUpdated: entity.lastUpdated,
    );
  }

  /// Converts this model to a domain entity.
  FileMetadata toEntity() {
    return FileMetadata(
      stableIdentifier: stableIdentifier,
      tags: List<String>.from(tags),
      notes: notes,
      lastUpdated: lastUpdated,
    );
  }
}

