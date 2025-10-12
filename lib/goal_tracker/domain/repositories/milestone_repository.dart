/*
  purpose:
    - Defines the abstract contract for the Milestone data access layer (Domain → Data boundary).
    - This repository interface decouples the domain layer from implementation details
      such as Hive, SQLite, REST APIs, or any persistence mechanism.
    - Implementations must ensure correct entity conversion and validation between
      domain models (Milestone) and their data source representations.

  usage:
    - The application’s MilestoneCubit or domain use-cases depend on this interface,
      not the concrete implementation.
    - Concrete implementations (e.g., HiveMilestoneRepository, LocalMilestoneRepository)
      should reside under the data/ or infrastructure/ layer.
    - Modify this interface only when there are domain-level changes to how Milestones
      are managed (not when the persistence schema changes).

  compatibility guidance:
    - Avoid persistence-specific details or technology-dependent parameters.
    - Keep all operations asynchronous and domain-pure.
    - On modification, document the change in ARCHITECTURE.md and update
      relevant contribution and migration notes.
*/

import '../entities/milestone.dart';

/// Abstract repository defining CRUD operations for [Milestone] entities.
///
/// This repository defines the boundary between the domain layer and data sources.
/// Concrete implementations are responsible for data persistence, mapping, and
/// error handling — keeping the domain layer completely agnostic to infrastructure.
abstract class MilestoneRepository {
  /// Retrieve all milestones from storage.
  ///
  /// The order and filtering behavior are left to the implementation.
  /// Implementations may choose to return all milestones or scoped ones as per app logic.
  Future<List<Milestone>> getAllMilestones();

  /// Retrieve a single milestone by its unique [id].
  ///
  /// Returns `null` if the milestone is not found.
  Future<Milestone?> getMilestoneById(String id);

  /// Retrieve all milestones associated with a specific [goalId].
  ///
  /// Returns an empty list if the goal has no milestones or the goal ID does not exist.
  Future<List<Milestone>> getMilestonesByGoalId(String goalId);

  /// Create a new [Milestone] record in storage.
  ///
  /// Implementations must ensure ID uniqueness and perform validation before persistence.
  Future<void> createMilestone(Milestone milestone);

  /// Update an existing [Milestone].
  ///
  /// Implementations should validate that [milestone.id] exists before updating.
  /// Throws or logs appropriately if the milestone cannot be updated.
  Future<void> updateMilestone(Milestone milestone);

  /// Delete a milestone identified by its [id].
  ///
  /// Implementations should handle non-existent IDs gracefully and ensure
  /// referential integrity (e.g., if cascades to other entities are needed).
  Future<void> deleteMilestone(String id);
}
