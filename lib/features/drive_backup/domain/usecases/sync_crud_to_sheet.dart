import '../repositories/drive_backup_repository.dart';

/// Use case for syncing CRUD operations to Google Sheets.
class SyncCrudToSheet {
  final DriveBackupRepository repository;

  SyncCrudToSheet(this.repository);

  /// Sync queued CRUD operations to Google Sheets.
  Future<void> call() {
    return repository.syncCrudToSheet();
  }
}

