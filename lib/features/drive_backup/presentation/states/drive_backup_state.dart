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
  final List<OperationLogEntry>? recentLogs; // Recent logs from last operation

  const DriveBackupConfigured(this.config, {this.recentLogs});
}

/// Log entry for operation progress tracking.
class OperationLogEntry {
  final DateTime timestamp;
  final String message;
  final LogLevel level;

  OperationLogEntry({
    required this.timestamp,
    required this.message,
    this.level = LogLevel.info,
  });
}

enum LogLevel {
  info,
  success,
  warning,
  error,
}

/// Loading state - operation in progress.
class DriveBackupLoading extends DriveBackupState {
  final String operation; // 'setup', 'backup', 'sync'
  final String message;
  final List<OperationLogEntry> logs;

  const DriveBackupLoading({
    required this.operation,
    required this.message,
    this.logs = const [],
  });

  DriveBackupLoading copyWith({
    String? operation,
    String? message,
    List<OperationLogEntry>? logs,
  }) {
    return DriveBackupLoading(
      operation: operation ?? this.operation,
      message: message ?? this.message,
      logs: logs ?? this.logs,
    );
  }
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

