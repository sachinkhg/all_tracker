/*
 * File: secret_question_local_data_source.dart
 *
 * Purpose:
 *   Hive-backed local data source for SecretQuestion objects. This file provides an
 *   abstract contract (SecretQuestionLocalDataSource) and a Hive implementation
 *   (SecretQuestionLocalDataSourceImpl) that persist SecretQuestionModel instances into a Hive box.
 *
 * Serialization rules (high level):
 *   - The concrete Hive adapter and the SecretQuestionModel DTO live in ../models/secret_question_model.dart.
 *   - Nullable fields, defaults, and any custom conversion are defined on SecretQuestionModel.
 *     Refer to SecretQuestionModel for which fields are nullable and default values.
 *   - Keys used for storage: secretQuestion.id (String) is used as the Hive key (not an auto-increment).
 *
 * Compatibility guidance:
 *   - Do NOT reuse Hive field numbers in secret_question_model.dart when adding/removing fields.
 *   - When changing the model layout or field numbers, update migration_notes.md
 *     with the adapter version and migration steps.
 *   - Any backward-compatibility conversions (legacy values -> new schema) should be
 *     implemented in SecretQuestionModel (factory / fromEntity / fromJson) so the data source
 *     remains thin and focused on persistence.
 *
 * Developer notes:
 *   - This file intentionally does not perform model conversions — it delegates that
 *     responsibility to SecretQuestionModel. Keep storage operations (put/get/delete) simple.
 *   - If you add caching, locking, or batch operations, maintain the invariant that
 *     keys are secretQuestion.id and that SecretQuestionModel instances match the Hive adapter version.
 */

import 'package:hive/hive.dart';
import '../models/secret_question_model.dart';

/// Abstract data source for local (Hive) secret question storage.
///
/// Implementations should be simple adapters that read/write SecretQuestionModel instances.
/// Conversions between domain entity and DTO should be implemented in SecretQuestionModel.
abstract class SecretQuestionLocalDataSource {
  /// Returns all secret questions stored in the local box.
  Future<List<SecretQuestionModel>> getAllSecretQuestions();

  /// Returns a single SecretQuestionModel by its string id key, or null if not found.
  Future<SecretQuestionModel?> getSecretQuestionById(String id);

  /// Returns all secret questions associated with a specific passwordId.
  Future<List<SecretQuestionModel>> getSecretQuestionsByPasswordId(String passwordId);

  /// Persists a new SecretQuestionModel. The implementation is expected to use secretQuestion.id as key.
  Future<void> createSecretQuestion(SecretQuestionModel secretQuestion);

  /// Updates an existing SecretQuestionModel (or creates it if missing) — uses the same
  /// semantics as Hive's `put` (overwrite if exists).
  Future<void> updateSecretQuestion(SecretQuestionModel secretQuestion);

  /// Deletes a secret question by its id key.
  Future<void> deleteSecretQuestion(String id);
}

/// Hive implementation of [SecretQuestionLocalDataSource].
///
/// This class treats the provided [box] as the single source of truth for
/// SecretQuestionModel persistence. It uses `secretQuestion.id` (String) as the Hive key — this keeps
/// keys stable across app runs and simplifies lookup.
///
/// Important:
///  - Any legacy value handling (e.g. migrating an old string format to a new enum)
///    should be done inside SecretQuestionModel (e.g., SecretQuestionModel.fromEntity/fromJson).
///  - The box must be registered with the appropriate adapter for SecretQuestionModel before
///    this class is constructed.
class SecretQuestionLocalDataSourceImpl implements SecretQuestionLocalDataSource {
  /// Hive box that stores [SecretQuestionModel] entries.
  ///
  /// Rationale: using a typed Box<SecretQuestionModel> enforces compile-time safety and
  /// ensures the Hive adapter for SecretQuestionModel is used for serialization.
  final Box<SecretQuestionModel> box;

  /// Create the local data source with the provided Hive box.
  ///
  /// The box should be opened and the SecretQuestionModel adapter registered prior to
  /// passing it here (typically during app initialization in core/hive initializer).
  SecretQuestionLocalDataSourceImpl(this.box);

  @override
  Future<void> createSecretQuestion(SecretQuestionModel secretQuestion) async {
    // Use secretQuestion.id as the key. This keeps keys consistent and human-readable.
    // We intentionally rely on Hive's `put` semantics — it will create or overwrite.
    await box.put(secretQuestion.id, secretQuestion);
  }

  @override
  Future<void> deleteSecretQuestion(String id) async {
    // Remove the entry with the given id key. No additional logic here to keep
    // the data source thin; domain-level cascade deletes (if any) should be handled
    // by the repository/usecase layer.
    await box.delete(id);
  }

  @override
  Future<SecretQuestionModel?> getSecretQuestionById(String id) async {
    // Direct box lookup by string key. Returns null if not present.
    // If additional compatibility work is needed (e.g. rehydration), implement it
    // in SecretQuestionModel (constructor/factory) so this call remains simple.
    return box.get(id);
  }

  @override
  Future<List<SecretQuestionModel>> getAllSecretQuestions() async {
    // Convert box values iterable to a list. Ordering is the insertion order from Hive.
    // If deterministic sorting is required, do it at the repository/presentation layer rather than here.
    return box.values.toList();
  }

  @override
  Future<List<SecretQuestionModel>> getSecretQuestionsByPasswordId(String passwordId) async {
    // Filter all secret questions by passwordId
    return box.values.where((sq) => sq.passwordId == passwordId).toList();
  }

  @override
  Future<void> updateSecretQuestion(SecretQuestionModel secretQuestion) async {
    // Update uses the same `put` as create — overwrites existing entry with same key.
    // This keeps create/update semantics unified and reduces duplication.
    await box.put(secretQuestion.id, secretQuestion);
  }
}

