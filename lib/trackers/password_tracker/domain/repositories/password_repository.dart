/*
  purpose:
    - Defines the abstract contract for the Password data access layer (Domain → Data boundary).
    - This repository interface decouples the domain layer from implementation details
      such as Hive, SQLite, REST APIs, or any persistence mechanism.
    - Implementations must ensure correct entity conversion and validation between
      domain models (Password) and their data source representations.

  usage:
    - The application's PasswordCubit or domain use-cases depend on this interface,
      not the concrete implementation.
    - Concrete implementations (e.g., HivePasswordRepository, LocalPasswordRepository)
      should reside under the data/ or infrastructure/ layer.
    - Modify this interface only when there are domain-level changes to how Passwords
      are managed (not when the persistence schema changes).

  compatibility guidance:
    - Avoid persistence-specific details or technology-dependent parameters.
    - Keep all operations asynchronous and domain-pure.
    - On modification, document the change in ARCHITECTURE.md and update
      relevant contribution and migration notes.
*/

import '../entities/password.dart';

/// Abstract repository defining CRUD operations for [Password] entities.
///
/// This repository defines the boundary between the domain layer and data sources.
/// Concrete implementations are responsible for data persistence, mapping, and
/// error handling — keeping the domain layer completely agnostic to infrastructure.
abstract class PasswordRepository {
  /// Retrieve all passwords from storage.
  ///
  /// The order and filtering behavior are left to the implementation.
  /// Implementations may choose to return all passwords or scoped ones as per app logic.
  Future<List<Password>> getAllPasswords();

  /// Retrieve a single password by its unique [id].
  ///
  /// Returns `null` if the password is not found.
  Future<Password?> getPasswordById(String id);

  /// Retrieve all passwords associated with a specific [categoryGroup].
  ///
  /// Returns an empty list if no passwords match the category or the category does not exist.
  Future<List<Password>> getPasswordsByCategory(String categoryGroup);

  /// Create a new [Password] record in storage.
  ///
  /// Implementations must ensure ID uniqueness and perform validation before persistence.
  Future<void> createPassword(Password password);

  /// Update an existing [Password].
  ///
  /// Implementations should validate that [password.id] exists before updating.
  /// Throws or logs appropriately if the password cannot be updated.
  Future<void> updatePassword(Password password);

  /// Delete a password identified by its [id].
  ///
  /// Implementations should handle non-existent IDs gracefully and ensure
  /// referential integrity (e.g., if cascades to secret questions are needed).
  Future<void> deletePassword(String id);
}

