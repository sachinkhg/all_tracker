/*
  purpose:
    - Encapsulates the "Update Secret Question" use case in the domain layer.
    - Defines a single, testable action responsible for updating an existing [SecretQuestion]
      via the [SecretQuestionRepository] abstraction.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation or application services (e.g., Cubit, Bloc) when a secret question is updated.
    - Accepts a [SecretQuestion] domain entity with updated values.
    - Delegates persistence responsibility to the repository layer.

  compatibility guidance:
    - Do not inject data-layer classes directly here — always depend on [SecretQuestionRepository].
    - Keep this use case simple and composable with other domain operations.
*/

import '../../entities/secret_question.dart';
import '../../repositories/secret_question_repository.dart';

/// Use case class responsible for updating an existing [SecretQuestion].
class UpdateSecretQuestion {
  final SecretQuestionRepository repository;
  UpdateSecretQuestion(this.repository);

  /// Executes the update operation asynchronously.
  Future<void> call(SecretQuestion secretQuestion) async => repository.updateSecretQuestion(secretQuestion);
}

