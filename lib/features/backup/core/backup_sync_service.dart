import 'package:flutter/foundation.dart';
import 'backup_preferences_service.dart';
import '../domain/usecases/list_backups.dart';
import '../domain/usecases/restore_backup.dart';
import '../domain/entities/backup_metadata.dart';
import '../domain/entities/restore_result.dart';
import '../data/datasources/google_auth_datasource.dart';

/// Service for automatically syncing/restoring from cloud backups.
/// 
/// Compares local data with cloud backups and restores if a newer backup is available.
class BackupSyncService {
  final BackupPreferencesService _preferencesService;
  final ListBackups _listBackupsUseCase;
  final RestoreBackup _restoreBackupUseCase;
  final GoogleAuthDataSource _googleAuth;

  BackupSyncService({
    required BackupPreferencesService preferencesService,
    required ListBackups listBackupsUseCase,
    required RestoreBackup restoreBackupUseCase,
    required GoogleAuthDataSource googleAuth,
  })  : _preferencesService = preferencesService,
        _listBackupsUseCase = listBackupsUseCase,
        _restoreBackupUseCase = restoreBackupUseCase,
        _googleAuth = googleAuth;


  /// Check for newer automatic backups and restore if available.
  /// 
  /// This should be called on app startup and when app comes from background.
  /// Only restores if:
  /// - User is signed in
  /// - Automatic backups are enabled
  /// - A newer automatic backup exists (newer than last restore time or last backup time)
  Future<void> checkAndRestoreIfNeeded() async {
    debugPrint('[BACKUP_SYNC] Checking for newer backups to restore...');

    // Check if user is signed in
    final isSignedIn = await _googleAuth.isSignedIn();
    if (!isSignedIn) {
      debugPrint('[BACKUP_SYNC] User not signed in, skipping restore check');
      return;
    }

    // Check if automatic backups are enabled
    if (!_preferencesService.autoBackupEnabled) {
      debugPrint('[BACKUP_SYNC] Automatic backups disabled, skipping restore check');
      return;
    }

    try {
      // Get all backups
      final allBackups = await _listBackupsUseCase.call();
      
      // Filter to only automatic backups (no name)
      final automaticBackups = allBackups
          .where((b) => b.name == null || b.name!.isEmpty)
          .toList();

      if (automaticBackups.isEmpty) {
        debugPrint('[BACKUP_SYNC] No automatic backups found');
        return;
      }

      // Sort by creation date (newest first)
      automaticBackups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final latestBackup = automaticBackups.first;

      debugPrint('[BACKUP_SYNC] Latest automatic backup: ${latestBackup.id} created at ${latestBackup.createdAt}');

      // Determine the reference time to compare against
      // Use the later of: last restore time or last backup time
      final lastRestore = _preferencesService.lastRestoreTime;
      final lastBackup = _preferencesService.lastBackupTime;
      
      DateTime? referenceTime;
      if (lastRestore != null && lastBackup != null) {
        referenceTime = lastRestore.isAfter(lastBackup) ? lastRestore : lastBackup;
      } else if (lastRestore != null) {
        referenceTime = lastRestore;
      } else if (lastBackup != null) {
        referenceTime = lastBackup;
      }

      // If we have a reference time and the latest backup is newer, restore it
      if (referenceTime != null) {
        if (latestBackup.createdAt.isAfter(referenceTime)) {
          debugPrint('[BACKUP_SYNC] Found newer backup (${latestBackup.createdAt}) than reference time ($referenceTime), restoring...');
          await _restoreBackup(latestBackup);
        } else {
          debugPrint('[BACKUP_SYNC] Latest backup (${latestBackup.createdAt}) is not newer than reference time ($referenceTime), no restore needed');
        }
      } else {
        // No reference time - this might be first time or no previous restore/backup
        // Check if we should restore the latest backup
        // Only restore if the backup is recent (within last 24 hours) to avoid restoring old backups
        final now = DateTime.now();
        final hoursSinceBackup = now.difference(latestBackup.createdAt).inHours;
        
        if (hoursSinceBackup <= 24) {
          debugPrint('[BACKUP_SYNC] No reference time found, but latest backup is recent ($hoursSinceBackup hours ago), restoring...');
          await _restoreBackup(latestBackup);
        } else {
          debugPrint('[BACKUP_SYNC] No reference time found, and latest backup is old ($hoursSinceBackup hours ago), skipping restore');
        }
      }
    } catch (e) {
      debugPrint('[BACKUP_SYNC] Error checking for restore: $e');
    }
  }

  /// Restore a specific backup.
  Future<void> _restoreBackup(BackupMetadata backup) async {
    try {
      debugPrint('[BACKUP_SYNC] Starting restore from backup: ${backup.id}');
      
      // For automatic backups, use device key mode (no passphrase needed)
      final result = await _restoreBackupUseCase.call(
        backupId: backup.id,
        passphrase: null,
      );

      if (result is RestoreSuccess) {
        await _preferencesService.setLastRestoreTime(DateTime.now());
        debugPrint('[BACKUP_SYNC] Successfully restored from backup: ${backup.id}');
      } else if (result is RestoreFailure) {
        debugPrint('[BACKUP_SYNC] Failed to restore backup: ${result.error}');
      }
    } catch (e) {
      debugPrint('[BACKUP_SYNC] Error restoring backup: $e');
    }
  }
}

