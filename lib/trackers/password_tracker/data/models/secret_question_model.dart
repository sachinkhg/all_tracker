import 'package:hive/hive.dart';
import '../../domain/entities/secret_question.dart';

part 'secret_question_model.g.dart'; // Generated via build_runner

/// ---------------------------------------------------------------------------
/// SecretQuestionModel – Data Transfer Object (DTO) / Hive Persistence Model
/// ---------------------------------------------------------------------------
///
/// Purpose:
/// - Represents a persisted `SecretQuestion` entity within Hive.
/// - Handles encryption/decryption of answer field through PasswordEncryptionService.
/// - Acts as a bridge between domain-layer entities and Hive storage.
///
/// Schema & Migration Guidelines:
/// - Each `@HiveField` index is permanent once written to storage.
/// - Never reuse or reorder field numbers — doing so will corrupt persisted data.
/// - Add new fields only at the end with new, unique field numbers.
/// - Document any changes in `migration_notes.md`.
///
/// Security:
/// - Answer field is encrypted before storage and decrypted when retrieved.
/// - Encryption is handled by PasswordEncryptionService.
/// ---------------------------------------------------------------------------

@HiveType(typeId: 23)
class SecretQuestionModel extends HiveObject {
  /// Unique identifier for the secret question.
  ///
  /// Hive field number **0** — stable ID, never change or reuse.
  @HiveField(0)
  String id;

  /// Foreign key linking this secret question to its parent Password.
  ///
  /// Hive field number **1** — required.
  @HiveField(1)
  String passwordId;

  /// The secret question text.
  ///
  /// Hive field number **2** — required.
  @HiveField(2)
  String question;

  /// Encrypted answer (stored as encrypted string).
  ///
  /// Hive field number **3** — required; stores encrypted answer.
  /// The actual answer is encrypted before storage.
  @HiveField(3)
  String encryptedAnswer;

  SecretQuestionModel({
    required this.id,
    required this.passwordId,
    required this.question,
    required this.encryptedAnswer,
  });

  /// Factory constructor to build a [SecretQuestionModel] from a domain [SecretQuestion].
  ///
  /// Note: This method requires an encryption service to encrypt the answer.
  /// The encryption should be handled by the repository layer, not here.
  /// This factory assumes the answer is already encrypted if provided.
  factory SecretQuestionModel.fromEntity(SecretQuestion sq, {String? encryptedAnswer}) => SecretQuestionModel(
        id: sq.id,
        passwordId: sq.passwordId,
        question: sq.question,
        encryptedAnswer: encryptedAnswer ?? '',
      );

  /// Converts this model back into a domain [SecretQuestion] entity.
  ///
  /// Note: This method requires an encryption service to decrypt the answer.
  /// The decryption should be handled by the repository layer.
  /// This method assumes the answer will be decrypted by the repository.
  SecretQuestion toEntity({String? decryptedAnswer}) => SecretQuestion(
        id: id,
        passwordId: passwordId,
        question: question,
        answer: decryptedAnswer ?? '',
      );

  /// Creates a copy of this SecretQuestionModel with the given fields replaced.
  ///
  /// Useful for updates where only certain fields change.
  SecretQuestionModel copyWith({
    String? id,
    String? passwordId,
    String? question,
    String? encryptedAnswer,
  }) {
    return SecretQuestionModel(
      id: id ?? this.id,
      passwordId: passwordId ?? this.passwordId,
      question: question ?? this.question,
      encryptedAnswer: encryptedAnswer ?? this.encryptedAnswer,
    );
  }
}

