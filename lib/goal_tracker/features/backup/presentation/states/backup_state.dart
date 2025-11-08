import 'package:equatable/equatable.dart';
import '../../domain/entities/backup_metadata.dart';
import '../../domain/entities/backup_progress.dart';

/// ---------------------------------------------------------------------------
/// BackupState (Bloc State Definitions)
///
/// File purpose:
/// - Defines the various states used by the [BackupCubit] for managing backup
///   operations and UI rendering.
/// - Encapsulates data and UI-relevant conditions (loading, loaded, error)
///   using immutable, equatable classes for efficient Bloc rebuilds.
///
/// State overview:
/// - [BackupInitial]: Initial state, no backup data loaded
/// - [BackupListLoading]: Emitted while loading backup list
/// - [BackupListLoaded]: Emitted when backup list is successfully loaded
/// - [BackupListError]: Emitted when loading backup list fails
/// - [BackupCreating]: Emitted during backup creation process
/// - [BackupRestoring]: Emitted during backup restore process
/// - [BackupProgress]: Emitted during backup/restore operations with progress updates
///
/// Developer guidance:
/// - States are intentionally minimal and serializable-safe (no mutable fields).
/// - Always emit new instances (avoid mutating existing state).
/// - When adding new states, ensure they extend [BackupState] and override
///   `props` for correct Equatable comparisons.
///
/// ---------------------------------------------------------------------------

/// Base state for backup operations
abstract class BackupState extends Equatable {
  const BackupState();

  @override
  List<Object?> get props => [];
}

/// Initial state — emitted when backup feature is first opened
class BackupInitial extends BackupState {}

/// Loading state — emitted when backup list is being fetched
class BackupListLoading extends BackupState {}

/// Loaded state — holds the list of available backups
class BackupListLoaded extends BackupState {
  final List<BackupMetadata> backups;

  const BackupListLoaded(this.backups);

  @override
  List<Object?> get props => [backups];
}

/// Error state — emitted when backup operations fail
class BackupListError extends BackupState {
  final String message;

  const BackupListError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Backup creation in progress state
class BackupCreating extends BackupState {
  final BackupProgress progress;

  const BackupCreating(this.progress);

  @override
  List<Object?> get props => [progress];
}

/// Backup restore in progress state
class BackupRestoring extends BackupState {
  final BackupProgress progress;

  const BackupRestoring(this.progress);

  @override
  List<Object?> get props => [progress];
}

/// Backup operation success state
class BackupSuccessState extends BackupState {
  final String message;
  final int? sizeBytes;

  const BackupSuccessState({required this.message, this.sizeBytes});

  @override
  List<Object?> get props => [message, sizeBytes];
}

/// Backup operation error state
class BackupError extends BackupState {
  final String message;

  const BackupError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Authentication required state
class BackupAuthRequired extends BackupState {}

