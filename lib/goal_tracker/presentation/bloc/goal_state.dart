import 'package:equatable/equatable.dart';
import '../../domain/entities/goal.dart';

/// ---------------------------------------------------------------------------
/// GoalState (Bloc State Definitions)
///
/// File purpose:
/// - Defines the various states used by the [GoalCubit] for managing goal
///   lifecycle and UI rendering.
/// - Encapsulates data and UI-relevant conditions (loading, loaded, error)
///   using immutable, equatable classes for efficient Bloc rebuilds.
///
/// State overview:
/// - [GoalsLoading]: Emitted while loading goals from the data source.
/// - [GoalsLoaded]: Emitted when goals are successfully loaded; contains a list
///   of [Goal] entities.
/// - [GoalsError]: Emitted when an exception or data failure occurs.
///
/// Developer guidance:
/// - States are intentionally minimal and serializable-safe (no mutable fields).
/// - Always emit new instances (avoid mutating existing state).
/// - When adding new states, ensure they extend [GoalState] and override
///   `props` for correct Equatable comparisons.
///
/// ---------------------------------------------------------------------------

// Base state for goal operations
abstract class GoalState extends Equatable {
  const GoalState();

  @override
  List<Object?> get props => [];
}

// Loading state — emitted when goal data is being fetched.
class GoalsLoading extends GoalState {}

// Loaded state — holds the list of successfully fetched goals.
class GoalsLoaded extends GoalState {
  final List<Goal> goals;

  const GoalsLoaded(this.goals);

  @override
  List<Object?> get props => [goals];
}

// Error state — emitted when fetching or modifying goals fails.
class GoalsError extends GoalState {
  final String message;

  const GoalsError(this.message);

  @override
  List<Object?> get props => [message];
}
