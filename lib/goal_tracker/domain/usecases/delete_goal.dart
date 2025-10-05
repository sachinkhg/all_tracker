// ./lib/goal_tracker/domain/usecases/delete_goal.dart
/*
  purpose:
    - Encapsulates the "Delete Goal" domain use case, responsible for removing
      an existing goal identified by its unique [id].
    - Defines a domain-level boundary for goal deletion, independent of the
      underlying storage or data implementation (Hive, SQLite, REST, etc.).
    - Maintains separation of concerns by ensuring only the [GoalRepository]
      performs persistence operations.

  usage:
    - Invoked by the UI or business logic when a user deletes a goal.
    - Delegates to [GoalRepository.deleteGoal] for actual data removal.
    - The repository implementation must handle missing or invalid IDs gracefully.

  compatibility guidance:
    - Avoid adding UI-level confirmation or user prompts here — keep it domain-pure.
    - Any cascade deletion or related clean-up logic should reside in repository implementations.
    - If soft-deletion or archival is introduced later, update this use case and
      document the change in README and migration_notes.md.
*/

import '../repositories/goal_repository.dart';

/// Use case class responsible for deleting a [Goal] by its [id].
///
/// Acts as a domain boundary for goal removal operations,
/// isolating persistence logic within the [GoalRepository].
class DeleteGoal {
  /// Repository abstraction handling data persistence.
  final GoalRepository repository;

  /// Constructs the use case with the required [GoalRepository] dependency.
  DeleteGoal(this.repository);

  /// Executes the delete operation asynchronously.
  ///
  /// Delegates to [GoalRepository.deleteGoal].
  /// Repository implementations should handle missing or invalid IDs safely.
  Future<void> call(String id) async => repository.deleteGoal(id);
}
