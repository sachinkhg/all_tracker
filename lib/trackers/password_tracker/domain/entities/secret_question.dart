/*
 * File: ./lib/trackers/password_tracker/domain/entities/secret_question.dart
 *
 * Purpose:
 *   Domain representation of a SecretQuestion used throughout the application business logic.
 *   This file defines the plain domain entity (immutable, equatable) and documents
 *   how it maps to persistence DTOs / Hive models (those mapper functions live in
 *   the data layer / local datasource).
 *
 * Serialization rules (for implementers of DTO / Hive adapters):
 *   - `id` (String)         : non-nullable, unique identifier (GUID-like). Expected to be persisted.
 *   - `passwordId` (String) : non-nullable, foreign key to Password entity.
 *   - `question` (String)   : non-nullable, the secret question text.
 *   - `answer` (String)    : non-nullable; will be encrypted in storage.
 *
 * Compatibility guidance:
 *   - When adding/removing persisted fields, DO NOT reuse Hive field numbers previously used.
 *   - Any change to persisted shape or Hive field numbers must be recorded in migration_notes.md
 *     and corresponding migration code must be added to the local data source.
 *
 * Notes for implementers:
 *   - This file intentionally contains only the pure domain entity and no persistence annotations.
 *     Keep persistence concerns (Hive annotations, adapters) inside the data layer to avoid
 *     coupling the domain layer to a storage implementation.
 */

import 'package:equatable/equatable.dart';

/// Domain model for a SecretQuestion.
///
/// This class is intended for use inside the domain and presentation layers only.
/// Persistence-specific mapping (Hive fields, DTO serialization) should live in the
/// data/local layer (e.g., `secret_question_model.dart`) which converts
/// between this entity and the stored representation.
class SecretQuestion extends Equatable {
  /// Unique identifier for the secret question (GUID recommended).
  ///
  /// Persistence hint: typically stored as the primary id in the DTO.
  /// Expected Hive field number (data layer): 0.
  final String id;

  /// Foreign key linking this secret question to its parent Password.
  ///
  /// Non-nullable: required foreign key to Password entity.
  /// Expected Hive field number (data layer): 1.
  final String passwordId;

  /// The secret question text.
  ///
  /// Persistence hint: non-nullable in domain; if a persisted record contains
  /// a null/empty question, the mapper should provide a sensible fallback or reject.
  /// Expected Hive field number (data layer): 2.
  final String question;

  /// The answer to the secret question (will be encrypted in storage).
  ///
  /// Non-nullable in domain. This will be encrypted when stored.
  /// Expected Hive field number (data layer): 3 (encrypted).
  final String answer;

  /// Domain constructor.
  ///
  /// Keep this immutable (`const`) so instances can be compared and used in const contexts.
  const SecretQuestion({
    required this.id,
    required this.passwordId,
    required this.question,
    required this.answer,
  });

  @override
  List<Object?> get props => [id, passwordId, question, answer];
}

