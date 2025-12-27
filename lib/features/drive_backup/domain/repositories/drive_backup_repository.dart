import '../entities/drive_backup_config.dart';

/// Repository interface for Drive backup operations.
abstract class DriveBackupRepository {
  /// Get the current Drive backup configuration.
  Future<DriveBackupConfig?> getConfig();

  /// Save the Drive backup configuration.
  Future<void> saveConfig(DriveBackupConfig config);

  /// Setup Drive backup by creating folder structure and spreadsheet.
  /// 
  /// [rootFolderId]: The ID of the root folder (user-selected)
  /// [trackerName]: The name of the tracker (e.g., 'Book Tracker')
  /// 
  /// Returns the created configuration.
  Future<DriveBackupConfig> setupBackup(
    String rootFolderId,
    String trackerName,
  );

  /// Backup book tracker data to Drive.
  /// 
  /// Serializes all books to JSON and uploads to Drive folder.
  /// Also syncs CRUD operations to Google Sheets.
  Future<void> backupToDrive();

  /// Restore book tracker data from Drive.
  /// 
  /// Checks if Google Sheet is newer than JSON file.
  /// If sheet is newer, restores from sheet; otherwise from JSON.
  Future<void> restoreFromDrive();

  /// Sync queued CRUD operations to Google Sheets.
  Future<void> syncCrudToSheet();
}

