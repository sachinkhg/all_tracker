/*
  purpose:
    - Defines the abstract contract for the Task data access layer (Domain → Data boundary).
    - This repository interface decouples the domain layer from implementation details
      such as Hive, SQLite, REST APIs, or any persistence mechanism.
    - Implementations must ensure correct entity conversion and validation between
      domain models (Task) and their data source representations.

  usage:
    - The application's TaskCubit or domain use-cases depend on this interface,
      not the concrete implementation.
    - Concrete implementations (e.g., HiveTaskRepository, LocalTaskRepository)
      should reside under the data/ or infrastructure/ layer.
    - Modify this interface only when there are domain-level changes to how Tasks
      are managed (not when the persistence schema changes).

  compatibility guidance:
    - Avoid persistence-specific details or technology-dependent parameters.
    - Keep all operations asynchronous and domain-pure.
    - On modification, document the change in ARCHITECTURE.md and update
      relevant contribution and migration notes.
*/

import '../entities/task.dart';

/// Abstract repository defining CRUD operations for [Task] entities.
///
/// This repository defines the boundary between the domain layer and data sources.
/// Concrete implementations are responsible for data persistence, mapping, and
/// error handling — keeping the domain layer completely agnostic to infrastructure.
abstract class TaskRepository {
  /// Retrieve all tasks from storage.
  ///
  /// The order and filtering behavior are left to the implementation.
  /// Implementations may choose to return all tasks or scoped ones as per app logic.
  Future<List<Task>> getAllTasks();

  /// Retrieve a single task by its unique [id].
  ///
  /// Returns `null` if the task is not found.
  Future<Task?> getTaskById(String id);

  /// Retrieve all tasks associated with a specific [milestoneId].
  ///
  /// Returns an empty list if the milestone has no tasks or the milestone ID does not exist.
  Future<List<Task>> getTasksByMilestoneId(String milestoneId);

  /// Retrieve all tasks associated with a specific [goalId].
  ///
  /// Returns an empty list if the goal has no tasks or the goal ID does not exist.
  Future<List<Task>> getTasksByGoalId(String goalId);

  /// Create a new [Task] record in storage.
  ///
  /// Implementations must ensure ID uniqueness and perform validation before persistence.
  Future<void> createTask(Task task);

  /// Update an existing [Task].
  ///
  /// Implementations should validate that [task.id] exists before updating.
  /// Throws or logs appropriately if the task cannot be updated.
  Future<void> updateTask(Task task);

  /// Delete a task identified by its [id].
  ///
  /// Implementations should handle non-existent IDs gracefully and ensure
  /// referential integrity (e.g., if cascades to other entities are needed).
  Future<void> deleteTask(String id);
}

