import '../../domain/entities/drive_backup_config.dart';

/// Base class for Drive backup states.
abstract class DriveBackupState {
  const DriveBackupState();
}

/// Initial state - checking configuration.
class DriveBackupInitial extends DriveBackupState {
  const DriveBackupInitial();
}

/// Idle state - no operation in progress.
class DriveBackupIdle extends DriveBackupState {
  const DriveBackupIdle();
}

/// Configured state - backup is set up and ready.
class DriveBackupConfigured extends DriveBackupState {
  final DriveBackupConfig config;

  const DriveBackupConfigured(this.config);
}

/// Loading state - operation in progress.
class DriveBackupLoading extends DriveBackupState {
  final String operation; // 'setup', 'backup', 'restore'
  final String message;

  const DriveBackupLoading({
    required this.operation,
    required this.message,
  });
}

/// Success state - operation completed successfully.
class DriveBackupSuccess extends DriveBackupState {
  final String message;

  const DriveBackupSuccess(this.message);
}

/// Error state - operation failed.
class DriveBackupError extends DriveBackupState {
  final String message;

  const DriveBackupError(this.message);
}

