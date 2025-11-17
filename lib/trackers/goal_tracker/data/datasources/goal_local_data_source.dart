/*
 * File: goal_local_data_source.dart
 *
 * Purpose:
 *   Hive-backed local data source for Goal objects. This file provides an
 *   abstract contract (GoalLocalDataSource) and a Hive implementation
 *   (GoalLocalDataSourceImpl) that persist GoalModel instances into a Hive box.
 *
 * Serialization rules (high level):
 *   - The concrete Hive adapter and the GoalModel DTO live in ../models/goal_model.dart.
 *   - Nullable fields, defaults, and any custom conversion are defined on GoalModel.
 *     Refer to GoalModel for which fields are nullable and default values.
 *   - Keys used for storage: goal.id (String) is used as the Hive key (not an auto-increment).
 *
 * Compatibility guidance:
 *   - Do NOT reuse Hive field numbers in goal_model.dart when adding/removing fields.
 *   - When changing the model layout or field numbers, update migration_notes.md
 *     with the adapter version and migration steps.
 *   - Any backward-compatibility conversions (legacy values -> new schema) should be
 *     implemented in GoalModel (factory / fromEntity / fromJson) so the data source
 *     remains thin and focused on persistence.
 *
 * Developer notes:
 *   - This file intentionally does not perform model conversions — it delegates that
 *     responsibility to GoalModel. Keep storage operations (put/get/delete) simple.
 *   - If you add caching, locking, or batch operations, maintain the invariant that
 *     keys are goal.id and that GoalModel instances match the Hive adapter version.
 */

import 'package:hive/hive.dart';
import '../models/goal_model.dart';

/// Abstract data source for local (Hive) goal storage.
///
/// Implementations should be simple adapters that read/write GoalModel instances.
/// Conversions between domain entity and DTO should be implemented in GoalModel.
abstract class GoalLocalDataSource {
  /// Returns all goals stored in the local box.
  Future<List<GoalModel>> getAllGoals();

  /// Returns a single GoalModel by its string id key, or null if not found.
  Future<GoalModel?> getGoalById(String id);

  /// Persists a new GoalModel. The implementation is expected to use goal.id as key.
  Future<void> createGoal(GoalModel goal);

  /// Updates an existing GoalModel (or creates it if missing) — uses the same
  /// semantics as Hive's `put` (overwrite if exists).
  Future<void> updateGoal(GoalModel goal);

  /// Deletes a goal by its id key.
  Future<void> deleteGoal(String id);
}

/// Hive implementation of [GoalLocalDataSource].
///
/// This class treats the provided [box] as the single source of truth for
/// GoalModel persistence. It uses `goal.id` (String) as the Hive key — this keeps
/// keys stable across app runs and simplifies lookup.
///
/// Important:
///  - Any legacy value handling (e.g. migrating an old string format to a new enum)
///    should be done inside GoalModel (e.g., GoalModel.fromEntity/fromJson).
///  - The box must be registered with the appropriate adapter for GoalModel before
///    this class is constructed.
class GoalLocalDataSourceImpl implements GoalLocalDataSource {
  /// Hive box that stores [GoalModel] entries.
  ///
  /// Rationale: using a typed Box<GoalModel> enforces compile-time safety and
  /// ensures the Hive adapter for GoalModel is used for serialization.
  final Box<GoalModel> box;

  /// Create the local data source with the provided Hive box.
  ///
  /// The box should be opened and the GoalModel adapter registered prior to
  /// passing it here (typically during app initialization in core/hive initializer).
  GoalLocalDataSourceImpl(this.box);

  @override
  Future<void> createGoal(GoalModel goal) async {
    // Use goal.id as the key. This keeps keys consistent and human-readable.
    // We intentionally rely on Hive's `put` semantics — it will create or overwrite.
    await box.put(goal.id, goal);
  }

  @override
  Future<void> deleteGoal(String id) async {
    // Remove the entry with the given id key. No additional logic here to keep
    // the data source thin; domain-level cascade deletes (if any) should be handled
    // by the repository/usecase layer.
    await box.delete(id);
  }

  @override
  Future<GoalModel?> getGoalById(String id) async {
    // Direct box lookup by string key. Returns null if not present.
    // If additional compatibility work is needed (e.g. rehydration), implement it
    // in GoalModel (constructor/factory) so this call remains simple.
    return box.get(id);
  }

  @override
  Future<List<GoalModel>> getAllGoals() async {
    // Convert box values iterable to a list. Ordering is the insertion order from Hive.
    // If deterministic sorting is required (e.g., by createdDate), do it at the
    // repository/presentation layer rather than here.
    return box.values.toList();
  }

  @override
  Future<void> updateGoal(GoalModel goal) async {
    // Update uses the same `put` as create — overwrites existing entry with same key.
    // This keeps create/update semantics unified and reduces duplication.
    await box.put(goal.id, goal);
  }
}
