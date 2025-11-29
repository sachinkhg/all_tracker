/*
  purpose:
    - Encapsulates the "Update Password" use case in the domain layer.
    - Defines a single, testable action responsible for updating an existing [Password]
      via the [PasswordRepository] abstraction.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation or application services (e.g., Cubit, Bloc) when a password is updated.
    - Accepts a [Password] domain entity with updated values.
    - Delegates persistence responsibility to the repository layer.

  compatibility guidance:
    - Do not inject data-layer classes directly here — always depend on [PasswordRepository].
    - Keep this use case simple and composable with other domain operations.
*/

import '../../entities/password.dart';
import '../../repositories/password_repository.dart';

/// Use case class responsible for updating an existing [Password].
class UpdatePassword {
  final PasswordRepository repository;
  UpdatePassword(this.repository);

  /// Executes the update operation asynchronously.
  Future<void> call(Password password) async => repository.updatePassword(password);
}

