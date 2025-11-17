/*
 * File: ./lib/goal_tracker/domain/entities/milestone.dart
 *
 * Purpose:
 *   Domain representation of a Milestone used throughout the application's
 *   business logic. Each Milestone represents a measurable checkpoint
 *   or progress marker associated with a Goal.
 *
 *   This file defines the plain, immutable domain entity and documents how
 *   it maps to persistence DTOs / Hive models (those mapper functions live
 *   in the data layer under `milestone_model.dart`).
 *
 * Serialization rules (for implementers of DTO / Hive adapters):
 *   - `id` (String)           : non-nullable, globally unique identifier.
 *   - `name` (String)         : non-nullable, human-readable title.
 *   - `description` (String?) : nullable; empty vs null semantics managed by mappers.
 *   - `plannedValue` (double?): nullable; represents planned quantitative target.
 *   - `actualValue` (double?) : nullable; represents actual achieved value.
 *   - `targetDate` (DateTime?): nullable; represents expected completion date.
 *   - `goalId` (String)       : non-nullable foreign key linking to parent Goal.
 *
 * Compatibility guidance:
 *   - Do not reuse or renumber Hive field indices once written.
 *   - Any schema evolution (adding/removing fields) must be recorded in
 *     `migration_notes.md` with proper migration logic.
 *   - Mapper implementations (e.g., MilestoneModel.fromEntity()) are responsible
 *     for backward compatibility handling, such as missing numeric fields or
 *     default values.
 *
 * Notes for implementers:
 *   - This file should remain persistence-agnostic. Keep storage annotations
 *     and logic in the data layer only.
 *   - The domain layer operates with immutable, type-safe entities.
 */

import 'package:equatable/equatable.dart';

/// Domain model for a Milestone.
///
/// Each Milestone belongs to a single Goal (via `goalId`) and represents
/// a measurable progress point such as a deliverable, metric target, or
/// sub-goal. This entity is designed for use within domain and presentation
/// layers — persistence mapping occurs in the data/local layer.
class Milestone extends Equatable {
  /// Unique identifier for the milestone (GUID or UUID recommended).
  ///
  /// Expected Hive field number (data layer): 0.
  final String id;

  /// Human-readable milestone title.
  ///
  /// Expected Hive field number (data layer): 1.
  final String name;

  /// Optional description giving context, objective, or details.
  ///
  /// Expected Hive field number (data layer): 2.
  final String? description;

  /// Planned (target) numeric value for this milestone.
  ///
  /// Example: “Target 100 data points labeled”, or “Revenue target 1.5M”.
  /// Expected Hive field number (data layer): 3.
  final double? plannedValue;

  /// Actual achieved numeric value.
  ///
  /// Represents real measured progress; may be null if not yet tracked.
  /// Expected Hive field number (data layer): 4.
  final double? actualValue;

  /// Expected target date for milestone completion.
  ///
  /// Nullable — absence implies “no fixed deadline”.
  /// Expected Hive field number (data layer): 5.
  final DateTime? targetDate;

  /// Foreign key linking this milestone to its parent Goal.
  ///
  /// Expected Hive field number (data layer): 6.
  final String goalId;

  /// Domain constructor.
  ///
  /// Keep this immutable (`const`) to ensure referential safety and ease of comparison.
  const Milestone({
    required this.id,
    required this.name,
    this.description,
    this.plannedValue,
    this.actualValue,
    this.targetDate,
    required this.goalId,
  });

  /// Creates a copy of this Milestone with the given fields replaced.
  ///
  /// Useful for updates where only certain fields change.
  Milestone copyWith({
    String? id,
    String? name,
    String? description,
    double? plannedValue,
    double? actualValue,
    DateTime? targetDate,
    String? goalId,
  }) {
    return Milestone(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      plannedValue: plannedValue ?? this.plannedValue,
      actualValue: actualValue ?? this.actualValue,
      targetDate: targetDate ?? this.targetDate,
      goalId: goalId ?? this.goalId,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, description, plannedValue, actualValue, targetDate, goalId];
}
