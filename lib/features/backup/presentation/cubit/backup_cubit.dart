import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/create_backup.dart';
import '../../domain/usecases/list_backups.dart';
import '../../domain/usecases/restore_backup.dart';
import '../../domain/usecases/delete_backup.dart';
import '../../core/backup_preferences_service.dart';
import '../../data/datasources/google_auth_datasource.dart';
import '../../domain/entities/backup_mode.dart';
import '../../domain/entities/backup_metadata.dart';
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

  bool _isSigningIn = false;

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
  /// Automatically initiates sign-in if user is not signed in.
  Future<void> checkAuthStatus() async {
    if (isClosed) return;
    if (!isClosed) {
      emit(BackupInitial());
    }

    // Check if user is already signed in (this checks for existing sessions)
    // The isSignedIn() method now properly checks for existing sessions
    final isSignedIn = await _googleAuth.isSignedIn();
    if (isSignedIn) {
      // User is already signed in, load backups immediately
      final account = await _googleAuth.getCurrentAccount();
      if (account != null) {
        debugPrint('[BACKUP_CUBIT] User already signed in: ${account.email}');
        if (!isClosed) {
          await loadBackups();
          
          // Also refresh after a delay to catch any newly created backups
          Future.delayed(const Duration(seconds: 3), () {
            if (!isClosed) {
              loadBackups();
            }
          });
        }
        return;
      }
    }

    // If not signed in, automatically initiate sign-in flow
    if (!isClosed) {
      debugPrint('[BACKUP_CUBIT] No existing session found, initiating sign-in...');
      await signIn();
    }
  }

  /// Sign in to Google.
  Future<void> signIn() async {
    if (isClosed) return;
    
    // Prevent concurrent sign-in attempts
    if (_isSigningIn) {
      return;
    }

    _isSigningIn = true;
    if (!isClosed) {
      emit(BackupSigningIn());
    }

    try {
      final success = await _googleAuth.signIn();
      if (success) {
        if (!isClosed) {
          await loadBackups();
        }
      } else {
        // Sign-in was cancelled or failed - show signed-out state
        // This allows the user to try again if they want
        if (!isClosed) {
          emit(BackupSignedOut());
        }
      }
    } catch (e) {
      // On error, still show signed-out state so user can retry
      // Silently handle cancellation exceptions - they're expected user behavior
      if (!isClosed) {
        emit(BackupSignedOut());
      }
    } finally {
      _isSigningIn = false;
    }
  }

  /// Sign out from Google.
  Future<void> signOut() async {
    if (isClosed) return;
    await _googleAuth.signOut();
    if (!isClosed) {
      emit(BackupSignedOut());
    }
  }

  /// Load list of available backups.
  Future<void> loadBackups() async {
    if (isClosed) return;
    
    final account = await _googleAuth.getCurrentAccount();
    if (account == null) {
      if (!isClosed) {
        emit(BackupSignedOut());
      }
      return;
    }

    try {
      debugPrint('[BACKUP_CUBIT] Loading backups...');
      final backups = await _listBackups.call();
      debugPrint('[BACKUP_CUBIT] Loaded ${backups.length} backups');
      if (!isClosed) {
        emit(BackupSignedIn(
          accountEmail: account.email,
          backups: backups,
        ));
      }
    } catch (e) {
      debugPrint('[BACKUP_CUBIT] Failed to load backups: $e');
      // Even if loading backups fails, preserve signed-in state
      if (!isClosed) {
        emit(BackupSignedIn(
          accountEmail: account.email,
          backups: const [],
          errorMessage: 'Failed to load backups: $e',
        ));
      }
    }
  }

  /// Create a new backup.
  Future<void> createBackup({
    required BackupMode mode,
    String? passphrase,
    String? name,
  }) async {
    if (isClosed) return;
    
    try {
      final result = await _createBackup.call(
        mode: mode,
        passphrase: passphrase,
        name: name,
      );

      if (result is domain.BackupSuccess) {
        await _preferencesService.setLastBackupTime(DateTime.now());
        if (!isClosed) {
          emit(BackupOperationSuccess(backupId: result.backupId, sizeBytes: result.sizeBytes));
          await loadBackups();
        }
      } else if (result is domain.BackupFailure) {
        if (!isClosed) {
          emit(BackupError(message: result.error));
        }
      }
    } catch (e) {
      if (!isClosed) {
        emit(BackupError(message: 'Backup failed: $e'));
      }
    }
  }

  /// Restore a backup.
  Future<void> restoreBackup({
    required String backupId,
    String? passphrase,
  }) async {
      try {
      if (isClosed) return;
      emit(RestoreInProgress(stage: 'Restoring...', progress: 0.0));

      final result = await _restoreBackup.call(
        backupId: backupId,
        passphrase: passphrase,
      );

      if (result is domain.RestoreSuccess) {
        // Update last restore time
        await _preferencesService.setLastRestoreTime(DateTime.now());
        // Show success state - bottom sheet will close after this
        if (!isClosed) {
          emit(RestoreOperationSuccess());
        }
        // Don't call loadBackups() here as the bottom sheet will close and dispose the cubit
        return;
      } else if (result is domain.RestoreFailure) {
        // Check if user is still signed in and preserve that state
        if (isClosed) return;
        final isSignedIn = await _googleAuth.isSignedIn();
        if (isSignedIn) {
          // User is still signed in - preserve signed-in state with error message
          final account = await _googleAuth.getCurrentAccount();
          if (account != null) {
            try {
              final backups = await _listBackups.call();
              if (!isClosed) {
                emit(BackupSignedIn(
                  accountEmail: account.email,
                  backups: backups,
                  errorMessage: result.error, // Include error in signed-in state
                ));
              }
            } catch (e) {
              // If loading backups fails, still preserve signed-in state
              if (!isClosed) {
                emit(BackupSignedIn(
                  accountEmail: account.email,
                  backups: const [],
                  errorMessage: result.error,
                ));
              }
            }
          } else {
            if (!isClosed) {
              emit(BackupSignedOut());
            }
          }
        } else {
          // User is actually signed out
          if (!isClosed) {
            emit(BackupSignedOut());
          }
        }
      }
    } catch (e) {
      // Check if user is still signed in after error
      if (isClosed) return;
      final isSignedIn = await _googleAuth.isSignedIn();
      if (isSignedIn) {
        // Preserve signed-in state even after error
        final account = await _googleAuth.getCurrentAccount();
        if (account != null) {
          try {
            final backups = await _listBackups.call();
            if (!isClosed) {
              emit(BackupSignedIn(
                accountEmail: account.email,
                backups: backups,
                errorMessage: 'Restore failed: $e',
              ));
            }
          } catch (loadError) {
            if (!isClosed) {
              emit(BackupSignedIn(
                accountEmail: account.email,
                backups: const [],
                errorMessage: 'Restore failed: $e',
              ));
            }
          }
        } else {
          if (!isClosed) {
            emit(BackupSignedOut());
          }
        }
      } else {
        if (!isClosed) {
          emit(BackupError(message: 'Restore failed: $e'));
        }
      }
    }
  }

  /// Delete a backup.
  Future<void> deleteBackup(String backupId) async {
    if (isClosed) return;
    
    try {
      await _deleteBackup.call(backupId);
      if (!isClosed) {
        await loadBackups();
      }
    } catch (e) {
      if (!isClosed) {
        emit(BackupError(message: 'Delete failed: $e'));
      }
    }
  }

  /// Update automatic backup preference.
  Future<void> setAutoBackupEnabled(bool enabled) async {
    if (isClosed) return;
    
    // Prevent duplicate calls if already set to the same value
    if (_preferencesService.autoBackupEnabled == enabled) {
      return;
    }
    
    await _preferencesService.setAutoBackupEnabled(enabled);
    
    // Emit a new state to trigger UI rebuild
    // Preserve the current signed-in state if we're signed in
    // Create a new list instance to ensure state is different (forces rebuild)
    if (!isClosed && state is BackupSignedIn) {
      final currentState = state as BackupSignedIn;
      emit(BackupSignedIn(
        accountEmail: currentState.accountEmail,
        backups: List<BackupMetadata>.from(currentState.backups),
        errorMessage: currentState.errorMessage,
      ));
    }
  }

  /// Update backup encryption mode.
  Future<void> setBackupMode(BackupMode mode) async {
    if (isClosed) return;
    
    // Prevent duplicate calls if already set to the same value
    if (_preferencesService.backupMode == mode) {
      return;
    }
    
    await _preferencesService.setBackupMode(mode);
    
    // Emit a new state to trigger UI rebuild
    // Preserve the current signed-in state if we're signed in
    // Create a new list instance to ensure state is different (forces rebuild)
    if (!isClosed && state is BackupSignedIn) {
      final currentState = state as BackupSignedIn;
      emit(BackupSignedIn(
        accountEmail: currentState.accountEmail,
        backups: List<BackupMetadata>.from(currentState.backups),
        errorMessage: currentState.errorMessage,
      ));
    }
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
