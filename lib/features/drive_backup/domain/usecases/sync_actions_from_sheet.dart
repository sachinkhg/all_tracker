import '../repositories/drive_backup_repository.dart';

/// Use case for syncing actions from Google Sheets.
/// 
/// Processes CREATE, UPDATE, and DELETE actions marked in the sheet
/// and applies them to the book tracker.
class SyncActionsFromSheet {
  final DriveBackupRepository repository;

  SyncActionsFromSheet(this.repository);

  /// Sync actions from Google Sheets to the app.
  /// 
  /// Reads rows with actions (CREATE, UPDATE, DELETE) from the sheet,
  /// processes them, and clears the action column after processing.
  Future<void> call() {
    return repository.syncActionsFromSheet();
  }
}

