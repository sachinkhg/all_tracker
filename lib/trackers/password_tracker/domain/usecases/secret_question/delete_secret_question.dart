/*
  purpose:
    - Encapsulates the "Delete Secret Question" use case in the domain layer.
    - Defines a single, testable action responsible for deleting a [SecretQuestion]
      via the [SecretQuestionRepository] abstraction.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation or application services (e.g., Cubit, Bloc) when a secret question is deleted.
    - Accepts the secret question ID to delete.
    - Delegates persistence responsibility to the repository layer.

  compatibility guidance:
    - Do not inject data-layer classes directly here — always depend on [SecretQuestionRepository].
    - Keep this use case simple and composable with other domain operations.
*/

import '../../repositories/secret_question_repository.dart';

/// Use case class responsible for deleting a [SecretQuestion].
class DeleteSecretQuestion {
  final SecretQuestionRepository repository;
  DeleteSecretQuestion(this.repository);

  /// Executes the delete operation asynchronously.
  Future<void> call(String id) async => repository.deleteSecretQuestion(id);
}

