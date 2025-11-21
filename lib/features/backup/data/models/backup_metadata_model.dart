import 'package:hive/hive.dart';

part 'backup_metadata_model.g.dart';

/// Hive model for backup metadata stored locally.
/// 
/// TypeId: 5
@HiveType(typeId: 5)
class BackupMetadataModel extends HiveObject {
  /// Drive file ID
  @HiveField(0)
  String id;

  /// Backup file name
  @HiveField(1)
  String fileName;

  /// When the backup was created
  @HiveField(2)
  DateTime createdAt;

  /// Device ID that created the backup
  @HiveField(3)
  String deviceId;

  /// Size of the backup in bytes
  @HiveField(4)
  int sizeBytes;

  /// Whether this backup is end-to-end encrypted
  @HiveField(5)
  bool isE2EE;

  /// Human-readable device description (optional)
  @HiveField(6)
  String? deviceDescription;

  BackupMetadataModel({
    required this.id,
    required this.fileName,
    required this.createdAt,
    required this.deviceId,
    required this.sizeBytes,
    required this.isE2EE,
    this.deviceDescription,
  });
}

