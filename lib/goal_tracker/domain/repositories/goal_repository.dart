// ./lib/goal_tracker/domain/repositories/goal_repository.dart
/*
  purpose:
    - Defines the abstract contract for the Goal data access layer (Domain → Data boundary).
    - This repository interface decouples the domain layer from implementation details
      such as Hive, SQLite, REST APIs, or any persistence mechanism.
    - Implementations must ensure proper entity conversion and validation between
      domain models (Goal) and their data source representations.

  usage:
    - The application’s GoalCubit or use-cases depend on this interface, not the concrete implementation.
    - Concrete implementations (e.g., HiveGoalRepository, LocalGoalRepository) should reside
      under the data/ or infrastructure/ layer.
    - Update this interface only when there are domain-level changes to the Goal lifecycle.

  compatibility guidance:
    - Avoid adding persistence-specific parameters here — keep this domain-pure.
    - All asynchronous operations must complete without leaking infrastructure details.
    - On modification, update ARCHITECTURE.md and contribution guidelines.
*/

import '../entities/goal.dart';

/// Abstract repository defining CRUD operations for [Goal] entities.
///
/// Acts as a contract between the domain layer and data layer.
/// Concrete implementations must handle persistence, error handling,
/// and entity serialization.
abstract class GoalRepository {
  /// Retrieve all goals from storage (unsorted or domain-sorted, as per implementation).
  Future<List<Goal>> getAllGoals();

  /// Retrieve a single goal by its unique [id].
  /// Returns null if not found.
  Future<Goal?> getGoalById(String id);

  /// Create a new [Goal] entry in storage.
  /// Implementations must handle ID generation if not provided.
  Future<void> createGoal(Goal goal);

  /// Update an existing [Goal].
  /// Implementations should throw or log if [goal.id] is missing.
  Future<void> updateGoal(Goal goal);

  /// Delete the goal identified by [id].
  /// Implementations should handle missing IDs gracefully.
  Future<void> deleteGoal(String id);
}
