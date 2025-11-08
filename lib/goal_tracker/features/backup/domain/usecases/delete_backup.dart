import '../repositories/backup_repository.dart';

/// Use case for deleting a backup.
class DeleteBackup {
  final BackupRepository repository;

  DeleteBackup(this.repository);

  Future<void> call(String backupId) {
    return repository.deleteBackup(backupId);
  }
}

