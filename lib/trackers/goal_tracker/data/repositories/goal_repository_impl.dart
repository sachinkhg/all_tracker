/*
 * File: goal_repository_impl.dart
 *
 * Purpose:
 *  - Repository implementation that bridges the domain layer (Goal entity)
 *    with the data layer (GoalModel / Hive-backed GoalLocalDataSource).
 *  - Converts domain entities to/from data transfer objects (GoalModel)
 *    and delegates persistence operations to the local data source.
 *
 * Serialization rules (high level):
 *  - The detailed serialization rules (nullable fields, default values,
 *    Hive field numbers) are defined on the GoalModel (models/goal_model.dart).
 *  - Nullable fields in the domain Goal (e.g., description, targetDate, context)
 *    are propagated into the GoalModel. Any defaults required for storage are
 *    applied by the GoalModel constructor / adapter, not by this repository.
 *
 * Compatibility guidance:
 *  - Do NOT reuse Hive field numbers. Any change to the GoalModel Hive field
 *    numbers must be accompanied by migration logic and an update to
 *    migration_notes.md.
 *  - Backward compatibility conversion logic (if needed) lives inside GoalModel
 *    (fromEntity / toEntity) or inside the data source. This repository only
 *    forwards and returns converted objects.
 *
 * Notes for maintainers:
 *  - This file intentionally contains only mapping calls (GoalModel.fromEntity
 *    and model.toEntity()) and orchestration calls to the local data source.
 *  - Keep mapping logic in the model so tests can exercise conversions in one
 *    place. Avoid adding ad-hoc conversion logic here unless it pertains to
 *    repository-specific behavior (e.g., soft-delete flags).
 */

import '../../domain/entities/goal.dart';
import '../../domain/repositories/goal_repository.dart';
import '../datasources/goal_local_data_source.dart';
import '../models/goal_model.dart';
import '../mappers/goal_mapper.dart';

/// Concrete implementation of [GoalRepository].
///
/// Responsibilities:
///  - Convert between domain [Goal] and data layer [GoalModel].
///  - Delegate persistence operations to [GoalLocalDataSource].
///
/// Implementation notes:
///  - All conversion/serialization specifics (nullable fields, legacy value
///    handling, Hive field numbers) are implemented inside `GoalModel`.
///  - If backward-compatibility fixes are needed (for example migrating an old
///    enum stored as string), prefer to place that logic inside `GoalModel` or
///    the data source so it's centralized and testable.
class GoalRepositoryImpl implements GoalRepository {
  /// Local data source that owns the Hive adapters / actual persistence.
  final GoalLocalDataSource local;
  
  /// Mapper for converting between domain entities and data models.
  final GoalMapper mapper;

  /// Creates a repository backed by the provided local data source.
  ///
  /// Use dependency injection at app bootstrap to supply the proper
  /// implementation (e.g., Hive-backed [GoalLocalDataSource]).
  GoalRepositoryImpl(this.local, {GoalMapper? mapper}) 
      : mapper = mapper ?? GoalMapper();

  @override
  Future<void> createGoal(Goal goal) async {
    // Convert domain entity -> data model using mapper.
    final model = mapper.toModel(goal);

    // Persist via local data source (Hive adapter). Keep repository logic
    // minimal; do not introduce business logic here.
    await local.createGoal(model);
  }

  @override
  Future<void> deleteGoal(String id) async {
    // Straight pass-through delete by id. The local data source decides whether
    // this is permanent delete or soft delete.
    await local.deleteGoal(id);
  }

  @override
  Future<List<Goal>> getAllGoals() async {
    // Fetch DTOs/models from the local data source.
    final models = await local.getAllGoals();

    // Map to domain entities using mapper. Preserve ordering provided by the data source.
    return mapper.toEntityList(models);
  }

  @override
  Future<Goal?> getGoalById(String id) async {
    // Retrieve model by id (may return null if not found) and convert to
    // domain entity using mapper. Null indicates absence.
    final model = await local.getGoalById(id);
    return model != null ? mapper.toEntity(model) : null;
  }

  @override
  Future<void> updateGoal(Goal goal) async {
    // Convert domain entity -> model using mapper and delegate update to data source.
    // Any field-level migration (e.g., migrating an older flag to the new
    // representation) should be handled inside the model or the data source.
    final model = mapper.toModel(goal);
    await local.updateGoal(model);
  }
}
