import 'package:hive/hive.dart';
import '../../domain/entities/cloud_file.dart';
import '../../domain/entities/file_type.dart';

part 'cloud_file_model.g.dart'; // Generated via build_runner

/// Hive model for caching cloud file metadata.
///
/// TypeId: 31 (as documented in migration_notes.md)
@HiveType(typeId: 31)
class CloudFileModel extends HiveObject {
  /// Full URL to access the file.
  @HiveField(0)
  String url;

  /// Name of the file.
  @HiveField(1)
  String name;

  /// Type of the file (stored as enum name string).
  @HiveField(2)
  String type;

  /// Size of the file in bytes.
  @HiveField(3)
  int? size;

  /// Modification date of the file (stored as milliseconds since epoch).
  @HiveField(4)
  int? modifiedDateMs;

  /// Folder/path where the file is located.
  @HiveField(5)
  String folder;

  /// MIME type of the file.
  @HiveField(6)
  String? mimeType;

  CloudFileModel({
    required this.url,
    required this.name,
    required this.type,
    this.size,
    this.modifiedDateMs,
    this.folder = '',
    this.mimeType,
  });

  /// Factory constructor to build a [CloudFileModel] from a domain entity.
  factory CloudFileModel.fromEntity(CloudFile file) => CloudFileModel(
        url: file.url,
        name: file.name,
        type: file.type.name,
        size: file.size,
        modifiedDateMs: file.modifiedDate?.millisecondsSinceEpoch,
        folder: file.folder,
        mimeType: file.mimeType,
      );

  /// Converts this model back into a domain [CloudFile] entity.
  CloudFile toEntity() {
    FileType fileType;
    try {
      fileType = FileType.values.firstWhere(
        (e) => e.name == type,
        orElse: () => FileType.other,
      );
    } catch (e) {
      fileType = FileType.other;
    }

    return CloudFile(
      url: url,
      name: name,
      type: fileType,
      size: size,
      modifiedDate: modifiedDateMs != null
          ? DateTime.fromMillisecondsSinceEpoch(modifiedDateMs!)
          : null,
      folder: folder,
      mimeType: mimeType,
    );
  }

  /// Creates a copy of this model with the given fields replaced.
  CloudFileModel copyWith({
    String? url,
    String? name,
    String? type,
    int? size,
    int? modifiedDateMs,
    String? folder,
    String? mimeType,
  }) {
    return CloudFileModel(
      url: url ?? this.url,
      name: name ?? this.name,
      type: type ?? this.type,
      size: size ?? this.size,
      modifiedDateMs: modifiedDateMs ?? this.modifiedDateMs,
      folder: folder ?? this.folder,
      mimeType: mimeType ?? this.mimeType,
    );
  }
}

