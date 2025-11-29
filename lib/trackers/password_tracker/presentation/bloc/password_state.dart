import 'package:equatable/equatable.dart';
import '../../domain/entities/password.dart';

/// ---------------------------------------------------------------------------
/// PasswordState (Bloc State Definitions)
///
/// File purpose:
/// - Defines the various states used by the [PasswordCubit] for managing password
///   lifecycle and UI rendering.
/// - Encapsulates data and UI-relevant conditions (loading, loaded, error)
///   using immutable, equatable classes for efficient Bloc rebuilds.
///
/// State overview:
/// - [PasswordsLoading]: Emitted while loading passwords from the data source.
/// - [PasswordsLoaded]: Emitted when passwords are successfully loaded; contains a list
///   of [Password] entities.
/// - [PasswordsError]: Emitted when an exception or data failure occurs.
///
/// Developer guidance:
/// - States are intentionally minimal and serializable-safe (no mutable fields).
/// - Always emit new instances (avoid mutating existing state).
/// - When adding new states, ensure they extend [PasswordState] and override
///   `props` for correct Equatable comparisons.
///
/// ---------------------------------------------------------------------------

// Base state for password operations
abstract class PasswordState extends Equatable {
  const PasswordState();

  @override
  List<Object?> get props => [];
}

// Loading state — emitted when password data is being fetched.
class PasswordsLoading extends PasswordState {}

// Loaded state — holds the list of successfully fetched passwords.
class PasswordsLoaded extends PasswordState {
  final List<Password> passwords;
  final Map<String, bool> visibleFields;

  const PasswordsLoaded(this.passwords, this.visibleFields);

  @override
  List<Object?> get props => [passwords, visibleFields];
}

// Error state — emitted when fetching or modifying passwords fails.
class PasswordsError extends PasswordState {
  final String message;

  const PasswordsError(this.message);

  @override
  List<Object?> get props => [message];
}

