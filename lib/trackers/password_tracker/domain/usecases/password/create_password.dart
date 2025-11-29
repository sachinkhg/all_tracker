/*
  purpose:
    - Encapsulates the "Create Password" use case in the domain layer.
    - Defines a single, testable action responsible for adding a new [Password]
      via the [PasswordRepository] abstraction.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation or application services (e.g., Cubit, Bloc) when a new password is created.
    - Accepts a [Password] domain entity already validated or constructed via the UI.
    - Delegates persistence responsibility to the repository layer.

  compatibility guidance:
    - Do not inject data-layer classes directly here — always depend on [PasswordRepository].
    - Keep this use case simple and composable with other domain operations.
*/

import '../../entities/password.dart';
import '../../repositories/password_repository.dart';

/// Use case class responsible for creating a new [Password].
class CreatePassword {
  final PasswordRepository repository;
  CreatePassword(this.repository);

  /// Executes the create operation asynchronously.
  Future<void> call(Password password) async => repository.createPassword(password);
}

