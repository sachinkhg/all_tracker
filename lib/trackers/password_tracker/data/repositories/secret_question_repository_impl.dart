/*
 * File: secret_question_repository_impl.dart
 *
 * Purpose:
 *  - Repository implementation that bridges the domain layer (SecretQuestion entity)
 *    with the data layer (SecretQuestionModel / Hive-backed SecretQuestionLocalDataSource).
 *  - Converts domain entities to/from data transfer objects (SecretQuestionModel)
 *    and delegates persistence operations to the local data source.
 *  - Handles encryption/decryption of answer field using PasswordEncryptionService.
 *
 * Serialization rules (high level):
 *  - The detailed serialization rules (nullable fields, default values,
 *    Hive field numbers) are defined on the SecretQuestionModel (models/secret_question_model.dart).
 *  - Answer encryption/decryption is handled here using PasswordEncryptionService.
 *
 * Compatibility guidance:
 *  - Do NOT reuse Hive field numbers. Any change to the SecretQuestionModel Hive field
 *    numbers must be accompanied by migration logic and an update to
 *    migration_notes.md.
 *  - Backward compatibility conversion logic (if needed) lives inside SecretQuestionModel
 *    (fromEntity / toEntity) or within the data source. This repository only
 *    forwards and returns converted objects.
 *
 * Notes for maintainers:
 *  - This file intentionally contains only mapping calls (SecretQuestionModel.fromEntity
 *    and model.toEntity()) and orchestration calls to the local data source.
 *  - Keep conversion logic in the model layer so tests can validate conversion
 *    behavior in one place.
 *  - Encryption/decryption is handled here to ensure answers are never stored in plain text.
 */

import '../../domain/entities/secret_question.dart';
import '../../domain/repositories/secret_question_repository.dart';
import '../datasources/secret_question_local_data_source.dart';
import '../models/secret_question_model.dart';
import '../services/password_encryption_service.dart';

/// Concrete implementation of [SecretQuestionRepository].
///
/// Responsibilities:
///  - Convert between domain [SecretQuestion] and data layer [SecretQuestionModel].
///  - Delegate persistence operations to [SecretQuestionLocalDataSource].
///  - Handle encryption/decryption of answer field.
///
/// Implementation notes:
///  - All field-level conversions, defaults, and compatibility logic
///    reside within SecretQuestionModel.
///  - The repository ensures the domain layer remains persistence-agnostic.
///  - Answer encryption/decryption is performed here using PasswordEncryptionService.
class SecretQuestionRepositoryImpl implements SecretQuestionRepository {
  /// Local data source handling actual persistence through Hive.
  final SecretQuestionLocalDataSource local;

  /// Encryption service for answer encryption/decryption.
  final PasswordEncryptionService encryptionService;

  /// Creates a repository backed by the provided local data source and encryption service.
  ///
  /// The data source should be initialized with a registered Hive adapter
  /// before creating this repository.
  SecretQuestionRepositoryImpl(this.local, this.encryptionService);

  @override
  Future<void> createSecretQuestion(SecretQuestion secretQuestion) async {
    // Encrypt answer
    final encryptedAnswer = await encryptionService.encrypt(secretQuestion.answer);

    // Convert domain entity → data model with encrypted answer
    final model = SecretQuestionModel.fromEntity(secretQuestion, encryptedAnswer: encryptedAnswer);

    // Persist through the local data source
    await local.createSecretQuestion(model);
  }

  @override
  Future<void> deleteSecretQuestion(String id) async {
    // Direct delete pass-through by ID
    await local.deleteSecretQuestion(id);
  }

  @override
  Future<List<SecretQuestion>> getSecretQuestionsByPasswordId(String passwordId) async {
    // Fetch DTOs/models filtered by passwordId and map each to the domain entity
    final models = await local.getSecretQuestionsByPasswordId(passwordId);
    final secretQuestions = <SecretQuestion>[];

    for (final model in models) {
      // Decrypt answer
      String decryptedAnswer;
      try {
        decryptedAnswer = await encryptionService.decrypt(model.encryptedAnswer);
      } catch (e) {
        // If decryption fails, skip this secret question or handle error
        // For now, we'll skip it
        continue;
      }

      secretQuestions.add(model.toEntity(decryptedAnswer: decryptedAnswer));
    }

    return secretQuestions;
  }

  @override
  Future<void> updateSecretQuestion(SecretQuestion secretQuestion) async {
    // Encrypt answer
    final encryptedAnswer = await encryptionService.encrypt(secretQuestion.answer);

    // Convert and persist updated secret question
    final model = SecretQuestionModel.fromEntity(secretQuestion, encryptedAnswer: encryptedAnswer);
    await local.updateSecretQuestion(model);
  }
}

