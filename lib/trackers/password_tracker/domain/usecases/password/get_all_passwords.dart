/*
  purpose:
    - Encapsulates the "Get All Passwords" use case in the domain layer.
    - Defines a single, testable action responsible for retrieving all [Password] entities
      via the [PasswordRepository] abstraction.
    - Keeps business rules and application logic independent of data storage or UI layers.

  usage:
    - Invoked by presentation or application services (e.g., Cubit, Bloc) when passwords need to be loaded.
    - Returns a list of all passwords from storage.

  compatibility guidance:
    - Do not inject data-layer classes directly here — always depend on [PasswordRepository].
    - Keep this use case simple and composable with other domain operations.
*/

import '../../entities/password.dart';
import '../../repositories/password_repository.dart';

/// Use case class responsible for retrieving all [Password] entities.
class GetAllPasswords {
  final PasswordRepository repository;
  GetAllPasswords(this.repository);

  /// Executes the get all operation asynchronously.
  Future<List<Password>> call() async => repository.getAllPasswords();
}

