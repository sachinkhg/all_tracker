/*
 * File: password_repository_impl.dart
 *
 * Purpose:
 *  - Repository implementation that bridges the domain layer (Password entity)
 *    with the data layer (PasswordModel / Hive-backed PasswordLocalDataSource).
 *  - Converts domain entities to/from data transfer objects (PasswordModel)
 *    and delegates persistence operations to the local data source.
 *  - Handles encryption/decryption of password field using PasswordEncryptionService.
 *
 * Serialization rules (high level):
 *  - The detailed serialization rules (nullable fields, default values,
 *    Hive field numbers) are defined on the PasswordModel (models/password_model.dart).
 *  - Nullable fields in the domain Password (e.g., url, username) are propagated
 *    into the PasswordModel. Any defaults required for storage are applied by
 *    the PasswordModel constructor or adapter, not by this repository.
 *  - Password encryption/decryption is handled here using PasswordEncryptionService.
 *
 * Compatibility guidance:
 *  - Do NOT reuse Hive field numbers. Any change to the PasswordModel Hive field
 *    numbers must be accompanied by migration logic and an update to
 *    migration_notes.md.
 *  - Backward compatibility conversion logic (if needed) lives inside PasswordModel
 *    (fromEntity / toEntity) or within the data source. This repository only
 *    forwards and returns converted objects.
 *
 * Notes for maintainers:
 *  - This file intentionally contains only mapping calls (PasswordModel.fromEntity
 *    and model.toEntity()) and orchestration calls to the local data source.
 *  - Keep conversion logic in the model layer so tests can validate conversion
 *    behavior in one place.
 *  - Encryption/decryption is handled here to ensure passwords are never stored in plain text.
 */

import '../../domain/entities/password.dart';
import '../../domain/repositories/password_repository.dart';
import '../datasources/password_local_data_source.dart';
import '../models/password_model.dart';
import '../services/password_encryption_service.dart';

/// Concrete implementation of [PasswordRepository].
///
/// Responsibilities:
///  - Convert between domain [Password] and data layer [PasswordModel].
///  - Delegate persistence operations to [PasswordLocalDataSource].
///  - Handle encryption/decryption of password field.
///
/// Implementation notes:
///  - All field-level conversions, defaults, and compatibility logic
///    reside within PasswordModel.
///  - The repository ensures the domain layer remains persistence-agnostic.
///  - Password encryption/decryption is performed here using PasswordEncryptionService.
class PasswordRepositoryImpl implements PasswordRepository {
  /// Local data source handling actual persistence through Hive.
  final PasswordLocalDataSource local;

  /// Encryption service for password encryption/decryption.
  final PasswordEncryptionService encryptionService;

  /// Creates a repository backed by the provided local data source and encryption service.
  ///
  /// The data source should be initialized with a registered Hive adapter
  /// before creating this repository.
  PasswordRepositoryImpl(this.local, this.encryptionService);

  @override
  Future<void> createPassword(Password password) async {
    // Encrypt password if provided
    String? encryptedPassword;
    if (password.password != null && password.password!.isNotEmpty) {
      encryptedPassword = await encryptionService.encrypt(password.password!);
    }

    // Convert domain entity → data model with encrypted password
    final model = PasswordModel.fromEntity(password, encryptedPassword: encryptedPassword);

    // Persist through the local data source
    await local.createPassword(model);
  }

  @override
  Future<void> deletePassword(String id) async {
    // Direct delete pass-through by ID
    await local.deletePassword(id);
  }

  @override
  Future<List<Password>> getAllPasswords() async {
    // Fetch DTOs/models and map each to the domain entity
    final models = await local.getAllPasswords();
    final passwords = <Password>[];

    for (final model in models) {
      // Decrypt password if encrypted
      String? decryptedPassword;
      if (model.encryptedPassword != null && model.encryptedPassword!.isNotEmpty) {
        try {
          decryptedPassword = await encryptionService.decrypt(model.encryptedPassword!);
        } catch (e) {
          // If decryption fails (e.g., different device/encryption key), 
          // still return the password but with null password field
          // This allows the user to see the entry and re-enter the password if needed
          // Set decryptedPassword to null - the password entry will still be shown
          decryptedPassword = null;
        }
      }

      final password = model.toEntity(decryptedPassword: decryptedPassword);
      passwords.add(password);
    }

    return passwords;
  }

  @override
  Future<Password?> getPasswordById(String id) async {
    // Fetch model by ID and convert to domain entity
    final model = await local.getPasswordById(id);
    if (model == null) return null;

    // Decrypt password if encrypted
    String? decryptedPassword;
    if (model.encryptedPassword != null && model.encryptedPassword!.isNotEmpty) {
      try {
        decryptedPassword = await encryptionService.decrypt(model.encryptedPassword!);
      } catch (e) {
        // If decryption fails (e.g., different device/encryption key),
        // still return the password but with null password field
        decryptedPassword = null;
      }
    }

    return model.toEntity(decryptedPassword: decryptedPassword);
  }

  @override
  Future<List<Password>> getPasswordsByCategory(String categoryGroup) async {
    // Get all passwords and filter by category
    final allPasswords = await getAllPasswords();
    return allPasswords.where((p) => p.categoryGroup == categoryGroup).toList();
  }

  @override
  Future<void> updatePassword(Password password) async {
    // Encrypt password if provided
    String? encryptedPassword;
    if (password.password != null && password.password!.isNotEmpty) {
      encryptedPassword = await encryptionService.encrypt(password.password!);
    }

    // Convert and persist updated password
    final model = PasswordModel.fromEntity(password, encryptedPassword: encryptedPassword);
    await local.updatePassword(model);
  }
}

