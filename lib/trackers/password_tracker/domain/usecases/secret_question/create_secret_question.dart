/*
  purpose:
    - Encapsulates the "Create Secret Question" use case in the domain layer.
    - Defines a single, testable action responsible for adding a new [SecretQuestion]
      via the [SecretQuestionRepository] abstraction.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation or application services (e.g., Cubit, Bloc) when a new secret question is created.
    - Accepts a [SecretQuestion] domain entity already validated or constructed via the UI.
    - Delegates persistence responsibility to the repository layer.

  compatibility guidance:
    - Do not inject data-layer classes directly here — always depend on [SecretQuestionRepository].
    - Keep this use case simple and composable with other domain operations.
*/

import '../../entities/secret_question.dart';
import '../../repositories/secret_question_repository.dart';

/// Use case class responsible for creating a new [SecretQuestion].
class CreateSecretQuestion {
  final SecretQuestionRepository repository;
  CreateSecretQuestion(this.repository);

  /// Executes the create operation asynchronously.
  Future<void> call(SecretQuestion secretQuestion) async => repository.createSecretQuestion(secretQuestion);
}

