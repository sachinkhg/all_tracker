import 'package:equatable/equatable.dart';
import '../../domain/entities/backup_metadata.dart';

/// Base class for backup states.
sealed class BackupState extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Initial state - checking authentication status.
class BackupInitial extends BackupState {}

/// Signing in to Google.
class BackupSigningIn extends BackupState {}

/// User is signed out.
class BackupSignedOut extends BackupState {}

/// User is signed in with their account.
class BackupSignedIn extends BackupState {
  final String accountEmail;
  final List<BackupMetadata> backups;
  final String? errorMessage; // Optional error message to display

  BackupSignedIn({
    required this.accountEmail,
    this.backups = const [],
    this.errorMessage,
  });

  @override
  List<Object?> get props => [accountEmail, backups, errorMessage];
}

/// Backup operation is in progress.
class BackupInProgress extends BackupState {
  final String stage; // e.g., "Exporting data", "Encrypting backup"
  final double progress; // 0.0 to 1.0

  BackupInProgress({required this.stage, required this.progress});

  @override
  List<Object?> get props => [stage, progress];
}

/// Restore operation is in progress.
class RestoreInProgress extends BackupState {
  final String stage;
  final double progress;

  RestoreInProgress({required this.stage, required this.progress});

  @override
  List<Object?> get props => [stage, progress];
}

/// Backup completed successfully.
class BackupOperationSuccess extends BackupState {
  final String backupId;
  final int sizeBytes;

  BackupOperationSuccess({required this.backupId, required this.sizeBytes});

  @override
  List<Object?> get props => [backupId, sizeBytes];
}

/// Restore completed successfully.
class RestoreOperationSuccess extends BackupState {}

/// An error occurred during backup/restore operation.
class BackupError extends BackupState {
  final String message;

  BackupError({required this.message});

  @override
  List<Object?> get props => [message];
}

