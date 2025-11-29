/*
  purpose:
    - Defines the abstract contract for the SecretQuestion data access layer (Domain → Data boundary).
    - This repository interface decouples the domain layer from implementation details
      such as Hive, SQLite, REST APIs, or any persistence mechanism.
    - Implementations must ensure correct entity conversion and validation between
      domain models (SecretQuestion) and their data source representations.

  usage:
    - The application's SecretQuestionCubit or domain use-cases depend on this interface,
      not the concrete implementation.
    - Concrete implementations (e.g., HiveSecretQuestionRepository, LocalSecretQuestionRepository)
      should reside under the data/ or infrastructure/ layer.
    - Modify this interface only when there are domain-level changes to how SecretQuestions
      are managed (not when the persistence schema changes).

  compatibility guidance:
    - Avoid persistence-specific details or technology-dependent parameters.
    - Keep all operations asynchronous and domain-pure.
    - On modification, document the change in ARCHITECTURE.md and update
      relevant contribution and migration notes.
*/

import '../entities/secret_question.dart';

/// Abstract repository defining CRUD operations for [SecretQuestion] entities.
///
/// This repository defines the boundary between the domain layer and data sources.
/// Concrete implementations are responsible for data persistence, mapping, and
/// error handling — keeping the domain layer completely agnostic to infrastructure.
abstract class SecretQuestionRepository {
  /// Retrieve all secret questions associated with a specific [passwordId].
  ///
  /// Returns an empty list if the password has no secret questions or the password ID does not exist.
  Future<List<SecretQuestion>> getSecretQuestionsByPasswordId(String passwordId);

  /// Create a new [SecretQuestion] record in storage.
  ///
  /// Implementations must ensure ID uniqueness and perform validation before persistence.
  Future<void> createSecretQuestion(SecretQuestion secretQuestion);

  /// Update an existing [SecretQuestion].
  ///
  /// Implementations should validate that [secretQuestion.id] exists before updating.
  /// Throws or logs appropriately if the secret question cannot be updated.
  Future<void> updateSecretQuestion(SecretQuestion secretQuestion);

  /// Delete a secret question identified by its [id].
  ///
  /// Implementations should handle non-existent IDs gracefully.
  Future<void> deleteSecretQuestion(String id);
}

