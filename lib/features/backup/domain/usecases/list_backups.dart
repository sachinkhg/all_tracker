import '../entities/backup_metadata.dart';
import '../repositories/backup_repository.dart';

/// Use case for listing all backups.
class ListBackups {
  final BackupRepository repository;

  ListBackups(this.repository);

  Future<List<BackupMetadata>> call() {
    return repository.listBackups();
  }
}

