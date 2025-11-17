/*
 * File: ./lib/goal_tracker/domain/entities/habit_completion.dart
 *
 * Purpose:
 *   Domain representation of a HabitCompletion used throughout the application's
 *   business logic. Each HabitCompletion represents a single instance of
 *   completing a habit on a specific date.
 *
 *   This file defines the plain, immutable domain entity and documents how
 *   it maps to persistence DTOs / Hive models (those mapper functions live
 *   in the data layer under `habit_completion_model.dart`).
 *
 * Serialization rules (for implementers of DTO / Hive adapters):
 *   - `id` (String)           : non-nullable, globally unique identifier.
 *   - `habitId` (String)      : non-nullable foreign key linking to parent Habit.
 *   - `completionDate` (DateTime): non-nullable; date when habit was completed.
 *   - `note` (String?)        : nullable; optional completion note.
 *
 * Compatibility guidance:
 *   - Do not reuse or renumber Hive field indices once written.
 *   - Any schema evolution (adding/removing fields) must be recorded in
 *     `migration_notes.md` with proper migration logic.
 *   - Mapper implementations (e.g., HabitCompletionModel.fromEntity()) are responsible
 *     for backward compatibility handling, such as missing fields or default values.
 *
 * Notes for implementers:
 *   - This file should remain persistence-agnostic. Keep storage annotations
 *     and logic in the data layer only.
 *   - The domain layer operates with immutable, type-safe entities.
 *   - completionDate should be normalized to date-only (midnight UTC) to avoid timezone issues.
 */

import 'package:equatable/equatable.dart';

/// Domain model for a HabitCompletion.
///
/// Each HabitCompletion belongs to a single Habit (via `habitId`) and represents
/// a single instance of completing that habit on a specific date. This entity
/// is designed for use within domain and presentation layers — persistence
/// mapping occurs in the data/local layer.
class HabitCompletion extends Equatable {
  /// Unique identifier for the completion (GUID or UUID recommended).
  ///
  /// Expected Hive field number (data layer): 0.
  final String id;

  /// Reference to the parent Habit this completion belongs to.
  ///
  /// Expected Hive field number (data layer): 1.
  final String habitId;

  /// Date when the habit was completed.
  ///
  /// Should be normalized to date-only (midnight UTC) to avoid timezone issues.
  /// Expected Hive field number (data layer): 2.
  final DateTime completionDate;

  /// Optional note about the completion.
  ///
  /// Expected Hive field number (data layer): 3.
  final String? note;

  /// Domain constructor.
  ///
  /// Keep this immutable (`const`) to ensure referential safety and ease of comparison.
  const HabitCompletion({
    required this.id,
    required this.habitId,
    required this.completionDate,
    this.note,
  });

  @override
  List<Object?> get props => [id, habitId, completionDate, note];
}
