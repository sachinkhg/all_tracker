/*
 * File: milestone_repository_impl.dart
 *
 * Purpose:
 *  - Repository implementation that bridges the domain layer (Milestone entity)
 *    with the data layer (MilestoneModel / Hive-backed MilestoneLocalDataSource).
 *  - Converts domain entities to/from data transfer objects (MilestoneModel)
 *    and delegates persistence operations to the local data source.
 *
 * Serialization rules (high level):
 *  - The detailed serialization rules (nullable fields, default values,
 *    Hive field numbers) are defined on the MilestoneModel (models/milestone_model.dart).
 *  - Nullable fields in the domain Milestone (e.g., description, plannedValue,
 *    actualValue, targetDate) are propagated into the MilestoneModel. Any defaults
 *    required for storage are applied by the MilestoneModel constructor or adapter,
 *    not by this repository.
 *
 * Compatibility guidance:
 *  - Do NOT reuse Hive field numbers. Any change to the MilestoneModel Hive field
 *    numbers must be accompanied by migration logic and an update to
 *    migration_notes.md.
 *  - Backward compatibility conversion logic (if needed) lives inside MilestoneModel
 *    (fromEntity / toEntity) or within the data source. This repository only
 *    forwards and returns converted objects.
 *
 * Notes for maintainers:
 *  - This file intentionally contains only mapping calls (MilestoneModel.fromEntity
 *    and model.toEntity()) and orchestration calls to the local data source.
 *  - Keep conversion logic in the model layer so tests can validate conversion
 *    behavior in one place.
 *  - Avoid adding business rules here — this class should remain a thin mediator
 *    between domain and persistence layers.
 */

import '../../domain/entities/milestone.dart';
import '../../domain/repositories/milestone_repository.dart';
import '../datasources/milestone_local_data_source.dart';
import '../models/milestone_model.dart';

/// Concrete implementation of [MilestoneRepository].
///
/// Responsibilities:
///  - Convert between domain [Milestone] and data layer [MilestoneModel].
///  - Delegate persistence operations to [MilestoneLocalDataSource].
///
/// Implementation notes:
///  - All field-level conversions, defaults, and compatibility logic
///    reside within MilestoneModel.
///  - The repository ensures the domain layer remains persistence-agnostic.
class MilestoneRepositoryImpl implements MilestoneRepository {
  /// Local data source handling actual persistence through Hive.
  final MilestoneLocalDataSource local;

  /// Creates a repository backed by the provided local data source.
  ///
  /// The data source should be initialized with a registered Hive adapter
  /// before creating this repository.
  MilestoneRepositoryImpl(this.local);

  @override
  Future<void> createMilestone(Milestone milestone) async {
    // Convert domain entity → data model.
    final model = MilestoneModel.fromEntity(milestone);

    // Persist through the local data source.
    await local.createMilestone(model);
  }

  @override
  Future<void> deleteMilestone(String id) async {
    // Direct delete pass-through by ID.
    await local.deleteMilestone(id);
  }

  @override
  Future<List<Milestone>> getAllMilestones() async {
    // Fetch DTOs/models and map each to the domain entity.
    final models = await local.getAllMilestones();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Milestone?> getMilestoneById(String id) async {
    // Fetch model by ID and convert to domain entity.
    final model = await local.getMilestoneById(id);
    return model?.toEntity();
  }

  @override
  Future<List<Milestone>> getMilestonesByGoalId(String goalId) async {
    // Retrieve all milestones linked to a specific goal.
    final models = await local.getMilestonesByGoalId(goalId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> updateMilestone(Milestone milestone) async {
    // Convert and persist updated milestone.
    final model = MilestoneModel.fromEntity(milestone);
    await local.updateMilestone(model);
  }
}
