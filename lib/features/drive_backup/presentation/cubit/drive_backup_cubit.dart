import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/setup_drive_backup.dart';
import '../../domain/usecases/backup_to_drive.dart';
import '../../domain/usecases/sync_actions_from_sheet.dart';
import '../states/drive_backup_state.dart';
import 'dart:async';

/// Cubit for managing Drive backup state and operations.
class DriveBackupCubit extends Cubit<DriveBackupState> {
  final SetupDriveBackup _setupBackup;
  final BackupToDrive _backupToDrive;
  final SyncActionsFromSheet _syncActionsFromSheet;

  DriveBackupCubit({
    required SetupDriveBackup setupBackup,
    required BackupToDrive backupToDrive,
    required SyncActionsFromSheet syncActionsFromSheet,
  })  : _setupBackup = setupBackup,
        _backupToDrive = backupToDrive,
        _syncActionsFromSheet = syncActionsFromSheet,
        super(const DriveBackupInitial()) {
    _loadConfig();
  }

  /// Load current configuration and update state.
  Future<void> _loadConfig() async {
    try {
      final config = await _setupBackup.repository.getConfig();
      if (config != null) {
        emit(DriveBackupConfigured(config));
      } else {
        emit(const DriveBackupIdle());
      }
    } catch (e) {
      emit(DriveBackupError('Failed to load configuration: $e'));
    }
  }

  /// Setup Drive backup.
  Future<void> setupBackup(String rootFolderId) async {
    emit(const DriveBackupLoading(
      operation: 'setup',
      message: 'Setting up Drive backup...',
    ));

    try {
      const trackerName = 'Book Tracker';
      emit(const DriveBackupLoading(
        operation: 'setup',
        message: 'Creating folder...',
      ));
      final config = await _setupBackup(rootFolderId, trackerName);
      emit(DriveBackupConfigured(config));
      emit(DriveBackupSuccess('Drive backup setup completed successfully. Folder and Google Sheet created.'));
      // Return to configured state after showing success
      Future.delayed(const Duration(seconds: 2), () {
        if (state is! DriveBackupConfigured) {
          emit(DriveBackupConfigured(config));
        }
      });
    } catch (e, stackTrace) {
      print('Setup backup error: $e');
      print('Stack trace: $stackTrace');
      emit(DriveBackupError('Failed to setup backup: $e'));
    }
  }

  /// Backup data to Drive.
  Future<void> backupToDrive() async {
    emit(const DriveBackupLoading(
      operation: 'backup',
      message: 'Backing up to Drive...',
    ));

    try {
      await _backupToDrive();
      await _loadConfig(); // Reload to get updated timestamps
      emit(DriveBackupSuccess('Backup completed successfully'));
      // Return to configured state after showing success
      Future.delayed(const Duration(seconds: 2), () async {
        await _loadConfig();
      });
    } catch (e) {
      emit(DriveBackupError('Failed to backup: $e'));
    }
  }

  /// Add a log entry to the current loading state.
  void _addLog(String message, {LogLevel level = LogLevel.info}) {
    if (state is DriveBackupLoading) {
      final currentState = state as DriveBackupLoading;
      final newLog = OperationLogEntry(
        timestamp: DateTime.now(),
        message: message,
        level: level,
      );
      emit(currentState.copyWith(
        logs: [...currentState.logs, newLog],
        message: message, // Update current message
      ));
    }
  }

  /// Sync actions from Google Sheets.
  /// 
  /// Processes CREATE, UPDATE, and DELETE actions marked in the sheet
  /// and applies them to the book tracker.
  Future<void> syncActionsFromSheet() async {
    final initialLogs = <OperationLogEntry>[];
    emit(DriveBackupLoading(
      operation: 'sync',
      message: 'Starting sync operation...',
      logs: initialLogs,
    ));

    _addLog('Connecting to Google Sheets...', level: LogLevel.info);

    try {
      _addLog('Reading actions from Google Sheet...', level: LogLevel.info);
      
      // Start the sync operation
      // The repository will process actions, update rows, and clear action columns
      await _syncActionsFromSheet();
      
      _addLog('All actions processed successfully', level: LogLevel.success);
      _addLog('Sync operation completed', level: LogLevel.success);
      
      final finalState = state as DriveBackupLoading;
      await _loadConfig(); // Reload to get updated timestamps
      
      // Emit success with logs
      emit(DriveBackupSuccess('Actions synced successfully'));
      
      // Return to configured state with recent logs after showing success
      Future.delayed(const Duration(seconds: 2), () async {
        final config = await _setupBackup.repository.getConfig();
        if (config != null) {
          emit(DriveBackupConfigured(config, recentLogs: finalState.logs));
        } else {
          await _loadConfig();
        }
      });
    } catch (e) {
      _addLog('Error occurred: ${e.toString()}', level: LogLevel.error);
      if (e.toString().contains('Quota exceeded') || e.toString().contains('429')) {
        _addLog('Rate limit exceeded. Retrying with backoff...', level: LogLevel.warning);
      }
      final finalState = state as DriveBackupLoading;
      emit(DriveBackupError('Failed to sync actions: $e'));
      
      // Keep logs in error state for debugging
      Future.delayed(const Duration(seconds: 3), () async {
        final config = await _setupBackup.repository.getConfig();
        if (config != null) {
          emit(DriveBackupConfigured(config, recentLogs: finalState.logs));
        } else {
          await _loadConfig();
        }
      });
    }
  }
}

