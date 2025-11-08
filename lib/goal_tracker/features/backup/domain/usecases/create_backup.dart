import '../entities/backup_mode.dart';

import '../entities/backup_result.dart';
import '../repositories/backup_repository.dart';

/// Use case for creating a backup.
class CreateBackup {
  final BackupRepository repository;

  CreateBackup(this.repository);

  Future<BackupResult> call({
    required BackupMode mode,
    String? passphrase,
  }) {
    return repository.createBackup(
      mode: mode,
      passphrase: passphrase,
    );
  }
}

