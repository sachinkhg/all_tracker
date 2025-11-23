import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/create_backup.dart';
import '../../domain/usecases/list_backups.dart';
import '../../domain/usecases/restore_backup.dart';
import '../../domain/usecases/delete_backup.dart';
import '../../core/backup_preferences_service.dart';
import '../../data/datasources/google_auth_datasource.dart';
import '../../domain/entities/backup_mode.dart';
import '../../domain/entities/backup_result.dart' as domain;
import '../../domain/entities/restore_result.dart' as domain;
import 'backup_state.dart';

/// Cubit for managing backup operations and state.
class BackupCubit extends Cubit<BackupState> {
  final CreateBackup _createBackup;
  final ListBackups _listBackups;
  final RestoreBackup _restoreBackup;
  final DeleteBackup _deleteBackup;
  final BackupPreferencesService _preferencesService;
  final GoogleAuthDataSource _googleAuth;

  BackupCubit({
    required CreateBackup createBackup,
    required ListBackups listBackups,
    required RestoreBackup restoreBackup,
    required DeleteBackup deleteBackup,
    required BackupPreferencesService preferencesService,
    required GoogleAuthDataSource googleAuth,
  })  : _createBackup = createBackup,
        _listBackups = listBackups,
        _restoreBackup = restoreBackup,
        _deleteBackup = deleteBackup,
        _preferencesService = preferencesService,
        _googleAuth = googleAuth,
        super(BackupInitial());

  /// Check authentication status and initialize state.
  Future<void> checkAuthStatus() async {
    emit(BackupInitial());

    final isSignedIn = await _googleAuth.isSignedIn();
    if (!isSignedIn) {
      emit(BackupSignedOut());
      return;
    }

    final account = await _googleAuth.getCurrentAccount();
    if (account != null) {
      await loadBackups();
    } else {
      emit(BackupSignedOut());
    }
  }

  /// Sign in to Google.
  Future<void> signIn() async {
    emit(BackupSigningIn());

    try {
      final success = await _googleAuth.signIn();
      if (success) {
        await loadBackups();
      } else {
        emit(BackupError(message: 'Sign-in cancelled or failed'));
      }
    } catch (e) {
      emit(BackupError(message: 'Sign-in error: $e'));
    }
  }

  /// Sign out from Google.
  Future<void> signOut() async {
    await _googleAuth.signOut();
    emit(BackupSignedOut());
  }

  /// Load list of available backups.
  Future<void> loadBackups() async {
    final account = await _googleAuth.getCurrentAccount();
    if (account == null) {
      emit(BackupSignedOut());
      return;
    }

    try {
      final backups = await _listBackups.call();
      emit(BackupSignedIn(
        accountEmail: account.email,
        backups: backups,
      ));
    } catch (e) {
      // Even if loading backups fails, preserve signed-in state
      emit(BackupSignedIn(
        accountEmail: account.email,
        backups: const [],
        errorMessage: 'Failed to load backups: $e',
      ));
    }
  }

  /// Create a new backup.
  Future<void> createBackup({
    required BackupMode mode,
    String? passphrase,
    String? name,
  }) async {
    try {
      final result = await _createBackup.call(
        mode: mode,
        passphrase: passphrase,
        name: name,
      );

      if (result is domain.BackupSuccess) {
        await _preferencesService.setLastBackupTime(DateTime.now());
        emit(BackupOperationSuccess(backupId: result.backupId, sizeBytes: result.sizeBytes));
        await loadBackups();
      } else if (result is domain.BackupFailure) {
        emit(BackupError(message: result.error));
      }
    } catch (e) {
      emit(BackupError(message: 'Backup failed: $e'));
    }
  }

  /// Restore a backup.
  Future<void> restoreBackup({
    required String backupId,
    String? passphrase,
  }) async {
    try {
      emit(RestoreInProgress(stage: 'Restoring...', progress: 0.0));

      final result = await _restoreBackup.call(
        backupId: backupId,
        passphrase: passphrase,
      );

      if (result is domain.RestoreSuccess) {
        // Show success state briefly, then restore signed-in state
        emit(RestoreOperationSuccess());
        // Reload backups to restore signed-in state
        await loadBackups();
      } else if (result is domain.RestoreFailure) {
        // Check if user is still signed in and preserve that state
        final isSignedIn = await _googleAuth.isSignedIn();
        if (isSignedIn) {
          // User is still signed in - preserve signed-in state with error message
          final account = await _googleAuth.getCurrentAccount();
          if (account != null) {
            try {
              final backups = await _listBackups.call();
              emit(BackupSignedIn(
                accountEmail: account.email,
                backups: backups,
                errorMessage: result.error, // Include error in signed-in state
              ));
            } catch (e) {
              // If loading backups fails, still preserve signed-in state
              emit(BackupSignedIn(
                accountEmail: account.email,
                backups: const [],
                errorMessage: result.error,
              ));
            }
          } else {
            emit(BackupSignedOut());
          }
        } else {
          // User is actually signed out
          emit(BackupSignedOut());
        }
      }
    } catch (e) {
      // Check if user is still signed in after error
      final isSignedIn = await _googleAuth.isSignedIn();
      if (isSignedIn) {
        // Preserve signed-in state even after error
        final account = await _googleAuth.getCurrentAccount();
        if (account != null) {
          try {
            final backups = await _listBackups.call();
            emit(BackupSignedIn(
              accountEmail: account.email,
              backups: backups,
              errorMessage: 'Restore failed: $e',
            ));
          } catch (loadError) {
            emit(BackupSignedIn(
              accountEmail: account.email,
              backups: const [],
              errorMessage: 'Restore failed: $e',
            ));
          }
        } else {
          emit(BackupSignedOut());
        }
      } else {
        emit(BackupError(message: 'Restore failed: $e'));
      }
    }
  }

  /// Delete a backup.
  Future<void> deleteBackup(String backupId) async {
    try {
      await _deleteBackup.call(backupId);
      await loadBackups();
    } catch (e) {
      emit(BackupError(message: 'Delete failed: $e'));
    }
  }

  /// Update automatic backup preference.
  Future<void> setAutoBackupEnabled(bool enabled) async {
    await _preferencesService.setAutoBackupEnabled(enabled);
  }

  /// Update backup encryption mode.
  Future<void> setBackupMode(BackupMode mode) async {
    await _preferencesService.setBackupMode(mode);
  }

  /// Update retention count.
  Future<void> setRetentionCount(int count) async {
    await _preferencesService.setRetentionCount(count);
  }

  /// Get current backup mode.
  BackupMode get backupMode => _preferencesService.backupMode;

  /// Get retention count.
  int get retentionCount => _preferencesService.retentionCount;

  /// Get auto backup enabled state.
  bool get autoBackupEnabled => _preferencesService.autoBackupEnabled;
}
