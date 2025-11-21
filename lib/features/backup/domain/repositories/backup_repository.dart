import '../entities/backup_metadata.dart';
import '../entities/backup_result.dart';
import '../entities/restore_result.dart';
import '../entities/backup_progress.dart';
import '../entities/backup_mode.dart';

/// Repository interface for backup operations.
abstract class BackupRepository {
  /// Create a new backup.
  /// 
  /// [mode]: The encryption mode (deviceKey or e2ee)
  /// [passphrase]: The passphrase for E2EE mode (required if mode is e2ee)
  /// 
  /// Returns the result of the backup operation.
  Future<BackupResult> createBackup({
    required BackupMode mode,
    String? passphrase,
  });

  /// List all available backups.
  /// 
  /// Returns a list of backup metadata sorted by creation date (newest first).
  Future<List<BackupMetadata>> listBackups();

  /// Restore a backup.
  /// 
  /// [backupId]: The ID of the backup to restore
  /// [passphrase]: The passphrase for E2EE backups (required if backup is E2EE)
  /// 
  /// Returns the result of the restore operation.
  Future<RestoreResult> restoreBackup({
    required String backupId,
    String? passphrase,
  });

  /// Delete a backup.
  /// 
  /// [backupId]: The ID of the backup to delete
  Future<void> deleteBackup(String backupId);

  /// Stream of backup progress events.
  /// 
  /// Emits progress updates during backup operations.
  Stream<BackupProgress> get backupProgress;
}

