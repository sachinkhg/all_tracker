import 'package:equatable/equatable.dart';
import '../../domain/entities/task.dart';

/// ---------------------------------------------------------------------------
/// TaskState (Bloc State Definitions)
///
/// File purpose:
/// - Defines the various states used by the [TaskCubit] to manage
///   task lifecycle and UI rendering.
/// - Encapsulates loading, loaded, and error conditions in an immutable,
///   equatable structure for efficient Bloc rebuilds.
///
/// State overview:
/// - [TasksLoading]: Emitted while fetching or modifying task data.
/// - [TasksLoaded]: Emitted when tasks are successfully fetched;
///   contains a list of [Task] entities (optionally scoped by milestone or goal).
/// - [TasksError]: Emitted when an exception or data failure occurs.
///
/// Developer guidance:
/// - Always emit new immutable state instances.
/// - Keep states serializable-safe (no mutable or context-specific fields).
/// - When adding new states (e.g., for create/update success), extend
///   [TaskState] and override `props` for proper Equatable comparison.
/// ---------------------------------------------------------------------------

// Base state for task operations.
abstract class TaskState extends Equatable {
  const TaskState();

  @override
  List<Object?> get props => [];
}

/// Loading state — emitted while task data is being fetched or updated.
class TasksLoading extends TaskState {}

/// Loaded state — emitted when tasks are successfully retrieved.
class TasksLoaded extends TaskState {
  /// The list of tasks retrieved from the repository.
  final List<Task> tasks;

  /// The milestoneId for which these tasks were loaded.
  /// Nullable for global contexts (e.g., all tasks view).
  final String? milestoneId;

  /// The goalId for which these tasks were loaded.
  /// Nullable for global contexts (e.g., all tasks view).
  final String? goalId;

  /// Optional UI metadata, such as which fields are visible.
  final Map<String, bool>? visibleFields;

  /// View type: 'list' or 'calendar'. Defaults to 'list'.
  final String viewType;

  const TasksLoaded(
    this.tasks, {
    this.milestoneId,
    this.goalId,
    this.visibleFields,
    this.viewType = 'list',
  });

  @override
  List<Object?> get props => [tasks, milestoneId, goalId, visibleFields, viewType];
}

/// Error state — emitted when task operations fail.
class TasksError extends TaskState {
  /// Human-readable message describing the failure.
  final String message;

  const TasksError(this.message);

  @override
  List<Object?> get props => [message];
}

