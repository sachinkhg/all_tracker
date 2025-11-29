import 'package:flutter/foundation.dart';
import 'backup_preferences_service.dart';
import '../domain/usecases/create_backup.dart';
import '../domain/entities/backup_mode.dart';
import '../domain/entities/backup_result.dart';
import '../data/datasources/google_auth_datasource.dart';

/// Service for scheduling automatic backups.
/// 
/// Handles periodic backup checking and execution when enabled.
class BackupSchedulerService {
  final BackupPreferencesService _preferencesService;
  final CreateBackup _createBackupUseCase;
  final GoogleAuthDataSource _googleAuth;

  BackupSchedulerService({
    required BackupPreferencesService preferencesService,
    required CreateBackup createBackupUseCase,
    required GoogleAuthDataSource googleAuth,
  })  : _preferencesService = preferencesService,
        _createBackupUseCase = createBackupUseCase,
        _googleAuth = googleAuth;

  /// Check if automatic backup should run and execute it if needed.
  /// 
  /// This should be called on app startup and periodically.
  /// Only runs if user is signed in to Google.
  Future<void> checkAndRunBackup() async {
    // Check if automatic backup is enabled and should run
    if (!_preferencesService.shouldRunAutomaticBackup()) {
      return;
    }

    // Check if user is signed in - automatic backups require authentication
    final isSignedIn = await _googleAuth.isSignedIn();
    if (!isSignedIn) {
      debugPrint('Automatic backup skipped: user not signed in');
      return;
    }

    try {
      final mode = _preferencesService.backupMode;
      // For automatic backups, use device key mode if E2EE is selected
      // (since we can't prompt for passphrase automatically)
      final backupMode = mode == BackupMode.e2ee ? BackupMode.deviceKey : mode;
      
      final result = await _createBackupUseCase.call(
        mode: backupMode,
        passphrase: null,
      );

      if (result is BackupSuccess) {
        await _preferencesService.setLastBackupTime(DateTime.now());
        debugPrint('Automatic backup completed successfully');
      } else if (result is BackupFailure) {
        debugPrint('Automatic backup failed: ${result.error}');
      }
    } catch (e) {
      // Silently fail automatic backups - don't disturb user
      // Errors will be logged for debugging
      debugPrint('Automatic backup failed: $e');
    }
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

