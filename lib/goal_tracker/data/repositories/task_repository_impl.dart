/*
 * File: task_repository_impl.dart
 *
 * Purpose:
 *  - Repository implementation that bridges the domain layer (Task entity)
 *    with the data layer (TaskModel / Hive-backed TaskLocalDataSource).
 *  - Converts domain entities to/from data transfer objects (TaskModel)
 *    and delegates persistence operations to the local data source.
 *
 * Serialization rules (high level):
 *  - The detailed serialization rules (nullable fields, default values,
 *    Hive field numbers) are defined on the TaskModel (models/task_model.dart).
 *  - Nullable fields in the domain Task (e.g., targetDate) are propagated
 *    into the TaskModel. Any defaults required for storage are applied by
 *    the TaskModel constructor or adapter, not by this repository.
 *
 * Compatibility guidance:
 *  - Do NOT reuse Hive field numbers. Any change to the TaskModel Hive field
 *    numbers must be accompanied by migration logic and an update to
 *    migration_notes.md.
 *  - Backward compatibility conversion logic (if needed) lives inside TaskModel
 *    (fromEntity / toEntity) or within the data source. This repository only
 *    forwards and returns converted objects.
 *
 * Notes for maintainers:
 *  - This file intentionally contains only mapping calls (TaskModel.fromEntity
 *    and model.toEntity()) and orchestration calls to the local data source.
 *  - Keep conversion logic in the model layer so tests can validate conversion
 *    behavior in one place.
 *  - Avoid adding business rules here — this class should remain a thin mediator
 *    between domain and persistence layers.
 */

import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_data_source.dart';
import '../models/task_model.dart';

/// Concrete implementation of [TaskRepository].
///
/// Responsibilities:
///  - Convert between domain [Task] and data layer [TaskModel].
///  - Delegate persistence operations to [TaskLocalDataSource].
///
/// Implementation notes:
///  - All field-level conversions, defaults, and compatibility logic
///    reside within TaskModel.
///  - The repository ensures the domain layer remains persistence-agnostic.
class TaskRepositoryImpl implements TaskRepository {
  /// Local data source handling actual persistence through Hive.
  final TaskLocalDataSource local;

  /// Creates a repository backed by the provided local data source.
  ///
  /// The data source should be initialized with a registered Hive adapter
  /// before creating this repository.
  TaskRepositoryImpl(this.local);

  @override
  Future<void> createTask(Task task) async {
    // Convert domain entity → data model.
    final model = TaskModel.fromEntity(task);

    // Persist through the local data source.
    await local.createTask(model);
  }

  @override
  Future<void> deleteTask(String id) async {
    // Direct delete pass-through by ID.
    await local.deleteTask(id);
  }

  @override
  Future<List<Task>> getAllTasks() async {
    // Fetch DTOs/models and map each to the domain entity.
    final models = await local.getAllTasks();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Task?> getTaskById(String id) async {
    // Fetch model by ID and convert to domain entity.
    final model = await local.getTaskById(id);
    return model?.toEntity();
  }

  @override
  Future<List<Task>> getTasksByMilestoneId(String milestoneId) async {
    // Retrieve all tasks linked to a specific milestone.
    final models = await local.getTasksByMilestoneId(milestoneId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Task>> getTasksByGoalId(String goalId) async {
    // Retrieve all tasks linked to a specific goal.
    final models = await local.getTasksByGoalId(goalId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> updateTask(Task task) async {
    // Convert and persist updated task.
    final model = TaskModel.fromEntity(task);
    await local.updateTask(model);
  }
}

