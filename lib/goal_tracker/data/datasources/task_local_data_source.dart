/*
 * File: task_local_data_source.dart
 *
 * Purpose:
 *   Hive-backed local data source for Task objects. This file provides an
 *   abstract contract (TaskLocalDataSource) and a Hive implementation
 *   (TaskLocalDataSourceImpl) that persist TaskModel instances into
 *   a Hive box.
 *
 * Serialization rules (high level):
 *   - The concrete Hive adapter and the TaskModel DTO live in ../models/task_model.dart.
 *   - Nullable fields, defaults, and any custom conversions are defined on TaskModel.
 *     Refer to TaskModel for which fields are nullable and how null/empty values are handled.
 *   - Keys used for storage: task.id (String) is used as the Hive key (not auto-incremented).
 *
 * Compatibility guidance:
 *   - Do NOT reuse Hive field numbers in task_model.dart when adding or removing fields.
 *   - When changing the model schema or field numbering, update migration_notes.md with
 *     adapter version and required migration steps.
 *   - Any backward-compatibility conversions (legacy values, renamed fields, etc.)
 *     should be implemented within TaskModel itself to keep this layer thin.
 *
 * Developer notes:
 *   - This data source is intentionally minimal — it only performs storage operations
 *     (put/get/delete) and defers any transformation logic to the model layer.
 *   - If caching, sorting, or cascade logic is needed, it should be implemented in
 *     repositories or use cases, not directly in this layer.
 */

import 'package:hive/hive.dart';
import '../models/task_model.dart';

/// Abstract data source for local (Hive) task storage.
///
/// Implementations are simple adapters that read/write TaskModel instances.
/// Conversion between domain entities and DTOs should be handled in TaskModel.
abstract class TaskLocalDataSource {
  /// Returns all tasks stored in the local box.
  Future<List<TaskModel>> getAllTasks();

  /// Returns a task by its string ID, or null if not found.
  Future<TaskModel?> getTaskById(String id);

  /// Persists a new task. The implementation must use task.id as the Hive key.
  Future<void> createTask(TaskModel task);

  /// Updates an existing task (or creates it if missing).
  /// Uses Hive's `put` semantics — overwrites if key exists.
  Future<void> updateTask(TaskModel task);

  /// Deletes a task by its ID key.
  Future<void> deleteTask(String id);

  /// Returns all tasks belonging to a specific milestone.
  ///
  /// Since Hive doesn't natively support relational queries, this performs
  /// an in-memory filter on all values. For large datasets, consider
  /// adding milestone-specific boxes or indices.
  Future<List<TaskModel>> getTasksByMilestoneId(String milestoneId);

  /// Returns all tasks belonging to a specific goal.
  ///
  /// Since Hive doesn't natively support relational queries, this performs
  /// an in-memory filter on all values.
  Future<List<TaskModel>> getTasksByGoalId(String goalId);
}

/// Hive implementation of [TaskLocalDataSource].
///
/// This class treats the provided [box] as the single source of truth for
/// TaskModel persistence. It uses `task.id` (String) as the Hive key.
class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  /// Hive box storing [TaskModel] entries.
  ///
  /// A typed Box<TaskModel> enforces adapter correctness and serialization safety.
  final Box<TaskModel> box;

  /// Constructs a local data source using the provided Hive box.
  ///
  /// Ensure that the TaskModel adapter is registered and the box opened
  /// before constructing this data source.
  TaskLocalDataSourceImpl(this.box);

  @override
  Future<void> createTask(TaskModel task) async {
    // Use task.id as the key for stable, human-readable lookups.
    await box.put(task.id, task);
  }

  @override
  Future<void> deleteTask(String id) async {
    // Remove entry with matching id key. Cascade deletions (if required)
    // are handled by higher layers (repository/use case).
    await box.delete(id);
  }

  @override
  Future<TaskModel?> getTaskById(String id) async {
    // Direct key lookup. Returns null if not found.
    return box.get(id);
  }

  @override
  Future<List<TaskModel>> getAllTasks() async {
    // Returns all values from the box as a list.
    return box.values.toList();
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    // Overwrites or creates an entry with the same id.
    await box.put(task.id, task);
  }

  @override
  Future<List<TaskModel>> getTasksByMilestoneId(String milestoneId) async {
    // Simple in-memory filter. Optimized solutions could use indexes if needed.
    return box.values.where((t) => t.milestoneId == milestoneId).toList();
  }

  @override
  Future<List<TaskModel>> getTasksByGoalId(String goalId) async {
    // Simple in-memory filter. Optimized solutions could use indexes if needed.
    return box.values.where((t) => t.goalId == goalId).toList();
  }
}

