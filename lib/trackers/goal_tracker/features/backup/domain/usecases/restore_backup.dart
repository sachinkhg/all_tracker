import '../entities/restore_result.dart';
import '../repositories/backup_repository.dart';

/// Use case for restoring a backup.
class RestoreBackup {
  final BackupRepository repository;

  RestoreBackup(this.repository);

  Future<RestoreResult> call({
    required String backupId,
    String? passphrase,
  }) {
    return repository.restoreBackup(
      backupId: backupId,
      passphrase: passphrase,
    );
  }
}

