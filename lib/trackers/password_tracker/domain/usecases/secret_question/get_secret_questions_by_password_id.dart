/*
  purpose:
    - Encapsulates the "Get Secret Questions By Password ID" use case in the domain layer.
    - Defines a single, testable action responsible for retrieving [SecretQuestion] entities
      associated with a password via the [SecretQuestionRepository] abstraction.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation or application services (e.g., Cubit, Bloc) when secret questions need to be loaded for a password.
    - Returns a list of secret questions for the specified password ID.

  compatibility guidance:
    - Do not inject data-layer classes directly here — always depend on [SecretQuestionRepository].
    - Keep this use case simple and composable with other domain operations.
*/

import '../../entities/secret_question.dart';
import '../../repositories/secret_question_repository.dart';

/// Use case class responsible for retrieving [SecretQuestion] entities by password ID.
class GetSecretQuestionsByPasswordId {
  final SecretQuestionRepository repository;
  GetSecretQuestionsByPasswordId(this.repository);

  /// Executes the get by password ID operation asynchronously.
  Future<List<SecretQuestion>> call(String passwordId) async => repository.getSecretQuestionsByPasswordId(passwordId);
}

