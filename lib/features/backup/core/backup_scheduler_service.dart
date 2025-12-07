import 'package:flutter/foundation.dart';
import 'backup_preferences_service.dart';
import '../domain/usecases/create_backup.dart';
import '../domain/usecases/list_backups.dart';
import '../domain/usecases/delete_backup.dart';
import '../domain/entities/backup_mode.dart';
import '../domain/entities/backup_result.dart';
import '../data/datasources/google_auth_datasource.dart';

/// Service for scheduling automatic backups.
/// 
/// Handles backup execution when app goes to background or closes.
/// Also manages cleanup of old automatic backups.
class BackupSchedulerService {
  final BackupPreferencesService _preferencesService;
  final CreateBackup _createBackupUseCase;
  final ListBackups _listBackupsUseCase;
  final DeleteBackup _deleteBackupUseCase;
  final GoogleAuthDataSource _googleAuth;

  // Flag to prevent concurrent backup operations
  bool _isBackupInProgress = false;

  BackupSchedulerService({
    required BackupPreferencesService preferencesService,
    required CreateBackup createBackupUseCase,
    required ListBackups listBackupsUseCase,
    required DeleteBackup deleteBackupUseCase,
    required GoogleAuthDataSource googleAuth,
  })  : _preferencesService = preferencesService,
        _createBackupUseCase = createBackupUseCase,
        _listBackupsUseCase = listBackupsUseCase,
        _deleteBackupUseCase = deleteBackupUseCase,
        _googleAuth = googleAuth;

  /// Run automatic backup when app goes to background or closes.
  /// 
  /// This should be called on app lifecycle changes (paused/inactive).
  /// Only runs if user is signed in to Google and automatic backup is enabled.
  Future<void> runAutomaticBackup() async {
    // Prevent concurrent backup operations
    if (_isBackupInProgress) {
      debugPrint('[AUTO_BACKUP] Backup already in progress, skipping...');
      return;
    }

    debugPrint('[AUTO_BACKUP] Checking if automatic backup should run...');
    
    // Check if automatic backup is enabled
    if (!_preferencesService.shouldRunAutomaticBackup()) {
      debugPrint('[AUTO_BACKUP] Automatic backup is disabled');
      return;
    }

    // Check if user is signed in - automatic backups require authentication
    final isSignedIn = await _googleAuth.isSignedIn();
    if (!isSignedIn) {
      debugPrint('[AUTO_BACKUP] Automatic backup skipped: user not signed in');
      return;
    }

    _isBackupInProgress = true;
    debugPrint('[AUTO_BACKUP] Starting automatic backup...');

    try {
      final mode = _preferencesService.backupMode;
      // For automatic backups, use device key mode if E2EE is selected
      // (since we can't prompt for passphrase automatically)
      final backupMode = mode == BackupMode.e2ee ? BackupMode.deviceKey : mode;
      
      // Create automatic backup (no name = automatic backup)
      final result = await _createBackupUseCase.call(
        mode: backupMode,
        passphrase: null,
        name: null, // No name indicates automatic backup
      );

      if (result is BackupSuccess) {
        await _preferencesService.setLastBackupTime(DateTime.now());
        debugPrint('[AUTO_BACKUP] Automatic backup completed successfully. Backup ID: ${result.backupId}, Size: ${result.sizeBytes} bytes');
        
        // Clean up old automatic backups after successful backup
        await _cleanupOldAutomaticBackups();
      } else if (result is BackupFailure) {
        debugPrint('[AUTO_BACKUP] Automatic backup failed: ${result.error}');
      }
    } catch (e) {
      // Silently fail automatic backups - don't disturb user
      // Errors will be logged for debugging
      debugPrint('[AUTO_BACKUP] Automatic backup failed: $e');
    } finally {
      _isBackupInProgress = false;
    }
  }

  /// Clean up old automatic backups, keeping only the last 3 automatic backups.
  /// Manual backups (those with a name) are always kept.
  Future<void> _cleanupOldAutomaticBackups() async {
    try {
      // Add a small delay to ensure the newly created backup is fully indexed in Google Drive
      await Future.delayed(const Duration(seconds: 2));
      
      final retentionCount = _preferencesService.retentionCount;
      debugPrint('[AUTO_BACKUP] Starting cleanup. Retention count: $retentionCount');
      
      final allBackups = await _listBackupsUseCase.call();
      debugPrint('[AUTO_BACKUP] Found ${allBackups.length} total backups');
      
      // Separate automatic backups (no name) from manual backups (has name)
      final automaticBackups = allBackups.where((b) => b.name == null || b.name!.isEmpty).toList();
      final manualBackups = allBackups.where((b) => b.name != null && b.name!.isNotEmpty).toList();
      
      debugPrint('[AUTO_BACKUP] Automatic backups: ${automaticBackups.length}, Manual backups: ${manualBackups.length}');
      
      // Sort automatic backups by creation date (newest first)
      automaticBackups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Log all automatic backups for debugging
      for (int i = 0; i < automaticBackups.length; i++) {
        debugPrint('[AUTO_BACKUP] Automatic backup $i: ${automaticBackups[i].id} created at ${automaticBackups[i].createdAt}');
      }
      
      // Keep only the last N automatic backups (where N = retentionCount)
      if (automaticBackups.length > retentionCount) {
        final backupsToDelete = automaticBackups.sublist(retentionCount);
        debugPrint('[AUTO_BACKUP] Need to delete ${backupsToDelete.length} old automatic backups');
        
        for (final backup in backupsToDelete) {
          try {
            debugPrint('[AUTO_BACKUP] Attempting to delete backup: ${backup.id}');
            await _deleteBackupUseCase.call(backup.id);
            debugPrint('[AUTO_BACKUP] Successfully deleted old automatic backup: ${backup.id}');
          } catch (e) {
            // Check if error is 404 (file not found) - this is OK, file may have been deleted already
            final errorString = e.toString();
            if (errorString.contains('404') || errorString.contains('not found') || errorString.contains('File not found')) {
              debugPrint('[AUTO_BACKUP] Backup ${backup.id} already deleted or not found, skipping...');
            } else {
              debugPrint('[AUTO_BACKUP] Failed to delete old backup ${backup.id}: $e');
            }
          }
        }
        
        debugPrint('[AUTO_BACKUP] Cleanup completed. Kept ${automaticBackups.length - backupsToDelete.length} automatic backups and ${manualBackups.length} manual backups.');
      } else {
        debugPrint('[AUTO_BACKUP] No cleanup needed. Current automatic backups (${automaticBackups.length}) <= retention count ($retentionCount)');
      }
    } catch (e) {
      // Don't fail the backup process if cleanup fails
      debugPrint('[AUTO_BACKUP] Failed to cleanup old automatic backups: $e');
    }
  }

  /// Check if automatic backup should run and execute it if needed.
  /// 
  /// This method is kept for backward compatibility but now just calls runAutomaticBackup.
  /// @deprecated Use runAutomaticBackup() instead
  Future<void> checkAndRunBackup() async {
    await runAutomaticBackup();
  }

  /// Force run a backup now (used for manual triggers).
  Future<bool> runBackupNow({
    required BackupMode mode,
    String? passphrase,
  }) async {
    try {
      final result = await _createBackupUseCase.call(
        mode: mode,
        passphrase: passphrase,
      );

      if (result is BackupSuccess) {
        await _preferencesService.setLastBackupTime(DateTime.now());
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Manual backup failed: $e');
      return false;
    }
  }
}

