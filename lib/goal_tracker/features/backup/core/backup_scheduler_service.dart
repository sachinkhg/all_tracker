import 'backup_preferences_service.dart';
import '../domain/usecases/create_backup.dart';
import '../domain/entities/backup_mode.dart';
import '../domain/entities/backup_result.dart';

/// Service for scheduling automatic backups.
/// 
/// Handles periodic backup checking and execution when enabled.
class BackupSchedulerService {
  final BackupPreferencesService _preferencesService;
  final CreateBackup _createBackupUseCase;

  BackupSchedulerService({
    required BackupPreferencesService preferencesService,
    required CreateBackup createBackupUseCase,
  })  : _preferencesService = preferencesService,
        _createBackupUseCase = createBackupUseCase;

  /// Check if automatic backup should run and execute it if needed.
  /// 
  /// This should be called on app startup.
  Future<void> checkAndRunBackup() async {
    if (!_preferencesService.shouldRunAutomaticBackup()) {
      return;
    }

    try {
      final mode = _preferencesService.backupMode;
      final result = await _createBackupUseCase.call(
        mode: mode,
        passphrase: null, // Will be handled by UI if E2EE
      );

      if (result is BackupSuccess) {
        await _preferencesService.setLastBackupTime(DateTime.now());
      }
    } catch (e) {
      // Silently fail automatic backups - don't disturb user
      // Errors will be logged for debugging
      print('Automatic backup failed: $e');
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
      print('Manual backup failed: $e');
      return false;
    }
  }
}

