/*
 * File: ./lib/goal_tracker/domain/entities/habit.dart
 *
 * Purpose:
 *   Domain representation of a Habit used throughout the application's
 *   business logic. Each Habit represents a recurring action that can
 *   contribute to milestone progress through completion tracking.
 *
 *   This file defines the plain, immutable domain entity and documents how
 *   it maps to persistence DTOs / Hive models (those mapper functions live
 *   in the data layer under `habit_model.dart`).
 *
 * Serialization rules (for implementers of DTO / Hive adapters):
 *   - `id` (String)           : non-nullable, globally unique identifier.
 *   - `name` (String)         : non-nullable, human-readable title.
 *   - `description` (String?) : nullable; empty vs null semantics managed by mappers.
 *   - `milestoneId` (String)  : non-nullable foreign key linking to parent Milestone.
 *   - `goalId` (String)       : non-nullable foreign key linking to parent Goal (auto-assigned from milestone).
 *   - `rrule` (String)        : non-nullable recurrence rule (RRULE format).
 *   - `targetCompletions` (int?): nullable; weight for milestone contribution (defaults to 1).
 *   - `isActive` (bool)       : non-nullable; whether habit is currently active (defaults to true).
 *
 * Compatibility guidance:
 *   - Do not reuse or renumber Hive field indices once written.
 *   - Any schema evolution (adding/removing fields) must be recorded in
 *     `migration_notes.md` with proper migration logic.
 *   - Mapper implementations (e.g., HabitModel.fromEntity()) are responsible
 *     for backward compatibility handling, such as missing numeric fields or
 *     default values.
 *
 * Notes for implementers:
 *   - This file should remain persistence-agnostic. Keep storage annotations
 *     and logic in the data layer only.
 *   - The domain layer operates with immutable, type-safe entities.
 *   - RRULE format should follow RFC 5545 standard for recurrence rules.
 */

import 'package:equatable/equatable.dart';

/// Domain model for a Habit.
///
/// Each Habit belongs to a single Milestone (via `milestoneId`) and represents
/// a recurring action that can be completed to contribute to milestone progress.
/// This entity is designed for use within domain and presentation layers —
/// persistence mapping occurs in the data/local layer.
class Habit extends Equatable {
  /// Unique identifier for the habit (GUID or UUID recommended).
  ///
  /// Expected Hive field number (data layer): 0.
  final String id;

  /// Human-readable habit title.
  ///
  /// Expected Hive field number (data layer): 1.
  final String name;

  /// Optional description giving context, objective, or details.
  ///
  /// Expected Hive field number (data layer): 2.
  final String? description;

  /// Reference to the parent Milestone this habit belongs to.
  ///
  /// Expected Hive field number (data layer): 3.
  final String milestoneId;

  /// Reference to the parent Goal this habit is associated with.
  ///
  /// This is derived from the milestone's goalId and should be auto-set
  /// during create/update operations. The UI should not allow direct editing.
  /// Expected Hive field number (data layer): 4.
  final String goalId;

  /// Recurrence rule defining when the habit should be performed.
  ///
  /// Follows RFC 5545 RRULE format. Examples:
  /// - "FREQ=DAILY" (every day)
  /// - "FREQ=WEEKLY;BYDAY=MO,WE,FR" (Monday, Wednesday, Friday)
  /// - "FREQ=DAILY;INTERVAL=2" (every 2 days)
  /// Expected Hive field number (data layer): 5.
  final String rrule;

  /// Optional weight for milestone contribution.
  ///
  /// When a habit is completed, it contributes this many units to the
  /// milestone's actualValue. If null, defaults to 1.
  /// Expected Hive field number (data layer): 6.
  final int? targetCompletions;

  /// Whether the habit is currently active.
  ///
  /// Inactive habits are preserved but don't appear in default lists
  /// and don't contribute to milestone progress.
  /// Expected Hive field number (data layer): 7.
  final bool isActive;

  /// Domain constructor.
  ///
  /// Keep this immutable (`const`) to ensure referential safety and ease of comparison.
  const Habit({
    required this.id,
    required this.name,
    this.description,
    required this.milestoneId,
    required this.goalId,
    required this.rrule,
    this.targetCompletions,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        milestoneId,
        goalId,
        rrule,
        targetCompletions,
        isActive,
      ];
}
