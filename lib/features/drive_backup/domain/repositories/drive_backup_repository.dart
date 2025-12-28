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

  /// Sync queued CRUD operations to Google Sheets.
  Future<void> syncCrudToSheet();

  /// Sync actions from Google Sheets to the app.
  /// 
  /// Reads rows with actions (CREATE, UPDATE, DELETE) from the sheet,
  /// processes them, and clears the action column after processing.
  /// 
  /// - CREATE with no GUID: generates GUID and creates new book
  /// - CREATE with existing GUID: adds read history entry to existing book
  /// - UPDATE: updates existing book
  /// - DELETE: deletes book by ID
  Future<void> syncActionsFromSheet();
}

