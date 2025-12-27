import '../entities/drive_backup_config.dart';
import '../repositories/drive_backup_repository.dart';

/// Use case for setting up Drive backup.
class SetupDriveBackup {
  final DriveBackupRepository repository;

  SetupDriveBackup(this.repository);

  /// Setup Drive backup for a tracker.
  /// 
  /// [rootFolderId]: The ID of the root folder (user-selected)
  /// [trackerName]: The name of the tracker (e.g., 'Book Tracker')
  /// 
  /// Returns the created configuration.
  Future<DriveBackupConfig> call(String rootFolderId, String trackerName) {
    return repository.setupBackup(rootFolderId, trackerName);
  }
}

