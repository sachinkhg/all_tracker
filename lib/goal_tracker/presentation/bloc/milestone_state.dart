import 'package:equatable/equatable.dart';
import '../../domain/entities/milestone.dart';

/// ---------------------------------------------------------------------------
/// MilestoneState (Bloc State Definitions)
///
/// File purpose:
/// - Defines the various states used by the [MilestoneCubit] to manage
///   milestone lifecycle and UI rendering.
/// - Encapsulates loading, loaded, and error conditions in an immutable,
///   equatable structure for efficient Bloc rebuilds.
///
/// State overview:
/// - [MilestonesLoading]: Emitted while fetching or modifying milestone data.
/// - [MilestonesLoaded]: Emitted when milestones are successfully fetched;
///   contains a list of [Milestone] entities (optionally scoped by goal).
/// - [MilestonesError]: Emitted when an exception or data failure occurs.
///
/// Developer guidance:
/// - Always emit new immutable state instances.
/// - Keep states serializable-safe (no mutable or context-specific fields).
/// - When adding new states (e.g., for create/update success), extend
///   [MilestoneState] and override `props` for proper Equatable comparison.
/// ---------------------------------------------------------------------------

// Base state for milestone operations.
abstract class MilestoneState extends Equatable {
  const MilestoneState();

  @override
  List<Object?> get props => [];
}

/// Loading state — emitted while milestone data is being fetched or updated.
class MilestonesLoading extends MilestoneState {}

/// Loaded state — emitted when milestones are successfully retrieved.
class MilestonesLoaded extends MilestoneState {
  /// The list of milestones retrieved from the repository.
  final List<Milestone> milestones;

  /// The goalId for which these milestones were loaded.
  /// Nullable for global contexts (e.g., all milestones view).
  final String? goalId;

  /// Optional UI metadata, such as which fields are visible.
  final Map<String, bool>? visibleFields;

  const MilestonesLoaded(
    this.milestones, {
    this.goalId,
    this.visibleFields,
  });

  @override
  List<Object?> get props => [milestones, goalId, visibleFields];
}

/// Error state — emitted when milestone operations fail.
class MilestonesError extends MilestoneState {
  /// Human-readable message describing the failure.
  final String message;

  const MilestonesError(this.message);

  @override
  List<Object?> get props => [message];
}
