import '../repositories/drive_backup_repository.dart';

/// Use case for backing up data to Drive.
class BackupToDrive {
  final DriveBackupRepository repository;

  BackupToDrive(this.repository);

  /// Backup book tracker data to Drive.
  Future<void> call() {
    return repository.backupToDrive();
  }
}

