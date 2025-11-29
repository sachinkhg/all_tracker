/*
 * File: password_local_data_source.dart
 *
 * Purpose:
 *   Hive-backed local data source for Password objects. This file provides an
 *   abstract contract (PasswordLocalDataSource) and a Hive implementation
 *   (PasswordLocalDataSourceImpl) that persist PasswordModel instances into a Hive box.
 *
 * Serialization rules (high level):
 *   - The concrete Hive adapter and the PasswordModel DTO live in ../models/password_model.dart.
 *   - Nullable fields, defaults, and any custom conversion are defined on PasswordModel.
 *     Refer to PasswordModel for which fields are nullable and default values.
 *   - Keys used for storage: password.id (String) is used as the Hive key (not an auto-increment).
 *
 * Compatibility guidance:
 *   - Do NOT reuse Hive field numbers in password_model.dart when adding/removing fields.
 *   - When changing the model layout or field numbers, update migration_notes.md
 *     with the adapter version and migration steps.
 *   - Any backward-compatibility conversions (legacy values -> new schema) should be
 *     implemented in PasswordModel (factory / fromEntity / fromJson) so the data source
 *     remains thin and focused on persistence.
 *
 * Developer notes:
 *   - This file intentionally does not perform model conversions — it delegates that
 *     responsibility to PasswordModel. Keep storage operations (put/get/delete) simple.
 *   - If you add caching, locking, or batch operations, maintain the invariant that
 *     keys are password.id and that PasswordModel instances match the Hive adapter version.
 */

import 'package:hive/hive.dart';
import '../models/password_model.dart';

/// Abstract data source for local (Hive) password storage.
///
/// Implementations should be simple adapters that read/write PasswordModel instances.
/// Conversions between domain entity and DTO should be implemented in PasswordModel.
abstract class PasswordLocalDataSource {
  /// Returns all passwords stored in the local box.
  Future<List<PasswordModel>> getAllPasswords();

  /// Returns a single PasswordModel by its string id key, or null if not found.
  Future<PasswordModel?> getPasswordById(String id);

  /// Persists a new PasswordModel. The implementation is expected to use password.id as key.
  Future<void> createPassword(PasswordModel password);

  /// Updates an existing PasswordModel (or creates it if missing) — uses the same
  /// semantics as Hive's `put` (overwrite if exists).
  Future<void> updatePassword(PasswordModel password);

  /// Deletes a password by its id key.
  Future<void> deletePassword(String id);
}

/// Hive implementation of [PasswordLocalDataSource].
///
/// This class treats the provided [box] as the single source of truth for
/// PasswordModel persistence. It uses `password.id` (String) as the Hive key — this keeps
/// keys stable across app runs and simplifies lookup.
///
/// Important:
///  - Any legacy value handling (e.g. migrating an old string format to a new enum)
///    should be done inside PasswordModel (e.g., PasswordModel.fromEntity/fromJson).
///  - The box must be registered with the appropriate adapter for PasswordModel before
///    this class is constructed.
class PasswordLocalDataSourceImpl implements PasswordLocalDataSource {
  /// Hive box that stores [PasswordModel] entries.
  ///
  /// Rationale: using a typed Box<PasswordModel> enforces compile-time safety and
  /// ensures the Hive adapter for PasswordModel is used for serialization.
  final Box<PasswordModel> box;

  /// Create the local data source with the provided Hive box.
  ///
  /// The box should be opened and the PasswordModel adapter registered prior to
  /// passing it here (typically during app initialization in core/hive initializer).
  PasswordLocalDataSourceImpl(this.box);

  @override
  Future<void> createPassword(PasswordModel password) async {
    // Use password.id as the key. This keeps keys consistent and human-readable.
    // We intentionally rely on Hive's `put` semantics — it will create or overwrite.
    await box.put(password.id, password);
  }

  @override
  Future<void> deletePassword(String id) async {
    // Remove the entry with the given id key. No additional logic here to keep
    // the data source thin; domain-level cascade deletes (if any) should be handled
    // by the repository/usecase layer.
    await box.delete(id);
  }

  @override
  Future<PasswordModel?> getPasswordById(String id) async {
    // Direct box lookup by string key. Returns null if not present.
    // If additional compatibility work is needed (e.g. rehydration), implement it
    // in PasswordModel (constructor/factory) so this call remains simple.
    return box.get(id);
  }

  @override
  Future<List<PasswordModel>> getAllPasswords() async {
    // Convert box values iterable to a list. Ordering is the insertion order from Hive.
    // If deterministic sorting is required (e.g., by lastUpdated), do it at the
    // repository/presentation layer rather than here.
    return box.values.toList();
  }

  @override
  Future<void> updatePassword(PasswordModel password) async {
    // Update uses the same `put` as create — overwrites existing entry with same key.
    // This keeps create/update semantics unified and reduces duplication.
    await box.put(password.id, password);
  }
}

