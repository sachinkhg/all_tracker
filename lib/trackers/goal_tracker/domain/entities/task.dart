/*
 * File: ./lib/goal_tracker/domain/entities/task.dart
 *
 * Purpose:
 *   Domain representation of a Task used throughout the application's
 *   business logic. Each Task represents a specific action item associated
 *   with a Milestone (which in turn is associated with a Goal).
 *
 *   This file defines the plain, immutable domain entity and documents how
 *   it maps to persistence DTOs / Hive models (those mapper functions live
 *   in the data layer under `task_model.dart`).
 *
 * Serialization rules (for implementers of DTO / Hive adapters):
 *   - `id` (String)         : non-nullable, globally unique identifier.
 *   - `name` (String)       : non-nullable, human-readable title.
 *   - `targetDate` (DateTime?): nullable; represents expected completion date.
 *   - `milestoneId` (String): non-nullable foreign key linking to parent Milestone.
 *   - `goalId` (String)     : non-nullable foreign key linking to parent Goal (derived from milestone).
 *   - `status` (String)     : non-nullable; represents task status: 'To Do', 'In Progress', or 'Complete'.
 *
 * Compatibility guidance:
 *   - Do not reuse or renumber Hive field indices once written.
 *   - Any schema evolution (adding/removing fields) must be recorded in
 *     `migration_notes.md` with proper migration logic.
 *   - Mapper implementations (e.g., TaskModel.fromEntity()) are responsible
 *     for backward compatibility handling, such as missing fields or
 *     default values.
 *
 * Notes for implementers:
 *   - This file should remain persistence-agnostic. Keep storage annotations
 *     and logic in the data layer only.
 *   - The domain layer operates with immutable, type-safe entities.
 *   - The `goalId` field is derived from the associated Milestone and should
 *     be auto-set during create/update operations in the cubit/repository layer.
 */

import 'package:equatable/equatable.dart';

/// Domain model for a Task.
///
/// Each Task belongs to a single Milestone (via `milestoneId`) and inherits
/// its Goal association through the Milestone's `goalId`. Tasks represent
/// actionable work items with a status and optional target date.
///
/// This entity is designed for use within domain and presentation layers —
/// persistence mapping occurs in the data/local layer.
class Task extends Equatable {
  /// Unique identifier for the task (GUID or UUID recommended).
  ///
  /// Expected Hive field number (data layer): 0.
  final String id;

  /// Human-readable task title.
  ///
  /// Expected Hive field number (data layer): 1.
  final String name;

  /// Expected target date for task completion.
  ///
  /// Nullable — absence implies "no fixed deadline".
  /// Expected Hive field number (data layer): 2.
  final DateTime? targetDate;

  /// Foreign key linking this task to its parent Milestone.
  ///
  /// Required — every task must belong to a milestone.
  /// Expected Hive field number (data layer): 3.
  final String milestoneId;

  /// Foreign key linking this task to its parent Goal.
  ///
  /// This is a derived/denormalized field automatically set from the milestone's goalId.
  /// The UI should treat this as read-only; it's populated by the cubit/repository
  /// during create/update operations.
  /// Expected Hive field number (data layer): 4.
  final String goalId;

  /// Current status of the task.
  ///
  /// Valid values: 'To Do', 'In Progress', 'Complete'.
  /// Non-nullable in domain; defaults to 'To Do' for new tasks.
  /// Expected Hive field number (data layer): 5.
  final String status;

  /// Domain constructor.
  ///
  /// Keep this immutable (`const`) to ensure referential safety and ease of comparison.
  const Task({
    required this.id,
    required this.name,
    this.targetDate,
    required this.milestoneId,
    required this.goalId,
    this.status = 'To Do',
  });

  @override
  List<Object?> get props =>
      [id, name, targetDate, milestoneId, goalId, status];
}

