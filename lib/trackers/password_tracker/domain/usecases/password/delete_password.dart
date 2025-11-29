/*
  purpose:
    - Encapsulates the "Delete Password" use case in the domain layer.
    - Defines a single, testable action responsible for deleting a [Password]
      via the [PasswordRepository] abstraction.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation or application services (e.g., Cubit, Bloc) when a password is deleted.
    - Accepts the password ID to delete.
    - Delegates persistence responsibility to the repository layer.

  compatibility guidance:
    - Do not inject data-layer classes directly here — always depend on [PasswordRepository].
    - Keep this use case simple and composable with other domain operations.
*/

import '../../repositories/password_repository.dart';

/// Use case class responsible for deleting a [Password].
class DeletePassword {
  final PasswordRepository repository;
  DeletePassword(this.repository);

  /// Executes the delete operation asynchronously.
  Future<void> call(String id) async => repository.deletePassword(id);
}

