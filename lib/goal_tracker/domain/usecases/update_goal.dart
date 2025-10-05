// ./lib/goal_tracker/domain/usecases/update_goal.dart
/*
  purpose:
    - Encapsulates the "Update Goal" domain use case, responsible for modifying
      an existing [Goal] entity via the [GoalRepository].
    - Ensures that application logic (Bloc/Cubit/UI) interacts through a clean domain boundary
      rather than calling data-layer methods directly.

  usage:
    - Called when an existing goal is edited through the UI or automated processes.
    - Accepts a [Goal] entity that includes its [id] and updated properties.
    - Delegates persistence to [GoalRepository.updateGoal], maintaining domain isolation.

  compatibility guidance:
    - Do not perform UI or persistence logic here; strictly domain-level coordination.
    - Validation (if any) should occur before invoking this use case.
    - If additional update rules (e.g., audit logs, versioning) are introduced,
      update README and domain documentation accordingly.
*/

import '../entities/goal.dart';
import '../repositories/goal_repository.dart';

/// Use case class responsible for updating an existing [Goal].
///
/// Interacts with [GoalRepository] to persist changes.
/// Keeps the domain logic independent from data-layer specifics.
class UpdateGoal {
  /// Repository that performs persistence operations for goals.
  final GoalRepository repository;

  /// Constructs the use case with a dependency on [GoalRepository].
  UpdateGoal(this.repository);

  /// Executes the update operation asynchronously.
  ///
  /// Delegates to [GoalRepository.updateGoal] for persistence.
  /// The provided [Goal] must include a valid [id]; repository
  /// implementations should handle missing or invalid IDs gracefully.
  Future<void> call(Goal goal) async => repository.updateGoal(goal);
}
