/*
 * File: ./lib/goal_tracker/domain/entities/goal.dart
 *
 * Purpose:
 *   Domain representation of a Goal used throughout the application business logic.
 *   This file defines the plain domain entity (immutable, equatable) and documents
 *   how it maps to persistence DTOs / Hive models (those mapper functions live in
 *   the data layer / local datasource).
 *
 * Serialization rules (for implementers of DTO / Hive adapters):
 *   - `id` (String)         : non-nullable, unique identifier (GUID-like). Expected to be persisted.
 *   - `name` (String)       : non-nullable, user-facing title.
 *   - `description` (String?): nullable; empty vs null semantics should be reconciled by mappers.
 *   - `targetDate` (DateTime?): nullable; when absent, treat as "no deadline".
 *   - `context` (String?)   : nullable; used for categorisation / tags.
 *   - `isCompleted` (bool)  : non-nullable, defaults to `false` when missing in legacy records.
 *
 * Compatibility guidance:
 *   - When adding/removing persisted fields, DO NOT reuse Hive field numbers previously used.
 *   - Any change to persisted shape or Hive field numbers must be recorded in migration_notes.md
 *     and corresponding migration code must be added to the local data source.
 *   - Mapper helpers (e.g., GoalDto.fromEntity(), GoalDto.toEntity()) should explicitly handle
 *     legacy values (for instance missing `isCompleted` => default to `false`, empty strings => null).
 *
 * Notes for implementers:
 *   - This file intentionally contains only the pure domain entity and no persistence annotations.
 *     Keep persistence concerns (Hive annotations, adapters) inside the data layer to avoid
 *     coupling the domain layer to a storage implementation.
 */

import 'package:equatable/equatable.dart';

/// Domain model for a Goal.
///
/// This class is intended for use inside the domain and presentation layers only.
/// Persistence-specific mapping (Hive fields, DTO serialization) should live in the
/// data/local layer (e.g., `goal_dto.dart` or `goal_hive_adapter.dart`) which converts
/// between this entity and the stored representation.
///
/// See the project README / ARCHITECTURE for where mappers and adapters are placed.
class Goal extends Equatable {
  /// Unique identifier for the goal (GUID recommended).
  ///
  /// Persistence hint: typically stored as the primary id in the DTO.
  /// Expected Hive field number (data layer): 0.
  final String id; // Unique identifier (GUID)

  /// Human-readable name/title for the goal.
  ///
  /// Persistence hint: non-nullable in domain; if a persisted record contains
  /// a null/empty name, the mapper should provide a sensible fallback or reject.
  /// Expected Hive field number (data layer): 1.
  final String name; // Goal name/title

  /// Optional longer description for the goal.
  ///
  /// Nullable: describe optional text, keep distinction between `null` and empty string
  /// consistent across mappers. If migrating from legacy storage that stored empty
  /// strings for "no description", convert empty -> null (or vice versa) consistently.
  /// Expected Hive field number (data layer): 2.
  final String? description; // Goal description

  /// Optional target/deadline for the goal.
  ///
  /// Nullable: absence implies "no deadline". Mappers should parse legacy integer timestamps
  /// or ISO strings as required and handle invalid/zero values by treating them as `null`.
  /// Expected Hive field number (data layer): 3.
  final DateTime? targetDate; // Optional target date for the goal

  /// Optional context/category for the goal (e.g., "Work", "Health").
  ///
  /// Nullable: used for filtering/grouping in the UI. Prefer reusing a small set of
  /// canonical context strings where possible.
  /// Expected Hive field number (data layer): 4.
  final String? context; // Optional context/category for the goal

  /// Whether the goal is completed.
  ///
  /// Non-nullable in domain. Mappers should default a missing or unknown value
  /// in persisted records to `false` to preserve backward compatibility.
  /// Expected Hive field number (data layer): 5.
  final bool isCompleted; // Status of the goal

  /// Domain constructor.
  ///
  /// Keep this immutable (`const`) so instances can be compared and used in const contexts.
  /// Note: do not encode persistence defaults here beyond those of the domain (e.g., isCompleted=false).
  const Goal({
    required this.id,
    required this.name,
    required this.description,
    this.targetDate,
    this.context,
    this.isCompleted = false,
  });

  @override
  List<Object?> get props => [id, name, description, targetDate, context, isCompleted];
}
