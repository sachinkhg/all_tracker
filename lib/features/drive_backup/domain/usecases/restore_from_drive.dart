import '../repositories/drive_backup_repository.dart';

/// Use case for restoring data from Drive.
class RestoreFromDrive {
  final DriveBackupRepository repository;

  RestoreFromDrive(this.repository);

  /// Restore book tracker data from Drive.
  Future<void> call() {
    return repository.restoreFromDrive();
  }
}

