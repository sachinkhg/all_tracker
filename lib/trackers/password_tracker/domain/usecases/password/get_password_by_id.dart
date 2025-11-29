/*
  purpose:
    - Encapsulates the "Get Password By ID" use case in the domain layer.
    - Defines a single, testable action responsible for retrieving a specific [Password]
      via the [PasswordRepository] abstraction.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation or application services (e.g., Cubit, Bloc) when a specific password needs to be loaded.
    - Returns the password if found, null otherwise.

  compatibility guidance:
    - Do not inject data-layer classes directly here — always depend on [PasswordRepository].
    - Keep this use case simple and composable with other domain operations.
*/

import '../../entities/password.dart';
import '../../repositories/password_repository.dart';

/// Use case class responsible for retrieving a [Password] by its ID.
class GetPasswordById {
  final PasswordRepository repository;
  GetPasswordById(this.repository);

  /// Executes the get by ID operation asynchronously.
  Future<Password?> call(String id) async => repository.getPasswordById(id);
}

