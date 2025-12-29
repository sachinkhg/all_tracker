/// Configuration for Drive backup feature.
/// 
/// Stores the selected folder ID, spreadsheet ID, and last sync timestamp.
class DriveBackupConfig {
  /// The ID of the Google Drive folder where backups are stored.
  final String folderId;

  /// The ID of the Google Sheets spreadsheet for CRUD logging.
  final String spreadsheetId;

  /// Timestamp of the last successful backup.
  final DateTime? lastBackupTime;

  /// Timestamp of the last successful restore.
  final DateTime? lastRestoreTime;

  /// Timestamp of the last sync to Google Sheets.
  final DateTime? lastSheetSyncTime;

  DriveBackupConfig({
    required this.folderId,
    required this.spreadsheetId,
    this.lastBackupTime,
    this.lastRestoreTime,
    this.lastSheetSyncTime,
  });

  /// Create a copy with updated fields.
  DriveBackupConfig copyWith({
    String? folderId,
    String? spreadsheetId,
    DateTime? lastBackupTime,
    DateTime? lastRestoreTime,
    DateTime? lastSheetSyncTime,
  }) {
    return DriveBackupConfig(
      folderId: folderId ?? this.folderId,
      spreadsheetId: spreadsheetId ?? this.spreadsheetId,
      lastBackupTime: lastBackupTime ?? this.lastBackupTime,
      lastRestoreTime: lastRestoreTime ?? this.lastRestoreTime,
      lastSheetSyncTime: lastSheetSyncTime ?? this.lastSheetSyncTime,
    );
  }
}

