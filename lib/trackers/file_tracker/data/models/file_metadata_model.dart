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
  final List<String> cast;

  @HiveField(4)
  final String? viewMode;

  @HiveField(5)
  final DateTime lastUpdated;

  FileMetadataModel({
    required this.stableIdentifier,
    required this.tags,
    this.notes,
    required this.cast,
    this.viewMode,
    required this.lastUpdated,
  });

  /// Creates a model from a domain entity.
  factory FileMetadataModel.fromEntity(FileMetadata entity) {
    // Ensure we create new list instances to avoid any reference issues
    final tagsList = entity.tags.isNotEmpty 
        ? List<String>.from(entity.tags)
        : <String>[];
    final castList = entity.cast.isNotEmpty
        ? List<String>.from(entity.cast)
        : <String>[];
    
    return FileMetadataModel(
      stableIdentifier: entity.stableIdentifier,
      tags: tagsList,
      notes: entity.notes,
      cast: castList,
      viewMode: entity.viewMode,
      lastUpdated: entity.lastUpdated,
    );
  }

  /// Converts this model to a domain entity.
  FileMetadata toEntity() {
    return FileMetadata(
      stableIdentifier: stableIdentifier,
      tags: List<String>.from(tags),
      notes: notes,
      cast: List<String>.from(cast),
      viewMode: viewMode,
      lastUpdated: lastUpdated,
    );
  }
}

