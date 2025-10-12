/*
 * File: milestone_local_data_source.dart
 *
 * Purpose:
 *   Hive-backed local data source for Milestone objects. This file provides an
 *   abstract contract (MilestoneLocalDataSource) and a Hive implementation
 *   (MilestoneLocalDataSourceImpl) that persist MilestoneModel instances into
 *   a Hive box.
 *
 * Serialization rules (high level):
 *   - The concrete Hive adapter and the MilestoneModel DTO live in ../models/milestone_model.dart.
 *   - Nullable fields, defaults, and any custom conversions are defined on MilestoneModel.
 *     Refer to MilestoneModel for which fields are nullable and how null/empty values are handled.
 *   - Keys used for storage: milestone.id (String) is used as the Hive key (not auto-incremented).
 *
 * Compatibility guidance:
 *   - Do NOT reuse Hive field numbers in milestone_model.dart when adding or removing fields.
 *   - When changing the model schema or field numbering, update migration_notes.md with
 *     adapter version and required migration steps.
 *   - Any backward-compatibility conversions (legacy values, renamed fields, etc.)
 *     should be implemented within MilestoneModel itself to keep this layer thin.
 *
 * Developer notes:
 *   - This data source is intentionally minimal — it only performs storage operations
 *     (put/get/delete) and defers any transformation logic to the model layer.
 *   - If caching, sorting, or cascade logic is needed, it should be implemented in
 *     repositories or use cases, not directly in this layer.
 */

import 'package:hive/hive.dart';
import '../models/milestone_model.dart';

/// Abstract data source for local (Hive) milestone storage.
///
/// Implementations are simple adapters that read/write MilestoneModel instances.
/// Conversion between domain entities and DTOs should be handled in MilestoneModel.
abstract class MilestoneLocalDataSource {
  /// Returns all milestones stored in the local box.
  Future<List<MilestoneModel>> getAllMilestones();

  /// Returns a milestone by its string ID, or null if not found.
  Future<MilestoneModel?> getMilestoneById(String id);

  /// Persists a new milestone. The implementation must use milestone.id as the Hive key.
  Future<void> createMilestone(MilestoneModel milestone);

  /// Updates an existing milestone (or creates it if missing).
  /// Uses Hive’s `put` semantics — overwrites if key exists.
  Future<void> updateMilestone(MilestoneModel milestone);

  /// Deletes a milestone by its ID key.
  Future<void> deleteMilestone(String id);

  /// Returns all milestones belonging to a specific goal.
  ///
  /// Since Hive doesn’t natively support relational queries, this performs
  /// an in-memory filter on all values. For large datasets, consider
  /// adding goal-specific boxes or indices.
  Future<List<MilestoneModel>> getMilestonesByGoalId(String goalId);
}

/// Hive implementation of [MilestoneLocalDataSource].
///
/// This class treats the provided [box] as the single source of truth for
/// MilestoneModel persistence. It uses `milestone.id` (String) as the Hive key.
class MilestoneLocalDataSourceImpl implements MilestoneLocalDataSource {
  /// Hive box storing [MilestoneModel] entries.
  ///
  /// A typed Box<MilestoneModel> enforces adapter correctness and serialization safety.
  final Box<MilestoneModel> box;

  /// Constructs a local data source using the provided Hive box.
  ///
  /// Ensure that the MilestoneModel adapter is registered and the box opened
  /// before constructing this data source.
  MilestoneLocalDataSourceImpl(this.box);

  @override
  Future<void> createMilestone(MilestoneModel milestone) async {
    // Use milestone.id as the key for stable, human-readable lookups.
    await box.put(milestone.id, milestone);
  }

  @override
  Future<void> deleteMilestone(String id) async {
    // Remove entry with matching id key. Cascade deletions (if required)
    // are handled by higher layers (repository/use case).
    await box.delete(id);
  }

  @override
  Future<MilestoneModel?> getMilestoneById(String id) async {
    // Direct key lookup. Returns null if not found.
    return box.get(id);
  }

  @override
  Future<List<MilestoneModel>> getAllMilestones() async {
    // Returns all values from the box as a list.
    return box.values.toList();
  }

  @override
  Future<void> updateMilestone(MilestoneModel milestone) async {
    // Overwrites or creates an entry with the same id.
    await box.put(milestone.id, milestone);
  }

  @override
  Future<List<MilestoneModel>> getMilestonesByGoalId(String goalId) async {
    // Simple in-memory filter. Optimized solutions could use indexes if needed.
    return box.values.where((m) => m.goalId == goalId).toList();
  }
}
