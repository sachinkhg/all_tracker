import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/setup_drive_backup.dart';
import '../../domain/usecases/backup_to_drive.dart';
import '../../domain/usecases/restore_from_drive.dart';
import '../states/drive_backup_state.dart';

/// Cubit for managing Drive backup state and operations.
class DriveBackupCubit extends Cubit<DriveBackupState> {
  final SetupDriveBackup _setupBackup;
  final BackupToDrive _backupToDrive;
  final RestoreFromDrive _restoreFromDrive;

  DriveBackupCubit({
    required SetupDriveBackup setupBackup,
    required BackupToDrive backupToDrive,
    required RestoreFromDrive restoreFromDrive,
  })  : _setupBackup = setupBackup,
        _backupToDrive = backupToDrive,
        _restoreFromDrive = restoreFromDrive,
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

  /// Restore data from Drive.
  Future<void> restoreFromDrive() async {
    emit(const DriveBackupLoading(
      operation: 'restore',
      message: 'Restoring from Drive...',
    ));

    try {
      await _restoreFromDrive();
      await _loadConfig(); // Reload to get updated timestamps
      emit(DriveBackupSuccess('Restore completed successfully'));
      // Return to configured state after showing success
      Future.delayed(const Duration(seconds: 2), () async {
        await _loadConfig();
      });
    } catch (e) {
      emit(DriveBackupError('Failed to restore: $e'));
    }
  }
}

